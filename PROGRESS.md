# Pawnic — ilerleme

## Kararlar
- Ad: **Pawnic**. Kart tabanlı yarış tahtası; zar yok, strateji var. Hedefe ilk varan kazanır, süre yok.
- Aynı telefonda 2–4 kişi. Bot yalnızca tek oyunculu modda. Sunucu ve ağ yok.
- Ekran dikey. Birden çok insan oyuncu varsa her sırada "telefonu ver" ekranı çıkar.
- Belirli bir mevcut oyunun kopyası yapılmaz.
- Oyun prototip değil, yayımlanacak ürün olarak geliştirilir. Paket adı `com.sezertanci.pawnic`.
- Diller: tr, en, de, es, fr, it, pt, id; hepsi tek `data/translations.csv` dosyasında.
- Gelir: ödüllü/geçiş reklamı ve uygulama içi satın alma. İkisi de arayüzle sarıldı; gerçek
  eklentiler AdMob ve GodotGooglePlayBilling'tir; bunlar yalnızca Gradle'lı derlemede bulunur,
  başka yerde (editör, testler, hızlı ön ayar) sahte sağlayıcılar çalışır. Geçiş reklamı oyunun ortasında yalnızca
  aşağıdaki 5 dakika kuralıyla gösterilir.
- Yarım kalan oyun her tur başında kaydedilir; açılışta "Devam et" çıkar.
- Tema altyapısı kuruldu (`BoardSkin`, `Skins` autoload'u); şimdilik tek tema: `classic`.
- Testler GUT ile; derlemeler Gradle ile (APK tablet, AAB Play). Ayrı tasarım dokümanı yok.
- Tahta tasarımı koddan ayrıldı: tahta `data/boards/*.json` dosyasındaki kareler ve bağlantılardan
  oluşan bir graftır (biçim README'de). Şekil serbesttir; yol ayrımları için her bağlantıda mod
  seçilir: `forced` (zorunlu), `choice` (geçerken seçilebilir), `exact` (yalnızca o karede duran
  taş girer). Yol ayrımında oyuncu varış karesini tahtada seçer. Şimdilik tek tahta var
  (`classic.json`, eski tahtanın aynısı); hangi tahtanın kullanılacağı `tuning.json`'dan gelir,
  tahta seçim ekranı yok.
- Oyun hızı: Ayarlar'da Yavaş / Normal / Hızlı (`GameSpeed` autoload'u, tercih olarak saklanır).
  Normal eski hızdır; çarpanlar `tuning.json` → `animation.speed_levels`. Yalnızca kart uçuşları
  ve taş yürüyüşü hızlanır/yavaşlar; botun bekleme süreleri etkilenmez. "Nasıl oynanır"
  demosu oyuncunun ayarından bağımsız, `demo_steps.json` → `speed` ile sabit yavaş oynar.

- Tahta düzeni ekran oranına göre değişmeyecek (2026-11-18: 13×17 ve altıgen taslakları çizildi,
  vazgeçildi). Bunun yerine kareler bitişik çiziliyor, üstlerindeki sayı ve simgeler büyütüldü.
- Başlangıçtaki aynı taşlar arasından çıkışta taş seçmeyi kolaylaştırma fikrine gerek görülmedi
  (2026-11-18). Her sayı kartıyla taş çıkarma fikri de şimdilik gündemde değil.
- Hareket yönü tahtada, bitiş alanının çevresinde 30 saniyede bir tur atan, yarı saydam dört oklu
  yayla gösterilir; yaylar sıradaki oyuncunun rengindedir (`TurnSpinner`, 2026-11-18). "Nasıl
  oynanır" listesinin başında da "Oyun saat yönünde oynanır." maddesi var.
- Ayarlar ekranında (`settings_overlay.gd`) ses açma/kapama, oyun hızı ve dil seçimi var.
- Oyun simgesi ve Android başlatıcı simgeleri (`assets/icon/`) hazır.
- El boyutu 3+1 (elde 3 kart, sırada 4. çekilir) şimdilik uygun (2026-11-18).
- Bot zorluğu (2026-11-18): Kolay, Orta, Zor, Çok zor. "Yeni oyun" ekranında, yalnızca tek
  oyunculu modda seçim düğmeleriyle seçilir; son seçim tercih olarak saklanır (`Difficulty`
  autoload'u), varsayılan Orta. Bütün botlar aynı seviyede oynar; seviye adı oyun ekranının üst
  çubuğunda saatin yanında "/" ile ayrılarak, seviyenin renginde yazar (tema: `level_colors`;
  Kolay yeşil, Orta mavi, Zor kırmızıya yakın turuncu, Çok Zor ateş kızılı) ve kayıtlı oyunla birlikte saklanır. Seviye ayarları
  `tuning.json` → `bot.levels`: Kolay %70, Orta %15 olasılıkla rastgele oynar (bu ikisi
  değişmeyecek). Zor sıradaki rakibin karşılığını hesaplar (`RivalForecast`) ve tehdit okur;
  Çok zor bütün rakiplerinkini hesaplar, tehdit okur ve Monte Carlo arama yapar.
- Botta hile yok (2026-11-18): bot yalnızca herkesin görebildiği bilgiyi kullanır. Kartların
  sırasını bilmez; yalnızca göremediği kartların (deste + rakip eller) dağılımını bilir
  (`GameMatch.unseen_cards`, `CardOdds`). Botların sana karşı birleşmesi önerildi, uygulanmadı.
- Tehdit okuma (`bot.levels[].read_threats`): ortak yoldaki her taşın değeri, sıradaki turda
  çarpılma olasılığı kadar düşürülür (`BotEvaluator`; kendi taşlarına `danger_weight`, rakip
  taşlarına `attack_weight`, ikisi de 0,6). Ağırlıklar öz-oyunla seçildi: tehdit okuyan bot aynı
  botun tehditsiz sürümünü %58–60 yener, 0,6 üstünde kazanç artmıyor.
- Monte Carlo arama (`RolloutSearch`, yalnızca Çok zor): en iyi 4 aday (`shortlist`), her biri
  10 olası oyunda (`rollouts`) denenir. Her olası oyunda göremediği kartlar yeniden karıştırılıp
  dağıtılır (`GameMatch.determinized`), aday oynanır, herkes bir kez tehdit okuyan hızlı botla
  (`bot.rollout_policy`) oynar ve tahta puanlanır. 30 deneme 10'dan belirgin güçlü değil, süresi
  iki kat. Ölçüm (iki oyuncu, 100 oyun): Çok Zor, Orta'yı %85, Zor'u %60 yener (aramadan önce
  %63 ve %44); PC'de hamle başına ortalama 55 ms, tablette de bekletmeden oynuyor.
  Kart saklama (`hold_cards`, `hold_values`) aramanın yerine geçtiği için kaldırıldı.
- Bot hamlesi oyunda `WorkerThreadPool` ile `bot_delay` süresince arka planda düşünülür.
- Hız karesi yalnızca ileri kartıyla (joker dahil) çalışır; geri kartlarında da çalışması
  konuşuldu, şimdilik olduğu gibi kalıyor (2026-11-18).
- Düzensiz hız kareleri renklere avantaj sağlamıyor (2026-11-18, `tools/seat_balance.gd`, kurulum başına
  2000 bot oyunu, ilk oynayan sırayla değişerek): 2 oyuncuda yeşil %50,3 / kırmızı %49,7; 4 oyuncuda
  bütün renkler %23,8–26,5 arası, hiçbiri anlamlı sapma sınırını (±1,9 puan) geçmedi.

## Prototip kuralları (deneme için, değişebilir)
- Tahta: 56 karelik ana yol, her renge 5 karelik ev yolu. Güvenli kareler: çıkış kareleri ve her
  kenarda bir kare daha. Hız kareleri her kenarda iki tane, değerleri karışık:
  +4, +6, -3, +3, -1, -4, +5, -2 (ring:4'ten başlayarak; desen oluşmasın diye düzensiz). Hız karesinden
  zıplayan taş başka hız karesine düşmez.
- Elde 3 kart tutulur; sırada 4. kart çekilir ve bir kart oynanır. Uygun hamle yoksa bir kart atılır.
- Taş sayısı seçilebilir (2–6, varsayılan 4).
- Sayı kartında oyuncu istediği taşı seçer. Ev yolundaki taş yalnızca sayı kartlarıyla ilerler.
- Yer değiştirme ve çarpma yalnızca ana yoldaki taşlara uygulanır; güvenli karedeki rakip taş korunur.
  Yer değiştirmede oyuncunun kendi taşı güvenli karede de seçilebilir (2026-11-17, tablet denemesi).
- Güvenli olmayan karede kendi taşının üstüne konulamaz.
- Deste (50 kart, güncel adetler `data/tuning.json`'da): İleri 1–12 (toplam 34), Geri 3 (3), Geri 5 (2), Çıkış (4), Yer değiştir (2), Geri yolla 8 (2), Kısayol (1),
  Joker (2, 1–6 arası) (2026-11-18: oyun normalde iki zarla oynandığı için).
- Deste boşalınca sıradaki oyuncu çekmeden önce atılanlar karıştırılıp desteye döner; kısa bir
  animasyon ve karıştırma sesi eşlik eder (2026-11-19). Sayaçlar kart desteden kalkınca düşer,
  atılanlara inince artar.
  - Taş başlangıçtan Çıkış, İleri 6 veya Joker 6 ile çıkar.
  - Geri 3/5 kendi taşını geri götürür (ceza kartı); üstüne geldiği rakibi çarpar.
  - Geri yolla 8 rakip taşı 8 kare geri gönderir. Taş kendi renginden bir taşın üstüne düşecekse
    kart o taşa oynanamaz; oyuncu başka taş, o da yoksa başka kart seçer.
  - Kısayol taşı ev yolu girişine götürür.

## Simülasyon (bot × bot, kurulum başına 50 oyun, bitmeyen yok)
| Oyuncu × taş | Oyuncu başına tur |
|---|---|
| 2 × 2 | 29 |
| 2 × 4 | 56 |
| 2 × 5 | 74 |
| 3 × 4 | 55 |
| 4 × 4 | 52 |
| 4 × 5 | 68 |

## Açık konular
- Hangi ek temaların olacağı kararlaştırılmadı. Ayarlar ekranında tema seçimi yok; şimdilik tek
  tema (`classic`) olduğu için gerek yok, ikinci tema gelince eklenecek.
- AdMob (2026-11-19): eklenti Poing Studios `godot-admob-plugin` v5.1.0 `addons/admob` altında,
  `editor_plugins` ile açık. Android ikilileri `addons/admob/android/bin` altında (gitignore'daki
  `android/` kalıbı yüzünden depoya girmez; yeni klonda eklenti kendisi indirir). iOS kapalı;
  `addons/admob/ios/bin/package.gd` yer tutucusu iOS indirmesini engeller. Eklentinin örnek,
  belge ve varlık klasörleri dışa aktarmadan hariç. Godot editörü her açılışta `project.godot`
  başlığını kendi İngilizce metniyle yeniden yazıyor.
  - Kod: `AdMobBackend` (UMP rızası → `MobileAds` başlatma → alt banner, geçiş ve ödüllü reklamı
    önceden yükleme). Kimlikler ve içerik sınıfı (`T`) `data/ads_config.tres` içinde; şimdilik
    Google test kimlikleri. Banner yüksekliği kadar bütün sütun (`AspectColumn.bottom_inset`)
    yukarı kayar. Geçiş reklamı kazanma ekranındaki Tekrar Oyna / Ana Menü düğmelerinde gösterilir.
  - Oyun içi reklam (2026-11-19): oyunlar 15 dakikayı bulabildiği için oyun süresi her 5 dakikayı
    (`ads.interstitial_interval_sec`) doldurunca, insan oyuncunun sırası başlamadan hemen önce
    geçiş reklamı çıkar. Öncesinde reklam anı (`last_ad_at`) kayda yazılır, saat reklam boyunca
    durur; uygulama reklamda kapanırsa oyun aynı yerden sürer ve reklam orada yeniden çıkmaz
    (kayıt sürümü 3). Son 2 dakikada (`ads.end_ad_cooldown_sec`) oyun içi reklam gösterildiyse oyun
    sonu reklamı atlanır. Reklam öncesi uyarı yok. İnternet izinleri (INTERNET, ACCESS_NETWORK_STATE,
    AD_ID) normal izindir, kurulumda verilir; oyuncuya sorulmaz.
    Ayarlarda "Gizlilik Seçenekleri" düğmesi yalnızca rıza gereken bölgelerde görünür
    (`MenuBlueButton` stili seçildi).
  - Gerçek reklam yalnızca Gradle'lı ön ayarlarda çıkar; `/ty` hızlı (Gradle'sız) ön ayarı
    kullandığı için tablette sahte sağlayıcı çalışır. Tablette denemek için "Android APK" ön ayarı
    gerekir.
  - Açık: AdMob hesabında uygulama açılınca gerçek uygulama kimliği (`admob/general/android/app_id`)
    ve birim kimlikleri yazılacak; ödüllü reklamın ödülü ve düğmesi belli değil; banner yüklenemezse
    yeniden denenmiyor.
- Reklamları kaldırma satın alması (`remove_ads`, tek seferlik ürün): resmî GodotGooglePlayBilling
  3.3.0 eklentisi (`addons/GodotGooglePlayBilling/`, `PlayBillingBackend`, yanıtları
  `BillingResponse` okur). Satın alınınca banner ve geçiş reklamları (oyun içi 5 dakika ve oyun
  sonu) kalkar, ödüllü reklam kalır. Düğme ana ekranda menünün altında (`GhostButton`, kurulum ekranındaki adım satırıyla aynı lacivert dolgu) ve
  ayarlar penceresinde (`MenuBlueButton`); fiyat Play'den gelince düğmede yazar, ürün alınınca
  düğmeler gizlenir. Ayrı geri yükleme düğmesi yok; satın almalar her açılışta Play'den okunur.
  Sahip olunan ürünler `SaveStore`'da da tutulur (internet yokken reklam gizli kalsın diye); iade
  edilen ürün bir sonraki okumada düşer. Tamamlanan satın alma onaylanır (onaylanmayan 3 günde
  iade edilir); bekleyen (PENDING) ödeme ürün vermez.
  - Play Console'da `remove_ads` ürünü açıldı (2026-11-19): satın alma seçeneği `buy`, "Eski
    sürümlerle uyumlu", 174 ülke. Fiyat: müşteri Türkiye'de 49,99 TL görür (Play'e girilen fiyat
    vergisizdir, KDV üstüne eklenir), diğer ülkeler 3,29 USD tabanlı. Ürün simgesi
    `store/pawnic/remove-ads-512.png`. Ürün açılabilmesi için BILLING izinli bir AAB'nin bir kanala
    yüklenmiş olması gerekir. Gerçek satın alma yalnızca Gradle'lı ön ayarla ve Play'den (dahili
    test, lisans test hesabı) yüklenen sürümde denenebilir; telefonda denendi, doğru çalışıyor.
- Yükleme anahtarı `C:\Users\Lenovo\keys\pawnic-upload.jks` (takma ad `upload`), yolu ve şifresi
  `.godot/export_credentials.cfg` içinde. Play App Signing açık. 2 (1.1.0) dahili test kanalına
  yüklendi; içinde mağaza görselleri vardı (yaklaşık 18 MB). `store/` klasörüne `.gdignore` eklendi,
  3 (1.2.0) görselsiz derlendi.
  4 (1.3.0) satın alma (BILLING) izniyle derlendi ve dahili test kanalı için Play'e verildi;
  `remove_ads` ürünü bu sürümden sonra açılabilir. Yerel `build/` klasörüne `.gdignore` kondu (deneme
  görüntüleri pakete giriyordu); klasör depoda olmadığı için yeni makinede yeniden konmalı.
- Play: `android.hardware.screen.portrait` uyarısı (dikey yön bu özelliği dolaylı zorunlu yapıyor)
  4 (1.3.0) yüklenirken "çözmeyi planlıyorum" ile yoksayıldı. `addons/portrait_feature` dışa
  aktarma eklentisi (2026-11-19) özelliği manifeste `android:required="false"` ile yazar; sonraki
  AAB'de uyarı çıkmamalı.
- Play beyanları AdMob'a göre güncellendi (2026-11-19): Reklam kimliği "Evet" (Analiz, Reklam veya
  pazarlama, Sahtekarlığı önleme), Reklamlar "Evet", Veri güvenliği formunda yaklaşık konum,
  kilitlenme günlükleri, teşhisler, diğer performans verileri, uygulama işlemleri ve cihaz
  kimlikleri toplanıyor ve paylaşılıyor (zorunlu, aynı üç amaç; aktarımda şifreli; hesap yok).
  Hedef kitle 13 ve üstü. `store/pawnic/privacy.html` bunlara göre yeniden yazıldı (AdMob, Play
  satın alması, Gizlilik Seçenekleri). Açık: yeni sayfa sezertanci.github.io/pawnic/privacy.html'e
  yayımlanacak.
- İki oyunculu oyunda ilk oynayanın küçük bir avantajı var (2026-11-18 ölçümü: %52,8'e %47,2).
  Şimdilik dokunulmadı; gerekirse ilk oyuncu kura ile seçilebilir.
- Yeni tahta tasarımları (ör. köşeden eve bağlantı) ve birden fazla tahta olup olmayacağı belli değil.
- Kısayol kartı tahtada tanımlı kısayol karesine götürür; dallanan tahtalarda anlamı yeniden
  düşünülmeli.

## Günlük
- **2026-11-17:** Proje başlatıldı. Kural motoru, bot, tahta çizimi, kurulum ve oyun ekranı,
  elden ele geçiş ve kazanan ekranı yazıldı. Simülasyon ve gdlint temiz. Debug APK alındı;
  tablete yükleme tabletin onay kısıtına takıldı.
- **2026-11-17 (2):** Prototip tablette denendi, kullanıcı iyi buldu ama değişiklikler olacak.
  Geri yolla 8 kuralındaki boşluk kapatıldı (aynı renkten iki taş normal karede üst üste kalabiliyordu).
- **2026-11-17 (3):** Ürün temeli kuruldu. Paket adı değişti, 8 dil eklendi, arayüz sahnelere
  bölündü (kurulum, oyun, ortak bileşenler), tema ve arayüz teması kuruldu. Autoload'lar:
  `Tuning`, `SaveStore`, `Localization`, `Skins`, `Ads`, `Iap`. Yarım oyun kaydı ve "Devam et"
  eklendi. GUT ile 25 birim testi yazıldı, hepsi geçiyor. Gradle şablonu kuruldu; APK ve AAB
  hazır ayarları eklendi.
- **2026-11-17 (4):** Tahta grafa taşındı (`BoardLayout`, `data/boards/classic.json`). Konumlar
  kare indeksiyle tutuluyor, kayıtta kare adlarıyla yazılıyor (`SAVE_VERSION` 2). Hamleler varış
  karesini taşıyor; yol ayrımında "kare seç" adımı eklendi. Dallanan deneme tahtasıyla testler
  yazıldı; 38 testin hepsi geçiyor, simülasyon sonuçları değişmedi.
- **2026-11-17 (5):** Taş hareketleri canlandırıldı: kare kare zıplama (kare başı 0,12 sn, altında
  gölge), hız karesinde kısa duraklama, çarpılan taşın başlangıca uçması, yer değiştirmede iki taşın
  kayması, eve varışta büyüme. Süreler `tuning.json` içindeki `animation` bölümünde. Hamle yolu
  kurallarda hesaplanıyor (`BoardState.move_path`), animasyon zaman çizelgesi `PawnAnimation`.
  48 testin hepsi geçiyor.
- **2026-11-17 (6):** Onaylanan kart taslağı oyuna eklendi. Sol altta deste (kalan kart sayısıyla),
  sağ altta atılanlar. Kart çekme (kalkışta açılan kart), insan kartının ortada büyüyüp atılanlara
  inmesi, botun kartının üstten gelip kendi renginde çerçeveyle gösterilmesi (`CardAnimator`).
  Kabarık kareler, kalınlıklı ve ışıklı taşlar, yelpaze kartlar, üstte sıra noktaları. Süreler
  `tuning.json` içindeki `cards` bölümünde. 50 testin hepsi geçiyor.
- **2026-11-17 (7):** Yer değiştir kartı (yeşil ve kırmızı taş, karşılıklı oklar) ve +6 kartı (taş,
  yukarı ok, "+6") yazı yerine sembolle çiziliyor (`CardSymbol`, renkler `ui_theme.tres` içinde).
  Bot kartındaki köşeli çerçeve yerine sağ üst köşede bot renginde rozet var. Tablet testleri için
  Gradle'sız "Android APK (hızlı)" ön ayarı eklendi (yalnızca arm64, ~12 sn); Gradle'lı ön ayarlar
  Play için kalıyor.
- **2026-11-17 (8):** Kalan kartlar da sembolle çiziliyor: Çıkış (kutudan dışarı çıkan taş ve ok),
  Geri yolla (kırmızı taş, dönen ok, "-8"), Kısayol (yeşil ev), Joker (sarı yıldız, "1–6"). Yalnızca
  sayı kartları (+1, -3 …) yazılı kaldı.
- **2026-11-17 (9):** Başla'ya basınca sol üstte kısa süre kart karılıyormuş gibi görünmesi düzeltildi:
  ilk tur, ekran düzeni kurulmadan başladığı için kartlar sıfır konumdan uçuyordu; tur artık bir kare
  sonra başlıyor.
- **2026-11-17 (10):** Deste ve atılanlar tahtanın üstüne taşındı, altta yalnızca el kaldı. Oynanan kart
  ortada büyümeden doğrudan atılanlara iniyor; botun kartı desteden açılarak atılanlara gidiyor.
  Atılanların üstündeki kartta son atanın renginde rozet kalıcı (kayıtta `last_discard_seat`).
  Üstteki "Sıra: …" yazısı ve son hamle satırı kaldırıldı; sıra noktaları sağ üstte kaldı.
- **2026-11-17 (11):** İpucu yazı satırı ve işe yaramayan Vazgeç tuşu kaldırıldı. Joker sayı düğmeleri elin
  yerinde çıkıyor. Oynanabilir kart yokken kartların sol üst köşesinde kırmızı daire içinde beyaz çarpı var.
- **2026-11-17 (12):** Joker sayılarının sağında geri oku var. Bot sırasında ve taş yürürken el kaybolmuyor,
  soluk ve basılamaz kalıyor (birden çok insan oyuncuda el yine gizli). Güvenli kareler açık mavi ve
  üzerlerinde kalkan var (çıkış kareleri oyuncu rengini korudu, kalkanı da aldı). Hız kareleri karışık
  değerli (+3…+6, -1…-4); eksi değerde taş geri gidiyor. Başlangıç alanına dokununca içinden taş seçiliyor,
  seçilebilir taşı olan alan çerçeveleniyor. Kısayol karesinde oyuncu renginde saydam ev var. Sesler eklendi
  (`Sound` autoload'u, `tools/make_sounds.py`): düğme ve taş dokunuşu, her zıplamada adım, kısayolda
  ışınlanma. Ses açma/kapama ayarı yok. `_boost_path` içindeki tipsiz `[]` dönüşü düzeltildi (ekran
  görüntüsü betiğindeki "Array[int]" hatasının kaynağı).
- **2026-11-17 (13):** Yer değiştirmede de ışınlanma sesi çalıyor. Kart desteden çekilirken yumuşak bir
  fışırtı sesi var. Kısayol karesindeki ev kalkan boyutunda. Hız kareleri düzensiz dizildi (karşılıklı
  kenarlardaki desen kalktı). Kısayolda taş zıplamadan yol üstünden kayıyor, arkasında oyuncu renginde
  ışık kuyruğu kalıyor; ışınlanma sesi kayma süresince (0,6 sn) çalıyor.
- **2026-11-17 (14):** Yer değiştirmede iki taş ana yolda kısa yönden birbirine doğru kayıyor (biri
  ileri, öteki geri), ikisinin de ışık kuyruğu var; kuyruk son 0,36 sn'lik yolu gösteriyor (`trail_sec`).
  Kısayol ve yer değiştirme aynı kayma süresini (1,2 sn) kullanıyor (`slide_sec`, `swap_sec` kaldırıldı).
  Kısayol karesi açık yeşil, üstündeki ev koyu yeşil ve kalkandan geniş (`shortcut_color`,
  `house_color`; `shortcut_alpha` kaldırıldı). En çok 6 taşla oynanabiliyor. Sol üstte geçen süre
  (05:33, bir saati geçince 1:05:33) gösteriliyor; süre kayda yazılıyor, devam edilen oyunda kaldığı
  yerden sayıyor. Joker sayıları el kartlarının 0,7 boyunda küçük kartlar; seçilen sayı joker
  kartının üst bölümünde görünüyor, geri oku düz düğme. Tablete kurulmadı.
- **2026-11-17 (15):** Işınlanma kayması 1,2 sn'ye çıktı (ses ve kuyruk da aynı oranda uzadı). Botun
  açtığı joker kartında ve atılanlar yığınındaki jokerde seçilen sayı üst bölümde görünüyor; sayı
  oyunda `top_discard_value` olarak tutuluyor ve kayda yazılıyor.
- **2026-11-17 (16):** Kısayol karesindeki ev, kısayolun sahibi olan oyuncunun renginde çiziliyor
  (`house_color` kaldırıldı); karenin kendisi o rengin açık tonu (`shortcut_lighten`, `shortcut_color` kaldırıldı). Çıkış sayısı kartı (+6) taş ve yukarı ok yerine çıkış kartındaki kutu
  simgesini gösteriyor, altında sayı yazıyor.
- **2026-11-17 (17):** Işınlanma kayması 1,8 sn'ye çıktı; kuyruk 0,54 sn, ışınlanma sesi de 1,8 sn.
- **2026-11-17 (18):** Ana ekran tasarlandı: büyük logo ve dört renkli taş, Devam et (yeşil) / Yeni oyun (mavi) / Nasıl oynanır düğmeleri; kurallar ayrı katmanda. Arka planda kenarda soluk kareli yol ve üstünde zıplayarak dolaşan dört taş (`HomeBackdrop`). Mod, oyuncu ve taş seçimi geri düğmeli ayrı "Yeni oyun" ekranına taşındı. Oyun ekranının sol üstüne geri düğmesi eklendi: oyunu bitirmez, ana ekrana döner, geçen süre kaydedilir, devam edilince o sıra baştan oynanır. Taş/kare çizimi `BoardPainter` içinde ortaklaştı. Temaya `PrimaryButton`, `SecondaryButton`, `GhostButton`, `IconButton`, `LogoLabel`, `HeadingLabel`, `OptionsPanel`, `WideMargin` eklendi.
- **2026-11-18:** Deste iki zar oranında İleri 2–12 oldu (İleri 1 kalktı). İleri ve geri kartlarında
  sayı, Titan One yazı tipiyle (OFL, `assets/fonts/`) iri, koyu konturlu ve gölgeli çiziliyor; ileri
  yeşil, geri kırmızı (`CardSymbol` temasında `forward_color`, `back_color`, `number_font`). Geri
  kartlarında eksi işareti gerçek eksi (−).
  Tahtadaki hız karelerinde de aynı iri sayı çiziliyor; ortak çizim `BigNumber` sınıfında.
  Sayılı sembollü kartlarda (çıkış +6, geri yolla −8, sayısı seçilmiş joker) üstte iri sayı, altta
  yarı boyda sembol var. Geri yolla sembolü: kırmızı taşı sağ üstten sağ alta dolaşan kalın eliptik ok.
- **2026-11-18 (2):** Kod incelemesi düzeltmeleri. Logo, kazanma ekranı ve konfeti değerleri
  `tuning.json` içindeki yeni `effects` bölümüne taşındı. Hamle animasyonunu kurma işi `BoardView`
  içinden `MoveAnimationBuilder` sınıfına ayrıldı. Tipsiz sözlükler tipli `Dictionary` oldu.
  Kullanılmayan kod (`is_animating`, `TITLE` çevirisi) silindi. Kurallardaki hız simgesi tahtadaki
  hız karesiyle aynı iri sayıyla çiziliyor (`BigNumber.draw_speed`, ortak).
- **2026-11-18 (3):** Bot zorluk seviyeleri. `Bot` artık seviyeli bir nesne; değerlendirme
  `BotEvaluator`, rakip tahmini `RivalForecast` sınıfında. Ayarlar ve yeni oyun ekranının seçim
  düğmeleri ortak `ChoiceButtons` yardımcısını kullanıyor. Seviyeleri birbirine karşı ölçen
  `tools/level_ladder.gd` eklendi. Kart saklama değerleri ölçümle dörtte birine indirildi
  (eski değerlerle Çok zor, Zor'a %44 kaybediyordu).
- **2026-11-18 (4):** Zor ve Çok zor güçlendi, hile eklenmedi. Yeni sınıflar: `CardOdds`
  (görünmeyen kartların dağılımı), `RolloutSearch` (Monte Carlo arama). `BotEvaluator` nesne oldu,
  tehdit okuyor. `GameMatch.unseen_cards` ve `determinized` eklendi. `Bot` artık seviye yerine
  `BotProfile` alıyor. Bot hamlesi arka plan iş parçacığında düşünülüyor. Testler
  `tests/unit/test_bot_reading.gd` (88 test geçiyor). Tablete kuruldu.
- **2026-11-18 (5):** Arayüz düzeltmeleri. Çıkış kartında başlangıç tepsisinin dalga ışığı tepsi
  gibi yuvarlak köşeli (`PulseWave.draw_frame` köşe yarıçapı alıyor). Atılanlar yığınının altında
  "Atılanlar" yerine deste gibi kart sayısı yazıyor (ortak `PILE_COUNT`, `GameMatch.discard_count`).
  Üst çubukta seviye "/" ile ayrılıp kendi renginde yazıyor. "Çok Zor" ve "Oyun Hızı" büyük harfe
  düzeltildi (oyuncuya görünen kısa etiketlerde her kelime büyük harfle başlar). Tanıtım ekranının
  açıklama yazısı daha büyük ve parlak (`DemoLabel`, 34 punto, beyaz, gölgeli).
- **2026-11-19:** Play mağaza dosyaları `store/pawnic/` altında: gizlilik politikası
  (sezertanci.github.io/pawnic/privacy.html'de yayında), tr/en mağaza metinleri, 512 simge, öne
  çıkan görsel (simge, tahta ve oyunun kendi çizdiği beş kart) ve ekran görüntüleri. Joker sayı
  seçenekleri ileri kartları gibi çiziliyor (`CardSymbol` ile yeşil, + işaretli). Arayüz
  düzeltmeleri tablete kuruldu; joker değişikliği yalnızca PC'de denendi.
- **2026-11-19 (2):** İkiden fazla oyunculu oyunda bitiren oyuncu oyunu bitirmiyor, kalanlar oynamaya
  devam ediyor. Bitiren için tahtada kısa yazı ve konfeti çıkıyor ("Kırmızı 1. Oldu!",
  `finish_banner_sec`), elindeki kartlar atılanların altına gidiyor, sıra noktalarında artık
  görünmüyor. Tek oyuncu kalınca ya da bütün insanlar bitirince (yalnızca botlar kalınca) oyun
  biter; bitirmeyenler tahtadaki ilerlemelerine göre sıralanır. Kazanma ekranında sonuç tablosu
  var: sıra, taş, ad ve bitirdiği tur (bitirmeyende "—"). Kural tarafı `GameMatch.finishers`,
  `finish_rounds`, `round_number` ve `MatchResult`; bot önceden bitirmiş rakipleri hesaba katmıyor.
  Kayıt sürümü değişmedi, eski kayıtlar varsayılanlarla açılıyor. Birim testleri yazıldı (95 test
  geçiyor). Duyuru ve sonuç tablosu, okunsun diye oyuncunun renginde buzlu cam panelin üstünde
  (`FrostedGlass` artık kendi malzemesini kuruyor). Botsuz oyunda başlığın sağa toplanması
  düzeltildi: boşluğu artık seviye yazısı değil, ayrı bir `Spacer` dolduruyor. Tablete kuruldu,
  sonuç tablosu tablette görüldü.
- **2026-11-19 (3):** Başlangıç tepsisinde her taş için, oyun başındaki taş sayısı kadar altlık var:
  taş tabanıyla aynı eğimde %60 saydam siyah elips (`BoardSkin.socket_color`,
  `BoardPainter.base_ellipse`). Taş çıkınca yeri boş altlık olarak görünüyor. Ferah dursun diye
  altlık taş tabanının 0.9 katı (`SOCKET_SCALE`) ve tepsideki yerler 0.2 kare yukarıda
  (`BASE_LIFT`). Dört renk ve dört aralık denemesinden seçildi, tablette görüldü.
