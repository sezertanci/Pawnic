class_name ToggleSwitch
extends Button
## Açık/kapalı anahtarı: yuvarlak uçlu bir yol ve üstünde kayan bir topuz. Açıkken topuz sağda,
## yol açık rengindedir. Renkler temadaki ToggleSwitch türünden okunur.

const TRACK_ON := &"track_on"
const TRACK_OFF := &"track_off"
const KNOB := &"knob"
## Topuzun, yolun yüksekliğine oranla yarıçapı.
const KNOB_RATIO := 0.38


func _init() -> void:
	toggle_mode = true
	toggled.connect(_on_toggled)


func _draw() -> void:
	var radius := size.y / 2.0
	var left := Vector2(radius, radius)
	var right := Vector2(size.x - radius, radius)
	var track := get_theme_color(TRACK_ON if button_pressed else TRACK_OFF)
	draw_line(left, right, track, size.y)
	draw_circle(left, radius, track)
	draw_circle(right, radius, track)
	var knob_center := right if button_pressed else left
	draw_circle(knob_center, size.y * KNOB_RATIO, get_theme_color(KNOB), true, -1.0, true)


func _on_toggled(_on: bool) -> void:
	queue_redraw()
