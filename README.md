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
  `godot --headless --path . -s tools/simulate.gd`
- Ekran görüntüleri: `godot --path . --resolution 720x1280 -s tools/screenshot.gd -- <klasör>`
- Biçim ve lint: `gdformat scripts tools tests` ve `gdlint scripts tools tests`
- Ses efektleri (`assets/sounds/`): `python tools/make_sounds.py assets/sounds` (yalnızca Python standart kütüphanesi)
- İkonlar (`assets/icon/`): `python tools/make_icon.py assets/images assets/icon` (Pillow gerekir).
  Önceki yazılı ikon `assets/icon/text/` altında saklanır:
  `python tools/make_icon.py assets/images assets/icon/text --design text`.
  Açılış ekranının görseli (`assets/icon/frame/icon.png`):
  `python tools/make_icon.py assets/images assets/icon/frame --design frame --size 1024`

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

## Klasörler
- `data/tuning.json`: kullanılan tahta dosyası, kural, deste ve bot ayarları
- `data/boards/`: tahta tasarımları (aşağıda)
- `data/translations.csv`: oyuncuya görünen metinlerin 8 dildeki karşılıkları
- `scripts/rules/`: kural motoru (`BoardState`, `GameMatch`, `MovePicker`), kartlar ve bot
- `scripts/ui/`: tahta çizimi, el, ana ekran, yeni oyun ve oyun ekranları
- `scripts/autoload/`: genel servisler (aşağıda)
- `scripts/services/`: reklam ve satın alma sağlayıcı arayüzleri ile sahte sürümleri
- `scenes/`: ana sahne, ekranlar ve ortak bileşenler
- `themes/`: arayüz teması ve tahta görünümleri (`themes/skins/`)
- `tests/unit/`: GUT birim testleri, `tests/fixtures/`: testlerde kullanılan deneme tahtası
- `tools/`: simülasyon, ekran görüntüsü, ses ve ikon üretme betikleri

## Tahta dosyası
Tahta bir ızgara üzerindeki kareler ve aralarındaki bağlantılardan oluşur; kod tahtanın şeklini
bilmez. Kullanılan dosya `data/tuning.json` içindeki `board.layout` ayarıyla seçilir.

- `paths`: kare dizileri. `points` köşe hücreleridir; aradaki hücreler kendiliğinden doldurulur
  (ardışık noktalar yatay, dikey ya da tam çapraz hizada olmalıdır). `loop: true` yolu kapatır.
  `owner` verilen yol yalnızca o koltuğa aittir (ev yolu gibi). Kareler `"yol:sıra"` diye anılır,
  sıra 0'dan başlar (ör. `"ring:8"`).
- `links`: yollar arası geçişler. `seats` boşsa herkes kullanır. `mode`:
  - `forced`: bu koltuklar kareden her zaman bağlantıya girer (ev yolu girişi).
  - `choice`: taş kareden geçerken ya da kareden başlarken oyuncu yolu seçer.
  - `exact`: bağlantıya yalnızca hamleye o karede başlayan taş girebilir.
- `safe`: güvenli kareler.
- `speed`: hız kareleri ve değerleri (ör. `{"ring:4": 4, "ring:18": -3}`). Artı değerde taş o kadar ileri,
  eksi değerde o kadar geri gider (geri giderken sahibinin çıkış karesinde durur). Bir hız karesinden
  zıplayan taş başka bir hız karesine düşmemelidir; birim test bunu denetler.
- `seats`: her koltuğun çıkış (`start`), ev (`home`) ve kısayol (`shortcut`) karesi ile başlangıç
  alanının hücre cinsinden merkezi (`base`).

Geri hareketler yolun önceki karesine, yolun ilk karesinden ise ona gelen bağlantının kaynağına
gider. Yol ayrımında birden fazla varış karesi çıkarsa oyuncu kareyi tahtada seçer.

## Autoload'lar
| Ad | Görevi |
|---|---|
| `Tuning` | `data/tuning.json` ayarlarını yükler |
| `SaveStore` | Tercihleri ve yarım kalan oyunu `user://save.json` dosyasında tutar |
| `Localization` | Dili seçer ve saklar |
| `Skins` | Tahta görünümünü seçer ve saklar (Godot'nun yerleşik `Skin` sınıfıyla çakışmasın diye bu ad) |
| `Ads` | Reklam sağlayıcısını sarar; şimdilik sahte sağlayıcı kullanılır |
| `Iap` | Satın alma sağlayıcısını sarar; şimdilik sahte sağlayıcı kullanılır |
| `Sound` | Ses efektlerini çalar; her düğmeye dokunma sesini kendiliğinden bağlar |
