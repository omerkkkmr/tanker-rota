-- v17 EK: teslim edilmiş bir sipariş sonradan silinirse kalıcı kayıtta
-- "silindi" olarak işaretlenir (Excel'de kırmızı gösterilecek)
-- SQL Editor → New query → yapıştır → RUN

alter table teslimat_kayitlari add column if not exists siparis_silindi boolean default false;

-- Bitti.
