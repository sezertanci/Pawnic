extends Node
## Ses efektlerini çalar. Ağaca eklenen her düğmeye dokunma sesi kendiliğinden bağlanır.
## Sesin açık ya da kapalı olduğu oyuncu tercihi olarak saklanır;
## kapalıyken ana ses yolu susturulur.
## Ses dosyaları tools/make_sounds.py ile üretilir.

const TAP := &"tap"
const STEP := &"step"
const TELEPORT := &"teleport"
const DRAW := &"draw"
const SOUNDS_DIR := "res://assets/sounds/"
const SOUND_EXTENSION := ".wav"
## Aynı sesin üst üste binebilecek en çok kopyası (art arda zıplamalar için).
const POLYPHONY := 4
const PREFERENCE_KEY := "sound"
const MASTER_BUS := &"Master"

var _players: Dictionary[StringName, AudioStreamPlayer] = {}


func _ready() -> void:
	for sound: StringName in [TAP, STEP, TELEPORT, DRAW]:
		var player := AudioStreamPlayer.new()
		player.stream = load(SOUNDS_DIR + sound + SOUND_EXTENSION)
		player.max_polyphony = POLYPHONY
		add_child(player)
		_players[sound] = player
	get_tree().node_added.connect(_on_node_added)
	_apply(is_enabled())


func play(sound: StringName) -> void:
	_players[sound].play()


func is_enabled() -> bool:
	var value: Variant = SaveStore.get_preference(PREFERENCE_KEY, true)
	return value if value is bool else true


func set_enabled(enabled: bool) -> void:
	SaveStore.set_preference(PREFERENCE_KEY, enabled)
	_apply(enabled)


func _apply(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), not enabled)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null:
		button.pressed.connect(play.bind(TAP))
