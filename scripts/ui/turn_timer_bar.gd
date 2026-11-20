class_name TurnTimerBar
extends ProgressBar
## Sıradaki oyuncunun sıra süresini gösteren çubuk: oyuncunun renginde azalır, solunda kalan
## saniye yazar. Son saniyelerde yazı uyarı rengine döner, çubuk her saniye uyarı renginde bir
## ışık yayıp söner ve tik sesi çalar. Çubuğun stilleri, uyarı rengi ve ışığın genişliği temadaki
## TurnTimerBar türünden gelir.

const FILL_STYLE := &"fill"
const BACKGROUND_STYLE := &"background"
const WARNING_COLOR := &"warning_color"
const GLOW_SIZE := &"glow_size"
const FONT_COLOR := &"font_color"
## Henüz tik sesi çalmadıysa son tik saniyesi yerine kullanılır.
const NO_SECOND := -1

## Temadaki dolgu stilinin bu çubuğa ait kopyası; rengi oyuncuya göre değişir.
var _fill: StyleBoxFlat
## Temadaki zemin stilinin kopyası; gölgesi uyarı ışığı olarak kullanılır.
var _background: StyleBoxFlat
## Son tik sesinin çaldığı saniye; uyarı süresinde her yeni saniyede bir tik çalar.
var _ticked_second := NO_SECOND

@onready var _seconds: Label = $Seconds


func _ready() -> void:
	_fill = _own_style(FILL_STYLE)
	_background = _own_style(BACKGROUND_STYLE)
	_background.shadow_size = get_theme_constant(GLOW_SIZE)


## limit saniyelik süreden left saniye kaldığını gösterir; warning saniye ya da daha az kalınca
## yazı uyarı rengine döner, çubuk her saniye ışık yayar ve tik sesi çalar.
func show_time(left: float, limit: float, warning: float, color: Color) -> void:
	visible = true
	max_value = limit
	value = left
	_fill.bg_color = color
	_seconds.text = str(ceili(left))
	if left <= warning:
		_warn(left)
	else:
		_calm()


## Saniye yazısıyla birlikte çubuğu üst düğümdeki left–right yatay aralığına (piksel) sığdırır;
## yazı aralığın solunda, çubuk onun sağında durur.
func fit_between(left: float, right: float) -> void:
	offset_left = left - _seconds.offset_left
	offset_right = right - get_parent_control().size.x


## Çubuğu gizler; sıradaki süre baştan sayılır.
func stop() -> void:
	visible = false
	_ticked_second = NO_SECOND
	_calm()


## Işık her yeni saniyenin başında en parlaktır ve saniye bitene kadar söner.
func _warn(left: float) -> void:
	var warning_color := get_theme_color(WARNING_COLOR)
	_seconds.add_theme_color_override(FONT_COLOR, warning_color)
	_background.shadow_color = Color(warning_color, left - floorf(left))
	_tick(ceili(left))


func _calm() -> void:
	_seconds.remove_theme_color_override(FONT_COLOR)
	_background.shadow_color = Color.TRANSPARENT


func _tick(second: int) -> void:
	if second != _ticked_second:
		_ticked_second = second
		Sound.play(Sound.TICK)


func _own_style(style_name: StringName) -> StyleBoxFlat:
	var style := get_theme_stylebox(style_name).duplicate() as StyleBoxFlat
	add_theme_stylebox_override(style_name, style)
	return style
