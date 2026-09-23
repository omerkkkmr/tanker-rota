-- v13 EK: dolum fişi (tanker tesiste dolarken alınan makbuz) kaydı
-- SQL Editor → New query → yapıştır → RUN

create table if not exists dolum_fisleri (
  id         uuid primary key default gen_random_uuid(),
  plate      text not null,          -- tankerin plakası
  vol        int,                    -- o dolumdaki litre (varsa)
  photo_url  text not null,          -- fiş fotoğrafı (belgeler bucket)
  note       text default '',
  created_at timestamptz default now()
);

alter table dolum_fisleri enable row level security;

do $$
begin
  drop policy if exists "read_all" on dolum_fisleri;
  drop policy if exists "write_all" on dolum_fisleri;
  create policy "read_all"  on dolum_fisleri for select using (true);
  create policy "write_all" on dolum_fisleri for all using (true) with check (true);
end $$;

-- Bitti. "belgeler" storage bucket'ı zaten var, aynısı kullanılıyor.
