class_name BoardSkin
extends Resource
## Tahtanın görünümü: renkler, saydamlıklar ve oyuncu renklerinin adları.
## Her tema themes/skins/ altında bu türden bir .tres dosyasıdır.

## Koltuk sırasıyla oyuncu renkleri: üst, sağ, alt, sol.
@export var seat_colors: Array[Color] = []
## Koltuk sırasıyla oyuncu adlarının çeviri anahtarları.
@export var seat_name_keys: Array[String] = []
@export var background_color := Color.BLACK
@export var track_color := Color.WHITE
@export var outline_color := Color.BLACK
@export var mark_color := Color.GRAY
## Karelerdeki hız sayılarının rengi; koyu konturla çizilir.
@export var speed_text_color := Color.WHITE
@export var highlight_color := Color.WHITE
## Seçilmiş taşın (ör. yer değiştirmede kendi taşın) halka rengi.
@export var selected_color := Color.ORANGE
## Zıplayan taşın yere düşen gölgesi.
@export var shadow_color := Color(0, 0, 0, 0.35)
## Kare dokusundaki alt kalınlık ve üst kenar (kare boyunun oranı); işaretler aradaki yüze çizilir.
@export var square_depth := 0.1
@export var square_top := 0.0
## Dış yolun (taş) ve ev yolunun (çimen) kare dokuları.
@export var track_texture: Texture2D
@export var lane_texture: Texture2D
## Koltuk sırasıyla taş görselleri.
@export var pawn_textures: Array[Texture2D] = []
## Güvenli karenin rengi ve üstündeki kalkan sembolünün rengi.
@export var safe_color := Color.LIGHT_BLUE
@export var shield_color := Color.STEEL_BLUE
## Kısayol karesi, sahibinin renginin bu oranda beyaza açılmış tonudur.
@export var shortcut_lighten := 0.6
## Ev yolundaki çimenin sahibinin rengine ne kadar boyanacağı.
@export var lane_tint := 0.3
## Başlangıç alanının saydamlığı.
@export var base_alpha := 0.25
## Çıkış karesinin oyuncu rengine ne kadar boyanacağı.
@export var start_tint := 0.5


func seat_color(seat: int) -> Color:
	return seat_colors[seat]


func seat_name(seat: int) -> String:
	return tr(seat_name_keys[seat])
