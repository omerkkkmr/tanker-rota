-- v15 EK: siparişi "bugünkü rotaya dahil etme" / ertesi güne bırakma
-- SQL Editor → New query → yapıştır → RUN

alter table orders add column if not exists held boolean default false;

-- held=true olan bir sipariş "Bekliyor" durumunda kalır ama "Rotayı hesapla"
-- onu görmezden gelir — planlamacı ertesi güne bıraktığı siparişleri bu
-- işaretle günün rotasına karışmadan bekletebilir.

-- Bitti.
-- v16 EK: kalıcı teslimat geçmişine fotoğraf linkleri eklenir
-- (v14'te teslimat_kayitlari'na foto kolonu unutulmuştu — Excel'de foto
-- linki görünmesi için gerekli)
-- SQL Editor → New query → yapıştır → RUN

alter table teslimat_kayitlari add column if not exists photo_tank_url text;
alter table teslimat_kayitlari add column if not exists photo_irsaliye_url text;

-- trigger fonksiyonunu foto linklerini de yazacak şekilde güncelle
create or replace function log_teslimat() returns trigger as $$
begin
  if NEW.status = 'done' then
    insert into teslimat_kayitlari
      (order_id, customer_name, qty, delivered_qty, vehicle, comp, note, deliver_note,
       order_created_at, delivered_at, photo_tank_url, photo_irsaliye_url)
    select NEW.id, coalesce(c.name,'—'), NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at,
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='tank' limit 1),
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='irsaliye' limit 1)
    from customers c where c.id = NEW.customer_id
    union all
    select NEW.id, '—', NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at,
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='tank' limit 1),
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='irsaliye' limit 1)
    where not exists (select 1 from customers c where c.id = NEW.customer_id)
    limit 1;
  end if;
  return NEW;
end;
$$ language plpgsql;

-- geriye dönük: hâlâ orders tablosunda duran (arşivlenmemiş) teslim edilmiş
-- siparişlerin foto linklerini, daha önce fotosuz loglanmış kayıtlara işle
update teslimat_kayitlari tk
set photo_tank_url = (select p->>'url' from jsonb_array_elements(coalesce(o.photos,'[]'::jsonb)) p where p->>'type'='tank' limit 1),
    photo_irsaliye_url = (select p->>'url' from jsonb_array_elements(coalesce(o.photos,'[]'::jsonb)) p where p->>'type'='irsaliye' limit 1)
from orders o
where o.id = tk.order_id
  and tk.photo_tank_url is null
  and tk.photo_irsaliye_url is null;

-- Bitti. Not: "Teslimleri arşivle" ile daha önce SİLİNMİŞ siparişlerin
-- fotoğrafları geriye dönük eklenemez (orders tablosunda kaydı kalmadı).
-- v17 EK: teslim edilmiş bir sipariş sonradan silinirse kalıcı kayıtta
-- "silindi" olarak işaretlenir (Excel'de kırmızı gösterilecek)
-- SQL Editor → New query → yapıştır → RUN

alter table teslimat_kayitlari add column if not exists siparis_silindi boolean default false;

-- Bitti.
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
