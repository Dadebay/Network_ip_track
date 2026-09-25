# Ağ İzleyici (network_monitor)

macOS için yerel ağ keşif ve cihaz izleme uygulaması (Flutter desktop). Aktif
ağı ve erişilebilir özel `172.16.0.0/12` alt ağlarını tespit eder, bu
kapsamda düşük hızlı, iptal edilebilir ve devam ettirilebilir cihaz keşfi
yapar; bulunan cihazları ağaç ve liste görünümünde gösterir.

> **Yalnızca yönetme izniniz olan ağlarda kullanın.** Uygulama güvenlik açığı
> aramaz, parola denemez, exploit çalıştırmaz ve kapsamlı port taraması
> yapmaz.

## Durum

| Faz | İçerik | Durum |
| --- | --- | --- |
| 1 | macOS iskelet, arayüz/route tespiti, `172.16/12` kapsam doğrulaması, Drift | Tamam |
| 2 | ARP/ping/reverse DNS/mDNS/SSDP/port adapter'ları, streaming tarama, kuyruk + checkpoint + pause/cancel/resume, kalıcılık ve dedup, ağaç/liste, cihaz detayı | Tamam |
| 3 | OUI üretici tespiti, mDNS TXT/SSDP/NetBIOS sinyalleri, güven seviyeli kural motoru, elle ad/tür/not ve "Bu cihazı tanıyorum", OS/üretici filtreleri | Tamam |
| 4 | `TrafficProvider`, demo provider, bağlantı testi, sayaç delta + günlük aggregation, 24 saat/7 gün grafikleri, liste trafik sütunları | Tamam |
| 5 | FortiGate adapter'ı (FortiOS REST API, trafik logları → cihaz başına kullanım) | Kod tamam; gerçek FortiGate'te API anahtarıyla doğrulanmadı |

## Kurulum

```bash
flutter pub get
flutter run -d macos
```

Kontroller:

```bash
dart format lib test
flutter analyze
flutter test          # gerçek ağa asla dokunmaz; tüm adapter'lar fake
flutter build macos
```

Drift şeması değişirse: `dart run build_runner build`.

Tarama ayarları (eşzamanlılık, zaman aşımları, yöntemler, port listesi)
`scan_settings.json`, trafik ayarları `traffic_settings.json` olarak uygulama
destek klasöründe saklanır. İkisi de gizli bilgi içermez. Dosyadan okunan
tarama ayarları, ayar ekranının izin verdiği sınırlara çekilir.

## Kapsam kuralları

- Otomatik kapsam yalnızca RFC1918 `172.16.0.0/12` bloğudur
  (`172.16.0.0` – `172.31.255.255`). `172.0.0.0/8`'in geri kalanı public
  adres içerebilir ve asla otomatik taranmaz.
- Kapsam seçenekleri:
  1. **Bu alt ağı tara** — aktif arayüzün alt ağı.
  2. **Erişilebilir tüm özel 172 ağlarını tara** (önerilen) — macOS route
     tablosunda bulunan `172.16/12` alt ağları.
  3. **Özel CIDR ekle** — yalnızca `172.16.0.0/12` içinde; dışındaki girişler
     reddedilir.
  4. **Tüm özel 172 bloğunu tara** — gelişmiş.
- Cihazlar **ağaç grafiği** olarak gösterilir (172.16.0.0/12 → alt ağlar →
  gateway → gruplar → cihazlar, eğri bağlantılarla; kaydırma/yakınlaştırma,
  "ekrana sığdır", dal aç/kapat) ya da sütunlu liste olarak.
- Tarama öncesi CIDR listesi, aday host sayısı, tahmini süre, yöntemler ve
  eşzamanlılık/zaman aşımı gösterilir.
- **Onay, seçeneğe göre değil planın boyutuna göre istenir:** 254'ten fazla
  host içeren her plan (bir /24'ten büyük) açık onay gerektirir. Route
  tablosunda `172.16.0.0/12` route'u varsa önerilen seçenek bile yaklaşık 1
  milyon adrese çözülür ve onaysız başlamaz. Kontrolcü de onaysız büyük
  planı reddeder.

## Tarama nasıl çalışır

1. **Aday toplama:** ARP tablosu (`arp -a -n`), mDNS/Bonjour (`dns-sd`) ve
   SSDP (UDP M-SEARCH) paralel okunur. Önceki taramalarda görülen adresler de
   aday sayılır.
2. **Adaylar önce:** bilinen adaylar sweep'ten önce yoklanır, sonra sweep'te
   atlanır.
3. **Sweep:** kapsam en fazla `/24` büyüklüğünde parçalara bölünür (tam
   `/12` = 4096 parça) ve düşük eşzamanlılıkla (varsayılan 8) taranır. Her
   parçanın ağ ve broadcast adresi atlanır, böylece directed-broadcast ping
   gönderilmez.
4. **Host başına:** tek ICMP echo; yerel segmentte `arp -n <ip>` (ICMP'yi
   düşüren ama ARP'ye cevap veren cihazlar da bulunur); ayarlardaki sınırlı
   port listesine TCP connect denemesi (veri gönderilmez). Açık bir port da
   canlılık sinyalidir, yani ICMP'yi düşüren routed cihazlar da bulunur.
   Canlı hostlarda reverse DNS (`dscacheutil`) çalışır.
5. **Streaming:** her bulunan host anında SQLite'a yazılır; ağaç/liste
   görünümleri tarama bitmeden güncellenir.

**Kuyruk ve devam ettirme:** her parçanın durumu ve tam kaldığı offset
`scan_sessions.checkpoint_json` içinde saklanır. Duraklat/iptal yeni iş
başlatmayı hemen durdurur, uçuştaki yoklamalar kendi zaman aşımlarıyla biter.
Uygulama tarama sırasında kapanırsa oturum bir sonraki açılışta
"duraklatıldı" olur ve **Tarama kapsamları** ekranından devam ettirilebilir.
Başka bir ağa bağlıyken eski ağın taraması devam ettirilmez.

**Ağ değişimi:** tarama sürerken aktif ağ belirli aralıklarla yeniden
algılanır. Arayüz, CIDR veya ağ kaydı değişirse ya da ağ algılanamazsa tarama
güvenli biçimde duraklatılır ve "Bu tarama başka bir ağda başlatılmış"
hatası gösterilir. Eski ağın kapsamı yeni ağ üzerinde taranmaya devam
etmez. Oturum, asıl ağa dönülünce devam ettirilebilir.

**Dedup:** cihaz kimliği MAC'tir; DHCP ile IP değişse de tek kayıt kalır ve
IP geçmişi `device_observations`'da tutulur. MAC bilinmiyorsa (network, IP)
geçici kimliktir; MAC sonradan öğrenilirse geçici kayıt MAC kaydına
birleştirilir. Ağ kimliği arayüz + CIDR'dır, yani aynı `en0` başka bir
Wi-Fi'da ayrı bir ağdır.

**Offline kararı:** tek başarısız ping ile verilmez. Tamamlanan bir taramada
görülmeyen cihaz önce `Bilinmiyor`, ardışık ikinci kaçırmada `Offline` olur.
Duraklatılan veya iptal edilen taramalar cihaz durumunu değiştirmez.

## Cihaz sınıflandırma

Tür ve işletim sistemi kural motoruyla **tahmin edilir**
(`lib/features/classification/application/device_classifier.dart`). Her
kural bir tür veya OS için 0–1 arası ağırlıklı kanıt ve okunabilir bir
gerekçe üretir:

- **MAC üreticisi (OUI):** IEEE kaydından. Rastgele/özel MAC'lerin üreticisi
  yoktur; bu durum ayrıca not edilir.
- **Hostname:** `iPhone`, `DESKTOP-XXXXXXX`, `raspberrypi` gibi kalıplar.
- **mDNS/Bonjour:** servis türleri (`_ipp`, `_googlecast`, `_hap`…) ve TXT
  kayıtları (`model=MacBookPro18,3`, `md=Chromecast`, `ty=…`).
- **SSDP:** Internet Gateway Device, MediaRenderer/DIAL, sunucu başlığı.
- **NetBIOS adı:** UDP 137 üzerinden tek bir NBSTAT sorgusu; yalnızca canlı
  olup başka yoldan adı bulunamayan hostlarda çalışır.
- **Sınırlı açık portlar** ve **TTL** (zayıf sinyal).

Aynı cevabı destekleyen kanıtlar `1 − Π(1 − w)` ile birleşir. Önde giden
cevap hem bir eşiği geçmeli hem de ikinciyi belirli bir farkla geçmelidir:

| Güven | Koşul |
| --- | --- |
| `Kesin` | Yalnızca olgular: route tablosundaki gateway, bu Mac |
| `Yüksek olasılık` | skor ≥ 0,85 ve ikinciden fark ≥ 0,25 |
| `Tahmini` | skor ≥ 0,45 ve fark ≥ 0,15 |
| `Bilinmiyor` | diğer her durum (ör. tek başına "Apple" üreticisi) |

Tür ve OS ayrı güven etiketleri taşır. Sonraki bir tarama daha az sinyal
görürse, önceki daha güçlü tahmin korunur. Kullanıcının girdiği ad, tür ve
not ile "Bu cihazı tanıyorum" her zaman tahminin önüne geçer ve taramalar
arasında korunur.

**OUI verisi:** IEEE MA-L listesi
(`https://standards-oui.ieee.org/oui/oui.csv`, ~40.000 kayıt) uygulamayla
birlikte `assets/oui/oui.csv` olarak gelir. Güncellemek için dosyayı yeniden
indirip değiştirmek yeterlidir. Dosya yoksa uygulama çalışır, ama üreticiler
"Bilinmiyor" kalır.

## macOS izinleri ve dağıtım

- App Sandbox açık. Entitlements: `network.client` (giden TCP/UDP: port
  kontrolü, SSDP, mDNS) ve Debug'da `network.server`.
- NetBIOS (UDP 137) ve SSDP (UDP 1900) ham datagram'la yapılır;
  `network.client` yeterlidir.
- Keşif, sistem araçlarını (`ping`, `arp`, `dscacheutil`, `dns-sd`,
  `ifconfig`, `netstat`, `route`, `networksetup`) **argüman listesiyle**
  çalıştırır; hiçbir zaman shell string'i kurulmaz. CIDR'lar tarama öncesi
  doğrulanır.
- Uygulama root olarak çalışmaz ve ayrı bir yetkili helper kullanmaz. macOS
  `ping`'i ayrıcalıksız ICMP datagram soketi kullanır.
- Sandbox ping'in ICMP soketini engellerse tarama sessizce "0 cihaz" ile
  bitmez; açık bir izin hatasıyla başarısız olur.
- Hedeflenen ilk dağıtım: Developer ID ile imzalı, notarize edilmiş doğrudan
  dağıtım (App Store dışı). Sandbox içinde ICMP/ARP bir macOS sürümünde
  engellenirse, bu dağıtım şeklinde sandbox kapatılabilir. App Store gerekirse
  dar IPC yüzeyli bir helper tasarlanmalıdır.

## Bilinen teknik sınırlamalar

1. IP taraması tek başına bir cihazın günlük kaç MB kullandığını göstermez.
2. Switch'li veya Wi-Fi ağdaki bir Mac diğer cihazların paketlerini göremez.
3. Cihaz başına doğru trafik için router'ın resmi/controller API'si,
   NetFlow/sFlow/IPFIX veya gateway üzerinde çalışan bir ölçüm sistemi
   gerekir.
4. SNMP arayüz toplamını cihazlara bölmek doğru ölçüm değildir; yapılmaz.
5. MAC üreticisi, hostname, mDNS, SSDP, NetBIOS, TTL ve açık portlar yalnızca
   tür/OS **tahmini** sağlar. Arayüz tahmini her zaman güven etiketiyle
   gösterir (`Kesin`, `Yüksek olasılık`, `Tahmini`, `Bilinmiyor`).
6. Ping'e cevap vermeyen bir cihaz kapalı olmayabilir.
7. Telefonların özel/rastgele MAC özelliği üretici tespitini yanıltabilir.
8. Aynı Layer-2 segment dışında MAC genellikle öğrenilemez; routed alt
   ağlardaki cihazların MAC'i `Bilinmiyor` kalabilir.

Trafik kaynağı yokken arayüz `0 MB` göstermez. Bunun yerine "Bu router
cihaz başına trafik verisi sağlamıyor veya entegrasyon kurulmadı" mesajı
görünür.

## FortiGate entegrasyonu (Faz 5)

Bu ağın gateway'i (`172.16.14.254`) bir **FortiGate** (MAC üreticisi
Fortinet, FortiOS 7.x yönetim arayüzü). Adapter yalnızca iki uç kullanır:

- `GET /api/v2/monitor/system/status` — bağlantı testi
- `GET /api/v2/log/<memory|disk>/traffic/forward` — forward trafik logları

Cihaz başına kullanım **oturum loglarından** hesaplanır: `srcip`/`srcmac`
oturumu başlatan cihaz, `sentbyte` onun yüklemesi, `rcvdbyte` indirmesi.
Oturum ara istatistikleri varsa (`sentdelta`/`rcvddelta`) yalnızca fark
sayılır, böylece bir oturum iki kez sayılmaz. Oturum toplamı
`[eventtime − duration, eventtime]` aralığına yayılır ve saat sınırlarında
orantılı bölünür. FortiView'in anlık kaynak baytları kullanılmaz: yalnızca
o an açık oturumları kapsar, bu yüzden cihaz sayacı değildir.

Güvenlik:
- Salt okunur REST API anahtarı yalnızca Keychain'de tutulur ve yalnızca
  `Authorization` başlığında gönderilir (URL'de asla).
- Yalnızca HTTPS. FortiGate'in kendinden imzalı sertifikası, kullanıcı
  parmak izini FortiGate panelindekiyle karşılaştırıp onaylarsa kabul
  edilir. TLS doğrulaması kapatılmaz.
- Loglar en fazla 5 dakikada bir, sayfa başına 1000 satır, okuma başına en
  fazla 20 sayfa okunur. Kaldığı yer (imleç) diskte saklanır; yeniden
  başlatmada aynı log iki kez sayılmaz. İlk okuma son 24 saati alır.
- Trafik yalnızca **aktif ağdaki** cihazlara yazılır.

Güvenlik duvarı yöneticisinden istenecekler (ayar ekranında da listelenir):
FortiOS sürümü; salt okunur REST API yöneticisi ("Log & Report" okuma);
"Trusted Hosts" listesine bu Mac; API anahtarı; LAN→internet
politikalarında "Log Allowed Traffic: All Sessions"; logların nerede
tutulduğu (bellek/disk; yalnızca FortiAnalyzer/FortiGate Cloud ise bu
uygulama okuyamaz); HTTPS yönetim portu.

Sınırlamalar: `srcmac` bir L3 atlamadan sonra gerçek cihazın değil
sonraki atlamanın MAC'idir; routed alt ağlarda eşleştirme IP ile yapılır.
Dışarıdan başlatılan oturumlar (port yönlendirme) cihaz trafiğine
eklenmez. Uzun oturumların baytları, ara istatistik logu yoksa oturum
kapanınca görünür.

## Router trafik sağlayıcısı ekleme

İki mod vardır: **Keşif modu** (trafik kaynağı yok; arayüz "Veri yok" der)
ve **Router entegrasyon modu** (seçili provider'ın sayaçları periyodik
okunur, uygulama açık olduğu sürece). Demo provider açıkça "DEMO" etiketlidir
ve kapatıldığında tüm demo örnekleri silinir.

Sayaçlar monotondur: önceki okumayla fark alınır; reset/wrap sonrası geriye
giden okuma kullanım sayılmaz. Gün sınırı yerel saate göre hesaplanır ve
örnek anındaki MAC-IP eşleşmesi `traffic_samples.mac_address/ip_address`
sütunlarında saklanır (şema v2). Ham örnekler 48 saat, saatlik özetler 8 gün,
günlük toplamlar seçilebilir süre (30–365 gün) tutulur.

Yeni bir adapter ya `CounterTrafficProvider`'ı (monoton cihaz sayaçları)
ya da `UsageTrafficProvider`'ı (zaman aralığına bağlı kullanım kayıtları,
ör. oturum logları) uygular ve
`availableTrafficProvidersProvider` listesine eklenir
(`lib/features/traffic/presentation/providers/traffic_providers.dart`).
Gerçek bir adapter yalnızca router marka/model/firmware ve API desteği
öğrenildikten sonra, o sisteme özel yazılır. Uydurma endpoint veya kimlik
bilgisi kullanılmaz. Router kimlik bilgileri yalnızca macOS Keychain'de
tutulur (`KeychainRouterCredentialStore` → Runner'daki
`network_monitor/keychain` kanalı, generic-password öğeleri, servis
`com.dadebay.networkMonitor.router-credentials`). SQLite'a, ayar dosyalarına
veya loglara asla yazılmaz. Keychain hata verirse başka bir yere yazılmaz,
hata gösterilir. Debug build'lerde imza her derlemede değiştiği için macOS
Keychain erişim onayı isteyebilir.

Gerçek entegrasyon için gerekenler: router marka/model, firmware (stok,
OpenWrt, RouterOS, UniFi…), panel/API erişimi, SNMP/NetFlow/sFlow/IPFIX
desteği, trafik geçmişinin saklama süresi ve MB (1000²) veya MiB (1024²)
tercihi.

## Mimari

```text
lib/
  app/                 kabuk, tema, navigasyon
  core/                hata, log, CIDR/IPv4/MAC yardımcıları, Drift DB
  features/
    network_scope/     arayüz + route tespiti, erişilebilir 172 alt ağları
    discovery/         tarama planı, ScanEngine, ScanCoordinator, macOS adapter'ları
    classification/    kural motoru, IEEE OUI veritabanı
    devices/           cihaz repository'si (dedup), ağaç/liste/detay UI
    traffic/           TrafficProvider, sayaç delta, aggregation, grafikler
    settings/          tarama ayarları
test/
  unit/ widget/ integration/ fixtures/
```

Platforma bağlı her işlem bir arayüzün (`ArpTableProvider`, `PingProvider`,
`RouteProvider`…) arkasındadır. macOS komut çıktıları saf parser'larla
ayrıştırılır ve fixture'larla test edilir. Windows desteği bu arayüzlerin
Windows implementasyonlarıyla eklenecek.
