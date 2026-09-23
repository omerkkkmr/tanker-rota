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
