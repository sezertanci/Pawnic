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
@export var highlight_color := Color.WHITE
## Seçilmiş taşın (ör. yer değiştirmede kendi taşın) halka rengi.
@export var selected_color := Color.ORANGE
## Zıplayan taşın yere düşen gölgesi.
@export var shadow_color := Color(0, 0, 0, 0.35)
## Kabarık karenin alt kenar kalınlığı (kare boyunun oranı).
@export var square_depth := 0.1
## Taşın alt kalınlığı (yarıçapın oranı).
@export var pawn_depth := 0.2
## Kare ve taşların gölgede kalan alt kenarının ne kadar koyulaşacağı.
@export var edge_darken := 0.35
## Taşın üstündeki ışık lekesi.
@export var shine_color := Color(1, 1, 1, 0.35)
## Güvenli karenin rengi ve üstündeki kalkan sembolünün rengi.
@export var safe_color := Color.LIGHT_BLUE
@export var shield_color := Color.STEEL_BLUE
## Kısayol karesi, sahibinin renginin bu oranda beyaza açılmış tonudur.
@export var shortcut_lighten := 0.6
## Ev yolu karelerinin saydamlığı.
@export var lane_alpha := 0.5
## Başlangıç alanının saydamlığı.
@export var base_alpha := 0.25
## Çıkış karesinin oyuncu rengine ne kadar boyanacağı.
@export var start_tint := 0.5


func seat_color(seat: int) -> Color:
	return seat_colors[seat]


func seat_name(seat: int) -> String:
	return tr(seat_name_keys[seat])
