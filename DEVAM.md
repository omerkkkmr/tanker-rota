# TANKER ROTA PLANLAMA SİSTEMİ — Devam Notu (Claude Code için)

Bu bir devralma dosyasıdır. Önceki geliştirme sohbetinden buraya taşındı.
Sen (Claude Code) bu projeyi kaldığı yerden devam ettireceksin. Aşağıdaki
her şeyi oku, sonra "Şu an nerede kaldık" bölümünden devam et.

Kullanıcı Türkçe konuşuyor, kısa ve doğrudan cevap ister, gereksiz açıklama
ve fazla soru sevmez. Netleşen kuralları tek seferde uygula.

---

## İŞ TANIMI

Sakarya merkezli akaryakıt bayii. Körfez'deki (İzmit) dolum tesisinden yakıt
alıp müşterilere tankerlerle dağıtıyor. Garaj (Sakarya) ile tesis (Körfez)
arası ~70 km. Uygulama: sipariş yönetimi + rota optimizasyonu + şoför
yönlendirmesi. Tek dosya HTML (Leaflet + OSRM + Supabase).

## GÜNCEL DOSYA

**(2026-09-23 itibariyle) Dosya adları kısa link için değiştirildi:**
- Planlayıcı: `index.html` (eskiden `tanker-rota-planlayici-v17.html`)
- Şoför ekranı: `sofor/index.html` (eskiden `sofor.html`)

Canlı adresler (GitHub Pages, repo: `github.com/omerkkkmr/tanker-rota`):
- Planlayıcı: `https://omerkkkmr.github.io/tanker-rota/`
- Şoför: `https://omerkkkmr.github.io/tanker-rota/sofor/`

Eski arşiv dosyaları (`PROJE-BAGLAM.md`, `tanker-rota-planlayici-v8.html`,
referans tasarım prototipi) kullanıcı isteğiyle silindi — hâlâ git
geçmişinde duruyor, gerekirse `git log --diff-filter=D` ile bulunabilir.

SQL kurulum: `supabase-kurulum.sql`, `supabase-v12-ek.sql` (is_tir kolonu),
`supabase-v13-dolum-fisi.sql` (dolum fişi fotoğrafı tablosu).

Çalışma düzeni: `main` dalına commit + `git push` → birkaç saniye içinde
canlı adrese yansır (GitHub Pages otomatik derliyor).

## TEKNİK YAPI

- Tek dosya HTML. Leaflet (CDN) + Supabase-js@2 (CDN) + OSRM (router.project-osrm.org).
- OSRM: /table matris (mesafe+süre), /route geometri.
- Font: Archivo + IBM Plex Mono. 8 renkli COLORS dizisi (tanker sırasına göre).
- Düğüm indeksleri: `nOf(o)=o.id+2`. 0=garaj(G), 1=tesis(P), 2+=müşteriler.
- localStorage anahtarı `tankerRotaV9` (yedek). Bulut (Supabase) ana kaynak.
- Test yöntemi: `<script>` bloğundan motor çıkarılıp node ile çalıştırılıyor.
  `const G=0,P=1;`'den `/* ---------- manuel müdahale`'ye kadar olan blok +
  tLoad/tDrop/tXfer tanımları /tmp/engine.js'e yazılıp `global.L2=n=>n` ile
  eval ediliyor, planFleet+schedule çağrılıyor. (Aşağıda hazır test scripti var.)

## KİLİT FONKSİYONLAR

- `planFleet(orders,fleet,ratio,cfg,T)` — ana planlama (fazlar 1-8)
- `tryInsert`/`commitInsert`/`fillOrderIntoTrip` — cheapest-insertion + göz bölme
- `schedule(plan,T,D,cfg)` — legs zaman çizelgesi (dolum, drop, besleme, feedout)
- `moveStop`/`optVeh` — manuel taşıma/yeniden optimize
- `sheetPage` — şoför görev formu
- `publishRoutes`/`subscribeRealtime`/`applyOrderChange` — Supabase senkron
- `endDay` — günü kapat (leftover'ı mevcut yakıta yazar)
- `cloudOrderUpsert`/`cloudTankUpsert` — Supabase yazma (isUUID + myWrites echo önleme)

---

## GERÇEK FİLO (Supabase'de yüklü)

| Plaka | Gözler (L) | Toplam | Lisans | TIR |
|---|---|---|---|---|
| 54 KP 857 | 7000, 4200 | 11.200 | var | hayır |
| 54 KP 262 | 5000×5 | 25.000 | var | hayır |
| 54 KP 525 | 5100,3800,4500,5500,6100 | 25.000 | var | hayır |
| 54 KP 654 | 3850,5820,4300,4400,3910,5720,5750 | 33.750 | var | **EVET** |
| 61 TK 485 | 2700,2000,2700 | 7.400 | **YOK** | hayır |

Hepsi 10 saat vardiya. TIR eşiği (en küçük iki göz) = 3850+3910 = **7.760 L**.

## İŞ KURALLARI (kesinleşmiş — bunlar değişmez, uygula)

1. **Kalan yakıt:** Tanker vardiya başında gözünde yakıtla gelebilir. Dolu gözle
   tesise GİRİLEMEZ — önce boşaltılmalı (müşteriye teslim veya garajda aktarım).

2. **Çoklu sefer:** Tankerler gün içinde defalarca dolabilir. Vardiya süresi frenler.

3. **Göz bölme:** Bir sipariş birden fazla göze bölünebilir. Göz yarım/çeyrek
   dolabilir, doluluk ÖNEMSİZ. Önemli olan tankerin toplam boş hacmi. Sipariş bir
   göze sığmazsa aynı tankerin başka gözünden tamamlanır. (parts[] ile tutuluyor.)

4. **Full dolum:** Doluma giden HER tanker (TIR dahil) kullandığı gözleri SONUNA
   KADAR doldurur, ihtiyaç ne olursa olsun. Teslimden artan yakıt araçta kalır
   (leftover). "Günü kapat" butonuyla ertesi günün mevcut yakıtına yazılır.

5. **Şoför:** Şoför araç DEĞİŞTİRMEZ. Bir tanker işini bitirir, garaja döner,
   gerekiyorsa garajdaki TIR'dan yeniden beslenip tekrar çıkar (AYNI araçla).
   Şoför sayısı < tanker sayısı olabilir (bazen 3 şoför). Fazla tanker garajda kalır.
   Şoför seçimi: kilitli işi olan > kalan yakıtı olan > TIR > büyük kapasiteli.

6. **TIR (654) — EN KRİTİK KURAL:**
   - TIR VARSAYILAN OLARAK BESLEYİCİDİR. Doluma gider, full dolar, garaja getirir,
     diğer tankerlere AKTARIR. Diğerleri bu aktarımla dağıtır (kendileri doluma gitmez).
   - TIR küçük işlere (7.760 L altı = en küçük iki göz toplamı) ASLA gitmez.
   - TIR kendi siparişe SADECE en küçük iki gözünden büyük (7.760+) tek/çift iş
     varsa gider. Onu boşaltıp döner.
   - İSTİSNA: TIR meşgulse (kendi büyük işi varsa) veya yakıt ihtiyacı TIR
     kapasitesini aşıyorsa, diğer tankerler de doluma gidebilir.
   - Aktarım noktası: merkez/garaj. Beslenen tanker tesise GİTMEZ.

7. **Kapsam dışı (bilinçli, yapma):** ADR/tehlikeli madde ayrımı, ürün karışmazlığı
   (motorin/benzin), yolda aktarım (sadece garajda aktarım var).

8. **Kısmi teslimat:** Mümkün ama sadece teslimatta (dolum hep full). Ayar: "Kısmi
   alt %" (varsayılan 75). Göz atama %90'a göre (büyük işi küçük göze zorlama yok).

## SÜRE MODELİ (kullanıcının verdiği gerçek rakamlar)

- Dolum: 25 dk sabit + kuyruk (panelde 0-180 dk). Hacimle DEĞİŞMEZ.
- Boşaltma: 8 dk + 2,5 dk/1000 L
- Garaj aktarımı: 2,5 dk/1000 L
- Mesafe/süre: OSRM gerçek yol ağı.

## SUPABASE

- URL: `https://vtrtshvfwjjazpvcmfcq.supabase.co`
- Publishable key: `sb_publishable_IIiVphchfanRWnzi9jehCQ_qt6w8i8o` (tarayıcıda güvenli)
- Planlamacı şifresi: `admin` (GEÇİCİ, değiştirilecek)
- Şoför PIN'leri (geçici, plaka son 3 hane): 857, 262, 525, 654, 485
- Tablolar: customers, tankers (comps jsonb, pin, is_tir, sort), orders (status:
  wait/plan/road/done/canc, delivered_qty, photos, gps_lat/lng, zaman damgaları),
  settings (tek satır jsonb), routes (tek satır jsonb — şoför okur).
- Storage bucket: `belgeler` (public).
- RLS: hepsi açık okuma+yazma. Erişim kontrolü uygulama içi şifreyle.
- Realtime açık: orders, routes, tankers.
- Container Supabase'e çıkamaz (ağ kısıtı) — testler tarayıcıda yapılır.

---

## ŞU AN NEREDE KALDIK (v17 durumu)

v17'de TIR besleme modeli VARSAYILAN yapıldı (fazlar 6-8 yeniden yazıldı):
- Faz 6: TIR'a sadece tirMin (7760) üstü büyük işler.
- Faz 7: Kalan siparişler dağıtımcılara (kırkayak + lisanssız). Sığmazsa TIR son çare.
- Faz 8: BESLEME — dağıtımcıların taşıyacağı toplam yakıt garajda TIR'dan aktarılır
  (transfers), dağıtımcı `fedFromTir=true` olur, tesise gitmez. TIR meşgulse/yetmezse
  dağıtımcı kendi doluma gider.
- schedule: `fedFromTir` olan tanker tesise gitmez, garajdan çıkıp doğrudan teslimata
  gider (phase:'besleme'). TIR besleyiciyse feedout leg'i (garaj→tesis→garaj→aktarım).
- Tanker başlığında "araçta kalan: X L" (leftover) gösteriliyor.

### DOĞRULANMIŞ TESTLER (node ile geçti)
- Küçük işler (hepsi <7760): TIR besleyici oldu, 262'ye 7500 L aktardı, 262 tesise
  gitmeden dağıttı. TIR küçük işe GİTMEDİ. ✓
- Büyük iş (9000>7760): TIR kendi aldı, taşıdı. ✓
- Göz bölme: 8000 L → Göz2(5820)+Göz7(2180), tek durak. ✓
- Full dolum: 1500 L iş → 5000 L full dolum, 1500 teslim, 3500 leftover. ✓

### AÇIK SORUN (kullanıcının son şikayeti — ÖNCE BUNU KONTROL ET)
Kullanıcı "857 yine doluma gitti" dedi. Ama son node testinde (4 şoför, 4 küçük iş)
857 "iş yok" çıkıyor, 262 besleniyordu — yani motor DOĞRU görünüyor. Tutarsızlık:
kullanıcının EKRANINDA 857 doluma gidiyor ama node testinde gitmiyor.

Olası sebepler (araştır):
1. Kullanıcının gerçek siparişleri node testinden farklı (konum/miktar). Gerçek
   veriyle üret: bazı siparişler TIR eşiği üstü olabilir → TIR meşgul → 857 doluma gider.
   Bu durumda 857'nin doluma gitmesi DOĞRU olabilir.
2. Kalan yakıt: 857'nin gözünde kalan yakıt varsa faz 3'te iş alır, sonra doluma
   gidebilir. Ekran görüntüsünde 857 "f" siparişini kalan yakıtla bırakmıştı.
3. Tarayıcıdaki v17 ile diskteki v17 farklı olabilir (kullanıcı eski dosya açmış olabilir).

İLK ADIM: kullanıcıdan ekran görüntüsü + o anki sipariş listesini (miktar+konum) iste,
VEYA onun gerçek senaryosunu node testine koy, 857'nin neden doluma gittiğini izle.
857 doluma gidiyorsa ya (a) TIR meşgul/yetersiz (doğru davranış) ya (b) bir faz-sırası
bug'ı. tryInsert'e/faz 8'e debug log koyup gerçek veriyle çalıştır.

### BİLİNEN GEÇMİŞ BUG'LAR (çözüldü, tekrar görülürse buraya bak)
- NaN bug (v15): tripTime'da a.give yoksa a.o.qty varsayılıyor. Kırkayaklar hiç iş
  almıyordu çünkü tDrop(undefined)=NaN, NaN<=shift hep false. ÇÖZÜLDÜ.
- Legend sonsuz döngü (v15): realtime kendi echo'sunu tekrar çiziyordu. myWrites Set
  ile kendi yazımı yok sayılıyor, applyOrderChange çizili rotayı yeniden çizmiyor. ÇÖZÜLDÜ.
- Fazla aktarım (v15): eski "her boş gözü doldur" kaldırıldı, ihtiyaç kadar aktarım. ÇÖZÜLDÜ.

## TEST SCRIPTİ (motoru node ile çalıştırmak için)

```bash
# motoru çıkar
python3 - << 'PYEOF'
import re
h=open('tanker-rota-planlayici-v17.html').read()
js=re.search(r'<script>(.*?)</script>\s*</body>',h,re.S).group(1)
start=js.index('const G=0,P=1;')
end=js.index('/* ---------- manuel müdahale')
block=js[start:end]
extra=''
for name in ['tLoad','tDrop','tXfer']:
    m=re.search(r'const '+name+r'=.*?;',js)
    if m: extra+=m.group(0)+'\n'
open('/tmp/engine.js','w').write(extra+'\n'+block)
PYEOF

# test et
cat > /tmp/run.js << 'EOF'
global.L2=n=>Math.round(n).toLocaleString('tr');
const fs=require('fs');
eval(fs.readFileSync('/tmp/engine.js','utf8'));
const cfg={start:480,queue:25,loadFix:25,dropFix:8,dropVar:2.5,balance:0.25,xferVar:2.5,drivers:4};
// T = süre matrisi [G,P,müşteriler...]. G=garaj, P=tesis(uzak ~60-78dk)
const T=[[0,60,15,20,25,78],[60,0,55,58,62,70],[15,55,0,10,12,40],[20,58,10,0,8,38],[25,62,12,8,0,35],[78,70,40,38,35,0]];
const D=T;
const orders=[{id:0,name:'b',qty:1500,lockVeh:null},{id:1,name:'c',qty:2000,lockVeh:null},{id:2,name:'e',qty:2500,lockVeh:null},{id:3,name:'f',qty:1500,lockVeh:null}];
const fleet=[
 {id:'857',caps:[7000,4200],cur:[0,0],shift:600,lic:true,tir:false},
 {id:'262',caps:[5000,5000,5000,5000,5000],cur:[0,0,0,0,0],shift:600,lic:true,tir:false},
 {id:'525',caps:[5100,3800,4500,5500,6100],cur:[0,0,0,0,0],shift:600,lic:true,tir:false},
 {id:'654',caps:[3850,5820,4300,4400,3910,5720,5750],cur:[0,0,0,0,0,0,0],shift:600,lic:true,tir:true,tirMin:7760},
 {id:'485',caps:[2700,2000,2700],cur:[0,0,0],shift:600,lic:false,tir:false},
];
const R=planFleet(orders,fleet,0.75,cfg,T);
console.log('go:',R.go.map(p=>p.veh.id).join(', '),'| park:',R.park.map(p=>p.veh.id).join(', '));
console.log('aktarım:',R.transfers.map(t=>t.from+'→'+t.to+' '+L2(t.vol)+'L').join(', ')||'yok');
R.plans.forEach(pl=>{
  const tr=pl.trips.flatMap(t=>t.items.map(a=>a.o.name));
  const tag=pl.tirFeeder?' [BESLEYİCİ]':pl.fedFromTir?' [beslendi]':(pl.trips.length?' [DOLUMA]':'');
  console.log('  '+pl.veh.id+tag+':', tr.length?tr.join(', '):'iş yok');
});
EOF
node /tmp/run.js
```

## GÖRÜNÜM YENİLEMESİ (2026-09-22)

Kullanıcı Desktop'ta ayrı tuttuğu bir tasarım prototipini (`Tanker-Rota-
Planlayici (2).html`, bir Claude Artifact "Bundled Page" çıktısı, kod
motoru YOK/kırık — yalnız görsel referans) örnek gösterip "görünüm böyle
olsun" dedi. O dosya render edilip (yerel http.server ile) renkler/fontlar
computed style'dan tam olarak çıkarıldı: bg `#f4f1ea` (krem), kart
`#ffffff`, ink `#1b1917`, altın vurgu `#d9a441`/buton `#e6b558`, font
`Instrument Sans` (Google Fonts) + `IBM Plex Mono` (zaten kullanılıyordu).

`tanker-rota-planlayici-v17.html`'nin TAMAMI bu palete geçirildi (motor
koduna dokunulmadı, yalnız CSS + birkaç inline stil + HTML iskeleti):
- Eski sol akordeon (`<details>` ile 5 bölüm) **sekme çubuğuna** çevrildi:
  Siparişler / Müşteriler / Filo / Ayarlar / Plan. "Konumlar" +
  "Süreler & Kısıtlar" tek "Ayarlar" sekmesinde birleşti. "Plan" sekmesi
  eskiden sayfanın altında duran `#status`/`#out` (rota sonucu) alanını
  taşıyor. Tüm eski `id`'ler (garage/plant/queue/drivers/... ve
  fleetcount/custcount/ordcount) AYNEN korundu — hiçbir JS fonksiyonu
  değişmedi, sadece görünürlük artık `showTab()` ile yönetiliyor.
- Üstte koyu (`#1b1917`) tam genişlik başlık çubuğu + harita üstünde krem
  "durum şeridi" (Açık Sipariş / Talep L / Tanker / Şoför / Plan —
  `updateStatBar()`, `renderOrders`/`renderFleet` içinden tetikleniyor).
- Kartlar/pill butonlar/badge'ler yuvarlatıldı, dark-on-dark renkler
  light-on-cream karşılıklarına çevrildi (ör. `.fbtn.act` artık siyah dolgu,
  referanstaki "Açık" pili gibi).
- Şoför görev formu (`#sheet`, yazdırma amaçlı) bilinçli olarak DOKUNULMADI
  — zaten kendi açık temasını kullanıyordu, riski düşürmek için aynen
  bırakıldı.

**Gerçek bir CSS Grid hatası bulunup düzeltildi:** İlk yazımda mobil
(`max-width:900px`) medya sorgusu `.mainrow`'a `grid-template-rows:auto 1fr`
uyguluyordu; `#side`'ın `overflow-y:auto` olması nedeniyle grid'in "auto"
satırı 0 yüksekliğe çöküyordu (sipariş formu görünmüyordu) — yalnızca
tarayıcıda gerçek dar pencere testiyle yakalandı. Çözüm: mobilde `body` ve
`.mainrow` düz `display:block`'a düşüyor, `#side` kendi doğal yüksekliğini
alıyor, normal sayfa kaydırması devreye giriyor.

**Doğrulama:** Yerel `python3 -m http.server` ile hem 415px (mobil) hem
1300px (masaüstü) genişlikte tüm sekmeler (Siparişler/Müşteriler/Filo/
Ayarlar/Plan) gerçek verideki gibi görsel olarak doğrulandı; ardından GERÇEK
işlevsel test yapıldı — 3 sipariş eklendi, "Rotayı hesapla" ile gerçek OSRM
rotası hesaplandı (bu sandboxtan OSRM'e erişim VAR, Supabase'e YOK — bilinen
kısıt), harita rotayı çizdi, Plan sekmesi araç kartlarını/uyarı kutularını
doğru renklerle gösterdi, şoför görev formu (`openSheet`) sorunsuz açıldı.
Motorda hiçbir davranış değişikliği yok, yalnız görünüm.

`sofor.html` bu turda DOKUNULMADI (kendi ayrı koyu teması var, kapsam
dışında tutuldu — istenirse ayrı bir iş olarak aynı palete geçirilebilir).

## PROJE KLASÖRÜ TAŞINDI + sofor.html PIN kaldırıldı (2026-09-23)

Kullanıcı çalışma klasörünün **Masaüstü/Tanker Rota** olmasını istedi (bu
oturuma kadar Downloads'ta çalışılıyordu — kullanıcının ilk mesajdaki
dosya ekleri oradan geldiği için). git deposu (.git + tüm commit geçmişi)
Downloads'tan buraya kopyalandı; Masaüstünde zaten duran eski dosyalar
(`PROJE-BAGLAM.md` — v8 dönemi eski bağlam dosyası, `tanker-rota-
planlayici-v8.html` — Supabase öncesi ilk sürüm, `Tanker-Rota-Planlayici
(2).html` — görünüm yenilemesinde referans alınan tasarım prototipi) de
depoya eklendi, arşiv olarak duruyorlar. Downloads'taki kopya silindi —
**tek çalışma klasörü artık burası.**

`sofor.html`'de kullanıcı "PIN falan olmasın" dedi — giriş ekranı PIN
girişinden **plaka listesine tıklayarak seçme**ye çevrildi:
`tankers` tablosundan `id,plate` çekilip (sort sırasına göre) her biri bir
buton olarak listeleniyor, tıklayınca doğrudan `enterApp()`. `doLogin()`/
`#pinInput`/`#loginBtn` kaldırıldı, yerine `loadPlateList()`/`selectPlate(
id,plate)` geldi. `tankers.pin` kolonu DB'de duruyor (dokunulmadı, zararsız,
kullanılmıyor). Kimlik doğrulama YOK artık — herhangi biri herhangi bir
tankeri seçip o tankerin rotasını görebilir/teslim işleyebilir; bu bilinçli
bir ödünleşim (kullanıcı sadeliği PIN güvenliğine tercih etti). Yerel
sunucuyla (sahte veriyle enjekte edilerek) plaka listesi görünümü ve
seçince ana ekrana geçiş tarayıcıda doğrulandı; gerçek Supabase bu ortamdan
erişilemediği için (bilinen kısıt) gerçek veriyle uçtan uca test kullanıcı
tarafından yapılmalı.

**Kullanıcının bildirdiği "Bağlantı hatası" şikayeti** muhtemelen ya (a)
Supabase ücretsiz projesinin otomatik duraklatılmış olması ya da (b)
dosyanın henüz telefona hiç ulaşmamış olması (sadece Mac'te duruyordu) —
kesin teşhis kullanıcıdan bekleniyor, konu KAPANMADI.

## HARİTA ALTLIĞI İKİ KEZ DEĞİŞTİ + DOLUM FİŞİ + MOBİL ATLAMA (2026-09-23)

Kullanıcı harita ekran görüntüsü paylaştı: `tile.openstreetmap.org` **403
"Access blocked — App is not following the tile usage policy"** veriyordu.
OSM'in gönüllü sunucuları uygulama/toplu istek trafiğini bilerek
engelliyor (bir önceki oturumda CARTO'dan buraya geçmiştim, o da kısa
sürede tıkandı). **Esri'nin anahtar istemeyen, uygulama gömme kullanımına
açık `World_Street_Map` tile servisine** geçildi — bu servis binlerce
Leaflet projesinde tam bu senaryo için (OSM'in engellemesi) standart
alternatif olarak kullanılıyor, tarayıcıda gerçek yol/etiket/harita ile
doğrulandı. **Eğer bu da ileride tıkanırsa** sıradaki seçenek: kullanıcının
kendi ücretsiz MapTiler/Stadia hesabı (anahtarla) — bunlar duraklamayan
kalıcı çözüm ama hesap açmayı gerektiriyor.

**Ayrıca aynı oturumda üç iş daha:**

1. **Dolum fişi fotoğrafı** — kullanıcı "tanker fişi fotosu da eklensin"
   dedi (tesiste dolum sırasında alınan kağıt makbuz/fiş — teslimattaki
   irsaliye/tank fotoğrafından AYRI, giriş tarafının kanıtı). Yeni tablo
   `dolum_fisleri` (`supabase-v13-dolum-fisi.sql` — plate, vol, photo_url,
   note, created_at; `belgeler` bucket'ı zaten var, aynısı kullanılıyor).
   `sofor.html`'de "Tesiste dolum" satırına bir "🧾 Fiş Yükle" butonu
   eklendi — dolum leg'inin dizideki index'i (`i`) oturum içi anahtar
   olarak kullanılıyor (`fisUploaded[i]`), kalıcı bir sipariş kaydına bağlı
   olmadığı için bu şekilde en basit çözüm. Tarayıcıda sahte veriyle modal
   görsel olarak doğrulandı; **kullanıcının bu tabloyu Supabase'de
   `supabase-v13-dolum-fisi.sql`'i çalıştırarak oluşturması gerekiyor**,
   yoksa fiş kaydı hata verir (foto yine de storage'a yüklenir, yalnız DB
   insert'i başarısız olur — bu turda bu hata durumu ayrıca test edilmedi).

2. **Mobilde liste↔harita atlama** — kullanıcı "şöför ve planlama
   ekranları tamamen mobile göre yapılsın" dedi. `sofor.html` zaten baştan
   mobil-öncelikliydi (dokunulmadı). Planlayıcıda TAM bir yeniden tasarım
   yerine (kapsamı büyük, kullanıcı ne istediğini netleştirmeden riskli),
   ÖLÇÜLÜ bir mobil iyileştirme yapıldı: mobilde sekme çubuğu artık
   `position:sticky` (kaydırırken kaybolmuyor); yüzen "🗺️ Haritayı Göster"
   / "📋 Listeye Dön" düğmeleri eklendi (`updateJumpButtons()`, scroll
   pozisyonuna göre ikisi arasında geçiş yapıyor) — böylece kullanıcı uzun
   sipariş listesini kaydırmadan haritaya atlayabiliyor. Tarayıcıda mobil
   genişlikte (375px) doğrulandı. **Bu, "tamamen mobile göre" isteğinin
   TAMAMI değil** — eğer kullanıcı daha fazlasını (ör. alttan sekme
   navigasyonu, masaüstü-özel ekranların mobilde tamamen gizlenmesi)
   isterse somut örnekle (ekran görüntüsü/referans) belirtmesi gerekiyor,
   kör bir "tam yeniden tasarım" riskli olurdu.

**AÇIK KALAN:** `dolum_fisleri` tablosu kullanıcı tarafından Supabase'de
henüz oluşturulmadı (SQL dosyası hazır, çalıştırılması gerekiyor).

## GITHUB PAGES YAYINI + SİPARİŞ GİRİŞİ EKRANI (2026-09-23)

Kullanıcı "androidde ve iphonda çalışır mı" diye sordu — cevap: tarayıcıdan
evet ama `file://` yerine bir https adresi gerekiyordu (kamera/GPS için).
Kullanıcı GitHub Pages'i seçti. Süreç: `gh` CLI kuruldu (Homebrew), kullanıcı
kendi hesabıyla device-flow ile giriş yaptı (`omerkkkmr`), `gh auth setup-git`
ile git'in kimlik doğrulaması `gh`'ye bağlandı (kullanıcı önce tarayıcıdan
Google ile giriş yapmaya çalışıp takılmıştı — git'in beklediği kimlik
doğrulama bu değildi). **`git push` işlemi Claude Code'un otomatik mod
sınıflandırıcısı tarafından "herkese açık içerik oluşturma" gerekçesiyle
engellendi** — sohbetteki onay yetmedi, kullanıcının komutu KENDİ
terminalinden çalıştırması gerekti (ilginç şekilde SONRAKİ push'lar Claude
Code'un kendi Bash aracından sorunsuz geçti — sınıflandırıcı görünüşe göre
yalnızca İLK/yeni public repo push'unu daha sıkı değerlendiriyor).

Repo: `github.com/omerkkkmr/tanker-rota` (**public** — ücretsiz GitHub Pages
private repo desteklemiyor; bu, `supabase-kurulum.sql`'deki proje URL'i +
publishable key'in artık daha kolay bulunabilir olduğu anlamına gelir —
zaten tasarım gereği tarayıcıda görünür olacaktı ama repo public olunca
GitHub arama/botlar için de görünür hale geldi; tüm tablolarda RLS "herkes
okur+yazar" olduğundan bu anahtarı bulan biri tüm veriyi okuyup
değiştirebilir — kullanıcıya açıkça söylendi, "yap" onayı alındı).

Canlı adresler kısaltıldı (dosyalar `index.html` olarak köke taşındı):
- Planlayıcı: `https://omerkkkmr.github.io/tanker-rota/`
- Teslimat (eski `sofor/`, kullanıcı "sofor değil teslimat olsun" dedi,
  klasör adı + sayfa `<title>`'ı değiştirildi): `.../tanker-rota/teslimat/`
- **Yeni: Sipariş Girişi** (kullanıcı "sadece sipariş girenler için ekran
  olsun" dedi — planlayıcının tam motorunu (Leaflet/OSRM/filo/rota) hiç
  yüklemeyen, yalnızca müşteri seç + miktar + not + "Talep Ekle" ve açık
  sipariş listesi olan minimal bir sayfa): `.../tanker-rota/siparis/`.
  Aynı `orders`/`customers` tablolarını kullanıyor (planlayıcıyla aynı
  veri, ayrı bir kopya değil), realtime abone — planlamacı ekranında da
  anında görünür. Gerçek Supabase verisiyle (gerçek müşteri/sipariş
  listesi) tarayıcıda doğrulandı; canlı veriyi kirletmemek için test
  siparişi GÖNDERİLMEDİ (insert kodu zaten planlayıcı/teslimat'takiyle
  birebir aynı desen, ayrıca test edilmiş).

`git push` sonrası GitHub Pages otomatik derliyor (~10-30 sn), her seferinde
`curl` ile canlı URL'in 200 döndüğü doğrulanarak ilerlendi.

## KALICI TESLİMAT GEÇMİŞİ (2026-09-23)

Kullanıcı "tüm yapılan teslim sipariş vs yi excelde biriktirsin her zaman"
dedi — sorun şuydu: `exportExcel()` yalnız o ANKİ `orderList`'i (bellek/
Supabase'deki güncel hal) yazıyordu; "Teslimleri arşivle" ile teslim edilen
siparişler `orders` tablosundan SİLİNDİĞİNDE geçmişleri de kayboluyordu.

Çözüm istemci kodunda DEĞİL, veritabanı seviyesinde: yeni
`supabase-v14-teslimat-log.sql` → `teslimat_kayitlari` tablosu + bir
Postgres TRIGGER (`log_teslimat()`, `orders` tablosunda `insert or update`
sonrası çalışır, `NEW.status='done'` olduğu her an bir satır ekler).
Bilinçli tercih: bunu her bir client dosyasına (planlayıcı `saveDeliv()`,
teslimat ekranı `submitDelivery()`, ileride eklenecek her ne olursa) TEK
TEK yazmak yerine DB tetikleyicisi yapıldı — "her zaman biriksin" isteği
böylece hangi ekrandan işlenirse işlensin garanti ediliyor, client kodu
unutamaz. "Teslimi düzelt" ile aynı sipariş tekrar 'done' yapılırsa YENİ
bir satır daha eklenir (silinmez/üzerine yazılmaz) — düzeltmeler de iz
bıraksın diye bilinçli bir tercih.

`index.html`'deki `exportExcel()` artık async: önce `teslimat_kayitlari`
tablosunun TAMAMINI çekip "Teslimat Geçmişi" (kalıcı, hiç silinmeyen) sayfası
olarak ekliyor, "Stok Özeti"/"Siparişler" sayfaları hâlâ o ANKİ görünümü
gösteriyor ("bugün" etiketiyle ayrıştırıldı). Tablo henüz yoksa (kullanıcı
SQL'i çalıştırmadıysa) hata fırlatmadan boş bir geçmiş sayfasıyla devam
ediyor, konsola uyarı yazıyor — tarayıcıda bu durum (tablo yokken) test
edilip çökmediği doğrulandı.

**AÇIK KALAN:** `supabase-v14-teslimat-log.sql` kullanıcı tarafından
Supabase'de henüz çalıştırılmadı — çalıştırılana kadar "Teslimat Geçmişi"
sayfası boş gelir (diğer iki sayfa normal çalışır). `dolum_fisleri`
(v13) de hâlâ aynı durumda, açık.

## FOTOĞRAF SIKIŞTIRMA (2026-09-23)

Kullanıcı Supabase ücretsiz depolama alanının (kabaca ~1 GB, kesin rakam
panelden teyit edilmeli — buradan giriş yapılamıyor) sıkıştırmasız
fotoğraflarla (teslimat başına 2 + dolum başına 1, telefon kamerası
1-4 MB/foto) 1-2 haftada dolabileceği hesaplandı, kullanıcı onayladı.

`teslimat/index.html`'e `compressImage()` eklendi: `uploadPhoto()` her
fotoğrafı (tank/irsaliye/fiş — üçü de aynı fonksiyonu kullanıyor)
yüklemeden ÖNCE tarayıcıda `createImageBitmap`+canvas ile uzun kenarı
max 1600px'e küçültüp JPEG q=0.75 olarak yeniden kodluyor. Sıkıştırma
başarısız olursa (ör. tarayıcı desteği yoksa) orijinal dosya olduğu gibi
yüklenir — hiçbir zaman yükleme tamamen engellenmez. Tarayıcıda sentetik
39 MB'lık (rastgele gürültü, JPEG için en kötü senaryo) bir test
görseliyle doğrulandı: 0,51 MB'a indi (77x küçülme) — gerçek fotoğraflarda
(gürültü değil, yumuşak geçişli görüntü) oran genelde çok daha iyi çıkar.

## GERÇEK HATALAR BULUNUP DÜZELTİLDİ + YENİ MÜŞTERİ AKIŞI (2026-09-23)

Kullanıcı üç şey bildirdi: (1) sipariş girerken yeni müşteri oluşturulamıyor,
(2) sildiği siparişler kapatıp açınca geri geliyor, (3) sipariş ekranından
girilen sipariş planlayıcıya gelmiyor. İkisi GERÇEK bug çıktı, ikisini de
gerçek Supabase verisiyle (test kayıtları sonradan temizlendi) doğrulayarak
düzelttim:

1. **Silme hatası (gerçek bug):** `index.html`'deki `delOrder(id)` siparişi
   yalnız YEREL `orderList`'ten çıkarıp `save()` (localStorage) çağırıyordu
   — `cloudOrderDelete(id)` HİÇ ÇAĞRILMIYORDU. Yani sipariş Supabase'de
   duruyordu; sayfa yenilenince `load()` buluttan tekrar çekip geri
   getiriyordu. Tek satır eksikti, eklendi.

2. **Senkron gecikmesi (gerçek eksik):** `index.html`'in realtime aboneliği
   yalnız `orders` tablosunu dinliyordu, `customers`'ı DİNLEMİYORDU. Sipariş
   Girişi ekranından yeni müşteri+sipariş eklenince, SİPARİŞ anında geliyordu
   ama o siparişin bağlı olduğu YENİ MÜŞTERİ gelmiyordu (plan­layıcıda
   "<silinmiş müşteri>" gibi görünebilirdi) — iki gerçek pencereyle test
   edilip doğrulandı. `subscribeRealtime()`'a `customers` tablosu +
   `applyCustomerChange()` eklendi, artık anında geliyor.

3. **Genel dayanıklılık (kullanıcının "teslimatı da dikkate alarak güncelle"
   isteği doğrultusunda üç ekrana da eklendi):** realtime WebSocket
   bağlantısı sessizce kopabiliyor (mobilde zayıf sinyal, sekme uzun süre
   arka planda, vb. — test sırasında BU ORTAMDA da bir WS bağlantısının
   gerçekten koptuğu gözlemlendi, bu riskin gerçek olduğunu doğruladı).
   Üç ekrana da (`index.html`, `teslimat/index.html`, `siparis/index.html`)
   45 saniyede bir sessizce buluttan tazeleyen bir yedek zamanlayıcı
   (`softRefresh`/`loadRoute(false)`) eklendi — realtime çalışmasa bile
   en geç 45 saniyede kendini onarır. Planlayıcıda bu fonksiyon ayrıca
   İLK yüklemede bulut erişilemezse bile (o zamana kadar "⚠ yerel" modunda
   takılı kalınırdı) sonradan kurtarabiliyor.

4. **Yeni müşteri akışı** (`siparis/index.html`): müşteri açılır listesine
   "+ Yeni müşteri ekle" seçeneği eklendi, seçilince bir isim alanı açılıyor.
   Sipariş girenler genelde müşterinin GPS konumunu bilmediği için yeni
   müşteri garajın konumuyla (geçici) kaydediliyor, kullanıcıya "konum
   planlayıcıdan düzeltilmeli" mesajı gösteriliyor — planlayıcıdaki mevcut
   "Haritadan seç" ile dispatcher sonradan düzeltir. Tarayıcıda gerçek
   Supabase'e yeni müşteri+sipariş eklenip planlayıcıda (madde 2'deki düzeltme
   sayesinde) doğru konumla (garaj koordinatları) göründüğü doğrulandı.

## SİPARİŞ GİRİŞİ EKRANINA HARİTADAN KONUM SEÇME (2026-09-23)

Kullanıcı "konumunu da eklesin" dedi — yeni müşteri artık garaj konumuna
sabitlenmek ZORUNDA değil. `siparis/index.html`'e Leaflet (CDN) eklendi;
"Yeni müşteri" seçilince isim alanının altında "📍 Haritadan Konum Seç
(opsiyonel)" butonu çıkıyor, tıklanınca planlayıcıdaki "Haritadan seç" ile
aynı görsel dilde (Esri altlık) küçük bir harita (240px) açılıyor, dokunulan
nokta işaretleniyor, buton "✓ Konum seçildi (lat, lng)" olarak yeşile dönüyor.
Konum seçilmezse (kullanıcı atlarsa) eskisi gibi garaj koordinatlarına
düşüyor — bilinçli olarak ZORUNLU yapılmadı, acil bir sipariş girerken
konum bilinmiyorsa akışı durdurmasın diye.

Gerçek Supabase'e uçtan uca test edildi: haritada bir noktaya dokunulup
("40.7150, 30.4280") yeni müşteri+sipariş eklendi, veritabanında TAM o
koordinatlarla kaydedildiği doğrulandı, test kaydı temizlendi.

## FOTOĞRAFLAR 3 EKRANDA DA + "YARINA BIRAK" AKIŞI (2026-09-23)

Kullanıcının iki isteği: (1) teslim fotoğrafları sadece `teslimat/`de
görünüyordu, planlayıcı ve sipariş girişinde de görünsün; (2) bazı
siparişleri aynı gün, bazılarını ertesi güne planladığı gerçek iş akışının
düzgün desteklenmesi — "Rotayı hesapla" HER ZAMAN tüm bekleyen+planlanan
siparişleri rotaya dahil ediyordu, yarına bırakılmak istenen bir sipariş
istemeden bugünün rotasına karışabiliyordu.

1. **Fotoğraflar:** `index.html` order kartlarına (durum='done') ve
   `siparis/index.html`'e yeni "Son Teslim Edilenler" bölümüne (son 15
   teslimat, fotoğraflarıyla) eklendi. `teslimat/index.html`'e dokunulmadı
   (zaten vardı). Gerçek geçmiş teslimat verisiyle (önceki oturumlardan
   kalma gerçek fotoğraflar) tarayıcıda doğrulandı.

2. **"Yarına bırak" akışı:** Yeni `orders.held` kolonu
   (`supabase-v15-siparis-erteleme.sql`). Bekleyen bir sipariş kartında
   "⏸ Yarına bırak" düğmesi — işaretlenince `activeOrders()` (rota hesaplama
   girdisi) o siparişi ATLAR, ama sipariş "Bekliyor" listesinde kalmaya
   devam eder ("⏸ Ertelendi — bugünkü rotaya dahil edilmeyecek" notuyla).
   Sipariş Girişi ekranında da aynı not gösteriliyor (siparişi giren kişi
   ertelendiğini görebilsin).

   **Kritik bir hata bulunup ANINDA düzeltildi (canlıya çıkmadan yakalandı):**
   `toRow()`'a `held` alanını koşulsuz eklemek, `orders.held` kolonu henüz
   Supabase'de yokken (migration çalıştırılmadıysa) HER sipariş yazma
   işlemini (yeni sipariş dahil!) sessizce başarısız kılıyordu — tarayıcı
   testinde bir test siparişinin gerçekte hiç kaydedilmediği fark edildi.
   `cloudOrderUpsert()` artık önce `held` ile dener, başarısız olursa
   `held` alanı OLMADAN otomatik tekrar dener — migration çalıştırılmamış
   olsa bile sipariş kaydı asla bozulmaz (erteleme özelliği o ana kadar
   yalnızca o oturumda/yerelde çalışır, kalıcı olmaz). Düzeltme sonrası
   gerçek Supabase'e tekrar test edildi, sipariş başarıyla kaydedildi.

**AÇIK KALAN:** `supabase-v15-siparis-erteleme.sql` kullanıcı tarafından
henüz çalıştırılmadı — çalıştırılana kadar "Yarına bırak" yalnızca o an
açık olan tarayıcı sekmesinde çalışır, sayfa yenilenince/başka cihazda
kaybolur (ama hiçbir zaman veri kaybına veya kayıt hatasına yol açmaz).

## MOBİL GÖRÜNÜM/DİNAMİK TARAMASI (2026-09-23)

Kullanıcı "görünümü ve dinamikleri mobile uygun yapalım" dedi. Üç ekranı
da gerçek 375px genişlikte (mobil) tek tek gezip somut sorun aradım —
`teslimat/` ve `siparis/` zaten baştan mobil-öncelikli yazıldığı için
temizdi, `index.html`'de (masaüstü dispatcher aracı, ama telefondan da
kullanılabiliyor) iki gerçek sorun bulundu:

1. **Yüzen "Haritayı Göster" düğmesi içerik üstüne biniyordu** — mobilde
   `position:fixed;bottom:18px` olduğu için, hangi sekmede olursa olsun
   listenin/planın EN ALTINDAKİ kart(lar)ın üzerine oturuyordu (ör. bir
   siparişin saati/butonu düğmenin arkasında kalıyordu). `#side`'a mobilde
   `padding-bottom:76px` eklendi — artık kaydırılabilir alanın sonunda
   düğmenin kapatabileceği kadar boşluk var, hiçbir içerik kalıcı olarak
   gizlenmiyor. Gerçek rota hesaplanıp Plan sekmesinin en altı kontrol
   edilerek doğrulandı.

2. **iOS Safari otomatik yakınlaştırma:** `index.html`'in taban input
   stili 12px'ti (masaüstü için tasarlanmış, kompakt); iOS Safari
   16px'in altındaki bir inputa dokununca SAYFAYI OTOMATİK YAKINLAŞTIRIR
   — telefonda her alana dokunuşta can sıkıcı bir zıplama olurdu. Mobilde
   (`max-width:900px`) tüm input/select/textarea + özel sınıflar
   (`.tplate`, `.cin`, `.shift-in`, `.ordqty`, `.lockrow select`) 16px'e
   çıkarıldı. **Bir CSS kaynak-sırası hatası da bulunup düzeltildi:** ilk
   denemede bu kuralı dosyanın BAŞINA (ilk `@media` bloğuna) koymuştum —
   aynı özgüllükteki `.tplate{font-size:12px}` gibi kurallar dosyada DAHA
   SONRA geldiği için onu eziyordu (CSS'te eşit özgüllükte kaynak sırası
   kazanır). Kural dosyanın EN SONUNA taşınınca (`getComputedStyle` ile
   tarayıcıda 12px→16px değiştiği doğrulanarak) düzeldi.

Masaüstü görünümüne hiç dokunulmadı (değişiklikler yalnızca
`@media(max-width:900px)` içinde).

## EXCEL'E FOTOĞRAF LİNKLERİ + ANDROID/iOS TEST KAPSAMI NOTU (2026-09-23)

Kullanıcının iki sorusu: (1) Excel'de fotoğraf olacak mı ve tüm kayıtları
alabilecek mi, (2) Android'de de sorun olmasın.

1. **Excel'de fotoğraf:** `teslimat_kayitlari` tablosu (v14) foto
   kolonlarını hiç almamıştı — gerçek bir eksiklikti. Yeni
   `supabase-v16-teslimat-log-fotograf.sql`: `photo_tank_url`/
   `photo_irsaliye_url` kolonları eklendi, trigger fonksiyonu
   `NEW.photos` jsonb dizisinden `type='tank'`/`type='irsaliye'`
   linklerini çıkarıp yazacak şekilde güncellendi, ARTI hâlâ `orders`
   tablosunda duran (arşivlenmemiş) eski kayıtlar için geriye dönük
   bir backfill UPDATE'i de var. `index.html`'in `exportExcel()`'i her
   iki sayfaya da ("Teslimat Geçmişi" VE "Siparişler (bugün)") foto
   linki sütunları eklendi. **"Tüm kayıtları alabilme"** zaten
   sağlanıyordu — "Teslimat Geçmişi" sorgusunda hiç `.limit()` yoktu,
   kontrol edilip doğrulandı. Tarayıcıda `XLSX.writeFile`'ı geçici
   olarak yakalayıp gerçek workbook içeriği okunarak test edildi:
   "Siparişler (bugün)" sayfası ŞU AN (v16 çalıştırılmadan) bile gerçek
   foto linklerini doğru taşıyor (bu veri zaten `orderList`'te bellekte
   duruyor); "Teslimat Geçmişi" sayfası v16 çalıştırılana kadar foto
   sütunlarını boş bırakıyor (çökmeden).

2. **Android/iOS test kapsamı — dürüst açıklama:** Bu ortamdaki tarayıcı
   aracı Chromium tabanlı (Blink motoru) — bu, **Android Chrome ile
   AYNI motor**, yani mobil görünüm/dinamik testleri Android için
   gerçekten temsil edici. iOS Safari ise FARKLI bir motor (WebKit) ve
   bu ortamdan hiç test edilemiyor — önceki oturumdaki 16px input
   düzeltmesi WebKit'in bilinen bir davranışına karşı ÖNLEYİCİ olarak
   uygulandı (literal olarak iPhone'da doğrulanamadı). Kullanıcıya bu
   ayrım açıkça belirtildi; gerçek bir iPhone'da hızlı bir el testi
   (herhangi bir input alanına dokunup sayfanın zıplayıp zıplamadığına
   bakmak) hâlâ değerli olur.

**AÇIK KALAN:** `supabase-v16-teslimat-log-fotograf.sql` kullanıcı
tarafından henüz çalıştırılmadı.

## VERİ TASARRUFU: LAZY LOAD + KÜÇÜK ÖNİZLEME (2026-09-23)

Kullanıcı "olabildiğince az veri harcasın, mümkün mü" dedi. En büyük veri
kalemi fotoğraflardı — önceki oturumda YÜKLEME tarafı sıkıştırılmıştı ama
listelerde küçük önizleme gösterirken bile TAM boyutlu (1600px) fotoğraf
indiriliyordu. İki katmanlı çözüm:

1. **`loading="lazy"`** — 3 ekrandaki tüm foto `<img>` etiketlerine
   eklendi (`index.html` teslim kartları, `siparis/index.html` "Son
   Teslim Edilenler", `teslimat/index.html` durak detayı). Ekrana hiç
   girmeyen fotoğraflar artık hiç indirilmiyor.

2. **Ayrı, çok daha küçük "thumb" (önizleme) dosyası** — asıl kazanım bu.
   `teslimat/index.html`'deki `uploadPhoto()` artık HER fotoğraf için iki
   dosya üretip yüklüyor: tam boyut (1600px, q0.75 — değişmedi) ve yeni
   bir thumb (220px, q0.55). `photos` alanı artık `{type,url,thumb}`
   şeklinde — 3 ekrandaki TÜM küçük resim gösterimleri (`<img>`) artık
   `p.thumb||p.url` kullanıyor (eski fotoğraflarda thumb yoksa tam
   boyuta düşer, kırılmaz); tıklanınca açılan `<a href>` hâlâ TAM
   fotoğrafa gidiyor. Thumb yüklemesi başarısız olursa (ör. eski
   tarayıcı) sessizce tam url'e düşer, teslimat asla engellenmez.
   `dolum_fisleri` (tek fotoğraflık, hiçbir listede küçük resim olarak
   gösterilmiyor) kasıtlı olarak dışarıda bırakıldı — gereksiz karmaşıklık.

   Tarayıcıda gerçek yüklemeyle ölçüldü: 3000×2000 sentetik bir görsel
   tam boyutta 95 KB, thumb'ı yalnızca **5,3 KB** (~18 kat küçük) çıktı.
   Gerçek teslim fotoğraflarında (rastgele gürültü değil, düz yüzeyler)
   oran muhtemelen daha da iyi. Test dosyaları storage'dan silinmeye
   çalışıldı, silme API'si beklenmedik "Bucket not found" hatası verdi
   (yok sayıldı — iki küçük test dosyası, ~100 KB, önemsiz).

**Excel'e etkisi yok** — `exportExcel()` hâlâ `.url` (tam boyut) linkini
kullanıyor, kayıt/doğrulama amaçlı tam kalite korunuyor.

**Dokunulmayanlar (bilinçli):** Harita karo (tile) trafiği — etkileşimli
rota haritasının doğası gereği, işlevi bozmadan azaltılamaz. 45 saniyelik
yedek yenileme (soft refresh) — küçük JSON, fotoğraf kadar maliyetli değil,
dokunulmadı.

## iOS ZOOM GERÇEKTEN KALICI KALIYORMUŞ (2026-09-23)

Kullanıcı "iphoneda yazı yazmak isteyince ekran yaklaşıyor ama geri eski
haline gelmiyor" dedi — önceki oturumdaki 16px input düzeltmesi (yakınlaşma
TETİKLENMESİNİ azaltır) sorunu tam çözmemiş. Kök neden bulundu:
`teslimat/index.html` ve `siparis/index.html`'in viewport meta etiketinde
`maximum-scale=1` VARDI (sayfa pinch-zoom'u tamamen kapatıyor, sorun hiç
yaşanmıyordu) ama **`index.html` (planlayıcı) bunu hiç içermiyordu** —
sadece `width=device-width, initial-scale=1`. iOS Safari'de bazen bir
inputa dokunup yakınlaştıktan sonra otomatik geri dönüş güvenilmiyor;
kalıcı çözüm yakınlaşmayı baştan hiç açmamak. `index.html`'e de aynı
`maximum-scale=1` eklendi.

**Haritanın kendi zoom'u etkilenmedi mi diye kontrol edildi:** Leaflet
haritası kendi dokunma/​buton işleyicileriyle çalışıyor, sayfa seviyesindeki
pinch-zoom kısıtlamasından bağımsız — tarayıcıda `map.zoomIn()` çağrılıp
zoom seviyesinin (10→11) sorunsuz değiştiği doğrulandı (zaten `siparis/
index.html`'de de aynı kısıtlamayla birlikte bir Leaflet haritası — konum
seçici — sorunsuz çalışıyordu, bu da ayrı bir kanıttı).

## SİLİNEN TESLİMATLAR EXCEL'DE KIRMIZI İZ BIRAKIR (2026-09-23)

Kullanıcı: "sipariş silinirse teslim edildiyse Excel'den silmesin, yanına
'silindi' kırmızı ile belirtsin." Kalıcı log (`teslimat_kayitlari`) zaten
`orders` tablosundan bağımsız olduğu için silme onu ETKİLEMİYORDU — asıl
eksik, silme OLAYININ görünür bir iz bırakmamasıydı.

Yeni `supabase-v17-silinen-teslimat-isaretle.sql`: `teslimat_kayitlari`'na
`siparis_silindi boolean` eklendi. `index.html`'in `delOrder()`'ı artık
sildiği sipariş `status==='done'` ise (a) silmeden önce ayrı, daha ciddi
bir onay mesajı gösteriyor, (b) `cloudOrderDelete`'ten sonra
`markLogDeleted(id)` ile kalıcı log satırını `siparis_silindi=true`
yapıyor.

**Gerçek kırmızı renk için kütüphane değişti:** `exportExcel()`'in
kullandığı standart `xlsx@0.18.5` (SheetJS ücretsiz sürüm) .xlsx
ÇIKTISINDA hücre stilini (dolgu rengi) desteklemiyor — denendi, sessizce
yok sayıyordu. `xlsx-js-style@1.2.0`'a (aynı API'yi koruyan, stil
desteği eklenmiş bir topluluk çatalı) geçildi. "Teslimat Geçmişi"
sayfasına yeni bir "Durum" sütunu eklendi; `siparis_silindi=true` olan
satırlar kırmızı dolgu + beyaz kalın yazıyla ("SİLİNDİ") işaretleniyor.

Tarayıcıda üç ayrı doğrulama yapıldı: (1) stil nesnesinin GERÇEKTEN
`.xlsx` ikili formatına yazılıp geri okunduğunda hayatta kaldığı
(`XLSX.write`→`XLSX.read` round-trip, dolgu rengi `C8402C` aynen
korundu, normal satırlarda dolgu yok) — bu, gerçekten Excel'de kırmızı
görüneceğinin kanıtı; (2) `markLogDeleted()` sütun henüz yokken (v17
çalıştırılmadan) çökmeden 400 hatasını sessizce yuttuğu; (3) tam
`exportExcel()` akışının yeni "Durum" sütunuyla hatasız tamamlandığı.

**AÇIK KALAN:** `supabase-v17-silinen-teslimat-isaretle.sql` kullanıcı
tarafından henüz çalıştırılmadı.

## "PLANDAN ÇIKAR" — BİR SİPARİŞİ AÇIKTA BEKLETME (2026-09-23)

Kullanıcı gerçek bir senaryo sordu: "siparişler geldi herkese atadım ama
birini beklettim/atamadım, açıkta durması gerek — ne yaparım?" Mevcut
"⏸ Yarına bırak" (v15, `held`) yalnızca HENÜZ 'wait' durumundaki bir
siparişte işe yarıyordu — `activeOrders()` held kontrolünü SADECE
`status==='wait'` için yapıyordu. Ama kullanıcının senaryosu şuydu: "Rotayı
hesapla" ZATEN çalıştırılmış, sipariş bir araca 'plan' olarak atanmış —
bunu GERİ ÇEKMENİN hiçbir yolu yoktu (durum düğmeleri yalnızca plan→road
ve road→plan destekliyordu, plan→wait hiç yoktu).

Yeni `unplanOrder(id)` + 'plan' durumundaki her sipariş kartına "⏸ Plandan
çıkar" düğmesi: `status='wait'`, `held=true`, `vehicle=null`, `comp=null`,
`plannedAt=null` yapıyor — sipariş anında açığa düşüyor VE bir sonraki
"Rotayı hesapla"da (held sayesinde) tekrar otomatik atanmıyor, kullanıcı
"▶ Bugüne al" ile bilinçli olarak geri dahil etmeden. Gerçek bir plan
siparişiyle (54 KP 525'e atanmıştı) uçtan uca test edildi:
`status/vehicle/comp` doğru şekilde Supabase'e yazıldı, `activeOrders()`
onu doğru şekilde dışladı. (`held` alanı kendisi hâlâ v15 SQL'i
bekliyor — o çalışana kadar bu koruma yalnızca o oturumda/yerelde geçerli,
ama status/vehicle sıfırlanması her zaman kalıcı.)

**Kullanıcıya cevap:** Sipariş henüz "Bekliyor"daysa doğrudan "⏸ Yarına
bırak"; "Planlandı"ya geçtiyse (rota zaten hesaplandıktan sonra fark
edildiyse) yeni "⏸ Plandan çıkar" düğmesini kullan — ikisi de aynı
sonuca (açıkta, ertelenmiş) götürür.

## "TESLİMLERİ ARŞİVLE" NET AÇIKLAMASI + DÜZELTME (2026-09-23)

Kullanıcı "arşivle deyince ne oluyor, sonra bir şekilde görebilecek miyim"
diye sordu. `clearDone()` kodu incelendi: teslim+iptal durumundaki
siparişleri `orders` tablosundan KALICI OLARAK siliyor (`cloudOrderDelete`
her biri için). **Gerçek bir tutarsızlık bulundu:** onay mesajı hâlâ eski
"CSV ile yedek alabilirsin" diyordu — CSV çoktan Excel'e çevrilmişti,
mesaj hiç güncellenmemişti. Düzeltildi: artık teslim/iptal sayısını ayrı
ayrı gösteriyor VE hangisinin kalıcı geçmişte kalıp hangisinin
KALMAYACAĞINI açıkça söylüyor.

**Gerçek/net durum:** Teslim edilenler `teslimat_kayitlari` tetikleyicisi
sayesinde (v14) arşivlemeden ÖNCE zaten kalıcı tabloya kopyalanmış
durumda — "Excel indir" → "Teslimat Geçmişi" sayfasında SONSUZA KADAR
kalırlar, arşivleme bunu hiç etkilemez. **İptal edilenler için böyle bir
kalıcı kayıt YOK** — arşivlenince tamamen, geri dönüşsüz silinirler.
Kullanıcıya bu asimetri açıkça anlatıldı, iptaller için de kalıcı log
istenirse (aynı `teslimat_kayitlari` deseni, `NEW.status='canc'` de
tetiklenecek şekilde) ayrı bir iş olarak eklenebilir — kullanıcı onayı
bekleniyor, otomatik yapılmadı.

**Güncelleme — kullanıcı onayladı, eklendi (aynı gün):** Yukarıdaki asimetri
kapatıldı. `supabase-v18-iptal-log.sql` — `teslimat_kayitlari` ile AYNI
desende yeni `iptal_kayitlari` tablosu + `log_iptal()` tetikleyicisi
(`NEW.status='canc'` olduğu an otomatik loglar, `OLD.status is distinct
from 'canc'` kontrolüyle aynı siparişin tekrar tekrar loglanması
engellendi). Excel indirmeye yeni bir "İptal Geçmişi" sayfası eklendi
(Teslimat Geçmişi ile yan yana). `clearDone()`'ın onay mesajı da artık
doğru: "ikisi de Excel'de HER ZAMAN kalır" diyor (önceki mesaj hâlâ
iptaller için kalıcı kayıt YOK diyordu — artık yanlış olurdu). **v18 SQL
kullanıcı tarafından henüz çalıştırılmadı** — çalıştırılana kadar İptal
Geçmişi sayfası sadece başlık satırıyla boş gelir, hata vermez (aynı
zaten kurulmuş "eksik migration → sessiz no-op" deseni, tarayıcıda
`iptal_kayitlari` bulunamadı uyarısıyla doğrulandı).

## iPHONE'DA "EXCEL İNDİR" ÇALIŞMIYOR — GERÇEK ÇÖZÜLDÜ (2026-09-23)

Kullanıcı gerçek iPhone'da test edip bildirdi: "excel indir çalışmıyor
iphonede denedim sadece" (masaüstünde ve Android'de sorun yoktu). **Kök
neden:** `exportExcel()` önce Supabase'den `teslimat_kayitlari` verisini
`await` ile çekiyor, SONRA `XLSX.writeFile(...)` çağırıyordu. iOS
Safari, bir `await` zincirinden sonra çalışan kodu artık "gerçek bir
kullanıcı tıklamasına bağlı" saymayabiliyor — bu yüzden dosya indirmeyi
sessizce engelliyor (hata da vermiyor, sadece hiçbir şey olmuyor).

**Çözüm — iki adımlı buton deseni:** `exportExcel(btn)` artık veriyi
`await`le çekip workbook'u hazırlıyor, sonra `XLSX.writeFile`'ı HEMEN
çağırmak yerine butonu "📥 İndirmek için tıkla"ya çeviriyor; o ikinci
tıklama `await` içermeyen SENKRON bir `onclick`, bu yüzden Safari'nin
"gerçek tıklama" şartını karşılıyor ve indirme güvenilir çalışıyor.
`btn` verilmezse (programatik çağrı) eski senkron davranış korunuyor.

Tarayıcıda doğrulandı: `XLSX.writeFile` mock'lanıp `exportExcel(null)`
çağrısıyla üretilen workbook'un sayfa isimleri/içerikleri doğru
üretildiği teyit edildi (bkz. aşağıdaki not — aynı testte yeni "İptal
Geçmişi" sayfası da doğrulandı); gerçek iPhone'da buton-tıkla akışı
kullanıcı tarafından henüz yeniden test edilmedi, bir sonraki kullanımda
teyit istenecek.

## TANKER GÖZ/HACİM: AYARLAR'A TAŞINDI (2026-09-23)

Kullanıcı isteği: "tankerlerin gözlerini ve hacimlerini ayarlardan
değiştirebileyim, içlerindeki litreleri filodan yazabileyim — sadece göz
ve hacimler ayarlardan değişsin." Önceden Filo sekmesindeki her tanker
kartında göz sayısı (+ göz/✕ ile) ve hacim (L) birlikte, günlük "mevcut L"
ile aynı yerde düzenleniyordu — yapısal (nadiren değişen) veri ile günlük
operasyon verisi karışıktı.

Ayarlar sekmesine yeni "Tanker Yapılandırması" bölümü (`renderTankConfig()`)
eklendi — göz ekleme/silme (`addComp`/`delComp`) ve hacim girme (`setCap`)
BURAYA taşındı, aynı `tankers[]` dizisini kullanıyor. Filo sekmesindeki
kart artık hacim'i salt-okunur gösteriyor, yalnızca "mevcut L" (`setCur`)
editable kaldı; "Göz/hacim değişikliği için Ayarlar sekmesine bak" ipucu
eklendi.

**Gerçek bir hata bulunup düzeltildi (kendi testimde yakalandı, kullanıcıya
gitmeden önce):** Hacim artık iki AYRI DOM'da gösteriliyor (Ayarlar'da
input, Filo'da salt-okunur metin) ama `setCap()` performans için (yazarken
odak kaybolmasın diye) tam `renderFleet()` yerine yalnız özet satırını
güncelliyordu — bu yüzden Ayarlar'da hacim değiştirilince Filo'daki eski
değer sekme değiştirilene kadar YANLIŞ görünmeye devam ediyordu (yalnız alt
toplam "L" doğru güncelleniyordu, tek tek göz hacmi değil). `hacim-${i}-${j}`
id'si eklenip `setCap` artık o elementi de canlı güncelliyor; aynı şekilde
Ayarlar'ın kendi alt toplamı (`tcfgsum${i}`) da önceden hiç canlı
güncellenmiyordu, o da eklendi. Tarayıcıda doğrulandı: Ayarlar'da bir
hacim 9999'a değiştirilip Filo'ya geçilince değerin ANINDA doğru göründüğü
teyit edildi, sonra test değeri geri (7000) alındı.

## GÖRSEL CİLA: DERİNLİK + HAREKET (2026-09-23)

Kullanıcı "görsel olarak iyi mi, daha iyi yapabilir miyiz, profesyonel
kalsın" diye sordu. Değerlendirme: durum rozetleri (BEKLİYOR/PLANLANDI/
YOLDA/TESLİM/İPTAL) zaten renk kodluydu (`.b-wait/.b-plan/.b-road/.b-done/
.b-canc`), buton hiyerarşisi (`.primary` dolu gold / `.ghost`+`.oacts`
çerçeveli) de zaten ayrışıktı — bunlar iyiydi. Eksik olan: hiçbir kart
(`ocard`, `tcard`, `card`, `stop`, `newform`, `queue-wrap`, `plateBtn`)
gölge kullanmıyordu (tamamen düz/kağıt üzerine çizim gibi duruyordu) ve
hiçbir etkileşimde (hover/active) yumuşak geçiş yoktu (renk/gölge anlık
sıçrıyordu).

Kullanıcı bir üçüncü parti "Yakıt Ofisi" filo/fatura paneli ekran görüntüsü
paylaştı ama netleştirdi: **referans değil**, renk/stil ona benzemesi
gerekmiyor — sadece "en uygun ve iyisini bul her açıdan" dendi, karar
serbest bırakıldı.

3 ekrana da (index/siparis/teslimat) aynı desen uygulandı: `:root`'a
`--sh-sm`/`--sh-md` iki gölge token'ı eklendi; tüm kart sınıflarına
`box-shadow:var(--sh-sm)` (dinlenme hali) eklendi; `.primary`/`.btn-save`
gibi birincil butonlara hover/active'te `box-shadow:var(--sh-md)` +
`transform:translateY(-1px)` "kalkma" mikro-etkileşimi eklendi;
button/input/select/kart sınıflarına genel `transition:box-shadow .15s,
border-color .15s,background-color .15s,transform .1s,color .15s`
eklendi; üç ekranın header/brand şeridine de zemin ile ayrışması için
ince bir alt gölge (`box-shadow:0 1px 0 rgba(0,0,0,.15)`) eklendi. Renk
paleti (cream/gold tema) ve rozet renkleri hiç değiştirilmedi — kullanıcı
"renkler önemli değil" dedi, mevcut kimlik korundu.

Tarayıcıda üç ekranın da masaüstü ve 375px mobil genişlikte doğru
render edildiği (kart gölgeleri görünür ama abartısız, hiçbir düzen
kayması/taşma yok) doğrulandı. `node --check` her üç dosyada da script
bloğunun bozulmadığını doğruladı.

**Devamı — kullanıcı daha fazlasını istedi:** "font ve kutular vs de
değişse nasıl olur, özgün ve amaca uygun olarak, yakıt ofisini boşver onu
örnek alma" + "modern olmalı". Aynı oturumda ikinci bir tur yapıldı:

1. **Font:** `Instrument Sans` → `Manrope` (wght 400-800) üç ekranda da
   (Google Fonts linki + tüm `font-family` referansları). Veri/rakam
   alanları (`IBM Plex Mono`) hiç değişmedi — plaka, litre, tarih gibi
   sabit genişlikli veriler için zaten doğru seçimdi, korundu. Başlıklar
   (`.brand h1`, `header h1`, `#login h1`) yeni 800 ağırlığa çekildi,
   daha vurgulu/modern bir hiyerarşi için.
2. **Kutular:** Tüm kart/input/buton `border-radius` değerleri kabaca
   ikiye katlandı (kartlar 8→14/16px, inputlar/butonlar 4→7-9px,
   uyarı/bilgi şeritleri 4→9px, teslimat modalının üst köşeleri
   12→20px) — daha yumuşak, çağdaş bir SaaS hissi için. Kartlara ayrıca
   biraz daha iç boşluk eklendi (örn. `.ocard` 11px/13px → 14px/16px)
   nefes alan bir düzen için. Küçük yapısal öğeler (harita pin'leri,
   renk noktaları/`.tdot`, dairesel rozet ikonları) bilinçli olarak
   dokunulmadı — onlar zaten işlevsel/küçük, büyütmek anlamsız olurdu.

Kullanıcının paylaştığı "Yakıt Ofisi" ekran görüntüsü netleştirildiği
gibi **referans olarak kullanılmadı** — renk paleti (cream/gold),
durum rozeti renkleri ve genel kompozisyon hiç değişmedi, yalnızca
tipografi ve kutu geometrisi güncellendi.

Tarayıcıda üç ekran da (Siparişler/Müşteriler/Filo sekmeleri, sipariş
kartı — gerçek teslim edilmiş bir sipariş fotoğraflarıyla dahil — ve
teslimat ekranının tanker seçim listesi) yeniden ekran görüntüsüyle
doğrulandı; `node --check` yine üç dosyada da temiz geçti.

## MÜŞTERİ REHBERİ EXCEL'E EKLENDİ + SEKME SIRASI (2026-09-23)

İki küçük istek aynı oturumda: "rehberde excele aktarılabilsin" ve
"ayarlar ve plan sekmelerinin yerleri değişsin, hatta filo da sağa kayıp
planla yer değişsin".

1. **Müşteri Rehberi sheet'i:** `exportExcel()`'e yeni bir sayfa eklendi
   — `customers[]` dizisi (isim + enlem/boylam) alfabetik sıralanıp
   "Müşteri Rehberi" adıyla eklendi. Sipariş/teslim istatistiği DAHİL
   EDİLMEDİ (bilinçli sadelik — kullanıcı sadece rehberin kendisinin
   aktarılabilmesini istedi, ekstra kırılım istemedi; istenirse sonra
   eklenebilir).
2. **Sekme sırası:** İki adımda değişti. Önce Ayarlar↔Plan yer
   değiştirdi, sonra kullanıcı "filo da sağa kayıp planla yer değişsin"
   dedi — Filo↔Plan da yer değiştirdi. Nihai sıra: **Siparişler →
   Müşteriler → Plan → Filo → Ayarlar** (önceki: Siparişler →
   Müşteriler → Filo → Ayarlar → Plan). Yalnızca `.tabbtn` buton
   sırası değişti; panel `<div>`'lerinin DOM sırası (`data-tab`
   toggle'ı zaten sıradan bağımsız çalışıyor) dokunulmadı.

Tarayıcıda doğrulandı: tabbar'da yeni sıra göründü; `exportExcel(null)`
mock'lanıp workbook sayfa listesinde "Müşteri Rehberi" olduğu ve
içeriğinin gerçek 6 müşteriyi (isim+koordinat, alfabetik) doğru taşıdığı
teyit edildi.

## "TESLİMLERİ ARŞİVLE" → "EKRANI TEMİZLE" (2026-09-23)

Kullanıcı haklı bir tutarsızlık fark etti: "teslimleri arşivle mantıksız
kalıyor, ekranı temizle demek daha mantıklı değil mi". Doğru — buton
aslında hiçbir şeyi arşivlemiyor; kalıcı arşivleme (`teslimat_kayitlari`/
`iptal_kayitlari` tetikleyicileri) zaten teslim/iptal ANINDA otomatik
oluyor. Bu butonun tek işlevi uygulamadaki GÖRÜNÜR listeyi temizlemek —
"arşivle" ismi kullanıcıyı "bu butona basmazsam veri kaybolur mu" diye
düşündürüyordu (nitekim önceki bir soru da tam bu karışıklıktan
doğmuştu). Buton metni "Ekranı temizle" oldu, onay mesajı da "arşivleme
işlemi zaten otomatik olur" diye netleştirildi. `clearDone()` fonksiyon
adı ve davranışı hiç değişmedi — yalnızca kullanıcıya gösterilen metin.

## TEŞHİS: v15-v18 SQL HİÇ ÇALIŞTIRILMAMIŞ (2026-09-23)

Kullanıcı "sildiğim teslim sipariş kırmızı görünmedi excelde" dedi.
Canlı Supabase'e doğrudan REST sorgusuyla (`curl` + publishable key)
bakıldı: `orders.held`, `teslimat_kayitlari.photo_tank_url`,
`teslimat_kayitlari.siparis_silindi` kolonları VE `iptal_kayitlari`
tablosunun HİÇBİRİ mevcut değil — yani v15, v16, v17, v18 SQL
dosyalarının HİÇBİRİ hâlâ çalıştırılmamış (yalnızca v13/v14
çalıştırılmıştı, bkz. önceki notlar). Bu, kod hatası değil — kod zaten
"kolon yoksa sessizce uyar, çökme" deseniyle yazılmıştı
(`markLogDeleted()`'daki catch), tam da bunun için: `siparis_silindi`
kolonu yoksa `UPDATE` isteği `42703` hatası alır, konsola uyarı yazılır,
Excel'deki satır normal (kırmızısız) görünmeye devam eder — kullanıcıya
hiçbir hata göstermeden.

Kolaylık için `supabase-v15-v18-toplu.sql` eklendi — dört dosyanın
birleşimi, hepsi `if not exists` korumalı olduğu için TEK seferde SQL
Editor'e yapıştırılıp çalıştırılabilir. Kullanıcıya bu adım hatırlatıldı.

**Güncelleme — kullanıcı çalıştırdı, doğrulandı (aynı gün):** REST
sorgusuyla `orders.held`, `teslimat_kayitlari.photo_tank_url`,
`teslimat_kayitlari.siparis_silindi` ve `iptal_kayitlari` tablosunun
hepsinin artık var olduğu teyit edildi — v15-v18'in DÖRDÜ DE canlıda
aktif. Kullanıcı ardından "gereksiz dosyaları sil" dedi;
`supabase-v15-v18-toplu.sql` işini gördüğü ve artık v15/v16/v17/v18
dosyalarının birebir (bakımı zor) kopyası olduğu için silindi — dört
ayrı versiyonlu migration dosyası (tarihçe için) repoda kalmaya devam
ediyor.

## PLAN DIŞI TESLİMAT + ŞU ANKİ KONUM + TIR HATASI + AKIŞ DENETİMİ (2026-09-24)

Kullanıcı üç şey istedi: (1) şoför plan dışı bir yere de teslimat yapabilsin,
yeni müşteri konumunu ekleme sırasında o anki konumla işaretleyebilsin;
(2) sipariş atama / gidiş sırası / durum akışı (açık-bekleyen-planlandı-teslim)
kontrol edilsin; (3) "TIR işaretliyorum ama Ayarlar'da kaydolmuyor".

**TIR hatası — kök neden:** canlı `tankers` tablosunda `is_tir` kolonu YOK
(`supabase-v12-ek.sql` hiç çalıştırılmamış). `cloudTankUpsert` satırda `is_tir`
gönderdiği için Postgrest TÜM güncellemeyi reddediyordu VE `error` hiç
kontrol edilmiyordu — yani şu an hiçbir tanker düzenlemesi (plaka, hacim,
mevcut L, vardiya, lisans) buluta gitmiyordu, sessizce. Düzeltme: hata artık
kontrol ediliyor; `is_tir` yüzünden başarısız olursa TIR hariç alanlar yine
yazılıyor ve kullanıcıya bir kez "supabase-v12-ek.sql'i çalıştır" uyarısı
gösteriliyor. **TIR'ın gerçekten kalıcı olması için `supabase-v12-ek.sql`
Supabase SQL Editor'de çalıştırılmalı** (henüz çalıştırılmadı; dikkat: dosya
54 KP 654'ü TIR yapar).

**Plan dışı teslimat (teslimat ekranı):** "➕ Plan dışı teslimat" düğmesi.
Müşteri seç VEYA "Yeni müşteri (bulunduğum konum)": yeni müşteride GPS
otomatik alınır (konum yoksa kayıt engellenir), müşteri o koordinatla
`customers`'a eklenir. Litre + 2 fotoğraf + not → `orders`'a `status='done'`,
`vehicle=plaka`, `note='Plan dışı teslimat'`, `deliver_note='[Plan dışı] ...'`
olarak yazılır (`log_teslimat` tetikleyicisi kalıcı geçmişe de ekler). Seçilen
müşterinin açık (wait/plan/road) siparişi varsa "o siparişe işlensin mi?"
diye sorulur — evetse o sipariş teslim edilir (aynı teslimat iki kez
sayılmaz/plana tekrar girmez). Ekranda ayrıca artık "✓ Tamamlanan — plan dışı
/ rotadan çıkan" bölümü var: bugün bu araçla teslim edilip rotada görünmeyen
her sipariş (plan dışı olanlar + rota yeniden hesaplanınca listeden düşenler)
görünür; Durak/Tamam/Teslim L sayaçları bunları da kapsar (önceden rota
yeniden hesaplanınca teslim edilen duraklar ekrandan ve sayaçtan kayboluyordu).
Rotası hiç olmayan şoför de plan dışı teslimat girebilir.

**Şu anki konum düğmeleri:** planlayıcı Müşteriler sekmesi ("📍 Şu anki
konumum" → koordinat alanını doldurur), sipariş ekranı yeni müşteri ("🎯 Şu
anki konumumu kullan" → haritada işaretler), teslimat plan dışı formu (otomatik).
İzin verilmezse anlaşılır uyarı çıkar.

**Akış denetimi (planlayıcı, yerelde bulut yazımı kapalı test):** ilk hesap
(atama+göz+sıra) doğru; ertelenen (held) sipariş dışarıda kalıyor; Yola çıktı →
yeniden hesapta araçta kalıyor; teslim işlenen yeniden hesapta korunuyor/rotadan
çıkıyor; Plandan çıkar → Bugüne al döngüsü çalışıyor; iptal→geri aç doğru.
Bulunan tek boşluk: planlanmış/yolda bir sipariş doğrudan iptal edilemiyordu
(İptal yalnız "Bekliyor"da vardı) → İptal artık wait/plan/road'da (onaylı),
iptalde araç/göz/planlama alanları temizleniyor.

## PLANLAYICIDAN SATIŞ / TESLİMAT GİRİŞİ (2026-09-24)

Kullanıcı: "planlayıcı satış/teslimat da girebilmeli sisteme". Siparişler
sekmesindeki yeni sipariş formuna "✓ Satış / teslimat gir (tamamlanmış)"
düğmesi eklendi. Mevcut teslim diyaloğu (`dlg`) yeniden kullanıldı: müşteri,
araç (opsiyonel), bırakılan litre, saat, not. Kayıt sipariş olmadan doğrudan
`status='done'` bir sipariş olarak yazılır (`log_teslimat` tetikleyicisi
kalıcı geçmişe/Excel'e de ekler). Müşterinin açık (wait/plan/road) siparişi
varsa "o siparişe işlensin mi?" diye sorar (şoför ekranındaki plan dışı
teslimatla aynı mantık — aynı teslimat iki kez sayılmaz). Planlayıcı
diyaloğunda fotoğraf yok (fotoğraf gereken teslimat şoför ekranından girilir).
Tarayıcıda (bulut yazımı kapalı) üç senaryo doğrulandı: açık siparişi olmayan
müşteri → yeni kayıt; açık siparişli + evet → mevcut sipariş teslim edildi;
açık siparişli + hayır → ayrı kayıt. Normal "Teslim işle" diyaloğu etkilenmedi.

## EXCEL'DE FOTOĞRAFLAR: TIKLANABİLİR BAĞLANTI (2026-09-24)

Kullanıcı "fotolar excelde olacak mı / nasıl olmalı" diye sordu. Foto linkleri
zaten sütunlardaydı ama düz uzun URL metniydi. Artık "Dolum tankı — aç" /
"İrsaliye — aç" adlı tıklanabilir (mavi, altı çizili) hücre bağlantıları
(`linkCell`, xlsx-js-style `l.Target`); Teslimat Geçmişi ve Siparişler
sayfalarında. Silindi (kırmızı) satırlarda da bağlantı korunuyor. Gerçek .xlsx
yazıp geri okuyarak doğrulandı. **Bilinçli karar:** fotoğraflar dosyaya
GÖMÜLMEDİ (SheetJS resim gömemez; gömmek dosyayı yüzlerce MB yapar ve
ExcelJS gibi ağır bir kütüphane ister) — link tıklanınca tam boyutlu foto
açılır. Not: v16 öncesi loglanan eski teslimatlarda foto linki yoktur
(backfill yalnızca orders'ta hâlâ duran kayıtlara uygulanabildi).

## TESLİMAT ONAY AKIŞI (2026-09-24)

Kullanıcı önerdi: "teslimatlar onaya düşsün, onaydan sonra kaydedilsin, teslim
tarihine göre sıralansın". Yeni sipariş durumu **`onay` (ONAY BEKLİYOR)**:
- **Şoför** teslimi (rota durağı VEYA plan dışı) girince sipariş `status='onay'`
  olur (litre, foto, GPS, saat hepsi yazılır) ama henüz `done` değildir. Kalıcı
  kayıt (`teslimat_kayitlari` tetikleyicisi yalnız `done`'da çalışır) ve Excel
  geçmişi bu yüzden ONAYDAN SONRA oluşur — kod değişikliği gerekmedi, mevcut
  tetikleyici zaten böyle davranıyor. Şoför ekranında rozet "⏳ Onayda", teslim
  sonrası "Teslimat gönderildi — onaydan sonra kaydedilecek" bildirimi çıkar.
- **Planlayıcı** Siparişler sekmesinde mor "Onay bekleyen N" filtresi + sekme
  başlığında "N onay bekliyor". Kart: teslim edilen litre, foto, saat + **✓ Onayla**
  (→`done`, kalıcı kayda işlenir), **Düzelt** (mevcut diyalog; litre/saat düzeltip
  onaylar), **Reddet** (→`plan`, şoför ekranında tekrar "Bekliyor" olur, yeniden
  girilebilir). Planlayıcının kendi girdiği teslim/satış doğrudan `done` (planlayıcı
  zaten onaylayan taraf).
- **Sıralama:** Teslim ve Onay filtreleri teslim tarihine göre (yeni→eski); Excel
  "Siparişler" sayfası teslim tarihine göre; "Teslimat Geçmişi" zaten
  `delivered_at` azalan. Stok özetinde onay bekleyenler teslim sayılır.
- Sipariş giriş ekranındaki "Son teslim edilenler" onay bekleyenleri de "ONAY
  BEKLİYOR" rozetiyle gösterir.
- Veritabanı değişikliği YOK (`orders.status` serbest metin). Not: onay bekleyen
  bir sipariş planlayıcı onaylamadıkça Excel geçmişine girmez.
Tarayıcıda doğrulandı (planlayıcı: filtre/sıralama/onayla/reddet; şoför: `onay`
yazımı, rozet, sayaç, bildirim).

## "TESLİMAT GİRİŞİ" AYRI SEKME (2026-09-24)

Kullanıcı: sipariş formunun içindeki "Satış / teslimat gir" düğmesi karıştırıyor,
sipariş gibi algılanıyor; düzgün bir yer ver, adı "Teslimat girişi" olsun. Düğme
sipariş formundan kaldırıldı; Siparişler'in yanına **"Teslimat girişi"** adlı
ayrı bir sekme eklendi (sıra: Siparişler → Teslimat girişi → Müşteriler → Plan →
Filo → Ayarlar). Sekmede müşteri, litre, araç (ops.), teslim tarihi/saati, not
formu + altında "Son teslimatlar" (en yeni 8, durum rozetli). Mantık aynı:
doğrudan `done` kaydı; müşterinin açık siparişi varsa "o siparişe işlensin mi?".
Önceki diyalog tabanlı doğrudan-mod kodu (`openDirect`/`saveDirect`) silindi.
Bulunan/ düzeltilen küçük hata: `renderOrders()` boş filtrede erken `return`
ettiği için (ve `updateStatBar` atlandığı için) sekmedeki liste yenilenmiyordu;
boş-liste yolunda da yenileme + `updateStatBar` çağrılıyor.

## ÜÇ EKRANDA DÜZENLEME (2026-09-24)

Kullanıcı: "teslimatçı teslim bilgilerini, sipariş giren siparişi bilgilerini
düzenleyebilsin; planlayıcı hem siparişi hem teslimatı".
- **Şoför (teslimat):** ONAY BEKLEYEN teslimatı (rota durağı veya plan dışı)
  "✎ Düzenle" ile düzeltir: litre, not, fotoğraflar (yalnız yeni çekilen değişir,
  diğeri kalır). Plan dışı notunun `[Plan dışı]` öneki korunur. Güncelleme
  `.eq('status','onay')` ile yapılır — arada planlayıcı onayladıysa reddedilir
  ("az önce onaylandı"). Onaylanmış teslimatta düzenleme yok ("planlayıcıya söyle").
- **Sipariş giren (siparis):** açık (Bekliyor/Planlandı) siparişte "✎ Düzenle":
  müşteri, miktar, not. Güncelleme `.in('status',['wait','plan'])` ile yapılır;
  arada yola çıktı/teslim olduysa reddedilir. Planlandı'da miktar değişirse rota
  planlayıcıda yeniden hesaplanınca güncellenir (uyarı satırı gösterilir). Yolda /
  teslim edilenlerde düzenleme yok.
- **Planlayıcı (index):** her sipariş kartında (iptal hariç) "✎ Düzenle": müşteri,
  sipariş miktarı, sipariş notu; teslim edilmiş/onay bekleyen ise ek olarak teslim
  edilen litre, teslim tarihi/saati, araç, şoför notu. Eski "Teslimi düzelt/Düzelt"
  düğmeleri bunun içine alındı. Not: onaylanmış (done) bir teslim düzenlenince
  `log_teslimat` tetikleyicisi kalıcı geçmişe düzeltilmiş halini YENİ satır olarak
  ekler (bilinçli, önceki davranışla aynı: düzeltmeler iz bırakır).
Tarayıcıda üç ekran da taklit kayıtlarla doğrulandı (alanlar, kısmi foto
değişimi, prefix, yarış durumu, düğme görünürlükleri).

## STOK DEFTERİ: GİREN / ÇIKAN / KALAN (2026-09-24)

Kullanıcı: "excelde giren çıkan kalan sütunları olmalı, stoğu takip etmeliyim,
gelen stoğu da girebilmeliyim". Merkezi stok defteri kuruldu:
- **Giren:** yeni `stok_girisleri` tablosu (`supabase-v19-stok.sql` — KULLANICI
  ÇALIŞTIRMALI, henüz çalıştırılmadı). Planlayıcıda yeni **Stok** sekmesi: gelen
  stok formu (litre, tarih/saat, kaynak/tedarikçi, belge no, not; ilk giriş
  "Açılış stoğu" olarak girilmeli) + silme (onaylı).
- **Çıkan:** ayrıca girilmez — ONAYLANMIŞ teslimatlar (`teslimat_kayitlari`)
  otomatik çıkış sayılır. Aynı siparişin düzeltme satırları çift sayılmaz
  (sipariş başına en son kayıt geçerli); silinen siparişin teslimatı "(sipariş
  silindi)" notuyla yine düşülür (yakıt fiilen çıktı). Onay bekleyenler stoktan
  düşülmez; sekmede "N teslimat onay bekliyor" bilgisi gösterilir.
- **Kalan** = Σ giren − Σ çıkan (kronolojik yürüyen bakiye). Negatifse kırmızı.
- **Excel:** yeni "Stok Hareketleri" sayfası (Tarih, Hareket, Müşteri/Kaynak, Araç,
  Belge no, Not, Giren, Çıkan, Kalan + TOPLAM satırı) ve "Günlük Stok" (Açılış,
  Giren, Çıkan, Kapanış) — eskiden yeniye sıralı. Mevcut araç bazlı "Stok Özeti
  (bugün)" korundu. Tablo yoksa Excel yine çıkar, giren boş kalır ve sayfada uyarı yazar.
- Kapsam notu: ürün ayrımı (motorin/benzin) ve tanker gözlerindeki anlık yakıt
  (Filo "mevcut L") bu defterden BAĞIMSIZ; tek bir merkezi stok tutulur. Tarayıcıda
  taklit veriyle hesap (düzeltme çift sayımı, silindi, negatif kalan) doğrulandı.

## KART DÜZENLEME + BESLEYİCİ TAM DOLUM + İRSALİYELİ STOK GİRİŞİ (2026-09-24)

1. **Planlayıcı kartında satır içi düzenleme kalktı:** sipariş kartındaki miktar
   kutusu (`setQty`) "Düzenle'ye basmasan da düzenleyebiliyorsun" diye karıştırıcıydı;
   kaldırıldı (`setQty` silindi). Bilgi düzenleme YALNIZ "✎ Düzenle" diyaloğundan.
   Kartta kalan tek kontrol araç atama listesi (⚙/🔒 — planlama aksiyonu, bilgi değil).
2. **Besleyici (TIR) tesise gidince HER ZAMAN tam doldurur:** motor (`schedule`)
   — saf besleyici rotasında plant leg hacmi artık dağıtılan değil tam boş kapasite
   (kalan yakıtlı gözler hariç); fazlası "araçta kalan" (`leftover`, mevcut "Günü
   kapat" akışıyla ertesi güne aktarılır). TIR kendi dağıtımına gidiyorsa da tüm
   boş gözleri doldurur (diğer araçlar eskisi gibi yalnız kullandığı gözleri).
   Kart: "besleyici · X L dağıtım · tam dolum · araçta kalan: Y L". Yerelde doğrulandı
   (33.750 L kapasiteli TIR her iki senaryoda 33.750 L yükledi).
3. **Stok girişi irsaliye bilgisiyle:** Stok sekmesi girişine bayi adı (irsaliyede
   yazan), satış türü (İç/Dış satış, ZORUNLU), irsaliye no, irsaliye fotoğrafı (küçültülüp
   `belgeler` deposuna; yoksa onay sorulur) eklendi. Excel "Stok Hareketleri"nde yeni
   sütunlar: Bayi, Satış türü, İrsaliye no, İrsaliye fotoğrafı (tıklanabilir link).
   Çıkışlar hâlâ teslim edilen (onaylı) siparişlerden otomatik. `supabase-v19-stok.sql`
   yeni kolonlarla güncellendi (tablo henüz kurulmamıştı → tek seferde çalışır).

## TASARIM: "ŞOFÖR GÖREV FORMU" DİLİ 3 EKRANA UYGULANDI (2026-09-24)

Kullanıcı: rastgele sipariş oluştur, Plan → Şoför görev formunu aç, dizaynını adım
adım incele, aynısını 3 ekrana uygula. İnceleme sonucu (görev formunun tasarım dili):
- **Kabuk:** koyu üst çubuk (#1b1917, büyük harf/aralıklı başlık, çerçeveli hayalet
  butonlar); altında koyu-sıcak sekme şeridi (#2a2621; aktif sekme = koyu zemin +
  beyaz yazı + 3px renkli alt çizgi).
- **Başlık bloğu:** beyaz; büyük mono plaka, mono gri alt satır, 1px çizgili KPI ızgarası
  (büyük mono rakam + küçük büyük-harf etiket); altında **2px koyu ayraç**.
- **Satırlar:** tam genişlik beyaz, 1px ince çizgiyle ayrılmış (kart/gölge/yuvarlaklık YOK),
  `36px ikon | içerik` ızgarası. İkon: durak = siyah numaralı DAİRE (bitti = yeşil ✓);
  garaj = altın, tesis = yeşil, aktarım = mor KARE (4px).
- **İçerik:** sol başlık 16px/600 + sağda mono 15px/600 saat; mono 12px gri bilgi satırı;
  siyah litre etiketi (kısmi = amber); sarı zeminli sol çizgili not kutusu.
- **Aksiyonlar:** düz dolgulu 4px butonlar — mavi = yol tarifi/gezinme, yeşil = onay/teslim,
  gri = detay, kırmızı çerçeve = tehlikeli; hiçbir gölge/yükselme yok.
Uygulama: **teslimat** (şoför) ekranı görev formunun birebir aynısı (başlık bloğu + adım
satırları, "✓ Teslim gir" yeşil, "▸ Yol tarifi" mavi, koyu başlıklı modal); **siparis**
ekranı (form bloğu + koyu bölüm şeritleri + durum renkli ikon daireli sipariş satırları);
**index** (planlayıcı) — koyu sekme şeridi, tam genişlik sipariş/tanker satırları, plan
listesi (araç blokları arası 2px ayraç, siyah numaralı daireler, renkli kare ikonlar),
banner'lar kare/tam genişlik, koyu başlıklı diyaloglar, yeşil birincil buton. Önceki turun
büyük köşe yuvarlaklıkları ve gölgeleri (`--sh-*` artık `none`) kaldırıldı; kontroller 4px.
Yazı tipleri (Manrope + IBM Plex Mono) ve renk paleti aynı. Sekme sayaçları kısaltıldı
("(8 açık · 1 onay)"). Görev formunun kendi ölçüleri (önceki turda bozulan 4px köşeler)
orijinaline döndürüldü. Tarayıcıda 375px mobil + masaüstünde 3 ekran ve diyaloglar
doğrulandı; tüm sipariş durumlarının kartları/düğmeleri regresyon kontrolünden geçti.

## PLANLAYICI SADELEŞTİRME (2026-09-24)

Kullanıcı: "planlayıcının ekranı çok karışık oldu". Sorun: her sipariş kartında 5 satır
metin + araç listesi + 5-6 düğme, 7 büyük harfli sekme, Plan sekmesinde 4-5 dolu banner.
Yapılanlar (yalnız planlayıcı, `index.html`):
- **Sipariş kartı:** 3 satır (ad+saat / litre+durum rozeti / araç·göz + varsa not).
  Durum başına TEK birincil düğme (Bekliyor→Düzenle, Planlandı/Yolda→✓ Teslim işle,
  Onay bekliyor→✓ Onayla + Reddet, Teslim→Düzenle, İptal→Geri aç) + "⋯" menüsü
  (`<details>`; Araç ata, Yola çıktı, Plandan çıkar, Yarına bırak, İptal, Geri al/aç, Sil).
  "girildi" tarih satırı ve tekrarlayan not kutuları kalktı (saat sağda zaten var).
- **Sekmeler:** büyük harf/aralık kaldırıldı, 12px; "Teslimat girişi"→"Teslimat"; Siparişler
  sayacı "(8 · ⏳1)".
- **Plan sekmesi:** uyarı/bilgi bannerları tek katlanır "Uyarılar ve notlar (N)" kutusunda
  (kapalı; uyarı varsa başlık kırmızı); yeşil özet + iki düğme görünür kalır. Araç başlığı:
  plaka + opt/📋 üst satır, istatistik alt satır.
- Tüm durum geçişleri (ertele/bugüne al, yola çıktı, geri al, plandan çıkar, onayla, geri aç,
  iptal, düzenle, sil, araç ata) tarayıcıda tek tek tıklanarak doğrulandı.

## TARİHLİ SİPARİŞ + AJANDA + GÜN TAKİBİ (2026-09-24)

Kullanıcı: "yola çıktı işaretlemenin anlamı yok, yarına bırak da gereksiz; elimizde takvim
yok — siparişi tarihli yapalım, bir ajanda olsun ama atamayı o gün gelince yapalım; sistem
günü takip etsin, ekran ona göre açılsın, önceki güne de gidebileyim".
- **Kaldırıldı:** "Yolda" durumu (`road` → eski kayıtlar `plan`'a çevrilir) ve "Yarına bırak"
  (`held` kullanılmıyor; eski held siparişler ajandada YARIN'a taşınır).
- **Sipariş günü (`plan_date`):** her siparişin bir teslim günü var (yeni sipariş formunda,
  planlayıcı düzenleme ve sipariş-giren ekranında tarih alanı; varsayılan bugün). **SQL:
  `supabase-v20-ajanda.sql` (KULLANICI ÇALIŞTIRMALI, henüz çalıştırılmadı; tekrar çalıştırılabilir).**
  Çalışmadan da uygulama çökmez: `plan_date` yazımı reddedilirse tarihsiz yedek yazım + bir kez
  uyarı; tarih o cihazda kalır.
- **Ajanda:** gelecek tarihli (planDay > bugün) açık siparişler rotaya GİRMEZ (`activeOrders`),
  "📅 Ajanda" filtresinde gün başlıklarıyla listelenir; günü gelince otomatik bugünün listesine
  düşer, "Rotayı hesapla" o gün atamayı yapar. Planlı siparişin tarihi ileri alınırsa ataması
  silinir (bekleyene döner).
- **Gün takibi:** ekran bugünün tarihiyle açılır; gece yarısı/telefon uyanışında (`checkNewDay`,
  60 sn + `visibilitychange`) yeni güne geçer; önceki günlerden kalan "planlandı" siparişler
  (eski rota geçersiz) bekleyene döner (`rolloverPlans`); bugünün listesinde geciken açık
  siparişler "GECİKMİŞ · gün" rozetiyle görünür; onay bekleyenler her gün görünür.
- **Gün çubuğu (Siparişler sekmesi):** ‹ Bugün/Dün/Yarın/Geçmiş/Ajanda + tarih › + takvim +
  "Bugün" düğmesi; geçmiş gün = o gün teslim edilen/planlanan siparişler; rota yalnız bugün için
  hesaplanır. Şoför ekranı dünün yayınlanmış rotasını (`routes.ts` bugün değil) göstermez.
- Excel "Siparişler" sayfasına "Plan günü" sütunu eklendi. Tarayıcıda: gün devri, ajanda
  gruplama, gün gezinmesi, rota (ajanda hariç), ileri tarihli ekleme+yedek yazım, tarih taşıma test edildi.

## YENİ SİPARİŞTE VARSAYILAN GÜN = YARIN (2026-09-24)

Kullanıcı: "ekranda sipariş girerken her zaman bir sonraki gün default seçili gelsin".
Planlayıcı yeni sipariş formu ve sipariş-giren ekranında teslim günü her zaman YARIN
(`nextDay()` / `addDays1()`) gelir; gün çubuğunda başka güne gidilse de, sipariş
eklendikten sonra da, gece yarısı devrinde de yarına döner. Her eklemede çıkan
"ajandaya eklendi" uyarısı (alert) ve filtreyi ajandaya zorlama kaldırıldı — yerine
form altında 3,5 sn'lik yeşil bilgi satırı ("✓ Ajandaya eklendi: 25 Eylül Cuma").
SQL durumu (canlı sorguyla doğrulandı): `tankers.is_tir` VAR, `stok_girisleri` (bayi
kolonuyla) VAR; tek bekleyen: `supabase-v20-ajanda.sql`.

## MOBİL HİZALAMA DENETİMİ + TESLİMAT SEKMESİ LİSTESİ (2026-09-24)

- **Tarih kutucuğu:** iOS Safari `type=date/datetime-local` alanlarını farklı yükseklikte/ortalı
  çizer. `appearance:none`, `text-align:left`, `::-webkit-date-and-time-value` sıfırlama ve
  alan yükseklikleri eşitlendi (planlayıcı formu 40px, sipariş ekranı 48px — önceden 46/48).
- **Denetim (375px):** her sekme/ekran/diyalog için yatay taşma + yan yana alan yükseklik
  taramasıyla kontrol edildi. Bulunan GERÇEK hata: şoför ekranı "Plan dışı teslimat" penceresinde
  müşteri listesi (`#aCust`) satır içi `width:100%` yüzünden 18px sağa taşıyordu — kaldırıldı.
  Diğer bulgular kapalı `<details>` içindeki elemanların yanlış alarmıydı. Araç seçim etiketi
  "— belirtilmedi —" → "—" (kesiliyordu).
- **Planlayıcı "Teslimat" sekmesi:** üstte giriş formu, altında TÜM teslimatlar yeni→eski,
  gün başlıklı (Bugün/Dün/tarih + gün toplamı). Litre = TESLİM EDİLEN miktar. Kaynak: onay
  bekleyenler + sipariş listesindeki teslimler + kalıcı kayıt (`teslimat_kayitlari`, sipariş
  başına en son kayıt; silinen siparişler "SİPARİŞ SİLİNDİ" rozetiyle). Fotoğraflar küçük önizleme
  (kalıcı kayıtta thumb adresi `-thumb` kuralıyla türetilir, yoksa tam foto). 40'ar 40'ar
  "Daha eski teslimatları göster"; onay/kayıt sonrası liste otomatik tazelenir.
- **Sipariş ekranı güncelliği:** teslim/onay gelince "Son teslim edilenler"de teslim edilen litre +
  fotoğraflar + "sipariş X L" görünür; yenileme 45→20 sn, sekmeye dönünce anında (ayrıca realtime).
  Planlayıcı yedek yenileme 45→30 sn + sekmeye dönünce.

## ÇİFT DOKUNMA YAKINLAŞMASI KAPATILDI (2026-09-24)

Kullanıcı: "ekrana çift tıklayınca yakınlaşıyor". Üç ekranda da `touch-action:manipulation`
(çift dokunma zoom'unu kapatır, kaydırma ve dokunma hareketleri etkilenmez) + viewport'a
`user-scalable=no` eklendi. Leaflet haritası kendi `touch-action:none`ını koruyor (harita
sıkıştırma/kaydırma çalışmaya devam eder). Not: iOS'ta erişilebilirlik gereği iki parmakla
sıkıştırma yakınlaşması bazı sürümlerde tamamen kapatılamayabilir; çift dokunma kapalıdır.

## PLANLAYICIDA TESLİM FOTOĞRAFI (2026-09-24)

Kullanıcı: "planlayıcı teslim işlerken foto koyamıyor". Planlayıcıda 3 yerde dolum tankı +
irsaliye fotoğrafı eklendi/değiştirilebilir: (1) "✓ Teslim işle" penceresi, (2) ✎ Düzenle
(teslim edilmiş/onay bekleyen siparişte; mevcut foto "(mevcut)" görünür, yalnız yeni seçilen
değişir), (3) Teslimat sekmesi girişi. Fotoğraflar tarayıcıda küçültülüp `belgeler` deposuna
(`teslimat/planlayici-…` + `-thumb`) yüklenir; `orders.photos` [{type,url,thumb}] olarak yazılır
(`log_teslimat` tetikleyicisi kalıcı kayda/Excel linklerine de işler). Not: planlayıcı normalde
`photos` alanını YAZMAZ — yalnız planlayıcıda fotoğraf değiştiğinde (`_pd` bayrağı) yazılır; böylece
şoförün yüklediği fotoğraflar planlayıcının eski verisiyle ezilmez. Yükleme başarısızsa uyarı verir,
kayıt yapılmaz.

## YOL TARİFİ KUTUSU, ÜST ÜSTE BİNEN DÜĞMELER, FOTOĞRAF BOYUTU (2026-09-24)

- **Şoför teslim penceresi:** alttaki "🧭 Yol Tarifi" kutusu (ve teslim edilmiş salt-okunur pencerenin
  "Yol Tarifi" düğmesi) kaldırıldı — rota satırında zaten "▸ Yol tarifi" var.
- **Planlayıcı "✓ Onayla" düğmeleri üst üste biniyordu — kök neden:** tasarım turunda `.ok` BANNER
  sınıfına `margin:0 -16px` (tam genişlik) verilmişti; aynı sınıf adını taşıyan `<button class="ok">`
  ("✓ Onayla", "✓ Teslim işle") da negatif kenar boşluğu alıp yanındakinin üstüne biniyordu.
  Banner kuralları `div.ok/div.warn/div.info` olarak daraltıldı; kart düğmelerinde çakışma taraması 0.
  Ders: genel sınıf adlarıyla (`.ok`, `.warn`, `.info`) hem banner hem düğme stillenmesin.
- **Fotoğraf boyutu:** tam boyut 1600px/q0.75 → **1280px/q0.65**, küçük önizleme 220px/q0.55 (aynı);
  sıkıştırma çıktısı orijinalden büyükse orijinal korunur. Ölçüm: 4000×3000 / ~4 MB fotoğraf →
  ~90 KB tam + ~8 KB önizleme (≈40× küçük). Şoför, planlayıcı ve stok irsaliyesi aynı yolu kullanır;
  listelerde yalnız önizleme (lazy) indirilir, tam foto tıklanınca açılır.

## "EKRANI TEMİZLE" KALDIRILDI (2026-09-24)

Kullanıcı: ajanda/gün gezinmesi geldiği için "Ekranı temizle" gereksiz ve işlevi bozar. Doğru:
düğme teslim+iptal siparişleri `orders` tablosundan KALICI siler; artık gün gezinmesiyle geçmiş
günlerin siparişleri (ve iptaller, ajanda) bu tablodan okunuyor — silinince geçmiş gün boşalırdı.
Düğme ve `clearDone()` kaldırıldı. Ekran zaten günlük görünümle sade kalıyor (bugün + geciken +
onay bekleyen); tek tek silme kartlardaki "⋯ → Sil"de duruyor. Kalıcı teslimat/iptal kayıtları
(Excel geçmişi) bundan bağımsızdı, etkilenmez.

## LİTRE ALANLARINDA SAYISAL KLAVYE (2026-09-25)

Kullanıcı: "litre girilen yerlerde numerik klavye çıksın sadece". Tüm litre alanlarına
`inputmode="numeric" pattern="[0-9]*"` eklendi (telefonda yalnız rakam tuş takımı açılır; litre
tam sayıdır): planlayıcı — yeni sipariş, Teslimat girişi, stok girişi, düzenle (sipariş + teslim
edilen), teslim işle, Filo "mevcut L" ve Ayarlar "hacim"; sipariş ekranı — miktar (düzenleme
zaten vardı); şoför ekranı — üç teslim formunun litre alanı (zaten vardı). Ondalık gereken
alanlara (dakika/saat ayarları) dokunulmadı.

## YAKINLAŞTIRMA TAMAMEN KAPATILDI (2026-09-25)

Kullanıcı: "yakınlaştırma olmasın" (önceki çift dokunma önlemi yetmedi). Üç kaynak kapatıldı:
1. **Odaklanınca otomatik zoom:** iOS 16px'ten küçük alana odaklanınca sayfayı yakınlaştırır.
   375px taramasıyla (tüm sekmeler + diyaloglar) bulundu: sipariş ekranı form alanları 15px
   (16'ya çekildi) ve planlayıcı gün çubuğu tarih seçicisi 11px (mobilde 16px). Şoför ekranı zaten temizdi.
2. **İki parmakla sıkıştırma:** iOS `user-scalable=no`'yu yok sayar → üç ekranda `gesturestart/
   gesturechange/gestureend` `preventDefault` (harita kendi dokunma yönetimini kullandığı için etkilenmez).
3. Çift dokunma (`touch-action:manipulation`) önceki turdan duruyor.

## DENEME VERİSİ TEMİZLİĞİ + EXCEL SAYFA ADLARI (2026-09-25)

Kullanıcı: "eski denemeleri vs ekrandan ve sqlden sil, şifreye gerek yok, exceli güncelle".
- **Şifre:** gerekmiyor (karar kullanıcıda; anon anahtar/açık RLS ödünleşimi olduğu gibi kalıyor).
- **Temizlik:** canlı veri incelendi — 9 sipariş (hepsi 5.000 L test), 4 teslimat kaydı, 1 iptal kaydı,
  deneme rotası, "Fhhhbh" test müşterisi, storage'da deneme fotoğrafları. Claude Code'un otomatik
  izin sistemi anon anahtarla toplu DELETE'i ("Cloud Storage Mass Delete") ENGELLEDİ; atlatılmadı.
  Bunun yerine `supabase-temizlik-deneme-verisi.sql` hazırlandı — kullanıcı SQL Editor'de çalıştırır
  (orders/teslimat_kayitlari/iptal_kayitlari/dolum_fisleri silinir, rota boşaltılır, Fhhhbh silinir).
  KORUNAN: tankerler, "Salih Pala" müşterisi, stok girişi (30.000 L Sunpet — silme isteğe bağlı satır
  dosyada yorumlu). Fotoğraflar SQL ile silinemez → Supabase panelinden Storage → belgeler → klasör sil.
- **Excel:** "Siparişler (bugün)" → "Siparişler", "Stok Özeti (bugün)" → "Araç Özeti" (artık bugünle
  sınırlı değildi); araç özeti başlıkları "Planlanan/Bekleyen" ("Yolda" kalktı); sayfa sırası:
  Stok Hareketleri, Günlük Stok, Teslimat Geçmişi, İptal Geçmişi, Siparişler, Araç Özeti, Müşteri Rehberi.

## EXCEL: TESLİMATLAR ODAKLI + MANTIKLI SÜTUN SIRASI, MÜŞTERİ DÜZENLEME (2026-09-25)

- **Excel artık sipariş değil TESLİMAT tutar:** "Siparişler" sayfası kaldırıldı; **"Teslimatlar"** sayfası
  (kalıcı kayıt + onay bekleyenler + listede duran teslimler; sipariş başına TEK satır, düzeltmede en son
  kayıt; açık sipariş/ajanda Excel'e girmez; altta TOPLAM). Sayfalar: Stok Hareketleri, Günlük Stok,
  Teslimatlar, İptal Geçmişi, Araç Özeti, Müşteri Rehberi. "Araç Özeti" artık teslimatlardan (araç bazında
  adet + teslim edilen L + onay bekleyen).
- **Sütun sırası (okuma sırasına göre):** Teslimatlar: Teslim tarihi, Müşteri, Araç, Göz, Sipariş (L),
  Teslim edilen (L), Fark (L), Şoför notu, Sipariş notu, Dolum tankı, İrsaliye, Durum, Sipariş girişi,
  Kayıt zamanı, Kayıt no (teknik alanlar sonda). Stok Hareketleri: Tarih, Hareket, Müşteri/Kaynak, Giren,
  Çıkan, Kalan, sonra Bayi/Satış türü/Araç/İrsaliye no/Not/foto. İptal: İptal tarihi ilk. Müşteri Rehberi:
  + "Haritada aç" linki. Başlık satırı koyu, sütun genişlikleri içeriğe göre. Silinen siparişin teslimatı
  kırmızı + "SİPARİŞ SİLİNDİ". Gerçek .xlsx yazıp geri okuyarak doğrulandı (düzeltme çift sayımı yok).
- Hata düzeltildi: kırmızı stilli satırlarda hücre tipi (`t`) eksikti (bellek içi okumada boş görünüyordu);
  stok defterinde "sipariş başına en son kayıt" artık `logged_at` karşılaştırmasıyla (sıraya bağımlı değil).
- **Müşteri düzenleme (Müşteriler sekmesi, satırda ✎):** ad + konum (enlem, boylam); konum için
  "📍 Şu anki konumum" veya "🗺️ Haritadan seç" (pencere gizlenir, haritada tıklanan yer alınır,
  pencere geri açılır). Kaydedince rehber, siparişler ve harita güncellenir; konum değiştiyse rotayı yeniden
  hesaplama uyarısı. Geçmiş teslimat kayıtlarında eski ad aynen kalır (kayıt anındaki isim). `cloudCustUpsert`
  hata kontrolü eklendi. Kapsam: müşteride yalnız ad+konum var; telefon/adres gibi ek alanlar istenirse yeni
  kolon (SQL) gerekir.

## TESLİMAT FİYATI — YALNIZ PLANLAYICI (2026-09-25)

Kullanıcı: "fiyatı da yazacağımız bir alan olmalı, teslimatçı göremez, onay kısmında planlayıcı yazsın".
- **Alan:** `orders.unit_price` (birim fiyat ₺/L) + kalıcı kayda `unit_price` ve `tutar` (= teslim edilen L × fiyat,
  2 hane). **SQL: `supabase-v21-fiyat.sql` — KULLANICI ÇALIŞTIRMALI** (kolonlar + `log_teslimat` tetikleyicisi
  fiyat/tutarı kalıcı kayda işler; tekrar çalıştırılabilir). Çalışmadan da uygulama çökmez: fiyat yazımı reddedilirse
  fiyatsız yedek yazım + bir kez uyarı (fiyat o cihazda kalır); Teslimat sekmesi fiyat kolonları yoksa onsuz okur.
- **Girdi noktaları (yalnız planlayıcı):** ✓ Onayla artık **"Teslimatı onayla" penceresi** açar (teslim edilen L,
  birim fiyat, canlı tutar; fiyatsız onayda "yine de?" sorusu); ayrıca "Teslim işle", ✎ Düzenle (teslim edilmiş/onay
  bekleyen) ve Teslimat girişi formunda fiyat alanı. Ondalık virgül/nokta kabul edilir (`inputmode=decimal`).
- **Gösterim (yalnız planlayıcı):** kartta "₺ 42,50/L · 208.250,00 ₺"; Teslimat sekmesinde satır + gün başlığında gün
  toplamı; Excel "Teslimatlar": Fark'tan sonra "Birim fiyat (₺/L)" ve "Tutar (₺)" sütunları + TOPLAM tutar.
- **Şoför/sipariş ekranları:** fiyatı hiç göstermez VE `orders` sorgularında `select('*')` yerine açık kolon listesi
  kullanır (fiyat isteğe bile dahil edilmez). Dürüst not: anon anahtar + açık RLS nedeniyle teknik bilgisi olan biri
  yine de doğrudan veritabanından okuyabilir; bu "arayüzde ve istekte gizli" düzeyindedir, sıkı erişim kontrolü değildir.

## SONRAKİ AŞAMALAR (yol haritası)

- ~~**Aşama 5: Şoför ekranı**~~ → **YAPILDI** (bkz. aşağıdaki not, 2026-09-22).
- Aşama 6: Canlı tanker takibi (GPS) — sofor.html artık her teslimde GPS
  yakalıyor (gps_lat/gps_lng), ama canlı harita üzerinde GÖSTERİM henüz yok.
- Aşama 7: iOS/Android (opsiyonel, en sonda). WhatsApp reddedildi.
- Güvenlik: admin şifresi + şoför PIN'leri değiştirilecek. RLS daraltılabilir.

## ŞOFÖR EKRANI + STOK/EXCEL NOTU (2026-09-22)

git deposu kuruldu (`git init`, ilk commit "v17 devralma"). "857 doluma gitti"
açık sorununa hâlâ elde gerçek sipariş verisi yok — motor kodu satır satır
incelendi, iki muhtemel senaryo (TIR meşgulken büyük iş var; 857'nin gözünde
kalan yakıt var) node ile test edildi, İKİSİNDE DE motor kurallara uygun
davrandı (857 hatalı doluma gitmedi). Gerçek veri/ekran görüntüsü gelmeden
bu konu kapatılamaz — DEVAM.md'nin istediği gibi kullanıcıdan bekleniyor.

Kullanıcı isteğiyle üç yeni parça eklendi, **hiçbiri Supabase şema değişikliği
gerektirmedi** (orders.photos/delivered_qty/gps_lat/gps_lng zaten vardı):

1. **`sofor.html`** (yeni, ayrı dosya) — plaka+PIN girişli mobil şoför ekranı.
   `routes` tablosundaki kendi plakasına ait `legs`'i okuyup durak listesi
   gösteriyor. Her durakta: boşaltılan litre girişi + **iki zorunlu fotoğraf**
   (dolum tankı + irsaliye, `capture="environment"` ile doğrudan kamera açar) +
   opsiyonel not. "Teslimi Kaydet" fotoğraflar `belgeler` bucket'ına yüklenip
   (path: `teslimat/{plaka}/{oid}-{ts}-tank|irsaliye.ext`), GPS best-effort
   (4 sn timeout, reddedilirse/başarısız olursa engellemez) alınıp `orders`
   satırı `status:'done', delivered_qty, photos:[{type,url}], gps_lat/lng,
   delivered_at` ile güncellenince tamamlanıyor. Ağ hatasında girilen veri
   KAYBOLMUYOR (form açık kalıyor, tekrar denenebiliyor). `routes` tablosuna
   realtime abone — planlamacı rotayı yeniden yayınlarsa şoförün ekranı
   otomatik tazeleniyor. Zaten var olan `sheetPage`/"Teslim işle" akışıyla
   AYNI kolonlara yazıyor (`delivered_qty`/`deliver_note`/`status`) — iki
   ekran birbirini bozmuyor, planlamacı hâlâ manuel de işleyebilir.

   **Test:** Gerçek Supabase'e bu ortamdan (container) çıkılamadığı için
   (bilinen ağ kısıtı, bkz. yukarı) uçtan uca gerçek veriyle DENENEMEDİ.
   Yerel `python3 -m http.server` ile JS syntax + login hata yönetimi +
   (sahte veriyle enjekte edilen) durak listesi/teslim formu/tamamlanmış
   durak görünümü tarayıcıda görsel olarak doğrulandı (mobil 375px genişlik).
   **Kullanıcının gerçek telefonunda gerçek PIN ile giriş + bir teslimat
   ucundan uca test edilmesi gerekiyor** — özellikle kamera izni ve GPS izni
   ilk açılışta tarayıcı tarafından isteniyor, bu adım simüle edilemedi.

2. **Excel'e aktar** (`tanker-rota-planlayici-v17.html`, mevcut "CSV indir"
   butonunun yerine): SheetJS (`xlsx@0.18.5`, CDN) eklendi, yeni
   `exportExcel()` fonksiyonu iki sayfalı bir `.xlsx` üretiyor:
   - **Stok Özeti**: araç bazında durak (tamam/toplam), yüklenmesi planlanan L,
     teslim edilen L (gerçek `delivered_qty` toplamı), bekleyen/yolda L.
   - **Siparişler**: eski CSV'nin birebir aynısı (satır bazında tüm alanlar).
   Bilinçli tasarım kararı: ayrı bir "stok hareket" tablosu AÇILMADI — giriş/
   çıkış rakamları `orderList`'ten (zaten senkron) CANLI TÜRETİLİYOR, statik
   bir log tutulmuyor. Bu, replan sonrası yinelenen kayıt riskini baştan
   önlüyor ama "geçmiş bir günün stok özeti"ni kalıcı olarak saklamıyor —
   ihtiyaç olursa (ör. ay sonu raporu) ayrı bir iş.

   **Test:** CDN + Supabase bu sandboxtan erişilemediği için buton TIKLANARAK
   gerçek bir .xlsx indirilemedi; yalnız buton varlığı ve fonksiyonun
   sözdizimsel doğruluğu (`node --check`) doğrulandı. **Kullanıcının kendi
   tarayıcısında bir kez denenmesi gerekiyor.**

**AÇIK KALAN / BİLİNÇLİ KAPSAM DIŞI:**
- Offline kuyruk yok — şoför sinyalsiz bölgede teslim kaydedemez, sinyal
  gelince tekrar denemesi gerekir (form verisi kaybolmaz ama otomatik
  yeniden deneme de yok).
- Garaj aktarımları (TIR→diğer tanker) şoför ekranından ONAYLANMIYOR, bu
  hareketler yalnızca planlamacının yayınladığı plan üzerinden GÖSTERİLİYOR
  (bilgi amaçlı okuma), stok özetine "yüklenen" olarak girmiyor — yalnız
  `orders`/`delivered_qty` üzerinden çıkış tarafı hesaplanıyor.
- Fiziksel dosyalar (`sofor.html`, planlayıcı) `file://` ile açılırsa kamera/
  GPS bazı mobil tarayıcılarda kısıtlı çalışabilir — gerçek kullanımda
  ikisinin de bir https adresinden (basit bir statik hosting, ör. GitHub
  Pages/Netlify) açılması ÖNERİLİR. Bu proje henüz hiçbir yere deploy
  edilmedi, hâlâ yerel dosya.

## KULLANICI ÜSLUBU

Türkçe, kısa, doğrudan. Fazla soru ve açıklama sevmez. Sinirlenince küfür eder,
kişisel değil — sadece hızlı ve çalışan sonuç istiyor. Mockup değil GERÇEK çalışan
araç ister. Netleşen kuralları TEK SEFERDE uygula, tekrar tekrar sorma. Adım adım
ilerlemeyi sever ama aynı şeyi iki kez sorarsan sinirlenir.
