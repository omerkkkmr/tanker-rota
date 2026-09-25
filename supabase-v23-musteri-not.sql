-- v23 EK: müşteri notu
-- SQL Editor → New query → yapıştır → RUN   (tekrar çalıştırılabilir)
alter table customers add column if not exists note text;
