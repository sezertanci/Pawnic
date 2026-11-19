# Pawnic — proje kuralları

Global `CLAUDE.md` kuralları bu projede de geçerlidir: çalışma biçimi, dil kuralları, genel tasarım
ilkeleri (OOP, SOLID, DRY, KISS, YAGNI, kısa metotlar, sihirli sayı yok), Git ve proje düzeni.
C#/.NET ve Angular'a özgü kuralların yerine aşağıdaki Godot kuralları uygulanır.

Oyun prototip değildir; Play'de yayımlanacak bir ürünün temelidir.

## Yol haritası
- `PROGRESS.md` projenin yol haritasıdır. Her oturumun başında okunur.
- Alınan kararlar, açık kalan konular ve ileride yapılacak fikirler bu dosyaya Türkçe olarak eklenir.
- Ayrı bir tasarım dokümanı yoktur.

## Çalışma düzeni
- Bütün geliştirme ve derleme bilgisayarda yapılır.
- Test için USB ile bağlı tablete yüklenir ve orada kontrol edilir.
- Telefonda testi kullanıcı yapar, sonuçları bildirir. Telefona yalnızca Play'in dahili test
  kanalından yüklenir.

## Teknoloji
- Godot 4 (kararlı son sürüm), GDScript, Compatibility (OpenGL ES 3) işleyicisi.
- Sunucu ve ağ yoktur; oyun tek cihazda oynanır.
- Android derlemeleri Gradle ile alınır: tablet için "Android APK", Play için "Android AAB".
  Tablette hızlı deneme için Gradle'sız "Android APK (hızlı)" kullanılır.
- Fizik motoru kullanılmaz.

## Kod stili
- Kod, dosya, düğüm ve sinyal adları İngilizce ve `snake_case`, sınıf adları `PascalCase`.
- Yorumlar ve README Türkçe.
- Tip bildirimi zorunludur, `untyped_declaration` uyarısı hata sayılır.
- Biçim ve lint için `gdformat` ve `gdlint` (gdtoolkit) kullanılır; `scripts`, `tools` ve `tests`
  temiz olmalıdır.

## Mimari
- Ayar değerleri ve deste kodda sabit sayı olarak durmaz, `data/tuning.json` içinde tutulur.
- Tahtanın şekli kodda durmaz; `data/boards/*.json` dosyasından `BoardLayout` ile okunur. Kural
  motoru ve çizim kare indeksleri ve bağlantılarla çalışır, kare halka ya da kenar uzunluğu
  varsaymaz. Biçim README'de anlatılır.
- Oyuncuya görünen metinler `data/translations.csv` içinde 8 dilde (tr, en, de, es, fr, it, pt, id)
  tutulur, kodda `tr()` ile çağrılır. Yeni anahtar eklenince 8 dil birden doldurulur.
- Renkler kodda durmaz; tahta görünümü `BoardSkin` kaynaklarından (`themes/skins/`), arayüz
  `themes/ui_theme.tres` temasından gelir.
- Kural motoru (`BoardState`, `GameMatch`, `MovePicker`) arayüzden bağımsızdır; bot ve testler
  onu doğrudan kullanır.
- Ekranlar ayrı sahnelerdir (`scenes/`); ekranlar arası geçişi `main.gd` yönetir.
- Bağımlılıklar autoload'lar üzerinden verilir: `Tuning`, `SaveStore`, `Localization`, `Skins`,
  `Ads`, `Iap`. Tema autoload'unun adı `Skins`'tir; Godot'da yerleşik `Skin` sınıfı vardır.
- Reklam ve satın alma `AdsBackend` / `IapBackend` arayüzleriyle sarılır; testte ve gerçek eklenti
  seçilene kadar sahte sürümler kullanılır.
- Yarım kalan oyun her tur başında `SaveStore`'a yazılır; kayıt biçimi değişirse
  `GameMatch.SAVE_VERSION` artırılır.
- Rastgelelik tohumlanabilir `RandomNumberGenerator` ile verilir.
- Geçiş reklamı oyun sonunda ve uzun oyunlarda `data/tuning.json`'daki aralıkla (5 dk) yalnızca
  insan oyuncunun sırası başlamadan önce gösterilir; kart seçerken ya da taş yürürken gösterilmez.
  Zamanlama `AdSchedule`'dadır. Analitik SDK eklenmez.

## Test
- Birim testler GUT ile `tests/unit/` altında yazılır; isimler `test_<davranış>` biçimindedir ve
  Arrange–Act–Assert yapısını izler.
- Kural motoru, kayıt ve sağlayıcılar birim testlerle kapsanır.
- Kural değişikliğinden sonra `tools/simulate.gd` çalıştırılır; bitmeyen oyun kalmamalıdır.
- Arayüz değişikliğinden sonra `tools/screenshot.gd` ile ekran görüntüsü alınıp kontrol edilir.

## Sürüm
- Play'e yeni AAB yüklenecekse `export_presets.cfg` içindeki üç presette `version/code` ve
  `version/name` birlikte yükseltilir: kod 1 artar, adın ara sürümü 1 artar
  (ör. `2` / `1.1.0` → `3` / `1.2.0`). Play'de `<kod> (<ad>)` biçiminde görünür.
- Sürüm notları Play'e `<tr-TR>…</tr-TR>` ve `<en-US>…</en-US>` etiketleriyle girilir.

## Depo
- `.godot/`, `build/`, `android/`, imza anahtarı ve şifreler depoya girmez.
