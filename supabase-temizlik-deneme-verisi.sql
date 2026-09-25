-- DENEME VERİSİ TEMİZLİĞİ
-- SQL Editor → New query → yapıştır → RUN
--
-- Silinenler: tüm siparişler, teslimat/iptal kalıcı kayıtları, dolum fişleri,
-- yayınlanmış deneme rotası. (Excel geçmişi ve Stok "çıkan" da bunlardan gelir → sıfırlanır.)
-- KORUNANLAR: tankerler, müşteri rehberi (yalnız "Fhhhbh" deneme kaydı silinir), stok girişleri.

delete from orders;
delete from teslimat_kayitlari;
delete from iptal_kayitlari;
delete from dolum_fisleri;

-- şoförlerin gördüğü yayınlanmış rotayı boşalt
update routes set data = '{}'::jsonb, updated_at = now() where id = 1;

-- deneme müşterisi
delete from customers where name = 'Fhhhbh';

-- İSTEĞE BAĞLI: Stok sekmesindeki deneme girişi(leri) de silmek istersen aşağıdaki satırın başındaki "--" işaretini kaldır:
-- delete from stok_girisleri;

-- FOTOĞRAFLAR: deneme fotoğrafları SQL ile silinemez (Supabase depoyu korur).
-- Supabase paneli → Storage → belgeler → "teslimat" (ve varsa "stok") klasörlerini seç → Delete.

-- Bitti.
