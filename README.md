# Pawnic

Aynı telefonda 2–4 kişinin oynadığı, kartla oynanan bir yarış tahtası oyunu. Zar yoktur; her
oyuncunun elinde kartlar vardır ve sırası gelen oyuncu hangi kartı hangi taşla oynayacağını seçer.
Bütün taşlarını eve ilk getiren kazanır. Tek oyunculu modda rakipler bottur. Sunucu ve ağ yoktur.

Paket adı `com.sezertanci.pawnic`. Oyun 8 dilde çıkar: Türkçe, İngilizce, Almanca, İspanyolca,
Fransızca, İtalyanca, Portekizce ve Endonezce.

## Gereksinimler
- Godot 4.7.2 (GL Compatibility işleyicisi) ve aynı sürümün dışa aktarma şablonları
- JDK 17 ve Android SDK (Godot düzenleyici ayarlarında yolları tanımlı olmalı)
- Biçim ve lint için gdtoolkit (`pip install gdtoolkit`)
- Testler için GUT (`addons/gut` içinde gelir)

## Çalıştırma
- Godot düzenleyicisinde projeyi açıp F5 ile çalıştırın.
- Birim testleri: `godot --headless --path . -s addons/gut/gut_cmdln.gd`
- Bot simülasyonu (kural motorunun takılmadan bittiğini denetler):
  `godot --headless --path . -s tools/simulate.gd [-- <tahta>]` (tahta verilmezse ilk tahta)
- Ekran görüntüleri: `godot --path . --resolution 720x1280 -s tools/screenshot.gd -- <klasör> [kaplama] [tahta]`
  (kaplama verilirse, ör. `wood` ya da `neon`, görüntüler o kaplamayla alınır; tahta verilirse,
  ör. `four_leaf`, o tahtayla). Son görüntüdeki
  tahta ayrıca kırpılıp `board_preview.png` olarak kaydedilir; bu dosya
  `assets/images/skin_preview_<kaplama>.png` adıyla kopyalanınca görünüm ekranındaki kartın
  görseli olur (kaplamanın `preview_texture` alanı). Tahta kartının görseli de aynı yolla
  klasik kaplamayla alınır (`assets/images/board_preview_<tahta>.png`, tahtanın `preview` alanı).
- Biçim ve lint: `gdformat scripts tools tests` ve `gdlint scripts tools tests`
- Simgesiz yeşil menü düğmesi (`assets/images/button_green_plain.png`, Tamam düğmelerinde):
  `python tools/make_plain_button.py assets/images/button_green.png assets/images/button_green_plain.png` (Pillow gerekir)
- Mor menü düğmesi (`assets/images/button_purple.png`, Görünüm düğmesinde):
  `python tools/shift_button_hue.py assets/images/button_blue.png assets/images/button_purple.png 60`
  (Pillow gerekir)
- Simgesiz kırmızı menü düğmesi (`assets/images/button_red_plain.png`, geri dönülmez işi onaylayan
  düğmelerde): `python tools/shift_button_hue.py assets/images/button_orange_plain.png
  assets/images/button_red_plain.png -28` (Pillow gerekir)
- Ahşap kaplamanın kare dokusu, elmas kakması ve masa dokusu (`tile_wood.png`,
  `tile_inlay_diamond.png`, `table_wood.png`): `python tools/make_wood_tiles.py assets/images`
  (Pillow ve numpy gerekir)
- Gece neon kaplamasının ışıyan kare dokusu (`tile_neon.png`):
  `python tools/make_neon_tiles.py assets/images` (Pillow ve numpy gerekir)
- Ses efektleri (`assets/sounds/`): `python tools/make_sounds.py assets/sounds` (yalnızca Python standart kütüphanesi)
- Müzik (`assets/music/`): `python tools/make_music.py assets/music` (numpy gerekir). Menü
  döngüsü (`menu.wav`) ve oyun müziği (`game.wav`) notalardan hesaplanır; tek kanal, 16 kHz
  yazılır, Godot QOA ile sıkıştırıp döngü olarak içe aktarır.
- İkonlar (`assets/icon/`): `python tools/make_icon.py assets/images assets/icon` (Pillow gerekir).
  Önceki yazılı ikon depoda tutulmaz, gerekirse `--design text` ile yeniden üretilir.
  Açılış ekranının görseli (`assets/icon/frame/icon.png`):
  `python tools/make_icon.py assets/images assets/icon/frame --design frame --size 1024`.
  Bu komutun ürettiği diğer dosyalar (`icon_192.png`, `icon_foreground.png`,
  `icon_background.png`) kullanılmaz; APK'ya girmemesi için silinir.
- Play Store öne çıkan görseli (`store/pawnic/feature-1024x500-<tr-TR|en-US>.png`, dil başına
  sloganlı, Pillow gerekir). Tahta `store/pawnic/feature-board.png` dosyasından alınır. Önce kartlar
  çizilir (pencereli çalışır, `--headless` olmaz), sonra görseller birleştirilir:
  `godot --path . -s tools/render_cards.gd -- build/feature_cards` ve
  `python tools/make_feature_graphic.py build/feature_cards store/pawnic`
- Play Store ekran görüntüleri (`store/pawnic/screenshots/`, 2 dil × 3 cihaz × 8 ekran, Pillow
  gerekir). Önce her dil ve cihaz için ham görüntüler alınır (pencereli çalışır, ağ ekranları için
  bilgisayarda yerel ağ adresi olmalıdır); cihaz boyutları telefon `1080x1920`, 7 inç tablet
  `1200x1920`, 10 inç tablet `1600x2560`:
  `godot --path . -s tools/store_screenshots.gd -- build/store_raw/<tr|en>/<phone|tablet-7|tablet-10> <tr|en> <genişlik>x<yükseklik>`.
  Sonra üstlerine `captions.json` içindeki tanıtım başlıkları bindirilir:
  `python tools/make_store_screenshots.py build/store_raw store/pawnic/screenshots`

## Android derlemesi
Derlemeler Gradle ile alınır. `android/build` klasörü depoda tutulmaz; ilk kez derlemeden önce
Godot düzenleyicisinde **Proje → Android Derleme Şablonunu Yükle** ile kurulur.

- Tablet için hata ayıklama APK'sı:
  `godot --headless --path . --export-debug "Android APK" build/pawnic.apk`
- Tablette hızlı deneme için Gradle'sız APK (yalnızca arm64, birkaç saniye sürer):
  `godot --headless --path . --export-debug "Android APK (hızlı)" build/pawnic_fast.apk`
- Play için AAB (yükleme anahtarı gerekir):
  `godot --headless --path . --export-release "Android AAB" build/pawnic.aab`

Yükleme anahtarı ve şifreleri depoya girmez. Godot bunları `.godot/export_credentials.cfg` içinde
tutar. Play'de uygulama imzalama (Play App Signing) kullanılır.

Play'e yeni AAB yüklenmeden önce `export_presets.cfg` içindeki üç presette `version/code` 1,
`version/name` ara sürümü 1 artırılır (ör. `2` / `1.1.0` → `3` / `1.2.0`).

## Play Store
Mağaza dosyaları `store/pawnic/` altındadır:
- `listing/`: Türkçe ve İngilizce mağaza metinleri (ad, kısa ve tam açıklama, sürüm notu)
- `screenshots/`: dil başına telefon, 7 inç ve 10 inç tablet için 8'er başlıklı ekran görüntüsü
  ve başlık metinleri (`captions.json`)
- `icon-512.png`: mağaza simgesi
- `feature-1024x500-tr-TR.png` ve `feature-1024x500-en-US.png`: sloganlı öne çıkan görseller;
  `feature-board.png` bunlardaki tahta görüntüsüdür
- `privacy.html`: gizlilik politikası. Yayındaki adresi
  `https://sezertanci.github.io/pawnic/privacy.html`; kaynak burada tutulur, değişince site
  deposuna kopyalanır.

`store/` klasöründeki `.gdignore`, Godot'nun bu görselleri içe aktarıp pakete katmasını önler
(yoksa AAB yaklaşık 18 MB büyür).

## Klasörler
- `data/tuning.json`: kullanılan tahta dosyası, kural, deste, bot, animasyon ve arayüz ayarları (ör. menü düğmelerinin ortak boyutu, ana ekran arka planının bulanıklığı) ile reklam
  ayarları; ödüllü reklamda teklif edilen kart sayısı `ads.reward_offer_count`, ödülün en uzun
  süresi `ads.reward_wait_sec`; kartların ödülde yer değiştirme süresi `cards.swap_sec`
- `data/boards/`: tahta tasarımları (aşağıda)
- `data/translations.csv`: oyuncuya görünen metinlerin 8 dildeki karşılıkları
- `scripts/rules/`: kural motoru (`BoardState`, `GameMatch`, `MovePicker`), kartlar, bot ve
  ödüllü reklamın kart teklifleri (`RewardDealer`)
- `scripts/ui/`: tahta çizimi, el, ana ekran, yeni oyun ve oyun ekranları
- `scripts/autoload/`: genel servisler (aşağıda)
- `scripts/services/`: reklam ve satın alma sağlayıcı arayüzleri ile sahte sürümleri
- `scenes/`: ana sahne, ekranlar ve ortak bileşenler
- `themes/`: arayüz teması ve tahta görünümleri (`themes/skins/`)
- `tests/unit/`: GUT birim testleri, `tests/fixtures/`: testlerde kullanılan deneme tahtası ve
  hakem testlerinin ortak tabanı (`referee_case.gd`)
- `tools/`: simülasyon, ekran görüntüsü, ses, ikon ve mağaza görseli üretme betikleri
- `store/`: Play Store dosyaları (yukarıda)

## Tahta dosyası
Tahta bir ızgara üzerindeki kareler ve aralarındaki bağlantılardan oluşur; kod tahtanın şeklini
bilmez. Oyundaki tahtalar `data/tuning.json` içindeki `board.boards` listesinde durur; her
girdinin kimliği (`id`), dosyası (`layout`), ad anahtarı (`name`), Yeni oyun ekranındaki kartın
görseli (`preview`) ve ödüllü reklamla açılıp açılmadığı (`needs_unlock`) vardır. Listedeki ilk
tahta varsayılandır. Seçilen tahta yarım kalan oyunun kaydına ve ağ oyununun duyurusuna yazılır.

- `paths`: kare dizileri. `points` köşe hücreleridir; aradaki hücreler kendiliğinden doldurulur
  (ardışık noktalar yatay, dikey ya da tam çapraz hizada olmalıdır). Kıvrımlı yollarda `points`
  yerine `squares` ile her karenin sol üst köşesi tek tek ve ondalık olarak yazılır. `loop: true` yolu kapatır.
  `owner` verilen yol yalnızca o koltuğa aittir (ev yolu gibi). Kareler `"yol:sıra"` diye anılır,
  sıra 0'dan başlar (ör. `"ring:8"`).
- `links`: yollar arası geçişler. `seats` boşsa herkes kullanır. `mode`:
  - `forced`: bu koltuklar kareden her zaman bağlantıya girer (ev yolu girişi).
  - `choice`: taş kareden geçerken ya da kareden başlarken oyuncu yolu seçer.
  - `exact`: bağlantıya yalnızca hamleye o karede başlayan taş girebilir.
- `safe`: güvenli kareler. Her koltuğun çıkış karesi bu listede olmalıdır; değilse tahta
  yüklenmez.
- `speed`: hız kareleri ve değerleri (ör. `{"ring:4": 4, "ring:18": -3}`). Artı değerde taş o kadar ileri,
  eksi değerde o kadar geri gider (geri giderken sahibinin çıkış karesinde durur). Bir hız karesinden
  zıplayan taş başka bir hız karesine düşmemelidir; birim test bunu denetler.
- `seats`: her koltuğun çıkış (`start`), ev (`home`) ve kısayol (`shortcut`) karesi ile başlangıç
  alanının hücre cinsinden merkezi (`base`). İsteğe bağlı `approach`, başlangıç alanından gelen
  patikanın çıkış karesine vardığı yöndür (kareden dışarı bakan birim yön, ör. `[0.45, -0.89]`);
  verilirse patika alanın uzun kenarından çıkıp halkanın dışından tek kavisle dolanır, yoksa
  alanın kareye bakan kenarından S çizerek gelir.
- İsteğe bağlı çizim alanları (kural motoru kullanmaz): `square_shape` karelerin biçimi
  (`square` ya da `circle`, varsayılan `square`), `size` tahtanın hücre cinsinden boyu (yoksa
  kareleri kapsayan alan), `center` ortadaki bitiş alanının dış çizgisi (hücre cinsinden nokta
  listesi; yoksa bitiş karelerini kapsayan kare alan), `spinner_ratio` dönen okların yarıçapının
  bitiş alanının yarı boyuna oranı (yoksa arayüzün varsayılanı).

Geri hareketler yolun önceki karesine, yolun ilk karesinden ise ona gelen bağlantının kaynağına
gider. Yol ayrımında birden fazla varış karesi çıkarsa oyuncu kareyi tahtada seçer.

## Autoload'lar
| Ad | Görevi |
|---|---|
| `Tuning` | `data/tuning.json` ayarlarını yükler |
| `SaveStore` | Tercihleri ve yarım kalan oyunu `user://save.json` dosyasında tutar |
| `Localization` | Dili seçer ve saklar (ayarlar penceresinden değiştirilir) |
| `Skins` | Tahta görünümünü seçer ve saklar; `themes/skins/` klasöründeki temaları görünüm ekranı için listeler; `needs_unlock` işaretli temalar (neon, ahşap) ödüllü reklam izlenince kalıcı olarak açılır ve açılanlar `unlocked_themes` tercihinde tutulur (Godot'nun yerleşik `Skin` sınıfıyla çakışmasın diye bu ad) |
| `Boards` | Yeni oyunun tahtasını seçer ve saklar (`board` tercihi); `needs_unlock` işaretli tahtalar (Dört yaprak) ödüllü reklam izlenince kalıcı olarak açılır ve açılanlar `unlocked_boards` tercihinde tutulur. Ağ oyununda kilit yalnızca oyunu kuranın seçimini sınırlar; katılan oyuncunun tahtayı açmış olması gerekmez |
| `Ads` | Reklam sağlayıcısını sarar (AdMob; Gradle'sız derlemede ve testte sahte sağlayıcı); reklamları kaldırma ürünü alındıysa banner ve geçiş reklamını göstermez |
| `Iap` | Satın alma sağlayıcısını sarar (Google Play Billing; Gradle'sız derlemede ve testte sahte sağlayıcı); sahip olunan ürünleri kayıtta da tutar |
| `PlayerColor` | Tek oyunculu oyunda oyuncunun seçtiği rengi saklar (varsayılan yeşil); botlar kalan renkleri alır |
| `PawnGlow` | Tahtadaki taşların ışığının açık/kapalı tercihini ve biçimini (düz ya da nabız) saklar; ilk açılışta açık ve nabızlıdır. Ayarlar penceresinden ve oyun ekranındaki menü tuşundan değiştirilir |
| `Sound` | Ses efektlerini `Effects` ses yolunda çalar; her düğmeye dokunma sesini kendiliğinden bağlar, efektlerin açık/kapalı tercihini saklar |
| `Music` | Arka plan müziğini `Music` ses yolunda çalar (menüde menü döngüsü, oyunda oyun müziği, geçişte kısıp açar); müziğin açık/kapalı tercihini efektlerden ayrı saklar. Ses düzeyi `tuning.json`'daki `audio` bölümündedir |
