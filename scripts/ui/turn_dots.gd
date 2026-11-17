class_name TurnDots
extends Control
## Oyuncuları sıra düzeninde renkli noktalarla gösterir; sırası gelenin çevresinde halka olur.

const RADIUS := 9.0
const GAP := 10.0
const RING_WIDTH := 3.0
const ARC_POINTS := 24

var _seats: Array[int] = []
var _current := 0


func _ready() -> void:
	Skins.changed.connect(queue_redraw)


## seats sıra düzenindeki koltuklar, current sırası gelenin bu listedeki yeri.
func show_turn(seats: Array[int], current: int) -> void:
	_seats = seats.duplicate()
	_current = current
	var edge := (RADIUS + RING_WIDTH) * 2.0
	custom_minimum_size = Vector2(_step() * (_seats.size() - 1) + edge, edge)
	queue_redraw()


func _step() -> float:
	return RADIUS * 2.0 + GAP


func _draw() -> void:
	var skin := Skins.current
	var ring := RADIUS + RING_WIDTH
	for index: int in range(_seats.size()):
		var center := Vector2(ring + _step() * index, size.y / 2.0)
		draw_circle(center, RADIUS, skin.seat_color(_seats[index]))
		if index == _current:
			draw_arc(center, ring, 0.0, TAU, ARC_POINTS, skin.highlight_color, RING_WIDTH)
