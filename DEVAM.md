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

**Aktif sürüm: `tanker-rota-planlayici-v17.html`** (tek dosya, ~96 KB)
Önceki çalışan yedek: `tanker-rota-planlayici-v16.html`
SQL kurulum: `supabase-kurulum.sql`, `supabase-v12-ek.sql` (is_tir kolonu)

İlk iş: bunu bir git deposuna al.
```
cd <proje-klasörü>
git init
git add tanker-rota-planlayici-v17.html supabase-kurulum.sql supabase-v12-ek.sql DEVAM.md
git commit -m "v17 devralma"
```
Bundan sonra v17 üzerinde çalış, sürüm numarası yerine git commit kullan.

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
