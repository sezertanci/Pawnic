# Pawnic — ilerleme

## Kararlar
- Ad: **Pawnic**. Kart tabanlı yarış tahtası; zar yok, strateji var. Hedefe ilk varan kazanır, süre yok.
- Aynı telefonda 2–4 kişi. Bot yalnızca tek oyunculu modda. Sunucu yok; aynı yerel ağda çok
  oyunculu oyun geliştiriliyor (yol haritası aşağıda).
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
- İkinci tema ahşap masa (`wood`), üçüncüsü gece neon (`neon`), görünüm ekranıyla birlikte
  `feature/wood-theme` dalında. Renkler tablette görülerek son kez kontrol edilecek.
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
    ve birim kimlikleri yazılacak; banner yüklenemezse
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
  6 (1.5.0) ağ oyununu telefonlarda denemek için hazırlandı (2026-11-20): üç ön ayarda ağ
  izinleri (`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`,
  `CHANGE_WIFI_MULTICAST_STATE`) açık. Bu sürümde sıra süresi ve kopmada bot yok (parça 2 ve 3);
  kopan oyuncu oyunu takar. Android çoklu yayın kilidi (`MulticastLock`) yok; bazı telefonlarda
  oyun bulma çalışmayabilir, bu sürümde denenecek.
- Play: `android.hardware.screen.portrait` uyarısı (dikey yön bu özelliği dolaylı zorunlu yapıyor)
  4 (1.3.0) yüklenirken "çözmeyi planlıyorum" ile yoksayıldı. `addons/portrait_feature` dışa
  aktarma eklentisi (2026-11-19) özelliği manifeste `android:required="false"` ile yazar; sonraki
  AAB'de uyarı çıkmamalı.
- Play: 6 (1.5.0) yüklenirken `android.hardware.wifi` uyarısı çıktı (Wi-Fi izinleri bu özelliği
  dolaylı zorunlu yapıyor). Aynı eklentiye bu özellik de eklendi (2026-11-20); düzeltme bir sonraki
  AAB'de (sürüm 7) geçerli olur.
  7 (1.6.0) ağ oyununun sıra süresi, kopma/geri dönme, duraklatma, Tekrar Oyna ve kurucu kaybı
  uyarısıyla hazırlandı (2026-11-21); telefonlarda ve Play sürümünde reklamlarla denenecek.
- Play beyanları AdMob'a göre güncellendi (2026-11-19): Reklam kimliği "Evet" (Analiz, Reklam veya
  pazarlama, Sahtekarlığı önleme), Reklamlar "Evet", Veri güvenliği formunda yaklaşık konum,
  kilitlenme günlükleri, teşhisler, diğer performans verileri, uygulama işlemleri ve cihaz
  kimlikleri toplanıyor ve paylaşılıyor (zorunlu, aynı üç amaç; aktarımda şifreli; hesap yok).
  Hedef kitle 13 ve üstü. `store/pawnic/privacy.html` bunlara göre yeniden yazıldı (AdMob, Play
  satın alması, Gizlilik Seçenekleri). Yeni sayfa sezertanci.github.io reposundan
  yayında (`pawnic/privacy.html`).
- (Kapandı) İki oyunculu oyunda ilk oynayanın küçük avantajı (2026-11-18 ölçümü: %52,8'e %47,2)
  artık sorun değil: başlayan oyuncu hem yerel hem ağ oyununda kurayla seçiliyor (`MatchStarter`).
- Yeni tahta tasarımları (ör. köşeden eve bağlantı) ve birden fazla tahta olup olmayacağı belli değil.
- Kısayol kartı tahtada tanımlı kısayol karesine götürür; dallanan tahtalarda anlamı yeniden
  düşünülmeli.

## Yerel oyunda renk seçimi (karar 2026-11-20, uygulandı)
- Renk koltuktan ayrılır: oyuncu yine altta oturur, yalnızca taşlarının ve alanlarının rengi
  değişir. Oyun başına "koltuk → renk" eşlemesi tutulur; bütün çizim (`seat_color` çağrıları) tek
  yardımcıdan geçer. Kural motoru, bot ve simülasyon koltuk numarasıyla çalışmaya devam eder.
- Renk yalnızca tek oyunculu modda, kurulum ekranında seçilir; son seçim tercih olarak saklanır
  (varsayılan bugünkü renk, yeşil). Botlar kalan renkleri sırayla (kırmızı, mavi, yeşil, sarı
  sırasıyla, seçileni atlayarak) alır.
- Aynı telefonda çok oyunculu modda renk seçimi yok; oyuncular hangi renkte oynamak isterse o
  rengin sırası geldiğinde oynar.
- Renk eşlemesi kayda girer, `SAVE_VERSION` artar; yarım kalmış eski oyunun yüklenmemesi kabul
  edildi.
- Ağ oyununda tahta yönü kararını kolaylaştırır (renk koltuktan ayrılmış olur).
- Kim başlar (yerel oyunda da): ağ oyunundaki gibi kura. Oyun başında renkler döner, rastgele
  birinde durur; o başlar, sıra saat yönünde sürer. Tek oyunculuda da aynı telefonda çok
  oyunculuda da geçerli. İlk oynayanın küçük avantajını (%52,8'e %47,2) dengeler. Uygulamada dikkat:
  `GameMatch.next_turn()` turu artık sıra başlayan oyuncuya (`GameMatch.starter`) dönünce
  artırıyor; başlayan kayıtta tutulur.
- Uygulama: eşleme `SeatColors` ve `GameMatch.colors`, tercih `PlayerColor` autoload'u,
  `SAVE_VERSION` 4. Kura ayrı katmandadır (`StarterDraw`): ekran kararır, ortada "Kim Başlıyor?"
  başlığıyla oyuncuların taşları sırayla döner, yavaşlar, başlayanda durur ve "Sarı Başlıyor!"
  gibi sonucu yazar. Süreleri `tuning.json` → `animation.starter_spin_*`. Kura yalnızca yeni oyunda
  (devam edilen oyunda değil) oynar; sürerken el boştur ve saat durur. Tablette denenmedi.

## Yol haritası: aynı ağda çok oyunculu (taslak, 2026-11-20)
Uygulamaya 2026-11-20'de `feature/lan-multiplayer` dalında başlandı, 2026-11-21'de `main`'e
birleştirildi (QR ve elle IP ile katılma yapılmadı); "Sunucu ve ağ yok" kararı
"sunucu yok, yerel ağ var" olarak güncellendi. Sunucu gerekmez; bir cihaz oyunu kurar (host),
diğerleri katılır. İş sırası kolaydan zora: tahtanın döndürülerek çizilmesi, sıra akışının ayrı
sınıfa taşınması (Aşama 1), mesaj biçimi ve sahte taşıyıcı, sonra Aşama 2–4.

**Yapılanlar**
- Tahtanın döndürülerek çizilmesi (2026-11-20): `BoardTurn` (scripts/ui) koltuğun başlangıç
  alanını alta getiren çeyrek tur sayısını tahtanın geometrisinden hesaplar; `BoardView.bottom_seat`
  verilince tahta döner (yalnızca konumlar; taşlar, sayılar, tepsiler dik kalır). Tepsiler yatay
  kaldığı için dosyadaki yerleri köşeye göre ayarlıdır; döndürmede tepsi, ekranda o köşeye düşen
  koltuğun dosyadaki tepsi yerine konur (`BoardTurn.base_center`), görünüm döndürmesizle aynı kalır. Varsayılan
  `NO_SEAT`, yani yerel oyunda döndürme yok; ağ oyununda her cihaz kendi koltuğunu verecek.
  Birim testleri `test_board_turn.gd`'de; dört koltuk için ekran görüntüsüyle denetlendi.
- Sıra akışının hakeme taşınması (2026-11-20): `MatchReferee` (scripts/match, Node) sırayı,
  botları, kaydı, saati ve geçiş reklamının zamanını yürütür; olanları `MatchEvent` olarak yayar
  (RESHUFFLED, AD_DUE, TURN_STARTED, CARD_REVEALED, MOVE_PLAYED, DISCARDED, PLAYER_FINISHED,
  MATCH_OVER) ve her olaydan sonra ekranın `acknowledge()` çağırmasını bekler. Oyuncunun seçimi
  `MatchIntent` (PLAY/DISCARD, koltukla) olarak `submit()` ile gelir; hakem sırayı ve hamlenin
  yasallığını (`Move.equals`) denetler. `GameScreen` yalnızca olayları çizer; reklamı gösterir ama
  zamanına hakem karar verir.
  Küçük fark: reklam kaldırılmış olsa da reklam zamanı (`last_ad_at`) kaydedilir; görünür etkisi yok.
  Hakem bir niyeti reddederse durum değişmez; ekran uyarı yazar, seçimi temizler ve hakem hâlâ o
  oyuncuyu bekliyorsa sırayı yeniden açar (yerel oyunda seçici yalnızca yasal hamle verdiğinden
  olmaz; ağ oyununda REJECTED mesajı gider).
  Birim testleri `test_match_referee.gd` ve `test_game_screen_intent.gd`'de; simülasyon ve ekran
  görüntüsüyle denetlendi; tablette yerel oyunda hata görülmedi.
- Mesaj biçimi ve sahte taşıyıcı (2026-11-20, yerel oyuna dokunulmadı): `Move`, `MatchIntent` ve
  `MatchEvent` sözlüğe çevrilir (`to_dict`/`from_dict`); gelen veri `MessageData` ile savunmacı
  okunur, bozuk alan null döner. Olaya açılan/çekilen kart, tur ve hakemin saati eklendi; çekilen
  kart yalnızca çekene yazılır. `MatchView` istemcinin kopyasıdır: oyun başında ve yeniden
  bağlanmada tamamı (SNAPSHOT) gönderilir, sonra olaylar `apply()` ile uygulanır; hamle kopyanın
  tahtasında yasal değilse ya da kart uyuşmazsa `apply()` false döner ve istemci SNAPSHOT_REQUEST
  ile tamamını yeniden ister. Zarf `MatchMessage` (`{"t": tür, "d": içerik}`; INTENT, EVENT,
  SNAPSHOT, REJECTED, SNAPSHOT_REQUEST). `MatchTransport` arayüzü ve aynı süreçte eşleri bağlayan
  `FakeTransport` (mesaj baytlara çevrilip nesnesiz okunur, bir kare sonra ulaşır). Olay bekleme:
  host yalnızca kendi ekranını bekler; geride kalan istemci olayları sıraya alıp oynatır.
  Testler `test_match_messages.gd`, `test_match_view.gd` (iki ve dört kişilik tam oyunda her sıra
  başında bütün kopyalar host'taki oyunla karşılaştırılır) ve `test_fake_transport.gd`'de.
- Host/istemci oturumu ve el sıkışma (2026-11-20, ağsız, yerel oyuna dokunulmadı): `HostSession`
  taşıyıcıyla hakemi bağlar. Eş HELLO (protokol sürümü `MatchMessage.PROTOCOL_VERSION` ve ayar
  özeti `GameSettings.digest` = tuning.json + tahta dosyasının SHA-256'sı) gönderir; uyuşmazsa
  REFUSED (`VERSION_MISMATCH`, "Oyunu güncelleyin"), uyuşursa WELCOME gider. Eş ancak WELCOME'dan
  sonra `seat_peer()` ile koltuğa oturtulur (lobi bunu çağıracak). Niyetteki koltuk alanı yok
  sayılır, eşin koltuğu yazılır; hakem reddederse REJECTED gider. Olaylar her eşe kendi
  görünümüyle, `share_match()` oyun başında görünümün tamamını gönderir, SNAPSHOT_REQUEST'e
  görünümle cevap verilir. `ClientSession` yalnızca HOST_PEER'den gelen mesajı okur, WELCOME'dan
  önce oyun mesajlarını yok sayar, olayı kopyaya uygular; uyuşmazsa görünümü yeniden ister ve o
  gelene kadar olayları atar. Kopyadaki geçen süre yalnızca sıra başında hostla eşitlenir.
  Testler `test_match_sessions.gd`'de (el sıkışma, koltuk, başka koltuk adına niyet, yabancı eş,
  uyuşmayan olay, sahte taşıyıcıyla tam oyun).
  Sonraya kalanlar: oyun ekranının istemcide `MatchView`'dan çizmesi.
- ENet taşıyıcısı (2026-11-20, ekran ve lobi yok, yerel oyuna dokunulmadı): `ENetTransport`
  `ENetMultiplayerPeer`'i doğrudan kullanır (SceneMultiplayer yok), paketleri her karede okur.
  Ayarlar `tuning.json`'daki `network` bölümünde: port 24680, en fazla mesaj 16 KB, eş başına
  saniyede 20 mesaj. Büyük mesaj çözülmeden, sınırı aşan mesaj okunmadan atılır; bağlantı
  kesilmez. Paket nesnesiz çözülür, sözlük olmayan atılır. Host en fazla `max_players - 1` istemci
  kabul eder. Bağlı olmayan eşe mesaj gönderilmez. `MatchTransport`'a `peer_connected` /
  `peer_disconnected` sinyalleri eklendi. `LocalAddress`: `is_private()` (10.x, 172.16–31.x,
  192.168.x), `wifi_address()` (Wi-Fi'deki, yoksa ilk özel IPv4); host ve istemci yalnızca özel
  ağ adresini ya da aynı cihazı (127.0.0.1, yalnızca deneme için) kabul eder. Testler
  `test_enet_transport.gd` (aynı cihazda iki uç) ve `test_local_address.gd`'de.
- Oyun bulma yayını (2026-11-20, ekran yok): `GameAnnouncer` hostun özel ağ adresinden
  255.255.255.255:24681'e saniyede bir ANNOUNCE yayını gönderir (protokol sürümü, oyun portu,
  oyuncu sayısı; oda kodu ve kişisel bilgi yok). `GameFinder` 24681'i her arayüzde dinler (yayın
  her arayüze gelebilir; soket yalnızca okur) ve `FoundGame` listesini tutar, değişince
  `games_changed` yayar. Özel ağ dışından gelen, 16 KB'tan büyük, bozuk, başka protokol
  sürümündeki ya da port/oyuncu sayısı geçersiz yayın atılır; 3 saniye yayını gelmeyen oyun
  listeden düşer. Süreler `tuning.json`'da (`discovery_port`, `announce_interval_ms`,
  `announce_expiry_ms`). Testler `test_game_discovery.gd`'de (aynı cihazda).
  Sonraya kalanlar: gerçek Wi-Fi'da (tablet + bilgisayar) deneme; Android'de `MulticastLock` ve
  izinler (Aşama 4).
- Lobi mantığı (2026-11-20, ekran yok): `HostLobby` her oyun kuruluşunda 4 haneli rastgele oda
  kodu üretir (`room_code_digits`). İstemci kodu HELLO içinde gönderir (`ClientSession.join(kod)`).
  `HostSession.admission` sırayla denetler: oyun başladıysa `MATCH_STARTED`, kod yanlışsa
  `WRONG_CODE`, koltuklar doluysa `ROOM_FULL`; reddedilen eşe REFUSED gider ve bağlantısı kesilir
  (`MatchTransport.kick`). Lobide toplam 10 yanlış denemede (`max_wrong_codes`) yeni kod üretilir
  ve sayaç sıfırlanır. Host oyuncu sayısını (2–4, lobidekilerden az olamaz) ve taş sayısını seçer;
  varsayılanlar 4 oyuncu ve `default_pawns`. Katılan sıradaki yere oturur, ilk boş rengi alır,
  COLOR_CHOICE ile boş bir renge geçebilir (dolu renk reddedilir, lobi ona yeniden gönderilir).
  Her değişiklikte LOBBY (`LobbyInfo`: oyuncu ve taş sayısı, katılma sırasıyla renkler, alıcının
  yeri) herkese gider; ayrılan oyuncunun yeri ve rengi boşalır. `start()` oyunu kurar: host sıra
  düzeninde ilk, katılanlar katılma sırasıyla koltuk alır, boş koltuklara Orta bot oturur, renkler
  `SeatColors.with_choices` ile, başlayan `MatchStarter` ile seçilir (yerel oyun da onu kullanır);
  yeni bağlantı alınmaz (`refuse_new_peers`). ENet'te `kick` kuyruktaki paketler gidince keser
  (`peer_disconnect_later`; anında kesmede ret mesajı kayboluyor, testle görüldü), kesilen eşin
  paketleri okunmaz; host kesince istemci taşıyıcısı kendini kapatır. Kilitli host ENet düzeyinde
  istemciye kısa süre "bağlandı" der ama eşi hemen sıfırlar; host tarafında bağlantı ve mesaj
  görünmez. Testler `test_host_lobby.gd`, `test_lobby_info.gd`, `test_enet_transport.gd`'de.
  Sonraya kalanlar: lobi ekranları (Aşama 2), host ayrılan oyuncuyu başlamadan önce görür ama
  oyun sırasında kopma (20 sn bekleme, bot devralması) henüz yok.
- Lobi ekranları (2026-11-20): Kurulum ekranına üçüncü sekme "Ağda" (ipucu "Aynı Wi-Fi'da")
  eklendi; bu sekmede oyun seçenekleri ve Başla yerine "Oyun Kur" ve "Katıl" düğmeleri görünür,
  ana ekran değişmedi. Ekransız `HostRoom` (oturum, lobi, taşıyıcı ve yayıncı bir arada) ve
  `GuestRoom` (bağlanınca kodla katılır; `refused`, `lost(was_welcomed)`) ekranlardan ayrı ve
  ENet ile uçtan uca test edildi (`test_network_rooms.gd`). `HostLobbyScreen` oda kodunu, oyuncu
  ve taş sayısını, koltuk satırlarını (`LobbyPanel`: dolu satırda taş ve renk adı, kendi satırında
  "Sen", hostunkinde "Kurucu"; boş satır soluk "Bot") ve renk düğmelerini (başkasının rengi kapalı)
  gösterir. Başla görünür ama kapalıdır. `JoinScreen` bulunan oyunları "Oyun 1 · Oyuncu: 2"
  biçiminde listeler (IP gösterilmez), seçilen oyun için oda kodu ister, katılınca aynı lobi
  panelini ve "Kurucunun oyunu başlatması bekleniyor" yazısını gösterir. Bulma portu açılamazsa
  (aynı bilgisayarda ikinci Katıl penceresi ya da portu tutan başka uygulama) ayrı
  `SEARCH_FAILED` mesajı çıkar ve arama yazısı gizlenir. Ret nedenleri ve kopma
  ekranda yazar. Lobi ekranları açıkken ekran kapanmaz. Hosta bağlanma zaman aşımı
  `connect_timeout_ms` (5 sn; bağlanınca ENet'in olağan değerine dönülür); önceden ulaşılamayan
  hostta 30 sn bekleniyordu. Renk düğmesi kurulumu `ChoiceButtons.add_color`'da ortaklaştı; temada
  kapalı yeşil düğme ve kapalı seçim düğmesi soluk görünür, oda kodu alanı için `CodeField` var.
  `tools/screenshot.gd` ağ sekmesini, host lobisini ve katılma ekranını da kaydeder.
  Sonraya kalanlar: Başla ve istemcide oyun ekranı (sonraki adım), elle IP ve QR ile katılma,
  oyun sırasında kopma.
- Ağ oyununun başlaması, parça 1/3 (2026-11-20): Oyun ekranı oyunu artık bir kaynaktan çizer
  (`MatchSource`): yerel oyunda ve hostta `RefereeSource` (hakem), istemcide `ClientSource`
  (hosttan gelen görünüm ve olaylar; olayları ekran bitirene kadar sırada tutar, görünümün tamamı
  gelince sırayı atar). Hostta Başla en az bir katılımcı gelince açılır (varsayım, sorulmadı);
  basınca hakem oyunu başlatır ve görünüm herkese gider, istemcide oyun ekranı ilk görünümle
  açılır. Tahta her cihazda kendi koltuğuna göre döner, hız hostunkidir, ağ oyunu kaydedilmez ve
  oyun içi reklam çıkmaz. Geri tuşu: katılan oyuncuya "Oyundan çıkılsın mı? Yerini bir bot
  alacak." sorulur, onaylarsa koltuğu kalıcı olarak bota geçer (LEAVE); hosta her zaman
  "Oyun herkes için bitecek." sorulur. Host çıkarsa ya da bağlantı koparsa istemcide
  "Kurucu oyunu kapattı." çıkar. Ağ oyunu bitince (ya da çıkınca) yeni oyun ekranının Ağ
  sekmesine dönülür; sonuç ekranında Tekrar oyna gizlenir, ana menü düğmesi "Yeni oyun" olur.
  Ortak onay katmanı `ConfirmOverlay` (`scenes/components/`). Testler `test_match_sources.gd`
  ve `test_confirm_overlay.gd`'de.
  Parça 2 (20 sn sıra süresi) yapıldı (2026-11-21 (2)). Parça 3 (oyun sırasında kopma ve geri
  dönme) yapıldı (2026-11-21 (3)). Ağ oyununda Tekrar oyna yapıldı (2026-11-21 (4)).
  Duraklatma yapıldı (2026-11-21 (5)). Ortak oyun içi reklam yapıldı (2026-11-21 (6)).
  Katılma ekranında "oyun bulunamadı" uyarısı yapıldı (2026-11-21 (7)).

**Kararlar (2026-11-20)**
- Oyuncular: her cihazda bir kişi; boş koltuklara bot konabilir. Bir cihazda birden çok kişi
  (telefonu ver) ağ oyununda yok.
- Ağ oyunundaki botlar (boş koltuk ve kopan oyuncunun yerine geçen) hep Orta seviyede oynar; lobide
  seviye seçimi yok.
- Oyuncu koparsa oyun 20 saniye bekler, sonra koltuğu bot devralır. Oyuncu yeniden bağlanırsa
  koltuğuna geri döner.
- Host koparsa ya da uygulamayı kapatırsa oyun biter; diğerlerine "oyun sona erdi" gösterilir.
- Sıra süresi 20 saniye; dolunca yalnızca o hamleyi bot oynar, koltuk oyuncuda kalır ve sıra
  yeniden gelince oyuncudan hamle beklenir. Yerel oyunda süre yok, değişmez.
- Ağ oyunu kaydedilmez; açılıştaki "Devam et" yalnızca yerel oyun içindir.
- Oyun içi 5 dakika geçiş reklamı ağ oyununda herkeste aynı anda çıkar: zamanı host belirler (insan
  oyuncunun sırası başlamadan önce kuralı korunur), herkes bitirince oyun sürer. Host'ta "Reklamları
  kaldır" varsa o oyunda oyun içi reklam hiç çıkmaz. Oyun sonu reklamı her cihazda kendi kuralıyla.
- Duraklatma (mola için; yalnızca ağ oyununda, yerel oyunda yok): yalnızca host duraklatır ve
  yalnızca host devam ettirir. Bütün ekranlar kararır, "Duraklatıldı" yazar ve altında ne kadar
  süredir durulduğunu gösteren, üst çubuktaki oyun saatiyle aynı biçimde bir sayaç işler; diğerleri oyuna
  müdahale edemez. Süre sınırı yok. Duraklatmada sıra süresi, oyun saati ve 5 dakika reklam süresi
  işlemez.
  - Molada isteyen oyuncu oyundan ayrılabilir; koltuğu bota geçer, bot da oyun devam edene kadar
    oynamaz. Kendi isteğiyle ayrılma kesindir, geri dönülemez (istemeden kopan geri dönebilir).
  - Molada kopma sayılmaz: 20 saniyelik kopma sayacı işlemez; oyuncu devam edilene kadar
    dönebilir, dönmemişse devamda sayaç başlar.
  - Host'un duraklatma ekranında "Telefonu kilitlerseniz oyun bitebilir." uyarısı yazar ve ekran
    açık tutulur. (Karar değişti, 2026-11-21: önceki "Telefonu kilitlemeyin, oyun biter" yazısı
    yumuşatıldı. Tablette host ekranı 20 sn'den uzun kapalı kaldı, açılınca misafir yeniden
    bağlandı ve oyun sürdü; Android uygulamayı kapatır ya da Wi-Fi'yi keserse oyun yine biter.)
- Katılma: otomatik oyun bulma, QR kod ve oda kodu / elle IP; üçü de olacak.
- QR okuma Google'ın kod tarayıcısıyla (Play Hizmetleri, ML Kit "Google code scanner") yapılır;
  uygulama kamera izni istemez. Hazır resmî Godot eklentisi bilinmiyor, küçük bir Godot Android
  eklentisi (AAR) yazılacak; AdMob/Billing gibi yalnızca Gradle'lı derlemede bulunur, başka yerde
  sahte sürüm çalışır. Tarama ekranı Google'ındır (tema yok, dil sistem dilinde). Play Hizmetleri
  yoksa ya da tarama başarısızsa oda koduna yönlendirilir. Modülü kurulumda indirten manifest
  ayarı uygulamadan önce belgelerden doğrulanacak. Gizlilik politikasında kamera kullanımı anılacak.
- Süreler (`20`, `20`) `data/tuning.json` içinde tutulur.
- Oyun hızı: ağ oyununda herkes host'un hız ayarıyla oynar. 20 saniyelik sıra süresi animasyonlar
  bitip oyuncunun eli hazır olunca başlar.
- Ekran: lobi ve ağ oyunu süresince bütün cihazlarda ekran açık tutulur, oyun bitince normale döner.
- Katılım koruması: bulunan oyuna girmek için host ekranındaki kısa oda kodu girilir; QR'da kod
  içinde gelir. Ortak Wi-Fi'da yabancıların katılmasını önler.
- Oyuncular yalnızca renkleriyle görünür; ad girilmez (başkalarına gösterilen kullanıcı içeriği yok).
- "Tekrar oyna": host aynı oyuncularla hemen yeni oyun başlatır; ayrılanların yerine bot girer.
  Ayrıntılar (karar 2026-11-21): aynı oyuncular, renkler, oyuncu ve taş sayısı kullanılır;
  başlangıç kurası yeniden yapılır. Misafirin sonuç ekranında tablonun altında "Kurucunun yeni
  oyunu başlatması bekleniyor…" yazar ve yalnızca "Yeni oyun" (çıkış) düğmesi kalır; host
  başlatınca oyun misafirde kendiliğinden açılır. Katılanların hepsi çıktıysa hostta Tekrar oyna
  gizlenir. Oyun sonu reklamı hostta Tekrar oyna'ya basınca, misafirde yeni oyun gelince ya da
  Yeni oyun'a basıp çıkınca kendi kuralıyla gösterilir. Kopuk oyuncunun koltuğu korunur: 20 sn
  bekleme kaldığı yerden sürer, süre dolduysa koltuğu bot oynar, oyuncu dönünce oturur.
- Bitiren oyuncu oyunu izler, isterse çıkar; çıkması kopma sayılmaz, oyunu etkilemez.
- Geç hamle: host'un saati esastır. İstemcide geri sayım görünür; süre dolunca yarım seçim iptal
  olur, host'a geç gelen hamle reddedilir ve sırayı bot oynar.

**Açık kararlar**

**Tahta yönü ve renkler (karar 2026-11-20)**
- Her oyuncu lobide kendi rengini seçer (yerel renk seçicisi kullanılır, dolu renkler kapalı
  görünür). Botlar kalan renkleri sırayla alır.
- Her cihazda tahta, o cihazın oyuncusu altta kalacak şekilde döndürülerek çizilir. Yalnızca çizim
  dönüşümüdür; kural motoru koltuk numarasıyla çalışır. Yerel oyunda döndürme yok (tek oyunculuda
  oyuncu zaten altta, aynı telefonda çok oyunculuda tahta ortaktır).
- Kim başlar: kura. Oyun başında zar atılır gibi renkler döner, rastgele birinde durur; o renk
  başlar, sıra saat yönünde sürer. Sonucu host'un tohumlanabilir RNG'si belirler ve herkese
  gönderir; bütün cihazlar aynı animasyonu aynı sonuçla oynatır.

**Bilinen riskler ve önlemler (2026-11-20 incelemesi)**
- Sıra akışı şu an `game_screen.gd` içinde (`GameMatch`'i doğrudan yönetiyor). Aşama 1'de ayrı bir
  sınıfa taşınması çalışan yerel oyuna dokunan tek büyük değişikliktir. Aşama 1 ağ kodu olmadan
  yapılır ve yerel oyunun aynı çalıştığı doğrulanmadan (testler, `simulate.gd`, ekran görüntüsü,
  tablet) Aşama 2'ye geçilmez.
- `game_screen.gd` her tur başında ve geri düğmesinde `SaveStore`'a yazıyor, oyun sonunda kaydı
  siliyor. Ağ oyunu bu yoldan geçmemeli; yarım kalan yerel oyunun kaydı korunmalı (testle).
- `bots` yalnızca evet/hayır tutuyor; ağ oyunu için koltuk durumu (uzaktaki insan, geçici bot,
  kalıcı bot) ayrı tutulur, kayıt biçimi ve `SAVE_VERSION` değişmez.
- Ağ oyunu yerel tercihleri (`Difficulty`, `GameSpeed`) değiştirmez.
- Geçiş reklamı açıkken Android Godot'un döngüsünü durdurabilir; reklam izleyen host kopmuş
  sanılabilir. ENet zaman aşımı en uzun reklamdan uzun tutulur, reklam sırasında kopma sayacı durur,
  reklamı yüklenemeyen cihaz için üst süre sınırı olur. Gerçek cihazda denenecek.
- Bağlanırken protokol sürümü ve ayar/tahta özeti karşılaştırılır; uyuşmazsa "Oyunu güncelleyin".
- Mesajlarda metin değil çeviri anahtarı gönderilir; her cihaz kendi dilinde gösterir.

**Güvenlik**
- Port yalnızca lobi ve oyun süresince açık; yalnızca Wi-Fi adresinde dinlenir (her arayüzde
  değil; mobil veride dışarıdan erişilebilir IPv6 olabilir).
- Gelen her mesaj güvenilmez veridir: nesne çözme kapalı (`allow_object_decoding` false,
  `bytes_to_var_with_objects` yok), boyut ve sıklık sınırı, en fazla 3 istemci, oyun başlayınca yeni
  bağlantı reddi, bozuk mesaj çökertmez (`from_dict` gibi savunmacı okuma).
- Host, niyetin sırası gelen koltuktan geldiğini ve `legal_moves()` içinde olduğunu doğrular;
  istemci de host'tan geleni doğrular.
- İstemciye yalnızca kendi eli gider. Host bütün elleri bilir; değiştirilmiş uygulamayla host hile
  yapabilir, yerel arkadaş oyunu için kabul edildi.
- QR ve oda kodu da güvenilmez veridir; yalnızca özel ağ adreslerine (192.168.x, 10.x,
  172.16–31.x) bağlanılır.
- Oyun bulma yayınında kişisel bilgi (cihaz adı, hesap) yok; yalnızca protokol sürümü, port,
  oyuncu sayısı.
- ENet trafiği şifresiz; yalnızca hamle verisi taşındığı için ilk sürümde kabul edildi.

**Aşama 1: Hakem/istemci ayrımı (ağsız)**
- `GameMatch` yalnızca host'ta çalışır; istemci yalnızca niyet gönderir (kart, taş, yol ayrımında
  kare). Host doğrular, uygular, olayları yayar.
- Niyet, olay ve durum için ağdan bağımsız mesaj biçimi; her oyuncuya yalnızca kendi eli gider.
- Taşıyıcı arayüzü (`AdsBackend` gibi) ve aynı süreçte çalışan sahte taşıyıcı; GUT testleri.
- Oyun ekranı yerel oyun ile ağ oyununu aynı olay akışından çizer.

**Aşama 2: Bağlantı ve lobi**
- `ENetMultiplayerPeer` ile gerçek taşıyıcı.
- Oyun bulma: `PacketPeerUDP` yayını; yedek olarak QR/elle IP.
- Lobi sahneleri: Oyun kur / Katıl, bulunan oyunlar, bekleyen oyuncular, renk seçimi, Başlat.
  `main.gd` geçişleri; yeni metinler 8 dilde. (Başlat dışında yapıldı, 2026-11-20.)

**Aşama 3: Dayanıklılık**
- Kopma ve yeniden bağlanma, host'un kopması, uygulamanın arka plana alınması.
- Kararlaştırılan reklam ve zaman aşımı davranışı.

**Aşama 4: Android ve Play**
- İzinler: INTERNET ve ACCESS_NETWORK_STATE zaten var. Oyun bulma için ACCESS_WIFI_STATE ve
  CHANGE_WIFI_MULTICAST_STATE; bazı telefonlarda yayın için `MulticastLock` gerekir (Godot almaz,
  küçük eklenti gerekebilir; QR/IP ile katılma bunu atlatır).
- Yeni Android sürümlerindeki yerel ağ erişimi izni hedef API'ye göre kontrol edilecek.
- Gizlilik politikası yerel ağ oyununa göre güncellendi (2026-11-20, "Yerel ağda oyun" bölümü,
  tr/en); sezertanci.github.io reposuna kullanıcı gönderir. Veri güvenliği formu değişmedi: oyun
  verisi yalnızca oyundaki cihazlar arasında gider, geliştiriciye ya da üçüncü tarafa gitmez.

**Test**
- Mesaj ve hakem mantığı sahte taşıyıcıyla birim testte; `tools/simulate.gd` ağ katmanından geçen
  bir kipte de çalıştırılabilir.
- Gerçek deneme: tablet + bilgisayarda Godot örneği (veya editörde birden çok örnek). Telefon
  yalnızca Play dahili testinden yüklenir.

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
- **2026-11-20:** Yerel oyunda renk seçimi ve başlangıç kurası eklendi (kurulum ekranında "Rengin"
  seçicisi, `SeatColors`, `PlayerColor`, kayıt sürümü 4). GUT 130/130, gdlint temiz, simülasyonda
  bitmeyen oyun yok. Not: `tests/unit/test_move_picker.gd` önceden de `gdformat --check`'ten
  geçmiyor (gdformat çok satırlı çağrıyı bozuk biçimde yeniden yazıyor); dokunulmadı.
- **2026-11-20 (2):** Ağ oyunu lobi ekranları (kurulumda "Ağda" sekmesi, Oyun Kur ve Katıl
  ekranları, `HostRoom` / `GuestRoom`). GUT 227/227, gdlint temiz, simülasyonda bitmeyen oyun yok.
- **2026-11-20 (3):** Ağ oyunu başlıyor (parça 1/3: Başla, istemcide oyun ekranı, çıkış onayı).
  GUT 238/238, gdlint ve gdformat temiz, simülasyonda bitmeyen oyun yok. Not: bilgisayarda açık
  Godot pencereleri 24680/24681 portlarını tutarsa oyun bulma testleri başarısız olur.
- **2026-11-20 (4):** Düzeltme: ağ oyununda istemci kendi kartını atınca atılanların üstünde bir
  süre önceki kart görünüyordu (üst kart ancak hosttan gelen hamle olayıyla yazılıyordu). Artık
  açılan kart inince üst kart hemen o karta geçiyor.
  Karar (kullanıcı seçti): ağ oyununda ekranlar birlikte ilerler. Hakem her olayda hostun ekranıyla
  birlikte oturan her eşin olayı bitirmesini bekler (istemci `EVENT_DONE` gönderir, protokol
  sürümü 2). Önceden host yalnızca kendi ekranını beklediği için başkasının kartı (açılış + 1,1 sn
  bekletme) kendi kartından uzun sürünce istemci her host hamlesinde ~2 sn geride kalıyordu.
  Görünümü yeniden isteyen, çıkan ya da bağlantısı kopan eş beklenmez (kopmada 20 sn bekleme
  parça 3'te). GUT 242/242, gdlint ve gdformat temiz, simülasyonda bitmeyen oyun yok.
- **2026-11-20 (5):** Düzeltme: ağ oyununda bir oyuncu kartını oynayınca diğer ekranlarda kart
  desteden açılıp 1,1 sn bekletiliyordu; hakem herkesi beklediği için taşın yürümesi her cihazda
  ~2 sn gecikiyordu. Artık başka bir insanın kartı desteden yüz yukarı, bekletmesiz ve kartı
  oynayanın ekranıyla aynı sürede atılanlara uçar; hamle her cihazda hemen ve birlikte başlar. Bot
  kartları her ekranda açılış + bekletmeyle kalır (süre her yerde eşit). GUT 242/242, gdlint ve
  gdformat temiz, simülasyonda bitmeyen oyun yok. PC'de ve tablette henüz denenmedi.
- **2026-11-20 (6):** Düzeltme: Gradle'sız "Android APK (hızlı)" ön ayarında ağ izni yoktu (Gradle'lı
  derlemede izinleri AdMob ve satın alma eklentileri ekliyor); tablette soket açılamıyor ve "Wi-Fi
  bağlantısı bulunamadı" görünüyordu. Hızlı ön ayara `internet`, `access_network_state`,
  `access_wifi_state` ve `change_wifi_multicast_state` izinleri eklendi; tablette izinlerin verildiği
  doğrulandı.
- **2026-11-20 (7):** Arayüz (kullanıcı istedi): iki düğmeli onay katmanı geri dönülmez işi
  onaylattığı için onay düğmesi kırmızı (`MenuPlainRedButton`), Vazgeç yeşil (`MenuPlainGreenButton`)
  oldu; tek düğmeli katmanda (Tamam) onay yeşil kalır. Vazgeç'teki boş simge yuvarlağı da kalktı.
  Kırmızı görsel turuncu düz düğmenin tonu kaydırılarak üretildi (`tools/shift_button_hue.py`,
  komut README'de). Bulunan oyunlar listesinde "Oyuncu" yerine "Katılan Sayısı" yazıyor (8 dil).
  gdlint ve gdformat temiz; GUT 235/242, kalan 7 test PC'de açık oyun pencereleri oyun bulma
  portlarını tuttuğu için düştü.
- **2026-11-20 (8):** Hata (kullanıcı bildirdi): ağ oyununda Çık ile çıkan istemcinin koltuğunu
  bot almıyor, sayaç sürüyordu. Neden: istemci LEAVE gönderip bağlantıyı anında kesiyordu; ENet
  kopma komutu aynı anda gelince eşin bekleyen paketlerini hostta siliyor, LEAVE kayboluyordu.
  Düzeltme: `ENetTransport.close()` istemcide bağlantıyı `peer_disconnect_later` ile kuyruk
  boşaldıktan sonra keser (en fazla `connect_timeout_ms` yoklanır); kopma da o karenin paketleri
  okunduktan sonra bildirilir. Yeni test: `test_message_sent_before_close_arrives`. Pencereyi
  kapatmak LEAVE göndermez, kopma sayılır; kopan oyuncunun koltuğu 20 sn sonra bota geçmesi
  parça 3'te yapılacak. gdlint ve gdformat temiz; GUT 243/243.
- **2026-11-20 (9):** Hata (kullanıcı bildirdi): oyuna katılan pencere oyun sürerken oyun bulma
  portunu tutuyor, aynı cihazdaki başka pencere oyun bulamıyordu; kurucu da oyun başladıktan sonra
  yayına devam ediyor, başlamış oyun listede görünüyordu. Düzeltme: katılma ekranı oyun başlayınca
  aramayı durdurur (`JoinScreen._stop_search()`); `HostRoom.start_match()` lobiyi başlatıp yayını
  durdurur. İstek: oyun ekranında başlığın altında ince bir oda satırı ("Oda 4568 · Kurucu: Yeşil ·
  Sen: Katılımcı"); yalnızca ağ oyununda görünür. `MatchSource.room_code()` eklendi (yerelde boş);
  kurucunun rengi `seats[HostLobby.HOST_INDEX]` koltuğundan okunur. Yeni çeviri anahtarları
  `ROOM_INFO`, `ROLE_HOST`, `ROLE_GUEST` (8 dil). Yeni testler:
  `test_started_match_is_no_longer_announced`, `test_sources_report_room_code`. gdlint ve gdformat
  temiz; GUT 245/245 (ağ testleri açık oyun pencereleri portları tuttuğu için kaydırılmış portla
  doğrulandı).
- **2026-11-20 (10):** Telefonda ağ oyunu denemesi için 6 (1.5.0): Gradle'lı APK ve AAB ön
  ayarlarına ağ izinleri eklendi (önce yalnızca hızlı APK'da vardı; Play sürümünde ağ oyunu
  çalışmazdı), üç ön ayarda sürüm yükseltildi.
- **2026-11-20 (11):** `store/pawnic/privacy.html`'e "Yerel ağda oyun" bölümü (tr/en) eklendi;
  mağaza metinlerine (tr-TR, en-US) Wi-Fi oyunu bölümü ve 1.5.0 sürüm notu eklendi.
- **2026-11-20 (12):** `addons/portrait_feature` eklentisi `android.hardware.wifi` özelliğini de
  `required="false"` ile manifeste yazar (Play uyarısı).
- **2026-11-21:** Kurulum ekranındaki mod sekmeleri yazısız, yalnızca simgeli oldu (beyaz SVG,
  temada yazı rengiyle boyanır): tek avatar, Wi-Fi (ortada), üçlü avatar. Kullanılmayan
  `MODE_SINGLE`, `MODE_MULTI`, `MODE_NETWORK` çevirileri silindi; açıklama satırı yerinde.
- **2026-11-21 (2):** Ağ oyunu parça 2, sıra süresi. `tuning.json` → `network.turn_time_sec` (20)
  ve `turn_warning_sec` (5). Hakem (`MatchReferee.turn_time_limit`, yalnızca hostta kurulur;
  yerel oyunda 0, süre yok) insan oyuncunun niyetini beklemeye başlayınca süreyi başlatır ve
  `turn_timer_started` yayar; süre dolunca o hamleyi Orta bot oynar (normal bot gecikmesiyle),
  koltuk insanda kalır, geç gelen niyet reddedilir. Host süreyi eşlere `TURN_TIMER` mesajıyla
  bildirir, görünüm (snapshot) kalan süreyi taşır; `PROTOCOL_VERSION` 3 oldu (eski sürümlerle
  bağlanmaz). İstemci süreyi kendi saatiyle sayar (ağ gecikmesi kadar geç biter, kabul edildi),
  süre dolunca seçimi kapatır. Ekran: elin üstünde ince çubuk (`TurnTimerBar`), herkes o an
  sırası olan insanın süresini görür, renk sıradakinin rengi; son 5 sn temanın `warning_color`
  kırmızısı ve her saniye `tick` sesi (`tools/make_sounds.py`). Yeni testler hakem, oturum,
  kaynak ve mesaj testlerinde. gdlint ve gdformat temiz; GUT 255/255; simülasyonda bitmeyen 0.
  Tablet denemesinden sonra (kullanıcı isteği): çubuğun solunda kalan saniye yazar (yalnızca
  sayı). Kırmızı oyuncuyla karışmasın diye son 5 sn çubuk rengi değişmez; çubuk her saniye
  kırmızı ışık yayıp söner (zemin stilinin gölgesi, temada `glow_size`), sayı kırmızı olur.
  Çubuk ve sayı tahtanın genişliğine hizalanır (`BoardView.grid_rect()`); geniş ekranda taşmaz.
- **2026-11-21 (3):** Ağ oyunu parça 3, kopma ve geri dönme. `tuning.json` → `network`:
  `peer_timeout_ms` (20000, ENet eş zaman aşımı; 2026-11-21 (6)'da 40000 oldu), `heartbeat_interval_ms` (1000),
  `silence_limit_ms` (3000), `rejoin_wait_sec` (20), `rejoin_interval_ms` (1000).
  `PROTOCOL_VERSION` 4 oldu; yeni mesajlar `HEARTBEAT`, `SEAT_STATUS`, `CLOSED`, yeni ret
  `NOT_IN_MATCH`. Host ve istemci birbirine her saniye yoklama gönderir (`PeerWatch`; cihaz
  arka planda durduysa o süre sessizlik sayılmaz). Hostta (`HostSession`): bağlantısı kopan ya da
  3 sn sesi gelmeyen eşin koltuğu uzakta sayılır (`SeatPresence`), diğer eşlere bildirilir; oyun
  sürer, sıra o koltuğa gelirse 20 sn'nin kalanı kadar beklenir (karar değişti, aşağıdaki nota bak).
  Süre dolunca koltuğu Orta bot oynar (`MatchReferee.hand_to_bot`). WELCOME eşe bir yeniden katılma
  anahtarı verir; eş aynı anahtarla yeniden bağlanınca eski bağlantısı kesilir, koltuğu geri
  verilir (`MatchReferee.take_back`; süren bot hamlesi biter, oyuncu sonraki sırasında oynar) ve
  görünümün tamamı gönderilir. Bilinmeyen anahtar `NOT_IN_MATCH` ile reddedilir. Lobi kilitlenince
  yeni bağlantı reddedilmez (`refuse_new_peers` kaldırıldı), oyun başladıktan sonra yalnızca
  anahtarlı eş kabul edilir; host yeniden bağlanan eşin eski bağlantısı için iki katı bağlantı
  ayırır. Host odayı kapatınca eşlere `CLOSED` gider; ENet taşıyıcı kapanırken (host da) kuyruğu
  boşaltıp bağlantıyı sonra keser. İstemcide (`GuestRoom`): oyun sürerken bağlantı koparsa her
  saniye aynı hosta anahtarla bağlanmaya çalışılır; oyuncu Çık'a basana, host `CLOSED` gönderene
  ya da yeniden bağlanırken ret gelene kadar sürer (kurucu uzun süre dönmezse deneme sürer,
  kullanıcı Çık'la çıkar). Ekran: bağlantı kopukken (ya da hostun sesi kesilince) "Bağlantı
  koptu. Yeniden bağlanılıyor…" katmanı ve Çık düğmesi; düzelince kapanır. Oyun sonu mesajları:
  host kapattıysa "Kurucu oyunu kapattı.", host artık oyunu tanımıyorsa "Kurucuya ulaşılamadı,
  oyun sona erdi." (`RECONNECTING`, `HOST_UNREACHABLE`, 8 dil). Sıra göstergesinde (`TurnDots`)
  kopan oyuncunun taşı soluk çizilir, bot alana kadar kalan saniye taşın üstünde yazar. Yeni
  testler `test_peer_presence.gd` ve `test_match_reconnect.gd`'de. gdlint ve gdformat temiz;
  GUT 271/271; simülasyonda bitmeyen 0. İki cihazla denendi (kullanıcı): uygulamayı arka plana
  alma ve interneti kesme sonrasında bekleme süresince bot devreye girdi, oyuncu yeniden
  bağlanıp koltuğuna döndü.
  Denemede bulunan hata: kurucu uygulamayı arka plana alınca istemcide "yeniden bağlanılıyor"
  katmanı çıkıyor, oyuncu hamle yapamıyor ama sıra süresi doluyordu. Düzeltme: bağlantı kopukken
  istemcide sıra süresi donar, düzelince kaldığı yerden sürer (`ClientSource`). Hostun cihazı
  durursa (sessizlik sınırından uzun kare) o süre sıra süresinden düşülmez ve kalan süre eşlere
  yeniden gönderilir (`MatchReferee`). Sesi kesilip aynı bağlantıdan dönen eşe hostun kalan sıra
  süresi gönderilir (`HostSession`). Uzaktaki koltuğu beklerken sıra süresi durmaz kararı aynen
  geçerli. GUT 274/274; simülasyonda bitmeyen 0. Tablette denenmedi.
  Denemede bulunan ikinci durum: mavinin bağlantısı kopunca sıra sarı bota geçtiği hâlde oyun,
  mavinin 20 sn'si dolana kadar durdu (host her olayda uzaktaki eşin olayı bitirmesini bekliyordu).
  Karar değişti (kullanıcı): uzaktaki eşin olayı bitirmesi beklenmez, diğer oyuncular ve botlar
  oynamaya devam eder; sıra kopan oyuncuya gelirse bekleme süresinin kalanı kadar beklenir, sonra
  koltuğu bot alır (`HostSession._mark_away` eşin bekletmesini bırakır, `_on_event` uzaktaki
  koltuğu beklemez). GUT 275/275. Tablette denenmedi.
  Dal incelemesinden iki düzeltme (protokol sürümü 4 → 5): bağlanıp sessizlik sınırı
  (`silence_limit_ms`) içinde HELLO göndermeyen eşin bağlantısı kesilir, yoksa aynı ağdaki bir
  cihaz bağlantı yerlerini doldurup katılmayı ve geri dönmeyi engelleyebilirdi. Olaylar sıra
  numarasıyla gider, EVENT_DONE numarayı geri getirir; sesi kesilip dönen eşin eski olaylar için
  gönderdiği bildirim güncel olayın beklemesini erken bitirmez. Yeniden katılma anahtarı ağda
  şifresiz gider (aynı ağda dinleyen biri koltuğu alabilir); bilgi olarak not edildi, düzeltilmedi.
  GUT 278/278. Tablette denenmedi.
- **2026-11-21 (4):** Ağ oyununda Tekrar oyna. `HostLobby.rematch` biten oyunun renkleri ve taş
  sayısıyla yeni oyun kurar, oturmayan katılımcının koltuğuna bot koyar, kurayı yeniden çeker;
  `HostLobbyScreen.rematch` onu aynı odada başlatır. `HostSession.share_match` bekleme süresi
  dolmuş koltukları yeni oyunda da bota verir. İstemcide `ClientSource` MATCH_OVER'dan sonra
  yeniden `begin()` bekler; yeni görünüm gelince oyun ekranı sonuç ekranını kapatıp oyunu açar
  (bitmiş oyunun yeniden bağlanma görünümü yok sayılır). `WinOverlay.set_mode` dört düzen
  (yerel, host, misafir, bitmiş ağ oyunu); yeni metin `WAITING_FOR_REMATCH` 8 dilde. Sonuç
  ekranı açıkken son katılımcı çıkarsa hostta Tekrar oyna hemen gizlenir
  (`HostSession.guests_changed` → `MatchSource.guests_changed`; kopan oyuncu çıkmış sayılmaz).
  GUT 284/284, simülasyonda bitmeyen yok. Tablette denenmedi.
- **2026-11-21 (5):** Ağ oyununda duraklatma. `MatchReferee.pause`/`resume`: molada saat, sıra
  süresi ve reklam süresi (oyun saatine bağlı) işlemez; yürüyen animasyon biter ama hakem sonraki
  adımı vermez, yarım seçim korunur, devamda sıra süresi kalan süreyle yeniden başlar.
  `SeatPresence.freeze`/`thaw` molada kopma sayacını durdurur (molada kopan koltuk bota geçmez,
  dönmemişse devamda sayaç başlar). Yeni iletiler PAUSED/RESUMED, görünüm mola süresini taşır
  (`PROTOCOL_VERSION` 6); yeniden katılan oyuncu molayı görünümden öğrenir. Yalnızca hostta üst
  çubukta ⏸ düğmesi (`PauseIcon`, çizilen simge). Mola katmanı `PauseOverlay`: "Duraklatıldı",
  mola süresi ve hostta "Telefonu kilitlerseniz oyun bitebilir." uyarısıyla Devam Et / Oyunu Bitir,
  misafirde bekleme yazısıyla Oyundan Çık (ikisi de mevcut onayla). Ekran ağ oyununda lobiden
  beri açık tutulduğu için ayrıca açılmadı. Yeni metinler `PAUSED`, `PAUSE_HOST_NOTE`,
  `PAUSE_GUEST_NOTE`, `QUIT_MATCH`, `END_MATCH` 8 dilde. `gdlintrc` eklendi, `max-public-methods`
  25 (kaynak sınıfları ve hakem testi 20'yi aşıyordu). GUT 295/295, simülasyonda bitmeyen yok.
  Tablette denenmedi.
- **2026-11-21 (6):** Ağ oyununda ortak oyun içi reklam. Host oyun içi reklamı kendi kuralıyla
  açar (`in_game_ads` = hostta reklamlar kaldırılmadıysa); AD_DUE olayı herkese aynı anda gider.
  `HostSession` reklam arasında reklamını bitirmeyen eşi `shared_ad_wait_sec` (30, `tuning.json`
  → `ads`) kadar bekler; bu sırada sesi kesilen ya da bağlantısı kopan eş uzakta sayılmaz. Süre
  dolunca oyun onsuz sürer ve sesi gelmeyen eş normal kopma kuralıyla uzakta sayılır. Hostun
  kendi reklamında durduğu süre `PeerWatch.stall()` ile son ana eklenir. Reklamı biten ya da
  reklamları kaldırılmış oyuncu "Reklam arası / Diğer oyuncular bekleniyor…" katmanını görür
  (`PauseOverlay.open_ad_break`, oyun ekranında `AdBreakOverlay`); herkes bitirince kalkar, bu
  sırada bağlantı koptu katmanı açılmaz (reklam arası bitince açılır). Katmanda çıkış düğmesi
  var: misafirde Oyundan Çık, hostta Oyunu Bitir (host kaybolursa misafir takılmasın diye).
  Oyun sonu reklamı her cihazda kendi kuralıyla gösterilir; istemci son oyun içi reklamın anını
  kendisi saklar (`ClientSource.skips_end_ad`, `AdSchedule.is_recent`). ENet zaman aşımı
  (`peer_timeout_ms`) 30 sn beklemeden uzun olsun diye 40000 yapıldı. Yeni metinler
  `AD_BREAK`, `AD_BREAK_NOTE` 8 dilde. GUT 302/302, simülasyonda bitmeyen yok. Tablette
  denenmedi.
- **2026-11-21 (7):** Katılma ekranında "oyun bulunamadı" uyarısı. `search_hint_sec` (15,
  `tuning.json` → `network`) boyunca oyun bulunamazsa "aranıyor…" yazısının yerine uyarı
  (kurucunun oyunu açtığı, aynı Wi-Fi, oyunun güncel olması ve misafir ağları) ve Yeniden Ara
  düğmesi çıkar. Protokol sürümü farklı oyunlar listeye hiç düşmediği için güncellik de anılır. Arama arka
  planda sürer; oyun bulununca uyarı kalkar, liste yeniden boşalırsa süre baştan sayılır. Yeniden
  Ara "aranıyor…" yazısını gösterip süreyi yeniden başlatır. Yeni metinler `SEARCH_NOT_FOUND`,
  `SEARCH_AGAIN` 8 dilde. GUT 302/302. Tablette denenmedi.
- **2026-11-21 (8):** Kurulum, katılma ve kurucu lobisi ekranlarında panel üste sabitlendi.
  Önceden `TopSpace` ve `BottomSpace` birlikte genişlediği için panel dikeyde ortalanıyor, sekme
  değişince (paneller farklı yükseklikte) sekmeler yukarı aşağı kayıyordu. `TopSpace` artık
  genişlemiyor; panel başlığın hemen altında başlıyor, alt düğmeler yine en altta. Ölçüm (800x1280):
  üç sekmede panel y=192. Oyuncu sayısı değişince kayma bilgisayarda görülmedi; panelin üstü sabit
  olduğu için boy değişse bile sekmeler ve sayaçlar yerinde kalır. GUT 302/302. Tablette denenmedi.
- **2026-11-21 (9):** Başlangıç kurasına ses ve çark gibi yavaşlama. Taş her değiştiğinde yeni çark
  tıkırtısı (`spin.wav`), sonuç yazılınca iki notalı çan (`starter.wav`) çalar; ikisi de
  `tools/make_sounds.py` ile üretilir, `Sound.SPIN` / `Sound.STARTER`. Adım süresi artık doğrusal
  değil, `ease()` eğrisiyle artar (`animation.starter_spin_ease` 2.0): kura uzun süre hızlı döner,
  sona doğru belirgin yavaşlar. Kullanıcı isteğiyle tur sayısı 2 → 3, son adım 0,4 → 0,5 sn;
  kura (bekleme hariç) 2 oyuncuda yaklaşık 1,2–1,4 sn'den 1,6–1,8 sn'ye, 4 oyuncuda 2,2–2,9 sn'den
  2,9–3,6 sn'ye uzadı. GUT 302/302. Tablette denenmedi.
- **2026-11-21 (10):** Kurada renkler artık sırayla değil karışık değişir (`StarterDraw.spin_order`):
  her adım rastgele ve bir öncekinden farklı, son adım başlayan. Sıra sondan başa kurulur, sonuç
  değişmez. Gösterim sırası yalnızca görünüş olduğu için tohumsuz yerel üretici kullanılır. Adım
  sayısı artık başlayana bağlı değil (`starter_spin_rounds * oyuncu + 1`); kuranın süresi sonucu
  ele vermez: 2 oyuncuda yaklaşık 1,6 sn, 4 oyuncuda 2,9 sn (bekleme hariç). Test
  `test_starter_draw.gd`. GUT 306/306. Tablette denenmedi.
- **2026-11-21 (11):** "Nasıl Oynanır" ekranı açılır gruplara bölündü (`RuleList`, `RuleGroup`,
  `GroupChevron`): Oyunun Amacı ve Sıra, Taşlar ve Tahta, Kartlar, Oyun Kurulumu, Wi-Fi Oyunu ve
  Uyarılar. Ekran açılınca bütün gruplar kapalıdır; dokunulan grup açılır, diğeri kapanır, açık
  gruba yeniden dokununca kapanır; açılan grup listenin üstüne kaydırılır. Demodan dönüşte açık
  grup korunur. Kural metinleri şimdiki kurallara göre güncellendi (çıkış, yakalama, kalkan, ev
  yolu, geri/geri gönder/yer değiştir kartları); kalkan, ileri ve çıkış kartı satırları eklendi.
  Kurulum grubunda her mod için simgeli bir satır, Wi-Fi grubunda oyunda görünen uyarılar kırmızı
  başlık olarak ve altında ne yapılacağı yazılır; süre ve oyuncu sayısı ayarlardan okunur
  (`FormattedLabel`). Kalkan çizimi `ShieldMark` olarak ortaklaştı (tahta ve kural simgesi).
  Test `test_rule_list.gd`. GUT 311/311. Tablette denenmedi.
- **2026-11-21 (12):** Karar: Türkçe metinlerde oyuncuya "siz" diye hitap edilir (kullanıcı
  isteği). Kural metinleri, demo, kurulum anlatımı, Wi-Fi uyarıları, oyun içi uyarılar, kart
  açıklamaları ve etiketler ("Renginiz", "Siz") çevrildi; 42 satır. Kısa düğme yazıları
  ("Başla", "Katıl", "Çık") olduğu gibi kaldı. Diğer dillerdeki samimi hitap değişmedi. Kural
  proje `CLAUDE.md` dosyasına yazıldı.
- **2026-11-21 (13):** Modlar her yerde Botlara Karşı, Aynı Wi-Fi'da, Aynı Telefonda sırasıyla
  anlatılır (Wi-Fi oyunu öne çıksın diye; kurulum ekranındaki sekmelerle aynı sıra). Nasıl Oynanır
  ekranının Oyun Kurulumu grubu bu sıraya getirildi.
- **2026-11-21 (14):** Kurucu aniden kaybolursa (Wi-Fi kopması, uygulamanın kapanması) katılımcı
  `host_lost_sec` (30 sn) boyunca yeniden bağlanmayı dener, sonra "Kurucuya ulaşılamadı, oyun
  sona erdi." uyarısıyla oyundan çıkar (`GuestRoom`). Kurucu oyundan çıktıktan sonra `HostSession`
  kare döngüsünde kalıyor ve konuğun bekleme süresi dolunca silinmiş hakeme erişiyordu;
  `close()` artık döngüden çıkıyor. Tablet ve PC ile Wi-Fi'da denendi: katılma, kart ve taş,
  duraklatma, süre dolunca otomatik hamle, yeniden bağlanma, düzgün kapatma, ani kurucu kaybı,
  oyun sonu ve Tekrar Oyna (aynı odada yeni oyun) çalışıyor.
- **2026-11-21 (15):** Sürüm 7 (1.6.0): üç ön ayarda sürüm yükseltildi; mağaza metinlerine (tr-TR,
  en-US) 1.6.0 sürüm notu eklendi. AAB Play'e, Gradle'lı APK tablete.
- **2026-11-21 (16):** Mağaza ekran görüntüleri 3'ten 8'e çıktı (tr-TR, en-US; telefon, 7 ve 10 inç
  tablet): ana ekran, kurulum (3 bot, Zor), kart seçilmiş tahta (çeşitli el), vurma/kalkan, Nasıl
  Oynanır (Kartlar açık), Wi-Fi lobisi, süreli ağ oyunu, konfetili sonuç. Kura çarkı listeye
  alınmadı. `tools/store_screenshots.gd` ham görüntüleri elle kurulmuş oyun durumlarıyla üretir;
  `tools/make_store_screenshots.py` üste yarı saydam şerit ve `captions.json`'daki başlığı
  bindirir (Titan One'da İ olmadığı için I ve i noktasıyla çizilir). `RuleList.sample_card`
  herkese açıldı. Öne çıkan görsel yeniden üretilmedi; üretilirse girdi olan
  `tablet-10/03-board.png` artık kart seçilmiş tahtadır (kırpılan alan şeridin altında kalır).
- **2026-11-21 (17):** Mağaza metni "siz" hitabına çevrildi; kalkan ve hız kareleri, kura, renk
  seçimi ve Wi-Fi ayrıntıları (lobide renk ve bot, sıra süresi, duraklatma, yeniden oynama, geri
  dönme) eklendi. 07 başlığı sayısız yazıldı ("Süre dolmadan hamlenizi yapın"), süre değişse de
  geçerli kalsın diye. Öne çıkan görsel iki dilde, "Pawnic" altında sloganla üretiliyor ("Zar yok,
  kart var!" / "No dice, just cards!"); tahta, eski 03 görüntüsünden kırpılıp
  `store/pawnic/feature-board.png` olarak sabitlendi. Play'de Türkçe uygulama adı "Pawnic:
  Hoppala, Başa Döndüm!" yapıldı (Kızma Birader havasında, ona benzemeyen bir ad).
- **2026-11-21 (18):** Uygulama boyutunu (~117 MB) küçültme işinden vazgeçildi. Ödüllü reklam
  eklendi: oyun ekranında deste ile atılan kartların sağında video simgeli "Kart Seç" düğmesi (solda simetri için
  boş yer). Oyuncunun sırasında, turda bir kez, sınırsız kullanılır; reklam hazır değilse ya da
  sıra başkasındaysa soluk durur. Reklam izlenince desteden oyuncunun işine en çok yarayacak 3
  kart (`RewardDealer`: her farklı kart, onunla yapılabilecek en iyi hamleye göre puanlanır)
  gösterilir; oyuncu birini seçer, sonra elindeki hangi kartın yerine geçeceğini seçer (bu sırada
  eldeki kartlar ve seçilen teklif sol üst köşede sarı değiştir ⇄ işaretiyle, `SwapMark`, görünür;
  teklife basılınca tekliflere dönülür). Seçimden sonra teklif kartı eldeki yere, eldeki kart da
  teklifin yerine aynı anda çaprazlama uçar (`CardAnimator.swap_cards`, `cards.swap_sec` 0,5 sn);
  ardından bırakılan kart kapanıp desteye gider ve desteye rastgele bir yere girer. Geri okuyla ödülden kartsız vazgeçilir. Tek cihazda, aynı
  telefonda ve Wi-Fi oyununda çalışır; ödül sürerken sıra süresi durur, kurucunun sessizliği
  sayılmaz ve hakem yalnızca ödül niyetlerini kabul eder. Ödül `ads.reward_wait_sec` (120 sn)
  içinde bitmezse kartsız kapanır. `remove_ads` ödüllü reklamı kaldırmaz. Ağ protokolü 7'ye
  çıktı (yeni niyet ve olay türleri); kayıt sürümü 4 kaldı (ödül kayda yazılmaz). Hakem testleri
  `tests/fixtures/referee_case.gd` tabanıyla ikiye bölündü (gdlint 25 public metot sınırı).
  `game_screen.gd` gdlint'in 1000 satır sınırına dayandığı için sonuç düğmelerini seçen kod
  `WinOverlay.mode_for`'a taşındı.
- **2026-11-21 (19):** Play'deki 1.6.0'da görülen ağ oyunu hatası düzeltildi: katılımcı sırası
  gelince oyunu arka plana alıp dönünce elinde 4–5 kart görüyor, tıklamaları bir süre işlemiyordu.
  Nedeni: ENet taşıyıcısı eş başına saniyede 20 mesaj sınırını istemcide hostun mesajlarına da
  uyguluyordu; arka planda biriken mesajlar dönüşte topluca gelince fazlası (botun oyuncu adına
  oynadığı hamle dahil) atılıyor, istemcinin kopyaları kayıyordu. Sınır artık yalnızca hostta,
  katılımcılardan gelen mesajlara uygulanır. Ayrıca ekranın kopyası (`ClientSource`) bir olaya
  uymazsa olayı ekrana vermez, `ClientSession.request_view` ile görünümün tamamını hosttan ister.
  Ağ protokolü (7) ve kayıt sürümü (4) değişmedi.
- **2026-11-22 (20):** İnceleme bulguları düzeltildi. Tahta dosyasında her çıkış karesi güvenli
  olmalıdır; değilse `BoardLayout` yüklenmez (kural motoru çıkış karesini güvenli sayar). Ödül
  kapanırken sıra süresi ve saat, REWARD_ENDED olayı bitene kadar durur; süre eşlerle aynı anda
  yeniden başlar. Bot, ana iş parçacığında alınan kopya (`GameMatch.determinized`) üstünde
  düşünür; kopya oyunla `seats`, `bots` ve `colors` dizilerini paylaşmaz. Ertelenenler:
  `game_screen.gd`'deki ödül akışının ayrı sınıfa alınması, `MSEC_PER_SECOND`'un ortak yere
  taşınması, `GameMatch.from_dict`'in bölünmesi, testlerdeki sahipsiz düğüm ve çıkış sızıntısı
  uyarıları.
- **2026-11-22 (21):** Sürüm 8 (1.7.0): üç ön ayarda sürüm yükseltildi; mağaza metinlerine (tr-TR,
  en-US) 1.7.0 sürüm notu eklendi (ödüllü reklamla "Kart Seç", ağ oyununda kayan kopyanın
  düzeltilmesi). AAB Play'e, Gradle'lı APK tablete.
- **2026-11-22 (22):** Arka plan müziği eklendi (`Music` autoload'u, `tools/make_music.py`).
  Menüde kalimbalı ~23 sn'lik sakin döngü, oyunda ~5 dk 48 sn'lik tek parça çalar. Oyun müziği
  beğenilen iki tarzın birleşimidir: "Oyunbaz" (Fa, Si bemol, Do) ve "Ada" (Sol, Do, Re). Tempo
  ikisinde de 116 BPM'dir. Bölümler sıradaki tona götüren geçiş akoruyla, iki tarzın ek yerleri
  ayrıca yumuşak bir yaygı akoruyla bağlanır. Tizler 2600 Hz'de kesilir, ritim yükselmez. Dosyalar
  tek kanal ve 16 kHz; QOA ile APK'da oyun müziği ~2,2 MB, menü ~150 KB. Ayarlarda ayrı "Müzik"
  anahtarı var: ilk açılışta açık, tercih saklanır. Ses efektleri anahtarından bağımsızdır (ayrı
  `Effects` ve `Music` ses yolları, `default_bus_layout.tres`); "Ses" anahtarının adı "Ses
  Efektleri" oldu. Müzik düzeyi `tuning.json`'da `audio.music_volume_db` (-15 dB), ekran
  geçişindeki kısıp açma süresi `music_fade_sec` (1,5 sn). Açık konu: müzik düzeyi tablette
  denenip gerekirse ayarlanacak.
- **2026-11-22 (23):** Tam ekran reklamda müzik: `Ads.full_screen_started` sinyali geçiş ya da
  ödüllü reklam açılmadan hemen önce gelir. `Music` o anda parçayı olduğu yerde duraklatır ve
  müzik ses yolunu susturur. Reklam kapanınca (`interstitial_closed` / `rewarded_completed`) parça
  kaldığı yerden sürer, ses yolu `music_fade_sec` boyunca yumuşakça açılır. Reklam hemen tam
  ekran açıldığı için kısma beklenmez. Gerçek AdMob reklamıyla tablette denenmedi.
- **2026-11-22 (24):** Eve giren taş ve kutlama sesleri: taş evine (ortadaki yamuğa) indiği anda
  "sihirli parıltı" (`Sound.HOME`: hızla yükselen arp dizisi ve üstüne serpilen tiz ışıltılar;
  ilk denenen üç notalı çan bildirim sesine benzediği için değiştirildi) çalar ve sahibinin yamuğu kendi renginin tam tonuna boyanıp
  çevresine aynı renkte bir ışık halesi yayar (`HomeTray.draw_halo`); ikisi
  `animation.home_glow_sec` (1,5 sn) içinde söner; botlar dahil her oyuncuda.
  Oyun sonu (oyuncu bitirince ve sonuç ekranında) için ses denendi ama beğenilmedi ve
  kaldırıldı; şimdilik zafer sesi yok, güzel bir ses bulununca eklenecek. Denenip beğenilmeyenler:
  sentetik alkış, üflemeli "ta-ta-ta-taaa" fanfarı, sentetik kalabalık "oley"i ve stadyum
  uğultusu, parti düdüğü, 8-bit melodi, çıtırtılı ya da tok havai fişek, zafer çanları, konfeti
  patlaması, 5 sn orkestral ve 5 sn synth çanlı casual zafer sesi. Çıtırtıya benzeyen sesler
  (tane tane kıvılcım, kâğıt hışırtısı) hiç kullanılmamalı. Yeni ses eklenince `Sound.DUCKING`
  listesine de konmalı. Sesler `tools/make_sounds.py` ile üretildi (`home.wav`); eski sesler
  değişmedi. Taş kırılınca başlangıca uçarken iki notalı,
  inen ve titreyen bir "ops" sesi (`Sound.CAPTURE`, `capture.wav`) bir kez çalar. Yalnızca rakip
  taşı başlangıca dönerse çalar; taş çıkarınca başlangıçta kalan taşların kayması sayılmaz.
  Başarı sesi müziğin altında kaldığı için çalarken müzik `Music.duck` ile
  kısılır (`audio.music_duck_db` -12 dB, 0,15 sn'de iner), ses bitince 0,6 sn'de açılır; efektler
  kapalıysa ya da reklam açıkken kısılmaz. Tablette dinlenip düzeyleri gerekirse
  ayarlanacak.
- **2026-11-22 (25):** Menü müziği oyundakinden yüksek geliyordu. Ölçüm: `menu.wav` K ağırlıklı
  -15,3 LUFS, `game.wav` -17,2 LUFS (ilk 30 sn -19,0); menü enerjisi kulağın duyarlı olduğu orta
  frekanslarda, oyun müziğininki basta, küçük hoparlörde bas duyulmadığı için fark büyüyor
  (250 Hz üstü ~2,7 dB). Menü müziği ayrı bir düzey aldı: `audio.menu_music_volume_db` -20 dB
  (oyun müziği `music_volume_db` -15 dB'de kaldı). -17 ve -18 dB kulakla denendi, menü yüksek
  geldi. Parçanın düzeyini `Music.volume_of` seçer.
- **2026-11-22 (26):** Kullanılmayan dosyalar silindi: eski yazılı ikon (`assets/icon/text/`,
  4 dosya), açılış görseli klasöründeki yan ürünler (`assets/icon/frame/` altında `icon_192`,
  `icon_foreground`, `icon_background`) ve dilsiz eski öne çıkan görsel
  (`store/pawnic/feature-1024x500.png`). İkonlar dışa aktarmada bütün kaynaklar alındığı için
  APK'ya da giriyordu (~0,3 MB). Ses, müzik ve `assets/images/` dosyalarının hepsi kullanılıyor.
- **2026-11-22 (27):** Ahşap tema (`themes/skins/wood.tres`) eklendi. Kareler tek renk kül beyazı
  ahşap (dama denendi, istenmedi), üstünde içi boş beyaz elmas kakma (`BoardSkin.inlay_texture`,
  boyanmadan çizilir). Kalkanlı, hız sayılı ve ev simgeli (kısayol) karelerde kakma yok. Ev
  yolları tam renk (`lane_tint` 1,0). Oyun ekranının arkasında ahşap masa dokusu döşenir
  (`BoardSkin.background_texture`, birleşim çizgisi yok; klasik temada boş). Görseller
  `tools/make_wood_tiles.py` ile üretilir; kare ve kakma dokularında mipmap açık, tahta ve logo
  halkası mipmap'li süzgeçle çizilir (küçük karede pürüz olmasın diye). `tools/screenshot.gd`
  ikinci argüman olarak kaplama alır.
- **2026-11-22 (28):** Gece neon tema (`themes/skins/neon.tres`) eklendi. Üç taslaktan B (mor
  dolgulu kare) seçildi. Kareler koyu lacivert zeminde mor dolgulu, kenarları rengin tam
  parlaklığında keskin ışık saçar ve dışa hafif hale yayar; ev yolları oyuncu renginde aynı
  biçimde. Elmas kakma denendi, istenmedi (kakma yok). Kareler arası boşluk dar tutuldu
  (dokunun ışıma payı kenarın %3'ü). Masa dokusu yok, arka plan düz renk. Kare dokusu
  `tools/make_neon_tiles.py` ile üretilir; taşlar klasik temanınkiler.
- **2026-11-22 (29):** Görünüm ekranı (`scenes/skin_screen.tscn`) eklendi. Ana menüde "Yeni
  Oyun" ile "Nasıl Oynanır" arasında aynı boyda mor "Görünüm" düğmesi (mavi düğmenin tonu +60°, simgesi 2x2 küçük
  kare: beyaz, kırmızı, mavi, beyaz). Ekranda her tema için alt alta, kaydırılan büyük kartlar;
  kartlarda ad yok, yalnızca tahta görseli. Karta dokununca tema hemen uygulanıp kaydedilir,
  kart sarı çerçeve ve tikle işaretlenir, ekranda kalınır; geri okla menüye dönülür. Kart
  görselleri hazır dosyadır (`assets/images/skin_preview_<tema>.png`), `tools/screenshot.gd`'nin
  kırptığı `board_preview.png`'den alınır. Temalar `themes/skins/` klasöründen listelenir.
- **2026-11-22 (30):** Ahşap temada başlangıç patikası soluk kalıyordu. Patikada oyuncu
  renginin zemine karışma oranları `BaseLink` sabitlerinden `BoardSkin`'e taşındı
  (`link_line_tint`, `link_fill_tint`; varsayılan 0.5 / 0.2, klasik ve neon değişmedi). Ahşapta
  çizgi 1.0, dolgu 0.65 (iki aday çizilip B seçildi).
- **2026-11-22 (31):** Yeni temalar ödüllü reklama bağlandı. `BoardSkin.needs_unlock` işaretli
  temalar (neon, ahşap) kilitli başlar; klasik açıktır. Görünüm ekranında kilitli kartın sol üst
  köşesinde tikle aynı renklerde sarı daire içinde kilit çizilir, görsel karartılmaz. Karta
  dokununca "Bu görünümü açmak için bir reklam izleyin." onayı (İzle / Vazgeç) sorulur;
  reklam hazır değilse tek düğmeli bilgi iletisi çıkar. Ödül verilirse kilit kalıcı olarak kalkar
  (`unlocked_themes` tercihi), tema seçilip kaydedilir. Reklam yeri `unlock_theme`. "Reklamları
  kaldır" alanlarda da kilit durur (ödüllü reklam kaldırılmaz). Kayıtta kilitli bir tema seçili
  kalmışsa açılışta klasiğe dönülür. `ConfirmOverlay.ask` risksiz onayda onayı yeşil, iptali
  kırmızı yapar.
