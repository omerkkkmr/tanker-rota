-- v15 EK: siparişi "bugünkü rotaya dahil etme" / ertesi güne bırakma
-- SQL Editor → New query → yapıştır → RUN

alter table orders add column if not exists held boolean default false;

-- held=true olan bir sipariş "Bekliyor" durumunda kalır ama "Rotayı hesapla"
-- onu görmezden gelir — planlamacı ertesi güne bıraktığı siparişleri bu
-- işaretle günün rotasına karışmadan bekletebilir.

-- Bitti.
