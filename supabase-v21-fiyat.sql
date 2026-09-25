-- v21 EK: teslimat fiyatı (birim fiyat + tutar)
-- SQL Editor → New query → yapıştır → RUN
--
-- Fiyatı yalnızca planlayıcı girer (onay sırasında); şoför ve sipariş ekranları bu alanı hiç okumaz.
-- Kalıcı teslimat kaydına (Excel geçmişi) de birim fiyat + tutar işlenir.
-- Tekrar çalıştırılabilir.

alter table orders             add column if not exists unit_price numeric(12,4);
alter table teslimat_kayitlari add column if not exists unit_price numeric(12,4);
alter table teslimat_kayitlari add column if not exists tutar      numeric(14,2);

create or replace function log_teslimat() returns trigger as $$
begin
  if NEW.status = 'done' then
    insert into teslimat_kayitlari
      (order_id, customer_name, qty, delivered_qty, vehicle, comp, note, deliver_note,
       order_created_at, delivered_at, photo_tank_url, photo_irsaliye_url, unit_price, tutar)
    select NEW.id, coalesce(c.name,'—'), NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at,
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='tank' limit 1),
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='irsaliye' limit 1),
           NEW.unit_price,
           case when NEW.unit_price is not null and NEW.delivered_qty is not null
                then round(NEW.delivered_qty * NEW.unit_price, 2) end
    from customers c where c.id = NEW.customer_id
    union all
    select NEW.id, '—', NEW.qty, NEW.delivered_qty, NEW.vehicle, NEW.comp,
           NEW.note, NEW.deliver_note, NEW.created_at, NEW.delivered_at,
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='tank' limit 1),
           (select p->>'url' from jsonb_array_elements(coalesce(NEW.photos,'[]'::jsonb)) p where p->>'type'='irsaliye' limit 1),
           NEW.unit_price,
           case when NEW.unit_price is not null and NEW.delivered_qty is not null
                then round(NEW.delivered_qty * NEW.unit_price, 2) end
    where not exists (select 1 from customers c where c.id = NEW.customer_id)
    limit 1;
  end if;
  return NEW;
end;
$$ language plpgsql;

-- Bitti.
