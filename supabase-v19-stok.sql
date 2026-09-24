-- v19 EK: gelen stok girişleri (stok defteri)
-- SQL Editor → New query → yapıştır → RUN
--
-- Giren stok buraya elle girilir (planlayıcı → Stok sekmesi).
-- Çıkan stok ayrıca tutulmaz: onaylanmış teslimatlar (teslimat_kayitlari)
-- otomatik çıkış sayılır. Kalan = Σ giren − Σ çıkan.

create table if not exists stok_girisleri (
  id          uuid primary key default gen_random_uuid(),
  tarih       timestamptz not null default now(),
  litre       int not null check (litre > 0),
  kaynak      text default '',      -- tedarikçi / kaynak (ör. "Açılış stoğu")
  belge_no    text default '',      -- irsaliye no
  aciklama    text default '',
  bayi        text default '',      -- irsaliyede yazan bayi adı
  satis_turu  text,                 -- 'ic' (iç satış) | 'dis' (dış satış)
  irsaliye_foto_url   text,
  irsaliye_foto_thumb text,
  created_at  timestamptz default now()
);

-- tablo daha önce (eski haliyle) kurulduysa yeni kolonları ekle
alter table stok_girisleri add column if not exists bayi text default '';
alter table stok_girisleri add column if not exists satis_turu text;
alter table stok_girisleri add column if not exists irsaliye_foto_url text;
alter table stok_girisleri add column if not exists irsaliye_foto_thumb text;

alter table stok_girisleri enable row level security;

do $$
begin
  drop policy if exists "read_all" on stok_girisleri;
  drop policy if exists "write_all" on stok_girisleri;
  create policy "read_all"  on stok_girisleri for select using (true);
  create policy "write_all" on stok_girisleri for all using (true) with check (true);
end $$;

-- Bitti.
