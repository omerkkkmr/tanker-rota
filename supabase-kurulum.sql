-- ============================================================
--  TANKER ROTA SİSTEMİ — Supabase tablo kurulumu
--  Supabase panelinde: SQL Editor → New query → yapıştır → RUN
-- ============================================================

-- ---------- MÜŞTERİLER ----------
create table if not exists customers (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  lat        double precision not null,
  lng        double precision not null,
  created_at timestamptz default now()
);

-- ---------- TANKERLER ----------
create table if not exists tankers (
  id         uuid primary key default gen_random_uuid(),
  plate      text not null,
  comps      jsonb not null,          -- [{cap, cur}, ...]
  shift_h    numeric default 10,      -- vardiya saati
  licensed   boolean default true,    -- dolum lisansı
  pin        text default '',         -- şoför giriş şifresi (araca ait)
  sort       int default 0,
  created_at timestamptz default now()
);

-- ---------- SİPARİŞLER ----------
create table if not exists orders (
  id             uuid primary key default gen_random_uuid(),
  customer_id    uuid references customers(id) on delete set null,
  qty            int not null,
  status         text default 'wait',   -- wait|plan|road|done|canc
  note           text default '',
  lock_veh       text,                  -- kilitli plaka (null=otomatik)
  vehicle        text,                  -- atanan plaka
  comp           int,                   -- atanan göz
  delivered_qty  int,
  deliver_note   text default '',
  photos         jsonb default '[]',    -- yüklenen foto url'leri
  gps_lat        double precision,      -- teslimde şoför konumu
  gps_lng        double precision,
  created_at     timestamptz default now(),
  planned_at     timestamptz,
  delivered_at   timestamptz
);

-- ---------- AYARLAR (tek satır) ----------
create table if not exists settings (
  id         int primary key default 1,
  data       jsonb not null default '{}',   -- garaj, tesis, süreler, vs.
  updated_at timestamptz default now(),
  constraint tek_satir check (id = 1)
);

-- ---------- HESAPLANMIŞ ROTALAR ----------
-- Planlamacı rota hesaplayınca buraya yazılır; şoförler buradan okur.
create table if not exists routes (
  id         int primary key default 1,
  data       jsonb not null default '{}',   -- tüm tankerlerin rotaları
  updated_at timestamptz default now(),
  constraint tek_satir_r check (id = 1)
);

-- başlangıç satırlarını oluştur
insert into settings (id, data) values (1, '{}') on conflict (id) do nothing;
insert into routes   (id, data) values (1, '{}') on conflict (id) do nothing;

-- ============================================================
--  ROW LEVEL SECURITY
--  publishable key tarayıcıda çalışır; RLS şart.
--  Basit model: herkes okuyabilir + yazabilir.
--  Erişim kontrolü uygulama içi şifreyle (admin / araç PIN'i).
--  NOT: Daha sıkı güvenlik istenirse aşama 6'da politikalar daraltılır.
-- ============================================================
alter table customers enable row level security;
alter table tankers   enable row level security;
alter table orders    enable row level security;
alter table settings  enable row level security;
alter table routes    enable row level security;

-- okuma + yazma politikaları (anon = publishable key)
do $$
declare t text;
begin
  foreach t in array array['customers','tankers','orders','settings','routes'] loop
    execute format('drop policy if exists "read_all" on %I', t);
    execute format('drop policy if exists "write_all" on %I', t);
    execute format('create policy "read_all"  on %I for select using (true)', t);
    execute format('create policy "write_all" on %I for all using (true) with check (true)', t);
  end loop;
end $$;

-- ---------- CANLI GÜNCELLEME (realtime) ----------
-- şoför teslim işleyince planlamacı anında görsün diye
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table routes;
alter publication supabase_realtime add table tankers;

-- ============================================================
--  GERÇEK FİLO
-- ============================================================
insert into tankers (plate, comps, shift_h, licensed, pin, sort) values
('54 KP 857', '[{"cap":7000,"cur":0},{"cap":4200,"cur":0}]', 10, true, '857', 1),
('54 KP 262', '[{"cap":5000,"cur":0},{"cap":5000,"cur":0},{"cap":5000,"cur":0},{"cap":5000,"cur":0},{"cap":5000,"cur":0}]', 10, true, '262', 2),
('54 KP 525', '[{"cap":5100,"cur":0},{"cap":3800,"cur":0},{"cap":4500,"cur":0},{"cap":5500,"cur":0},{"cap":6100,"cur":0}]', 10, true, '525', 3),
('54 KP 654', '[{"cap":3850,"cur":0},{"cap":5820,"cur":0},{"cap":4300,"cur":0},{"cap":4400,"cur":0},{"cap":3910,"cur":0},{"cap":5720,"cur":0},{"cap":5750,"cur":0}]', 10, true, '654', 4),
('61 TK 485', '[{"cap":2700,"cur":0},{"cap":2000,"cur":0},{"cap":2700,"cur":0}]', 10, false, '485', 5);

-- ---------- FOTOĞRAF DEPOSU (storage) ----------
-- Şoför fişleri için. Panelde Storage → New bucket → "belgeler" (public) da açılabilir;
-- ya da bu SQL ile:
insert into storage.buckets (id, name, public)
values ('belgeler', 'belgeler', true)
on conflict (id) do nothing;

-- storage politikaları: publishable key ile yükleme + okuma
do $$
begin
  drop policy if exists "belge_read"   on storage.objects;
  drop policy if exists "belge_write"  on storage.objects;
  create policy "belge_read"  on storage.objects for select using (bucket_id = 'belgeler');
  create policy "belge_write" on storage.objects for insert with check (bucket_id = 'belgeler');
exception when others then null;
end $$;

-- ============================================================
--  BİTTİ. "Success. No rows returned" görmen normal.
-- ============================================================
