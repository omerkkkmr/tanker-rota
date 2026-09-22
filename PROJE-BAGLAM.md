# Tanker Rota Planlama Sistemi — Proje Bağlamı

> Bu dosya, projenin tüm iş kurallarını, verilmiş kararları ve teknik yapısını içerir.
> Yeni bir sohbete başlarken veya başka biriyle çalışırken **önce bu dosyayı paylaş**.
> Son güncelleme: 14 Temmuz 2026 · Güncel sürüm: v8

---

## 1. İŞ TANIMI

Akaryakıt bayii. Dolum tesisinden yakıt alınıp müşteri adreslerine tankerlerle dağıtılıyor.
Bölge: Sakarya ve çevresi.

**Günlük akış:** Siparişler farklı lokasyonlardan, farklı miktarlarda gelir. Tankerler garajdan
çıkar, dolum tesisinden yakıt alır, müşterilere dağıtır, garaja döner. Gün içinde birden fazla
sefer yapabilirler.

---

## 2. İŞ KURALLARI (kesinleşmiş)

### Konumlar
- **Tek garaj** — tüm tankerler burada başlar ve biter
- **Tek dolum tesisi**
- Müşteriler koordinatla tanımlı (rehberde kayıtlı)

### Tankerler
- Her tankerin **birden fazla gözü (tankı)** var, her göz farklı hacimde
- Bir sipariş **tek gözden** karşılanır (gözler arası birleştirme yok)
- **Dolum lisansı:** bazı tankerler tesise giremez. Lisanssız tanker yalnızca
  garajda aktarımla yüklenir, tesise hiç uğramaz.
- Vardiya süresi tanker bazında (varsayılan 10 saat)

### Kalan yakıt kuralı (önemli)
- Tanker vardiya başında gözünde yakıtla gelebilir
- **Dolu gözle tesise girilemez.** Önce boşaltılmalı:
  - ya bir müşteriye teslim edilerek
  - ya da garajda başka bir tankere aktarılarak
- Bu yüzden rota: garaj → (kalan yakıtla teslimatlar) → tesis → dolum → teslimatlar → garaj

### Çoklu sefer
- Tankerler gün içinde defalarca dolabilir
- **Tesise boş girilir** — yeniden dolum için tüm gözler boşalmış olmalı
- Sefer sayısı sınırı yok; **vardiya süresi** frenler
- Örnek: TIR (tek büyük göz) sürekli büyük müşteriye gider, boşaltır, tesise döner, tekrar dolar

### Kısmi teslimat
- Yarım boşaltma yapılmaz, ama **%20-25 civarı eksik** verilerek müşterinin işi görülebilir
- Sistemde ayarlanabilir: "kısmi alt sınır %75" = siparişin en az %75'i karşılanıyorsa eşleşme kabul

### Şoför kısıtı
- Şu an **4 şoför** var (ayarlanabilir)
- Şoförsüz tanker yola çıkamaz
- Sistem en uygun tankerleri seçer; öncelik: kilitli siparişi olan > kalan yakıtı olan > büyük kapasiteli

### Kapsam dışı (bilinçli olarak yok sayıldı)
- **ADR / tehlikeli madde kuralları** — yok sayılıyor
- **Ürün karışmazlığı** (motorin/benzin ayrımı) — yok sayılıyor
- **Yolda aktarım** — gerçekte oluyor ama v1'de modellenmedi (sadece garajda aktarım var).
  İleride eklenebilir; iki tankerin buluşma noktasında zaman senkronizasyonu gerektirir.

---

## 3. SÜRE MODELİ (kullanıcı tarafından verilen gerçek rakamlar)

| İşlem | Formül | Not |
|---|---|---|
| **Dolum (tesiste)** | 25 dk + kuyruk | Sabit. Hacimle **değişmez**. Kuyruk o günkü yoğunluğa göre panelden girilir (0-180 dk) |
| **Boşaltma (müşteride)** | 8 dk + 2,5 dk/1000 L | Sabit kısım + pompalama |
| **Aktarım (garajda)** | 2,5 dk/1000 L | Tesis dışı transfer, sabit yok |

Tüm alanlar panelden değiştirilebilir.

**Mesafe/süre:** OSRM genel sunucusu (`router.project-osrm.org`) — gerçek yol ağı, kuş uçuşu değil.
- `/table` → süre + mesafe matrisi (tek istek, tüm noktalar)
- `/route` → harita üzerine çizilecek gerçek geometri

---

## 4. OPTİMİZASYON MOTORU

### Geçmiş sorun ve çözümü
**v7'ye kadar:** atama (hangi sipariş hangi göze) ve rotalama (sıralama) ayrı adımlardı.
Atama sadece hacim uyumuna bakıyordu, coğrafyayı görmüyordu. Sonuç: bir tanker 197 km,
diğerleri 40 km gidiyordu — çünkü hacmen uyan siparişler birbirine 150 km uzaktı.

**v8'de çözüldü:** en ucuz ekleme (cheapest insertion). Her sipariş "hangi tankere/sefere
eklersem toplam süre en az artar" diye yerleştiriliyor. Coğrafya + kapasite birlikte değerlendiriliyor.

### Algoritma akışı
1. **Garaj aktarımı** — lisanssız tankerlerin boş gözlerine, kalan yakıtlı lisanslı tankerlerden
2. **Şoför seçimi** — puanlama: kilitli sipariş (1e9) > kalan yakıt (1e8) > toplam kapasite
3. **Sefer 0** — kalan yakıtla teslimatlar (tesise girmeden)
4. **Kilitli siparişler** — kullanıcının elle atadığı, kendi araçlarına zorlanır
5. **Serbest siparişler** — en ucuz ekleme + yük dengesi katsayısı
6. **Sıralama** — her sefer içinde nearest-neighbour + 2-opt

### Yük dengesi (balance) ayarı
`maliyet = ekleme_maliyeti + (o tankerin mevcut yükü × balance)`

- **0** → en az km, ama tek tanker tüm işi üstlenebilir (test: A=357dk, B=0dk)
- **0.25** (varsayılan) → dengeli, kümeleme korunur (test: A=106dk, B=266dk)
- **0.6** → iş eşit dağılır, km artar

Gerçek işleyişte kalibre edilecek.

### Manuel müdahale
- **Sipariş kartından:** açılır listeden tanker seç → 🔒 kilitlenir
- **Rota sonucundan:** durağa tıkla → hedef tanker listesi → seç → taşınır ve kilitlenir
- **Her tankerde ⟳ opt tuşu** — o tankerin listesini yeniden dizer
- **Kilitler yeniden hesaplamada korunur**
- Kalan yakıt durakları taşınamaz (yakıt fiziksel olarak o araçta)

---

## 5. SİPARİŞ MODELİ

```js
{
  id, cid,            // sipariş kimliği, müşteri kimliği
  qty,                // sipariş miktarı (L)
  status,             // wait | plan | road | done | canc
  note,               // sipariş notu
  createdAt, plannedAt, deliveredAt,
  deliveredQty,       // şoförün bıraktığı gerçek litre
  vehicle, comp,      // atanan araç ve göz
  lockVeh,            // elle kilitlenmiş araç (null = otomatik)
  deliverNote         // şoför notu
}
```

**Durum akışı:** BEKLİYOR → (rota hesapla) → PLANLANDI → (yola çıktı) → YOLDA → (teslim işle) → TESLİM

- Rota hesaplanınca bekleyenler otomatik "planlandı" olur, araç/göz yazılır
- Rotaya giremeyenler "bekliyor"a döner
- Teslim işlenirken bırakılan litre + saat + not girilir
- Eksik teslimat otomatik hesaplanır ve turuncu gösterilir

**Bu model Supabase'e taşınmak üzere tasarlandı** — her alan bir kolon olacak.

---

## 6. MEVCUT DURUM (v8)

**Tek dosya HTML.** Kurulum yok, çift tıkla açılır. Veri `localStorage`'da.

### Çalışan özellikler
- Garaj + tesis konumu (haritadan seçilebilir)
- Tanker kartları: plaka, gözler (hacim + mevcut yakıt), lisans anahtarı, vardiya
- Müşteri rehberi (kalıcı)
- Sipariş yönetimi: talep girişi, durum akışı, filtreler, CSV dışa aktarma
- Rota hesaplama: çoklu sefer, coğrafi kümeleme, yük dengesi
- Harita: gerçek yollara oturmuş renkli rotalar, numaralı duraklar
- Manuel müdahale: tıklayarak taşıma, kilitleme, tanker bazında yeniden optimize
- **Şoför görev formu:** plaka sekmeleri, sıralı adımlar, her durakta Google Maps navigasyon
  butonu, "✓ Teslim işle" ile litre girişi, yazdırılabilir

### Bilinen sınırlar
- **Veri tarayıcıya bağlı** — başka bilgisayarda açılırsa boş gelir
- **Şoför formu senin ekranında** — şoförün telefonunda değil
- OSRM demo sunucusu hız limitli
- ~30-40 sipariş için tasarlandı

---

## 7. YOL HARİTASI

| Aşama | İçerik | Durum |
|---|---|---|
| 1 | Rota motoru, tek dosya | ✅ v8 |
| 2 | Sipariş yönetimi + görev formu | ✅ v8 |
| 3 | **Supabase kurulumu + tablolar** | ⬅ SIRADA |
| 4 | Planlama ekranı Supabase'e bağlanır | |
| 5 | Şoför ekranı — plaka ile giriş, kendi rotası, teslim işleme | |
| 6 | Canlı tanker takibi (GPS) | |
| 7 | iOS/Android uygulaması | *en sonda* |

### Neden Supabase (karar gerekçesi)
- Postgres — veride ilişkiler var (sipariş↔müşteri↔tanker↔teslimat), NoSQL uygun değil
- Canlı senkron hazır geliyor
- Kullanıcı girişi hazır (şoför/planlamacı ayrımı)
- Ücretsiz katman fazlasıyla yeterli
- İleride uygulama yapılırsa **aynı veritabanına** bağlanır

### Reddedilen seçenekler
- **Firebase** — NoSQL, veri yapısına uygun değil
- **Kendi VPS'i** — sistem yöneticiliği yükü, gereksiz
- **Google Sheets** — ölçek büyüyünce çöker
- **Baştan iOS uygulaması** — 99$/yıl, Mac+Xcode gerekir, App Store onayı,
  Android ayrı iş, **ve veri paylaşımı sorununu çözmez** (yine sunucu lazım).
  Web sayfası telefonda "Ana Ekrana Ekle" ile uygulama gibi çalışır.

### Aşama 3 için gereken
Kullanıcının yapması gerekenler:
1. supabase.com'da ücretsiz hesap
2. Yeni proje oluştur
3. Proje URL'i + anon key paylaş (gizli değil, tarayıcıda görünmek üzere tasarlanmış)

Sonra: tablo SQL'i + iki dosya (planlama ekranı, şoför ekranı) yazılacak.

---

## 8. TEKNİK NOTLAR

- **Tek dosya HTML**, harici bağımlılık: Leaflet (CDN), OSRM (API)
- Harita: Leaflet + CARTO Voyager altlık
- Depolama: `localStorage`, anahtar `tankerRotaV4`
- Renk paleti: 8 renk döngüsü (`COLORS`), tanker sırasına göre
- Düğüm indeksleri: `0=garaj, 1=tesis, 2+=müşteriler` (`nOf(o) = o.id+2`)
- Dil: arayüz tamamen Türkçe
- Yazı tipleri: Archivo (başlık/gövde), IBM Plex Mono (sayı/veri)

### Kilit fonksiyonlar
| Fonksiyon | İş |
|---|---|
| `planFleet()` | Ana planlama — aktarım, şoför seçimi, atama |
| `tryInsert()` | Bir siparişi bir plana eklemenin en ucuz yolunu bulur (uygulamaz) |
| `commitInsert()` | Bulunan yerleşimi uygular |
| `schedule()` | Planı zaman çizelgesine (legs) çevirir |
| `moveStop()` | Manuel taşıma |
| `optVeh()` | Tek tanker yeniden optimize |
| `sheetPage()` | Şoför görev formu üretir |

---

## 9. KULLANICI TERCİHLERİ

- Türkçe konuşuyor, çoğunlukla büyük harfle yazıyor
- Kısa ve doğrudan cevap istiyor, gereksiz açıklama sevmiyor
- Gerçek çalışan araç istiyor, mockup değil
- Adım adım ilerlemeyi tercih ediyor: "bir uygulayayım sonra bakarız gerçek hayatta"
- Aşırı mühendislikten kaçınılmalı — önce kullan, gör, sonra geliştir
