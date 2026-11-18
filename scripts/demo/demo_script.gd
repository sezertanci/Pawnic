class_name DemoScript
extends RefCounted
## "Nasıl oynanır" demosunun senaryosu: data/demo_steps.json dosyasındaki koltuklar, koltuk
## başına taş sayısı, gösterimler arasındaki bekleme ve adımlar. Oyuncu ilk koltuktur.

const PATH := "res://data/demo_steps.json"
const KEY_SEATS := "seats"
const KEY_PAWNS_PER_SEAT := "pawns_per_seat"
const KEY_PAUSE := "pause_sec"
const KEY_SPEED := "speed"
const KEY_STEPS := "steps"
const REQUIRED_KEYS: Array[String] = [
	KEY_SEATS, KEY_PAWNS_PER_SEAT, KEY_PAUSE, KEY_SPEED, KEY_STEPS
]

var seats: Array[int] = []
var pawns_per_seat := 0
## Kartın gösterilmesiyle oynanması arasındaki bekleme (saniye).
var pause := 0.0
## Animasyonların hız çarpanı; oyuncunun hız ayarından bağımsızdır ki demo izlenebilsin.
var speed := 0.0
var steps: Array[DemoStep] = []


## Dosyayı okur; dosya ya da adımlardan biri okunamazsa hatayı yazar ve null döner.
static func load_from(path: String) -> DemoScript:
	var root := JsonData.read(path, REQUIRED_KEYS)
	if root.is_empty():
		return null
	var demo := DemoScript.new()
	for seat: Variant in root[KEY_SEATS]:
		demo.seats.append(int(seat))
	demo.pawns_per_seat = int(root[KEY_PAWNS_PER_SEAT])
	demo.pause = float(root[KEY_PAUSE])
	demo.speed = float(root[KEY_SPEED])
	for entry: Dictionary in root[KEY_STEPS]:
		var step := DemoStep.from_dict(entry)
		if step == null:
			push_error("Demo adımı okunamadı: %s" % entry)
			return null
		demo.steps.append(step)
	return demo


## Oyuncunun koltuğu.
func player_seat() -> int:
	return seats[0]


## Koltuklara taşları dizilmiş, bütün taşları başlangıçta boş bir tahta.
func new_board(settings: GameSettings) -> BoardState:
	var board := BoardState.new(settings)
	for seat: int in seats:
		board.add_pawns(seat, pawns_per_seat)
	return board
