class_name ComingSoonCard
extends Button
## Listelerin sonundaki "Yakında" kartı: yeni tahtaların ya da görünümlerin geleceğini haber
## verir. Mor zeminde altın parıltı simgesi, "Yakında" başlığı ve listeye göre bir alt yazı
## vardır. Tahta listesinde tahta kartı gibi yan yana, görünüm listesinde alt alta ve ortalanmış
## dizilir. Seçilemez; dokununca kısa bir sallanma yapar. Renkler arayüz temasındaki
## ComingSoonCard türlerinden gelir.

const BOARD_TYPE := &"ComingSoonCard"
const SKIN_TYPE := &"ComingSoonSkinCard"
const BOARD_ICON_TYPE := &"ComingSoonIcon"
const SKIN_ICON_TYPE := &"ComingSoonSkinIcon"
const TITLE_TYPE := &"PanelLabel"
const NOTE_TYPE := &"ComingSoonNote"
const SKIN_TITLE_TYPE := &"ComingSoonSkinTitle"
const SKIN_NOTE_TYPE := &"ComingSoonSkinNote"
const STYLE := &"normal"
const SPARKLE_COLOR := &"sparkle_color"
const SEPARATION := &"separation"
const TITLE_KEY := "COMING_SOON"
const BOARD_NOTE_KEY := "COMING_SOON_BOARDS"
const SKIN_NOTE_KEY := "COMING_SOON_THEMES"
const SPARKLE := preload("res://assets/images/icon_sparkle.svg")
## Görünüm listesindeki kartın simge kutusunun boyu; kartın yüksekliğini listedeki öteki kartlar
## belirler.
const SKIN_ICON_SIZE := Vector2(240.0, 240.0)
## Parıltının simge kutusuna oranı.
const SPARKLE_SCALE := 0.62
## Simge ile yazılar arasındaki boşluk: tahta listesinde ve görünüm listesinde.
const GAP := 12
const SKIN_GAP := 28
## Sallanma: ilk salınımın açısı (derece), bir salınımın süresi (sn) ve salınım sayısı. Her
## salınım bir öncekinden küçüktür.
const SHAKE_DEGREES := 3.0
const SHAKE_STEP := 0.06
const SHAKE_SWINGS := 4

var _box: BoxContainer
var _sparkle: TextureRect
## Parmak karta değdiğinde kartın ekrandaki yeri; bırakınca farklıysa dokunuş kaydırmadır.
var _down_at := Vector2.ZERO
var _shake: Tween


## `stacked`: görünüm listesindeki gibi alt alta ve ortalanmış dizilir.
func _init(stacked: bool) -> void:
	theme_type_variation = SKIN_TYPE if stacked else BOARD_TYPE
	# Dokunuş üstteki kaydırma alanına da geçsin; yoksa parmak kartın üstündeyken liste kaymaz.
	mouse_filter = MOUSE_FILTER_PASS
	focus_mode = FOCUS_NONE
	size_flags_horizontal = SIZE_EXPAND_FILL
	if not stacked:
		custom_minimum_size.y = BoardCard.MIN_HEIGHT
	_box = VBoxContainer.new() if stacked else HBoxContainer.new()
	_box.mouse_filter = MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override(SEPARATION, SKIN_GAP if stacked else GAP)
	_box.add_child(_icon(stacked))
	_box.add_child(_texts(stacked))
	add_child(_box)
	button_down.connect(_on_down)
	pressed.connect(_on_pressed)
	resized.connect(_on_resized)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		Nodes.fit_inside(_box, get_theme_stylebox(STYLE))
		_sparkle.modulate = get_theme_color(SPARKLE_COLOR)


## Ortasında parıltı olan yuvarlak köşeli kutu; tahta listesinde tahta görseli boyundadır.
func _icon(stacked: bool) -> PanelContainer:
	var holder := PanelContainer.new()
	holder.theme_type_variation = SKIN_ICON_TYPE if stacked else BOARD_ICON_TYPE
	holder.custom_minimum_size = SKIN_ICON_SIZE if stacked else BoardCard.THUMB_SIZE
	holder.size_flags_horizontal = SIZE_SHRINK_CENTER
	holder.size_flags_vertical = SIZE_SHRINK_CENTER
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	_sparkle = Nodes.picture(SPARKLE, holder.custom_minimum_size * SPARKLE_SCALE)
	_sparkle.size_flags_horizontal = SIZE_SHRINK_CENTER
	_sparkle.size_flags_vertical = SIZE_SHRINK_CENTER
	holder.add_child(_sparkle)
	return holder


func _texts(stacked: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_FILL if stacked else SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = MOUSE_FILTER_IGNORE
	var align := HORIZONTAL_ALIGNMENT_CENTER if stacked else HORIZONTAL_ALIGNMENT_LEFT
	if stacked:
		column.add_child(_label(TITLE_KEY, SKIN_TITLE_TYPE, align))
		column.add_child(_label(SKIN_NOTE_KEY, SKIN_NOTE_TYPE, align))
	else:
		column.add_child(_label(TITLE_KEY, TITLE_TYPE, align))
		column.add_child(_label(BOARD_NOTE_KEY, NOTE_TYPE, align))
	return column


func _label(key: String, type: StringName, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = key
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _on_down() -> void:
	_down_at = global_position


## Liste kaydırılırken kart yer değiştirdiyse dokunuş sayılmaz.
func _on_pressed() -> void:
	if global_position.is_equal_approx(_down_at):
		_wiggle()


## Kart ortası çevresinde sağa sola giderek küçülen salınımlarla sallanır.
func _wiggle() -> void:
	if _shake != null:
		_shake.kill()
	rotation = 0.0
	_shake = create_tween()
	var angle := deg_to_rad(SHAKE_DEGREES)
	for swing: int in range(SHAKE_SWINGS):
		var side := 1.0 if swing % 2 == 0 else -1.0
		var fade := 1.0 - float(swing) / SHAKE_SWINGS
		_shake.tween_property(self, "rotation", side * angle * fade, SHAKE_STEP)
	_shake.tween_property(self, "rotation", 0.0, SHAKE_STEP)


func _on_resized() -> void:
	pivot_offset = size / 2.0
