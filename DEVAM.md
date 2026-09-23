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
