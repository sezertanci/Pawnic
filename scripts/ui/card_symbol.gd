class_name CardSymbol
extends Control
## Kartlarda yazının yerine çizilen sembol:
## İleri ve geri: iri, konturlu ve gölgeli renkli sayı (+7, −5).
## Yer değiştir: iki taş ve aralarında karşılıklı oklar.
## Çıkış: kutudan dışarı çıkan taş ve ok. Kısayol: ev. Joker: yıldız ve seçilebilen sayı aralığı.
## Sayılı sembollü kartlarda (çıkış sayısı +6, geri yolla −8, sayısı seçilmiş joker) üst yarıda
## iri sayı, alt yarıda küçültülmüş sembol çizilir.
## Yıldız: yalnızca yıldız (kural ekranındaki kazanma simgesi).
## Sembolü olmayan kartlarda gizlidir. Renkler arayüz temasındaki CardSymbol türünden okunur.

enum Kind { NONE, FORWARD, BACK, SWAP, EXIT_FORWARD, EXIT, SEND_BACK, SHORTCUT, JOKER, STAR }

const STYLE := &"CardSymbol"
const PAWN_COLOR := &"pawn_color"
const RIVAL_COLOR := &"rival_color"
const STAR_COLOR := &"star_color"
const INK_COLOR := &"ink_color"
const FORWARD_COLOR := &"forward_color"
const BACK_COLOR := &"back_color"
const NUMBER_FONT := &"number_font"
const LABEL_STYLE := &"CardLabel"
const KIND_BY_TYPE: Dictionary[Card.Type, Kind] = {
	Card.Type.FORWARD: Kind.FORWARD,
	Card.Type.BACK: Kind.BACK,
	Card.Type.SWAP: Kind.SWAP,
	Card.Type.EXIT: Kind.EXIT,
	Card.Type.SEND_BACK: Kind.SEND_BACK,
	Card.Type.SHORTCUT: Kind.SHORTCUT,
	Card.Type.JOKER: Kind.JOKER,
}
## Ölçüler kart genişliğine oranla verilir; yükseklikteki yerler (…_Y) kart boyuna oranladır.
const LINE_RATIO := 0.03
const HEAD_RATIO := 0.08
const HEAD_ANGLE := PI / 6.0
const PAWN_RADIUS := 0.17
const PAWN_Y := 0.48
const TEXT_Y := 0.85
## Sayılı sembollü kartlarda iri sayının kapladığı üst bölüm ve küçük sembolün ortası
## (kart boyuna oranla), sembolün küçültme oranı.
const NUMBER_AREA := 0.5
const SMALL_SYMBOL_Y := 0.72
const SMALL_SYMBOL_SCALE := 0.5
const SWAP_RADIUS := 0.13
const SWAP_PAWN_X := 0.2
const SWAP_ARROW_X := 0.35
const SWAP_ARROW_GAP := 0.07
const ARROW_GAP := 0.05
## Çıkış kartı: kutunun yarı boyu ve merkezi, sağ kenardaki açıklık, kutudaki taş ve ok.
const BOX_HALF := 0.2
const BOX_X := 0.4
const BOX_OPENING := 0.12
const BOX_PAWN_RADIUS := 0.09
## Taşın kutunun sol kenarından uzaklığı (kutu yarı boyuna oranla).
const BOX_PAWN_SHIFT := 0.5
const BOX_ARROW_END := 0.88
## Kutunun dikey yeri (kart boyuna oranla).
const EXIT_Y := 0.5
## Geri yolla: taşı çevreleyen eliptik okun yatay ve dikey yarıçapı; ok sağ üstten başlar,
## taşın üstünden ve solundan dolaşıp sağ altta biter (açılar radyan, ekranda y aşağıdır).
const ORBIT_RADII := Vector2(0.34, 0.25)
const ORBIT_FROM := -PI / 4.0
const ORBIT_TO := -PI * 7.0 / 4.0
## Eliptik okun kalınlığı, normal çizgi kalınlığına oranla.
const ORBIT_WIDTH := 1.6
## Kısayol: kartta evin kapladığı alan (kart boyuna oranla).
const HOUSE_BOUNDS := Rect2(0.2, 0.2, 0.6, 0.42)
## Evin parçaları, kapladığı alana oranla: gövde genişliği, çatı yüksekliği, kapı boyu.
const HOUSE_BODY_WIDTH := 0.73
const ROOF_HEIGHT := 0.43
const DOOR_WIDTH := 0.2
const DOOR_HEIGHT := 0.29
## Joker: yıldızın dış ve iç yarıçapı, köşe sayısı.
const STAR_OUTER := 0.26
const STAR_INNER := 0.11
const STAR_POINTS := 5
const RANGE_TEXT := "1–%d"

var _kind := Kind.NONE
var _value := 0
var _joker_max := 0
## Jokerde oyuncunun seçtiği sayı; seçilmediyse Card.NO_VALUE.
var _chosen := Card.NO_VALUE
## Soluk gösterimde renklerin karıştığı zemin rengi ve karışım oranı (0: hiç).
var _fade_color := Color.WHITE
var _fade := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	hide()


static func kind_for(card: Card, exit_value: int) -> Kind:
	if card.type == Card.Type.FORWARD and card.value == exit_value:
		return Kind.EXIT_FORWARD
	return KIND_BY_TYPE.get(card.type, Kind.NONE)


## Kartın sembolü varsa gösterir, yoksa gizlenir.
func show_card(card: Card, settings: GameSettings) -> void:
	_joker_max = settings.joker_max
	show_symbol(kind_for(card, settings.exit_value), card.value)


## Kart olmadan bir sembol gösterir (ör. kural ekranı). value sıfırsa sayı yazılmaz.
func show_symbol(kind: Kind, value: int = 0) -> void:
	_kind = kind
	_value = value
	_chosen = Card.NO_VALUE
	visible = _kind != Kind.NONE
	queue_redraw()


func _draw() -> void:
	match _kind:
		Kind.FORWARD:
			_draw_number(Card.Type.FORWARD, FORWARD_COLOR, _value, Rect2(Vector2.ZERO, size))
		Kind.BACK:
			_draw_number(Card.Type.BACK, BACK_COLOR, _value, Rect2(Vector2.ZERO, size))
		Kind.SWAP:
			_draw_swap()
		Kind.EXIT_FORWARD:
			_draw_numbered(Card.Type.FORWARD, FORWARD_COLOR, _value, _draw_exit)
		Kind.EXIT:
			_draw_exit()
		Kind.SEND_BACK:
			if _value > 0:
				_draw_numbered(Card.Type.BACK, BACK_COLOR, _value, _draw_send_back)
			else:
				_draw_send_back()
		Kind.SHORTCUT:
			var ink := _color(INK_COLOR)
			var bounds := Rect2(HOUSE_BOUNDS.position * size, HOUSE_BOUNDS.size * size)
			draw_house(self, bounds, _color(PAWN_COLOR), ink, _line_width())
		Kind.JOKER:
			if _chosen == Card.NO_VALUE:
				_draw_star()
				_draw_caption(RANGE_TEXT % _joker_max)
			else:
				_draw_numbered(Card.Type.FORWARD, FORWARD_COLOR, _chosen, _draw_star)
		Kind.STAR:
			_draw_star()


## Jokerde seçilen sayıyı kartın üst bölümünde iri gösterir; Card.NO_VALUE verilirse kaldırır.
func show_chosen(value: int) -> void:
	_chosen = value
	queue_redraw()


## rect alanının ortasına iri sayı; type yalnızca işaretini (+, −) belirler.
func _draw_number(type: Card.Type, color_name: StringName, value: int, rect: Rect2) -> void:
	var text := tr(Card.LABEL_KEYS[type]) % value
	var font := get_theme_font(NUMBER_FONT, STYLE)
	BigNumber.draw(self, font, rect, text, _color(color_name), _color(INK_COLOR))


## Üst yarıda iri sayı, alt yarıda küçültülmüş sembol. draw_symbol sembolü tam kart boyunda
## çizer; ölçekli dönüşümle kartın ortası alt bölüme taşınır.
func _draw_numbered(
	type: Card.Type, color_name: StringName, value: int, draw_symbol: Callable
) -> void:
	_draw_number(type, color_name, value, Rect2(0.0, 0.0, size.x, size.y * NUMBER_AREA))
	var target := Vector2(size.x / 2.0, size.y * SMALL_SYMBOL_Y)
	var offset := target - size / 2.0 * SMALL_SYMBOL_SCALE
	draw_set_transform(offset, 0.0, Vector2.ONE * SMALL_SYMBOL_SCALE)
	draw_symbol.call()
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_swap() -> void:
	var middle := size.y / 2.0
	var gap := size.x * SWAP_ARROW_GAP
	_draw_pawn(Vector2(size.x * SWAP_PAWN_X, middle), SWAP_RADIUS, PAWN_COLOR)
	_draw_pawn(Vector2(size.x * (1.0 - SWAP_PAWN_X), middle), SWAP_RADIUS, RIVAL_COLOR)
	var left := size.x * SWAP_ARROW_X
	var right := size.x - left
	_draw_arrow(Vector2(left, middle - gap), Vector2(right, middle - gap))
	_draw_arrow(Vector2(right, middle + gap), Vector2(left, middle + gap))


## Sağ kenarı açık bir kutu; içindeki taştan dışarıya bir ok çıkar.
func _draw_exit() -> void:
	var center := Vector2(size.x * BOX_X, size.y * EXIT_Y)
	var half := size.x * BOX_HALF
	var opening := size.x * BOX_OPENING
	var top := center.y - half
	var bottom := center.y + half
	var left := center.x - half
	var right := center.x + half
	var outline := PackedVector2Array(
		[
			Vector2(right, top + half - opening),
			Vector2(right, top),
			Vector2(left, top),
			Vector2(left, bottom),
			Vector2(right, bottom),
			Vector2(right, bottom - half + opening),
		]
	)
	SmoothDraw.stroke(self, outline, _color(INK_COLOR), _line_width())
	var pawn := Vector2(left + half * BOX_PAWN_SHIFT, center.y)
	_draw_pawn(pawn, BOX_PAWN_RADIUS, PAWN_COLOR)
	var arrow_start := pawn.x + size.x * (BOX_PAWN_RADIUS + ARROW_GAP)
	_draw_arrow(Vector2(arrow_start, center.y), Vector2(size.x * BOX_ARROW_END, center.y))


## Rakip taş ve onu sağ üstten sağ alta, geriye doğru dolaşan eliptik ok.
func _draw_send_back() -> void:
	var center := _pawn_center()
	_draw_pawn(center, PAWN_RADIUS, RIVAL_COLOR)
	var radii := ORBIT_RADII * size.x
	var orbit := PackedVector2Array()
	for point: Vector2 in SmoothDraw.arc_points(Vector2.ZERO, 1.0, ORBIT_FROM, ORBIT_TO):
		orbit.append(center + point * radii)
	var width := _line_width() * ORBIT_WIDTH
	SmoothDraw.stroke(self, orbit, _color(INK_COLOR), width)
	var tip := orbit[orbit.size() - 1]
	_draw_head(tip, (tip - orbit[orbit.size() - 2]).normalized(), width)


## Ev sembolü: gövde, çatı ve kapı; ölçüler rect'e oranlıdır (tahtadaki kısayol karesi de kullanır).
## Evi bounds alanının tamamını kaplayacak biçimde çizer: çatı üst kenara, saçaklar yan kenarlara,
## gövde alt kenara değer.
static func draw_house(
	canvas: CanvasItem, bounds: Rect2, fill: Color, ink: Color, line_width: float
) -> void:
	var middle := bounds.get_center().x
	var half := bounds.size.x * HOUSE_BODY_WIDTH / 2.0
	var top := bounds.position.y + bounds.size.y * ROOF_HEIGHT
	var bottom := bounds.end.y
	var body := PackedVector2Array(
		[
			Vector2(middle - half, top),
			Vector2(middle + half, top),
			Vector2(middle + half, bottom),
			Vector2(middle - half, bottom),
		]
	)
	SmoothDraw.outlined(canvas, body, fill, ink, line_width)
	var roof := PackedVector2Array(
		[
			Vector2(bounds.position.x, top),
			Vector2(middle, bounds.position.y),
			Vector2(bounds.end.x, top),
		]
	)
	SmoothDraw.outlined(canvas, roof, fill, ink, line_width)
	var door_half := bounds.size.x * DOOR_WIDTH / 2.0
	var door_height := bounds.size.y * DOOR_HEIGHT
	var door := Rect2(middle - door_half, bottom - door_height, door_half * 2.0, door_height)
	canvas.draw_rect(door, ink, true, -1.0, true)


func _draw_star() -> void:
	var center := _pawn_center()
	var points := PackedVector2Array()
	for index: int in range(STAR_POINTS * 2):
		var ratio := STAR_OUTER if index % 2 == 0 else STAR_INNER
		var angle := -PI / 2.0 + PI * index / STAR_POINTS
		points.append(center + Vector2.from_angle(angle) * size.x * ratio)
	SmoothDraw.outlined(self, points, _color(STAR_COLOR), _color(INK_COLOR), _line_width())


## Sembolü zemin rengine karıştırarak soluklaştırır. Saydamlık yerine renk karıştırılır;
## saydam çizimde üst üste binen parçalar (ok ucu ile gövdesi) koyu leke bırakır.
func fade_into(background: Color, amount: float) -> void:
	_fade_color = Color(background, 1.0)
	_fade = amount
	queue_redraw()


func _pawn_center() -> Vector2:
	return Vector2(size.x / 2.0, size.y * PAWN_Y)


func _draw_caption(text: String) -> void:
	var font := get_theme_font(ThemeKeys.FONT, LABEL_STYLE)
	var font_size := get_theme_font_size(ThemeKeys.FONT_SIZE, LABEL_STYLE)
	var baseline := Vector2(0.0, size.y * TEXT_Y)
	draw_string(
		font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, _color(INK_COLOR)
	)


func _draw_pawn(center: Vector2, radius_ratio: float, color_name: StringName) -> void:
	var radius := size.x * radius_ratio
	SmoothDraw.circle(self, center, radius, _color(color_name), _color(INK_COLOR), _line_width())


func _draw_arrow(from: Vector2, to: Vector2) -> void:
	SmoothDraw.stroke(self, PackedVector2Array([from, to]), _color(INK_COLOR), _line_width())
	_draw_head(to, (to - from).normalized())


## Ok ucu: tip noktasında birleşen, direction yönünü gösteren iki kısa çizgi.
## line_width verilmezse normal çizgi kalınlığı kullanılır.
func _draw_head(tip: Vector2, direction: Vector2, line_width: float = 0.0) -> void:
	var back := -direction * size.x * HEAD_RATIO
	var head := PackedVector2Array(
		[tip + back.rotated(HEAD_ANGLE), tip, tip + back.rotated(-HEAD_ANGLE)]
	)
	var width := line_width if line_width > 0.0 else _line_width()
	SmoothDraw.stroke(self, head, _color(INK_COLOR), width)


func _line_width() -> float:
	return size.x * LINE_RATIO


func _color(color_name: StringName) -> Color:
	return get_theme_color(color_name, STYLE).lerp(_fade_color, _fade)
