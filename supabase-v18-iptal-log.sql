-- v18 EK: kalıcı iptal geçmişi (teslimat_kayitlari ile aynı desen)
-- SQL Editor → New query → yapıştır → RUN
--
-- "Teslimleri arşivle" ile orders tablosundan silinen İPTAL kayıtları
-- şimdiye kadar hiçbir yerde kalmıyordu. Bir sipariş status='canc'
-- olduğu an bir trigger burayı otomatik doldurur; arşivleme bunu etkilemez.

create table if not exists iptal_kayitlari (
  id                uuid primary key default gen_random_uuid(),
  order_id          uuid,
  customer_name     text,
  qty               int,
  vehicle           text,
  note              text,
  order_created_at  timestamptz,
  cancelled_at      timestamptz default now(),
  logged_at         timestamptz default now()
);

alter table iptal_kayitlari enable row level security;

do $$
begin
  drop policy if exists "read_all" on iptal_kayitlari;
  drop policy if exists "write_all" on iptal_kayitlari;
  create policy "read_all"  on iptal_kayitlari for select using (true);
  create policy "write_all" on iptal_kayitlari for all using (true) with check (true);
end $$;

create or replace function log_iptal() returns trigger as $$
begin
  if NEW.status = 'canc' and (TG_OP = 'INSERT' or OLD.status is distinct from 'canc') then
    insert into iptal_kayitlari
      (order_id, customer_name, qty, vehicle, note, order_created_at)
    select NEW.id, coalesce(c.name,'—'), NEW.qty, NEW.vehicle, NEW.note, NEW.created_at
    from customers c where c.id = NEW.customer_id
    union all
    select NEW.id, '—', NEW.qty, NEW.vehicle, NEW.note, NEW.created_at
    where not exists (select 1 from customers c where c.id = NEW.customer_id)
    limit 1;
  end if;
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_log_iptal on orders;
create trigger trg_log_iptal
  after insert or update on orders
  for each row execute function log_iptal();

-- Bitti. Bundan sonra her iptal kalıcı olarak burada birikir.
