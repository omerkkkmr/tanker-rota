-- v12 EK: TIR modu kolonu
-- SQL Editor → New query → yapıştır → RUN

alter table tankers add column if not exists is_tir boolean default false;

-- 54 KP 654 TIR modunda
update tankers set is_tir = true where plate = '54 KP 654';

-- eski v11 kolonları artık kullanılmıyor (kalsalar da zarar vermez, istersen sil):
-- alter table tankers drop column if exists min_l;
-- alter table tankers drop column if exists max_stops;

-- Bitti.
