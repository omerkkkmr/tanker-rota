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

## SONRAKİ AŞAMALAR (yol haritası)

- **Aşama 5: Şoför ekranı** (ayrı `sofor.html`) — plaka+PIN giriş, routes tablosundan
  kendi rotası, fotoğraf yükleme (dolum/fiş/irsaliye → belgeler bucket), GPS konum
  doğrulama, teslim işleme → orders tablosuna yazar, planlamacı realtime görür.
- Aşama 6: Canlı tanker takibi (GPS).
- Aşama 7: iOS/Android (opsiyonel, en sonda). WhatsApp reddedildi.
- Güvenlik: admin şifresi + şoför PIN'leri değiştirilecek. RLS daraltılabilir.

## KULLANICI ÜSLUBU

Türkçe, kısa, doğrudan. Fazla soru ve açıklama sevmez. Sinirlenince küfür eder,
kişisel değil — sadece hızlı ve çalışan sonuç istiyor. Mockup değil GERÇEK çalışan
araç ister. Netleşen kuralları TEK SEFERDE uygula, tekrar tekrar sorma. Adım adım
ilerlemeyi sever ama aynı şeyi iki kez sorarsan sinirlenir.
