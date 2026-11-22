class_name BoardSkin
extends Resource
## Tahtanın görünümü: renkler, saydamlıklar ve oyuncu renklerinin adları.
## Her tema themes/skins/ altında bu türden bir .tres dosyasıdır.

## Oyuncu renkleri renk sırasıyla: kırmızı, mavi, yeşil, sarı. Oyunda bir koltuğun rengi
## SeatColors eşlemesiyle bulunur; birebir eşlemede sıra koltuk sırasıdır (üst, sağ, alt, sol).
@export var seat_colors: Array[Color] = []
## Renk sırasıyla oyuncu adlarının (renk adlarının) çeviri anahtarları.
@export var seat_name_keys: Array[String] = []
@export var background_color := Color.BLACK
## Oyun ekranının arkasına döşenen doku (ör. ahşap masa); boşsa yalnızca background_color görünür.
@export var background_texture: Texture2D
@export var track_color := Color.WHITE
@export var outline_color := Color.BLACK
@export var mark_color := Color.GRAY
@export var highlight_color := Color.WHITE
## Bot zorluk seviyelerinin yazı renkleri, Bot.Level sırasıyla: Kolay, Orta, Zor, Çok Zor.
@export var level_colors: Array[Color] = []
## Seçilmiş taşın (ör. yer değiştirmede kendi taşın) halka rengi.
@export var selected_color := Color.ORANGE
## Zıplayan taşın yere düşen gölgesi.
@export var shadow_color := Color(0, 0, 0, 0.35)
## Başlangıç tepsisindeki taş altlıklarının rengi.
@export var socket_color := Color(0, 0, 0, 0.6)
## Kare dokusundaki alt kalınlık ve üst kenar (kare boyunun oranı); işaretler aradaki yüze çizilir.
@export var square_depth := 0.1
@export var square_top := 0.0
## Kare dokusu (taş); ev yolu da aynı dokuyu sahibinin rengine boyanmış olarak kullanır.
@export var track_texture: Texture2D
## Çember kareli tahtalarda kare dokusu; oranları track_texture ile aynıdır.
@export var round_track_texture: Texture2D
## Kare yüzüne boyanmadan çizilen süs (ör. elmas kakma); işaretli karelerde çizilmez. Boş olabilir.
@export var inlay_texture: Texture2D
## Görünüm ekranındaki kartta gösterilen tahta görseli (tools/screenshot.gd çıktısındaki
## board_preview.png).
@export var preview_texture: Texture2D
## Renk sırasıyla taş görselleri.
@export var pawn_textures: Array[Texture2D] = []
## Ortadaki bitiş alanının ortasındaki harf görseli (uygulama simgesindeki P).
@export var home_letter_texture: Texture2D
## Güvenli karenin rengi ve üstündeki kalkan sembolünün rengi.
@export var safe_color := Color.LIGHT_BLUE
@export var shield_color := Color.STEEL_BLUE
## Kısayol karesi, sahibinin renginin bu oranda beyaza açılmış tonudur.
@export var shortcut_lighten := 0.6
## Ev yolu karelerinin sahibinin rengine ne kadar boyanacağı.
@export var lane_tint := 0.3
## Çıkış karesinin oyuncu rengine ne kadar boyanacağı.
@export var start_tint := 0.5
## Başlangıç alanından çıkan patikada oyuncu renginin zemine karışma oranı: kenar çizgileri
## ve ok işaretleri için, aradaki dolgu için.
@export var link_line_tint := 0.5
@export var link_fill_tint := 0.2
## Tema ancak ödüllü reklam izlenince açılır; açılınca kilit kalıcı olarak kalkar.
@export var needs_unlock := false


func seat_color(color: int) -> Color:
	return seat_colors[color]


func level_color(level: Bot.Level) -> Color:
	return level_colors[level]


func seat_name(color: int) -> String:
	return tr(seat_name_keys[color])
