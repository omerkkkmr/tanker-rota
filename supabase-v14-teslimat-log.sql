-- v14 EK: kalıcı teslimat geçmişi (Excel'de hep birikmesi için)
-- SQL Editor → New query → yapıştır → RUN
--
-- "Teslimleri arşivle" ile orders tablosundan silinen kayıtlar burada
-- KALICI olarak kalır. Bir sipariş status='done' olduğu an (hangi ekrandan
-- işlenirse işlensin — planlayıcı, teslimat/sofor ekranı, ileride eklenecek
-- her ne olursa) bir trigger burayı otomatik doldurur; client kodunun
-- bunu hatırlaması gerekmez.

create table if not exists teslimat_kayitlari (
  id                uuid primary key default gen_random_uuid(),
  order_id          uuid,
  customer_name     text,
  qty               int,              -- sipariş miktarı
  delivered_qty     int,              -- bırakılan gerçek miktar
  vehicle           text,
  comp              int,
  note              text,             -- sipariş notu
  deliver_note      text,             -- şoför notu
  order_created_at  timestamptz,
  delivered_at      timestamptz,
  logged_at         timestamptz default now()
);

alter table teslimat_kayitlari enable row level security;

do $$
begin
  drop policy if exists "read_all" on teslimat_kayitlari;
  drop policy if exists "write_all" on teslimat_kayitlari;
  create policy "read_all"  on teslimat_kayitlari for select using (true);
  create policy "write_all" on teslimat_kayitlari for all using (true) with check (true);
end $$;

-- sipariş 'done' olduğu an otomatik logla (aynı sipariş tekrar düzeltilip
-- kaydedilirse — "Teslimi düzelt" — yeni bir satır daha eklenir, en güncel
-- olan logged_at'e göre en sonda görünür; bu bilinçli: geçmiş düzeltmeler
-- de iz bıraksın istendi)
create or replace function log_teslimat() returns trigger as $$
begin
  if NEW.status = 'done' then
    insert into teslimat_kayitlari
      (order_id, customer_name, qty, delivered_qty, vehicle, comp, note, deliver_note, order_created_at, delivered_at)
    select NEW.id, coalesce(c.name,'—'), NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at
    from customers c where c.id = NEW.customer_id
    union all
    select NEW.id, '—', NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at
    where not exists (select 1 from customers c where c.id = NEW.customer_id)
    limit 1;
  end if;
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_log_teslimat on orders;
create trigger trg_log_teslimat
  after insert or update on orders
  for each row execute function log_teslimat();

-- Bitti. Bundan sonra her teslim (nereden işlenirse işlensin) kalıcı
-- olarak burada birikir — "Teslimleri arşivle" bunu etkilemez.
