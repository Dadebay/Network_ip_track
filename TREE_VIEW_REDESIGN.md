# Cihaz Ağacı Yeniden Tasarım Görevi

Bu görev yalnızca **Cihazlar > Ağaç** görünümünü yeniden tasarlamak içindir.
Liste görünümünü, tarama motorunu, veritabanını, cihaz sınıflandırmasını ve
trafik hesaplamalarını değiştirme.

## Problem

Mevcut `DeviceGraphView`, bütün düğümleri büyük bir node-link canvas üzerinde
soldan sağa yerleştirip grafiğin tamamını ekrana sığdırıyor. 585 cihaz gibi
büyük sonuçlarda ölçek yaklaşık `%15` seviyesine düşüyor; kartlar ve metinler
okunamıyor, içerik ekranın ortasında ince bir çizgi gibi görünüyor.

Amaç, ağı **yukarıdan aşağıya okunan, tam genişliği kullanan, açılır/kapanır
dikey bir hiyerarşi** olarak göstermek. Bütün 585 cihazı tek seferde dev bir
grafiğe yerleştirme ve otomatik olarak ekrana sığdırma yaklaşımını kaldır.

## Hedef görünüm

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ ▼ 172.16.0.0/12 · Özel 172 ağı                         585 cihaz         │
├──────────────────────────────────────────────────────────────────────────┤
│   ▼ 172.16.14.0/24 · Doğrudan bağlı                    585 cihaz         │
│   │                                                                    │
│   ├─ Gateway · 172.16.14.254                         Çevrimiçi           │
│   │                                                                    │
│   ├─ ▶ Telefonlar                                      128 cihaz         │
│   ├─ ▼ Bilgisayarlar                                   214 cihaz         │
│   │    MacBook-Pro       172.16.14.26   macOS       24,3 MB             │
│   │    DESKTOP-AB12      172.16.14.41   Windows     81,6 MB             │
│   │    ubuntu-server     172.16.14.58   Linux        1,2 GB             │
│   ├─ ▶ Ağ cihazları                                     18 cihaz         │
│   ├─ ▶ IoT                                             102 cihaz         │
│   └─ ▶ Bilinmeyen                                      123 cihaz         │
└──────────────────────────────────────────────────────────────────────────┘
```

Bu bir dosya yöneticisindeki outline/tree görünümü gibi çalışmalı: kök en
üstte, alt seviyeler aşağı doğru devam etmeli, girinti ve ince bağlantı
çizgileri hiyerarşiyi göstermeli.

## Zorunlu tasarım kararları

### 1. Yerleşim

- `DeviceGraphView` içindeki sonsuz canvas, pan/zoom ve “Ekrana sığdır”
  davranışını kaldır.
- İçerik mevcut alanın tam genişliğini kullansın; ortada dar bir sütun veya
  sabit `260 px` kart genişliği olmasın.
- Tek bir dikey scroll olsun. Yatay scroll normal kullanımda oluşmasın.
- Görsel sıra değişmesin:
  `172.16.0.0/12 > alt ağ > gateway > cihaz grubu > cihaz`.
- Her seviye soldan `20–24 px` girintilensin. Girinti dışında kalan alan satır
  içeriğine verilsin.
- Dikey ve dirsek biçimli bağlantı çizgileri çok hafif olsun; metnin önüne
  geçmesin.
- Kök ve subnet satırları bölüm başlığı gibi, gateway orta vurguda, grup
  satırları accordion başlığı gibi, cihaz satırları ise kompakt liste satırı
  gibi görünmeli.

### 2. Büyük veri davranışı

- 585 cihazın tamamını aynı anda widget ağacına kurma.
- Mevcut `flattenDeviceTree(...)` yaklaşımını kullanabilir veya aynı sonucu
  üreten bir görünür-satır modeli oluşturabilirsin.
- Görünür satırları `ListView.builder`, `SliverList` veya eşdeğer lazy builder
  ile render et.
- İlk açılışta şu seviyeler açık olsun:
  - özel 172 bloğu,
  - aktif subnet,
  - gateway,
  - cihaz grupları **kapalı**.
- Kullanıcı bir grubu açtığında yalnızca o grubun cihazları render edilsin.
- Arama sonucu varsa eşleşen cihazların üst yolu otomatik görünür olmalı;
  kullanıcı filtresi nedeniyle bir sonucu gizli accordion altında bırakma.
- Yeni cihazlar tarama sırasında geldiğinde scroll konumu ve kullanıcının
  aç/kapat seçimleri korunmalı.
- Düğüm kimlikleri mevcut `DeviceTreeNode.id` değerleriyle stabil kalmalı.

### 3. Satır içerikleri

Kök satırı:

- CIDR ve “Özel 172 ağı” açıklaması
- toplam görünür cihaz sayısı
- aç/kapat ikonu

Subnet satırı:

- CIDR
- erişim türü: `Doğrudan bağlı`, `Router üzerinden`, `Erişilemiyor`
- cihaz sayısı
- erişilemiyorsa durum rengi ve kısa açıklama

Gateway satırı:

- router/gateway ikonu
- ad veya `Gateway`
- IP adresi
- durum
- tıklanınca mevcut cihaz detayını açmalı

Grup satırı:

- cihaz türü ikonu
- grup adı
- cihaz sayısı sağda badge olarak
- tüm satır aç/kapat hedefi olsun

Cihaz satırı:

- durum noktası + tür ikonu
- `displayName`
- IP
- mümkünse üretici veya tahmini OS
- trafik provider varsa bugünkü trafik; yoksa `Veri yok`
- seçili/hover/focus durumları
- tıklanınca mevcut `DeviceDetailPanel` davranışı çalışmalı

Dar genişlikte ikincil alanlar sırayla gizlenebilir: önce üretici, sonra trafik,
sonra OS. Cihaz adı ve IP her zaman görünür kalsın.

### 4. Kontroller

- Üstteki arama, filtre, sıralama ve `Ağaç / Liste` seçici aynen çalışmalı.
- Ağaç alanında küçük bir `Tüm grupları daralt` eylemi olabilir.
- `Tümünü genişlet` ile 585 cihazı birden açma. Böyle bir eylem eklenecekse
  yalnızca blok/subnet/grup başlıklarını açmalı veya çok büyük sonuçta onay
  istemeli.
- Zoom düğmeleri kaldırılmalı; metin hiçbir zaman ölçeklenerek küçültülmemeli.
- Klavye davranışı:
  - `↑/↓`: satırlar arasında gezinme
  - `←`: daraltma veya üst düğüme gitme
  - `→`: genişletme
  - `Enter/Space`: aç/kapat veya cihaz detayını açma
- Semantics üzerinde düğüm adı, seviye, cihaz sayısı ve açık/kapalı durumu
  okunabilmeli.

## Görsel stil

- Mevcut tema ve renk tokenlarını kullan; sabit açık/koyu renk yazma.
- macOS ile uyumlu, sakin ve yoğun bilgi gösterebilen bir görünüm kullan.
- Satır yüksekliği:
  - başlık düğümleri: yaklaşık `48–56 px`
  - cihaz satırları: yaklaşık `40–46 px`
- Her satırı büyük, ayrı ve gölgeli karta dönüştürme. Grup ayrımı için hafif
  yüzey tonu, divider ve girinti yeterli.
- Hover yalnızca hafif arka plan değişimi versin; kartı büyüten scale animasyonu
  kullanma.
- Aç/kapat animasyonu `150–220 ms`, ease-out olmalı; yüzlerce çocuğu tek
  animasyonda ölçmeye çalışma.
- Seçili cihaz mevcut primary rengin düşük opaklıklı arka planı ve sol accent
  çizgisiyle belirtilebilir.

## Kod kapsamı

Önce mevcut kodu incele ve mümkün olduğunca mevcut domain modelini koru:

- `lib/features/devices/application/device_tree.dart`
- `lib/features/devices/application/device_graph_layout.dart`
- `lib/features/devices/presentation/widgets/device_graph_view.dart`
- `lib/features/devices/presentation/providers/device_providers.dart`
- `lib/features/devices/presentation/screens/devices_screen.dart`
- ilgili unit/widget testleri

`DeviceGraphView` adı artık doğru değilse `DeviceTreeView` olarak yeniden
adlandırabilirsin. Kullanılmayan graph layout/painter kodunu ve testlerini
temizle; iki ayrı ağaç implementasyonu bırakma.

## Kabul kriterleri

1. 585 cihaz varken görünüm ilk açılışta okunabilir; hiçbir metin otomatik
   scale ile küçültülmez.
2. Kök en üstte, hiyerarşi aşağı doğru ilerler ve ekran genişliğini kullanır.
3. Gruplar ilk açılışta kapalıdır; kullanıcı yalnızca istediği grubu açar.
4. Yalnızca görünür satırlar lazy olarak oluşturulur; 585 cihazda scroll akıcı
   kalır.
5. Expand/collapse sırasında scroll konumu ve seçim korunur.
6. Arama/filtre sonucu kapalı bir dalın arkasında görünmez kalmaz.
7. Cihaz tıklaması mevcut detay panelini açar; geniş ekranda sağ panel, dar
   ekranda ayrı sayfa davranışı bozulmaz.
8. Ağaç/Liste geçişi, trafik sütunları, durumlar ve canlı tarama güncellemeleri
   çalışmaya devam eder.
9. Koyu ve açık temada taşma, okunmayan renk veya yatay scroll oluşmaz.
10. En az şu testler eklenir/güncellenir:
    - kök > subnet > gateway > grup > cihaz sırası,
    - varsayılan kapalı grup davranışı,
    - açılan grubun cihazlarını göstermesi,
    - 585 cihazda lazy rendering,
    - aramanın eşleşen cihaz yolunu göstermesi,
    - seçim ve detay paneli,
    - dar genişlikte overflow olmaması.

## Doğrulama

Değişiklik bitince şunları çalıştır:

```bash
dart format .
flutter analyze
flutter test
flutter build macos --debug
```

Son cevapta değiştirilen dosyaları, test sonuçlarını ve 585 cihaz senaryosunda
hangi widgetların lazy oluşturulduğunu açıkça belirt. Tarama veya trafik
mantığında bu görevle ilgisiz değişiklik yapma.
