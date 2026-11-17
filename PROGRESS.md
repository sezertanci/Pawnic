# Pawnic — ilerleme

## Kararlar
- Ad: **Pawnic**. Kart tabanlı yarış tahtası; zar yok, strateji var. Hedefe ilk varan kazanır, süre yok.
- Aynı telefonda 2–4 kişi. Bot yalnızca tek oyunculu modda. Sunucu ve ağ yok.
- Ekran dikey. Birden çok insan oyuncu varsa her sırada "telefonu ver" ekranı çıkar.
- Belirli bir mevcut oyunun kopyası yapılmaz.
- Oyun prototip değil, yayımlanacak ürün olarak geliştirilir. Paket adı `com.sezertanci.pawnic`.
- Diller: tr, en, de, es, fr, it, pt, id; hepsi tek `data/translations.csv` dosyasında.
- Gelir: ödüllü/geçiş reklamı ve uygulama içi satın alma. İkisi de arayüzle sarıldı; gerçek
  eklentiler seçilene kadar sahte sağlayıcılar çalışır. Geçiş reklamı oyunun ortasında gösterilmez.
- Yarım kalan oyun her tur başında kaydedilir; açılışta "Devam et" çıkar.
- Tema altyapısı kuruldu (`BoardSkin`, `Skins` autoload'u); şimdilik tek tema: `classic`.
- Testler GUT ile; derlemeler Gradle ile (APK tablet, AAB Play). Ayrı tasarım dokümanı yok.
- Tahta tasarımı koddan ayrıldı: tahta `data/boards/*.json` dosyasındaki kareler ve bağlantılardan
  oluşan bir graftır (biçim README'de). Şekil serbesttir; yol ayrımları için her bağlantıda mod
  seçilir: `forced` (zorunlu), `choice` (geçerken seçilebilir), `exact` (yalnızca o karede duran
  taş girer). Yol ayrımında oyuncu varış karesini tahtada seçer. Şimdilik tek tahta var
  (`classic.json`, eski tahtanın aynısı); hangi tahtanın kullanılacağı `tuning.json`'dan gelir,
  tahta seçim ekranı yok.

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
- Deste (44 kart): İleri 1–6 (4'er), İleri 8 ve 10 (2'şer), Geri 3 (3), Geri 5 (2), Çıkış (4),
  Yer değiştir (2), Geri yolla 8 (2), Kısayol (1), Joker (2).
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
- Oyun süresi uzun olabilir (4 taşta oyuncu başına ~55 tur). Deneme sonrası kısaltma gerekebilir.
- Hangi ek temaların olacağı kararlaştırılmadı.
- Dil ve tema seçimi için ayarlar ekranı yok (altyapı hazır). Ses açma/kapama ayarı da yok.
- AdMob eklentisi seçilmedi; UMP rıza ekranı eklenecek (hedef kitle 13 yaş ve üstü).
- Play Billing için resmi eklenti eklenecek; ürün listesi belli değil.
- Yükleme (upload) anahtarı oluşturulmadı; AAB release derlemesi bunu bekliyor.
- Çeviriler Claude tarafından yazıldı; anadili konuşan biri tarafından kontrol edilmeli.
- Kullanıcının tablet denemesinden çıkan değişiklik listesi bekleniyor.
- El boyutu (3+1) deneme sonrası kesinleşecek.
- Kartlarda ve tahtada hareket yönünü gösteren ok yok.
- Hız kareleri artık simetrik değil; renkler arasında avantaj farkı olup olmadığı simülasyonla ölçülmedi.
- Yer değiştirmede taşlar düz kayıyor, ışık kuyruğu yok.
- Proje simgesi yok (dışa aktarmada uyarı veriyor).
- Bot basit (tek hamle ileri bakar); zorluk seviyesi yok.
- Yeni tahta tasarımları (ör. köşeden eve bağlantı) ve birden fazla tahta olup olmayacağı belli değil.
- Kısayol kartı tahtada tanımlı kısayol karesine götürür; dallanan tahtalarda anlamı yeniden
  düşünülmeli.
- Başlangıçtaki taşlar birbirinin aynı olduğu için çıkışta taş seçmek gereksiz. Seçenekler: tek
  anlamlı hamlesi olan kartı dokununca oynamak, çıkış karesine dokunmak, kartta onay.
- Çıkış kartı yerine her sayı kartıyla taş çıkarma fikri (şimdilik ertelendi). Seçenekler: taş
  yalnızca çıkış karesine konur / taş sayı − 1 ilerler / yalnızca 1 ve 6 çıkarır. Önce simülasyonla
  ölçülecek.

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
