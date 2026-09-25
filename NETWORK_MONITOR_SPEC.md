# macOS Yerel Ağ Keşif ve Cihaz Trafik İzleme Uygulaması

## Claude Opus için ana görev

Bu dokümandaki gereksinimlere göre çalışan, temiz mimarili ve test edilebilir bir macOS masaüstü uygulaması geliştir.

İlk sürüm yalnızca macOS için tamamlanacak. Kullanıcı ürünü beğenirse ikinci aşamada Windows desteği eklenecek. Bu nedenle UI ve domain kodu ortak tutulmalı; işletim sistemine bağlı ağ işlemleri adapter/interface arkasında olmalıdır. İlk sürümde Windows kodu yazma, ancak macOS'a özel kodu domain veya UI katmanına dağıtma.

Uygulama yalnızca kullanıcının sahibi olduğu veya tarama izni bulunan ağlarda kullanılmalıdır. Güvenlik açığı arama, parola deneme, exploit çalıştırma veya izinsiz erişim yapma. Ağ keşfi düşük hızda, iptal edilebilir ve yalnızca kullanıcının onayladığı özel ağ aralıklarında yapılmalıdır.

## Ekran görüntüsündeki başlangıç bilgileri

- Bilgisayarın IPv4 adresi: `172.16.14.26`
- Alt ağ maskesi: `255.255.255.0`
- Mevcut doğrudan bağlı ağ: `172.16.14.0/24`
- Mevcut ağdaki kullanılabilir hostlar: `172.16.14.1` - `172.16.14.254`
- Broadcast: `172.16.14.255`
- Router/gateway: `172.16.14.254`
- DNS: `217.174.237.105`, `217.174.237.106`

Bu değerler yalnızca örnektir. Kod içine sabitlenmemeli; aktif ağ arayüzünden dinamik olarak okunup hesaplanmalıdır.

## Taranacak 172 ağı

Kullanıcı yerel olan bütün `172` adreslerini görmek istiyor. RFC1918'e göre özel/yerel 172 bloğu:

```text
172.16.0.0/12
172.16.0.0 - 172.31.255.255
Toplam 1.048.576 adres
```

`172` ile başlayan her IP yerel değildir. `172.0.0.0/8` bloğunun tamamını tarama. `172.0.0.0-172.15.255.255` ve `172.32.0.0-172.255.255.255` public adres içerebilir ve otomatik kapsama alınmamalıdır.

Mevcut Mac doğrudan yalnızca `172.16.14.0/24` ağına bağlıdır. `172.16.0.0/12` içindeki diğer alt ağların bulunabilmesi için o ağlara bir route olması gerekir. Route bulunmayan bir IP bloğuna kör tarama yapma.

Uygulamada şu kapsam seçenekleri olsun:

1. `Bu alt ağı tara` — örnekte `172.16.14.0/24`
2. `Erişilebilir tüm özel 172 ağlarını tara` — macOS route tablosunda bulunan `172.16/12` alt ağları
3. `Özel CIDR ekle` — yalnızca `172.16.0.0/12` içinde ve kullanıcı yetkisindeki CIDR'lar
4. `Tüm özel 172 bloğunu tara` — gelişmiş seçenek; açık uyarı/onay, parçalı kuyruk ve durdur/devam et desteği gerektirir

Önerilen varsayılan seçenek `Erişilebilir tüm özel 172 ağlarını tara` olsun.

## Ürün amacı

Kullanıcı uygulamayı açtığında:

- Aktif ağını ve erişilebilir özel 172 alt ağlarını görmeli.
- Taramayı başlatabilmeli, durdurabilmeli ve büyük taramaya daha sonra devam edebilmeli.
- Bulunan cihazları tarama bitmeden ağaç ve liste görünümünde görebilmeli.
- Bir cihaza basınca IP, MAC, üretici, hostname, tahmini cihaz türü, tahmini işletim sistemi ve son görülme zamanını görebilmeli.
- Router destekliyorsa cihazın bugünkü download/upload/toplam MB değerini görebilmeli.
- Router trafik verisi sağlamıyorsa sahte `0 MB` yerine açıkça `Trafik verisi mevcut değil` mesajı görmeli.

## Önemli teknik sınırlamalar

Bu maddeleri hem uygulama davranışında hem README'de açıkça belirt:

1. IP taraması tek başına cihazın günlük kaç MB kullandığını göstermez.
2. Switch'li veya Wi-Fi bir ağdaki normal Mac, diğer cihazların bütün paketlerini göremez.
3. Cihaz başına doğru trafik için router'ın resmi API'si, controller API'si, NetFlow/sFlow/IPFIX veya gateway üzerinde çalışan bir ölçüm sistemi gerekir.
4. SNMP interface toplamını cihazlara bölmek doğru ölçüm değildir ve yapılmamalıdır.
5. MAC üreticisi, hostname, mDNS, SSDP, NetBIOS, TTL ve açık portlar yalnızca cihaz türü/OS tahmini sağlar.
6. Ping yanıtı vermeyen bir cihaz kapalı olmayabilir.
7. Telefonların özel/rastgele MAC özelliği üretici tespitini yanıltabilir.
8. Aynı Layer-2 segment dışında MAC adresi genellikle doğrudan öğrenilemez. Router/DHCP client listesi yoksa routed alt ağdaki bazı cihazların MAC'i `Bilinmiyor` kalabilir.

## Teknoloji seçimi

### Uygulama

- Flutter desktop, Dart
- İlk build target: macOS
- Durum yönetimi: Riverpod
- Yerel veritabanı: SQLite + Drift
- Grafik: `fl_chart` veya eşdeğer, aktif bakımı yapılan paket
- Arka plan işleri: isolate/worker yapısı; UI thread üzerinde tarama yapma
- Hassas bilgiler: macOS Keychain

### Neden Flutter?

- İlk sürüm macOS'ta çalışır.
- Daha sonra aynı UI, domain ve veritabanı koduyla Windows desteği eklenebilir.
- Yalnızca ağ arayüzü/route/ARP/ping/native izin adapter'ları platforma göre değiştirilir.

Yeni paket eklemeden önce gerçekten gerekli olduğunu doğrula. Bakımı bırakılmış veya yalnızca mobil platformları destekleyen Flutter ağ paketlerini kullanma.

## Mimari

```text
lib/
  app/
  core/
    errors/
    logging/
    utils/
  features/
    network_scope/
      domain/
      application/
      infrastructure/
      presentation/
    discovery/
    devices/
    traffic/
    settings/

macos/
  Runner/
  Native network bridge/helper

test/
  fixtures/
  unit/
  widget/
  integration/
```

Katmanlar:

```text
Flutter UI
  -> Application use-case'leri
    -> Domain modelleri ve repository interface'leri
      -> Infrastructure
        - NetworkInterfaceProvider
        - RouteProvider
        - DeviceDiscoveryProvider
        - DeviceFingerprintProvider
        - TrafficProvider
        - DeviceRepository
```

Platforma bağlı komut veya native API çıktısını widget içinde parse etme. Bütün provider'lar mock edilebilir olsun. macOS komut çıktıları için fixture tabanlı parser testleri yaz.

## Ana özellikler

### 1. Aktif ağ ve route tespiti

- Aktif fiziksel ağ arayüzlerini listele.
- Varsayılan route'u kullanan arayüzü otomatik seç.
- IPv4, subnet mask, CIDR, network address, broadcast ve gateway değerlerini hesapla.
- Wi-Fi/Ethernet adını göster.
- Loopback, VPN, bridge, Docker ve sanal arayüzleri etiketle.
- Birden fazla uygun arayüz varsa kullanıcı seçim yapabilsin.
- macOS route tablosunu okuyarak `172.16.0.0/12` içindeki erişilebilir alt ağları çıkar.
- Çakışan/iç içe geçmiş route'ları normalize et; aynı IP'yi iki kez tarama.
- Route bulunmayan blokları `Erişilemiyor` olarak göster.
- IPv6'yı veri modelinde engelleme, ancak MVP aktif taraması IPv4 ile sınırlı olsun.

### 2. Tarama kapsamı ve büyük ağ yönetimi

Tarama başlamadan önce göster:

- CIDR listesi
- Toplam aday IP sayısı
- Tahmini süre
- Kullanılacak keşif yöntemleri
- Concurrency ve timeout özeti

`172.16.0.0/12` toplam 1.048.576 adres içerdiği için:

- Bütün bloğa aynı anda istek gönderme.
- Önce route, mevcut ARP/neighbor tablosu ve varsa router/DHCP client listesinden adayları topla.
- Taramayı alt ağ/parça işleri olarak kuyruğa böl.
- Kuyruğu SQLite'ta sakla.
- Alt ağ başına ilerleme, bulunan cihaz sayısı, geçen ve tahmini kalan süre göster.
- Duraklat, devam et ve iptal özellikleri ekle.
- Uygulama yeniden açılınca tamamlanmamış taramayı devam ettirme seçeneği sun.
- Varsayılan concurrency düşük ve ayarlanabilir olsun.
- Public veya yetkisiz CIDR'a yönelme.

### 3. Cihaz keşfi

Keşfi aşamalı ve streaming yap:

1. macOS ARP/neighbor tablosunu oku.
2. Yerel segmentte düşük eşzamanlı ICMP probe/ping uygula.
3. ARP cevabı veren cihazları tespit et.
4. Reverse DNS dene.
5. mDNS/Bonjour servislerini keşfet.
6. SSDP/UPnP yanıtlarını değerlendir.
7. Gerekirse NetBIOS adı dene.
8. Yalnızca sınıflandırmaya yardımcı olacak sınırlı port kontrolü yap.

Varsayılan sınırlı port listesi:

```text
22, 53, 80, 139, 443, 445, 548, 631, 8008, 8009, 8080, 9100
```

Kurallar:

- Port listesi ayarlardan değiştirilebilir olsun.
- Tarama exploit, parola deneme veya kapsamlı port taraması yapmasın.
- Sonuçları tarama bitmeden UI'a stream et.
- Cancellation gerçek çalışsın; yeni işler durmalı ve açık kaynaklar kapanmalı.
- IP + MAC + geçmiş gözlem ile duplicate kayıtları birleştir.
- DHCP nedeniyle IP değişirse MAC üzerinden cihaz geçmişini koru.
- MAC bilinmiyorsa geçici IP tabanlı kimlik kullan; daha sonra MAC bulunursa kayıtları birleştir.
- Offline kararını tek başarısız ping ile verme.

### 4. Cihaz sınıflandırma

Her cihaz için:

- Gösterilen ad/hostname
- IPv4
- MAC, varsa
- OUI üreticisi, varsa
- Tahmini cihaz türü
- Tahmini işletim sistemi
- Güven seviyesi
- Tahmin gerekçeleri
- Görülen sınırlı servisler/portlar
- İlk görülme
- Son görülme
- Online/offline/unknown
- Gateway etiketi
- `Bu Mac` etiketi
- Kullanıcı özel adı, türü ve notu

Cihaz türleri:

- Telefon
- Tablet
- Windows bilgisayar
- Mac
- Linux bilgisayar/sunucu
- Router/gateway
- Yazıcı
- Akıllı TV/medya cihazı
- IoT/akıllı ev
- Oyun konsolu
- Bilinmiyor

Sınıflandırma sinyalleri:

- MAC OUI
- DHCP/hostname
- mDNS servisleri ve TXT kayıtları
- SSDP açıklaması
- NetBIOS
- Sınırlı açık portlar
- TTL gibi zayıf sinyaller
- Router API client bilgisi

Güven etiketleri: `Kesin`, `Yüksek olasılık`, `Tahmini`, `Bilinmiyor`.

Kullanıcının manuel adı/türü her zaman otomatik tahminden üstün olsun ve sonraki taramalarda korunsun.

## Arayüz

macOS'e uygun, sade ve hızlı bir arayüz tasarla. Klavye navigasyonu, VoiceOver etiketleri, açık/koyu tema ve renk dışı durum işaretleri olsun.

### Sol panel

- Ağlar/alt ağlar
- Tarama kapsamları
- Son taramalar
- Ayarlar

### Ana ağaç görünümü

```text
172.16.0.0/12 · Özel 172 ağı
├── 172.16.14.0/24 · Doğrudan bağlı
│   └── Gateway · 172.16.14.254
│       ├── Telefonlar (3)
│       │   ├── iPhone · 172.16.14.12 · Online
│       │   └── Android · 172.16.14.18 · Online
│       ├── Bilgisayarlar (2)
│       │   ├── MacBook · 172.16.14.26 · Bu Mac
│       │   └── Windows-PC · 172.16.14.40 · Online
│       ├── Yazıcılar (1)
│       ├── IoT (4)
│       └── Bilinmeyen (2)
├── 172.16.20.0/24 · Router üzerinden erişilebilir
└── 172.20.0.0/16 · Erişilemiyor
```

- Gruplar açılıp kapanabilsin.
- Online/offline/unknown hem ikon hem metinle gösterilsin.
- Arama IP, MAC, hostname, üretici ve özel adda çalışsın.
- Filtreler: durum, tür, OS, üretici, alt ağ.
- Sıralama: IP, ad, son görülme, günlük trafik.

### Liste görünümü

Ağaç/liste geçişi olsun. Kolonlar:

- Durum
- Cihaz adı
- IP
- MAC
- Üretici
- Tür/OS
- Bugünkü indirme
- Bugünkü yükleme
- Toplam
- Son görülme

Büyük listede virtualization/pagination kullan. Kolonlar yeniden boyutlandırılabilir ve gösterilip gizlenebilir olsun.

### Cihaz detay ekranı

- Kimlik ve ağ bilgileri
- Tahmini cihaz türü/OS, güven ve gerekçeler
- Bugünkü download/upload/toplam
- Son 24 saat saatlik grafik
- Son 7 gün günlük grafik
- İlk/son görülme
- IP geçmişi
- Görülen servisler
- Kullanıcı özel adı/türü/notu
- `Bu cihazı tanıyorum` seçeneği

Trafik kaynağı yoksa `0 MB` gösterme. `Bu router cihaz başına trafik verisi sağlamıyor veya entegrasyon kurulmadı` mesajı ve kurulum bağlantısı göster.

## Cihaz başına trafik ölçümü

Ortak bir `TrafficProvider` interface'i tanımla. Her örnek:

- Cihaz kimliği/MAC/IP
- Başlangıç ve bitiş zamanı
- Download byte
- Upload byte
- Kaynak/provider
- Güvenilirlik

Provider önceliği:

1. Router'ın resmi API'si/controller API'si
2. Gateway üzerinde çalışan ölçüm ajanı
3. NetFlow/sFlow/IPFIX
4. Yalnızca cihaz başına sayaç veriyorsa SNMP
5. Sadece bu Mac için macOS trafik sayaçları

MVP'de iki mod olsun:

- `Keşif modu`: cihazları bulur; trafik yoksa bunu doğru gösterir.
- `Router entegrasyon modu`: desteklenen provider varsa sayaçları periyodik alır.

Router marka/modeli verilmeden uydurma endpoint veya kimlik bilgisi kullanma. İlk geliştirmede:

- `TrafficProvider` interface'i
- Mock/demo provider
- Provider bağlantı testi
- Günlük aggregation
- Grafikleri tamamla

Gerçek adapter router bilgileri alındıktan sonra eklenir.

Monoton sayaçlarda:

- Önceki değerle farkı hesapla.
- Reset/wrap sonrası negatif farkı kullanım sayma.
- Örnek zamanındaki MAC-IP eşleşmesini sakla.
- Gün sınırını yerel saat diliminde hesapla.
- Download/upload yönünü provider tanımına göre normalize et.

## Veri modeli

### `networks`

- `id`
- `interface_name`
- `display_name`
- `cidr`
- `gateway_ip`
- `first_seen_at`
- `last_seen_at`

### `devices`

- `id`
- `network_id`
- `mac_address` nullable
- `current_ip`
- `hostname` nullable
- `vendor` nullable
- `inferred_type`
- `inferred_os` nullable
- `confidence`
- `custom_name` nullable
- `custom_type` nullable
- `note` nullable
- `is_gateway`
- `is_local_device`
- `first_seen_at`
- `last_seen_at`
- `status`

### `device_observations`

- `id`
- `device_id`
- `observed_at`
- `ip_address`
- `hostname` nullable
- `services_json`
- `signals_json`

### `traffic_samples`

- `id`
- `device_id`
- `source`
- `period_start`
- `period_end`
- `download_bytes`
- `upload_bytes`
- `reliability`

### `scan_sessions`

- `id`
- `network_id`
- `started_at`
- `finished_at` nullable
- `target_cidrs_json`
- `status`
- `hosts_scanned`
- `devices_found`
- `checkpoint_json` nullable
- `error_message` nullable

MAC/IP değerlerini normalize et. Byte değerini integer sakla; MB/GB dönüşümünü presentation katmanında yap.

## Güvenlik ve macOS izinleri

- İlk açılışta `Yalnızca yönetme izniniz olan ağlarda kullanın` uyarısı göster.
- Taranacak CIDR ve host sayısını tarama öncesinde görünür yap.
- Otomatik kapsamı yalnızca `172.16.0.0/12` ile sınırla.
- Gerekli izinleri yalnızca ihtiyaç anında iste ve nedenini açıkla.
- Uygulamayı sürekli root olarak çalıştırma.
- Ayrı helper gerekirse en az yetki prensibi ve dar IPC yüzeyi kullan.
- Router kullanıcı adı/parola/token bilgilerini SQLite veya log'a yazma; macOS Keychain'de sakla.
- Loglarda parola, token ve authentication header olmasın.
- Komut parametrelerinde kullanıcı girdisini shell string birleştirmesiyle çalıştırma; argument listesi ve CIDR doğrulaması kullan.
- İlk dağıtım şeklini README'de açıkla. App Sandbox/raw socket/helper kısıtlarını hedeflenen dağıtım yöntemine göre doğrula.

## Hata durumları

- Ağ arayüzü bulunamadı
- Tarama sırasında ağ değişti
- VPN aktif veya route belirsiz
- Ping/ARP izni yok
- Native helper başlatılamadı
- Router API'ye ulaşılamıyor
- Router authentication başarısız
- Rate limit
- Sayaç resetlendi
- Veritabanı hatası
- Tarama kullanıcı tarafından iptal edildi
- Uygulama uykuya girdi/uyandı

Kullanıcı mesajı çözüm önerisi içersin. Teknik detay ayrı açılabilir bölümde ve logda correlation ID ile bulunsun.

## Performans

- `/24` taramasında UI donmamalı.
- Sonuçlar akış halinde görünmeli.
- `172.16/12` kuyruğu durdurulabilir/devam ettirilebilir olmalı.
- Bellek kullanımı toplam host sayısıyla kontrolsüz büyümemeli.
- 1.000 cihaz ve 90 günlük saatlik trafik verisinde liste/grafik akıcı olmalı.
- Ham trafik için saklama süresi ve günlük aggregation olmalı.
- App lifecycle, sleep/wake ve ağ değişimlerinde işler güvenli devam etmeli veya kontrollü durmalı.

## Testler

### Unit

- IPv4 + maske -> CIDR/network/broadcast
- `/24`, `/16`, `/30`, `/12` ve geçersiz maskeler
- `172.16.0.0/12` sınırları
- `172.16.0.0` ve `172.31.255.255` dahil
- `172.15.255.255` ve `172.32.0.0` hariç
- Route tablosu parser fixture'ları
- ARP/neighbor parser fixture'ları
- CIDR normalize/birleştirme ve duplicate engelleme
- MAC normalizasyonu/OUI lookup
- Device deduplication
- Sınıflandırma ve güven seviyesi
- Counter delta/reset/gün sınırı
- Byte -> MB/GB formatı

### Integration

- Mock discovery ile streaming sonuç
- Tarama iptal/duraklat/devam
- Checkpoint sonrası uygulama yeniden açma
- IP'si değişen aynı MAC'in tek cihaz kalması
- Mock traffic provider günlük toplam
- Provider bağlantı/auth hataları
- Ağ değişikliği ve sleep/wake senaryosu

### Widget/UI

- Empty/loading/error/retry
- Tarama ilerleme paneli
- Ağaç aç/kapat
- Liste arama/filtre/sıralama
- Cihaz detayında trafik var/yok
- Açık/koyu tema
- VoiceOver/klavye navigasyonu

Standart test komutu gerçek ağı taramamalıdır. Gerçek ağ testleri ayrı, açıkça opt-in olmalıdır.

## Kabul kriterleri

- `172.16.14.26` + `255.255.255.0` için `172.16.14.0/24` doğru hesaplanır.
- Gateway `172.16.14.254` olarak gösterilir.
- `172.16.0.0/12` özel blok olarak tanınır; bütün `172.0.0.0/8` taranmaz.
- Route tablosundaki erişilebilir özel 172 alt ağları ayrı gösterilir.
- Büyük tarama parçalı, durdurulabilir ve devam ettirilebilir.
- Cihazlar tarama tamamlanmadan görünür.
- Aynı MAC duplicate olmaz.
- Ağaç ve liste görünümü çalışır.
- Cihaz detay ekranı çalışır.
- OS/tür tahmini güven etiketi olmadan kesin bilgi gibi gösterilmez.
- Trafik provider yokken `0 MB` gösterilmez.
- Mock provider ile günlük download/upload/toplam doğru hesaplanır.
- Hassas router bilgisi Keychain'de tutulur.
- Uygulama kapanırken kaynaklar temiz kapatılır.
- `dart format`, `flutter analyze`, unit/widget/integration testleri ve macOS build başarılıdır.

## Uygulama fazları

### Faz 1 — macOS iskelet ve ağ kapsamı

- Flutter macOS projesi
- Tema, navigation ve temel ekran durumları
- Domain modelleri/provider interface'leri
- Aktif interface, subnet, gateway ve route tespiti
- `172.16/12` kapsam doğrulaması
- SQLite/Drift başlangıcı
- Unit testleri

### Faz 2 — keşif ve cihaz UI

- macOS ARP/neighbor, ping ve isim çözümleme adapter'ları
- Streaming sonuçlar
- Kuyruk/checkpoint/cancel/resume
- Kalıcılık ve deduplication
- Ağaç/liste
- Cihaz detayının ağ bilgileri

### Faz 3 — sınıflandırma

- OUI verisi
- mDNS/SSDP/NetBIOS sinyalleri
- Güven seviyeli kural motoru
- Manuel cihaz adı/türü/notu

### Faz 4 — trafik altyapısı

- `TrafficProvider`
- Mock provider
- Ayar ve bağlantı testi ekranı
- Counter delta ve aggregation
- 24 saat/7 gün grafikleri

### Faz 5 — gerçek router adapter'ı

Router marka/model/firmware ve API desteği öğrenildikten sonra yalnızca o sisteme uygun adapter geliştir. Genel veya uydurma API yazma.

### Faz 6 — Windows, yalnızca daha sonra istenirse

- Mevcut Flutter UI/domain/database kodunu koru.
- `NetworkInterfaceProvider`, `RouteProvider` ve `DeviceDiscoveryProvider` için Windows implementation ekle.
- Windows izin, firewall ve paketleme belgelerini ekle.
- macOS davranışını bozmayan platform testleri yaz.

İlk görevde Faz 6'yı uygulama.

## Claude'un çalışma kuralları

1. Bu dosyayı tamamen oku.
2. Önce repository durumunu incele ve kısa plan/klasör yapısı paylaş.
3. Faz 1'den başla; fazları sırayla uygula.
4. Router ayrıntısı olmadan trafik değerleri veya endpoint uydurma.
5. Platform kodunu adapter arkasında tut.
6. Shell çıktısını UI katmanında parse etme.
7. Testlerin gerçek ağı otomatik taramadığını doğrula.
8. Her faz sonunda format, analyze, test ve uygun build çalıştır.
9. Hataları ignore/suppress ederek geçme; kök nedeni düzelt.
10. README'ye kurulum, macOS izinleri, tarama sınırları, trafik sınırlaması ve router provider ekleme rehberi koy.
11. Windows'u bu aşamada geliştirme; yalnızca mimariyi hazır tut.
12. Tamamlandığında çalışan özellikleri, bilinen sınırlamaları ve sonraki adımları yaz.

## Claude Opus'a gönderilecek kısa komut

```text
NETWORK_MONITOR_SPEC.md dosyasını tamamen oku ve gereksinimleri Faz 1'den başlayarak uygula. İlk ve tek hedef şimdilik macOS masaüstüdür; Flutter kullan ve Windows'u geliştirme, yalnızca platform adapter mimarisini daha sonra Windows eklenebilecek şekilde tut. Özel 172 kapsamı yalnızca 172.16.0.0/12'dir, bütün 172.0.0.0/8 değildir. Route tablosundan gerçekten erişilebilir alt ağları bul. Büyük taramaları parçalı, durdurulabilir ve devam ettirilebilir yap. Tarayıcı/web uygulaması geliştirme. Cihaz başına trafik verisini uydurma; router bilgisi yoksa TrafficProvider interface'i ve mock provider kullan. Önce repository durumunu inceleyip kısa plan ve klasör yapısını paylaş. Her faz sonunda dart format, flutter analyze, testler ve macOS build çalıştır. Standart testler gerçek yerel ağı taramasın. Güvenlik ve kabul kriterlerinden taviz verme.
```

## Gerçek trafik entegrasyonundan önce kullanıcıdan istenecek bilgiler

- Router marka/model
- Firmware: stok, OpenWrt, RouterOS, UniFi vb.
- Router paneli/API erişimi
- SNMP, NetFlow/sFlow/IPFIX veya resmi API desteği
- Trafik geçmişinin saklama süresi
- MB (`1000²`) veya MiB (`1024²`) tercihi

