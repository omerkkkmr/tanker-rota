-- v20 EK: sipariş günü (ajanda)
-- SQL Editor → New query → yapıştır → RUN
--
-- Her siparişin bir "plan günü" (teslim günü) olur. Gelecek tarihli siparişler
-- ajandada bekler, günü gelince rotaya girer (atama o gün yapılır).
-- Bu dosya birden fazla kez çalıştırılabilir (tekrarında bir şey bozmaz).

alter table orders add column if not exists plan_date date;

-- eski siparişler: oluşturuldukları gün
update orders
   set plan_date = (created_at at time zone 'Europe/Istanbul')::date
 where plan_date is null;

-- tarih verilmeden eklenen yeni siparişler bugüne yazılır
alter table orders alter column plan_date
  set default ((now() at time zone 'Europe/Istanbul')::date);

-- eski "yarına bırak" (held) siparişleri → ajandada yarın
update orders
   set plan_date = ((now() at time zone 'Europe/Istanbul')::date + 1),
       held = false
 where held is true
   and status = 'wait'
   and plan_date <= (now() at time zone 'Europe/Istanbul')::date;

-- "Yolda" durumu kaldırıldı → planlandı
update orders set status = 'plan' where status = 'road';

-- Bitti.
