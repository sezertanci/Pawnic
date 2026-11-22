extends Node
## Arka plan müziğini çalar: menü ekranlarında menü döngüsü, oyun ekranında oyun müziği. Parça
## değişince eskisi kısılırken yenisi açılır. Müziğin açık ya da kapalı olduğu oyuncu tercihi
## olarak saklanır (ilk açılışta açık); kapalıyken yalnızca müzik ses yolu susturulur, efektler
## bundan etkilenmez. Tam ekran reklam açılırken müzik duraklar, reklam kapanınca kaldığı yerden
## yumuşakça açılarak sürer. Kutlama sesleri çalarken müzik bir süre kısılır (duck), ses bitince
## yeniden açılır. Ses düzeyi ve süreler data/tuning.json'dan gelir.
## Müzik dosyaları tools/make_music.py ile üretilir.

enum Track { NONE, MENU, GAME }

const PREFERENCE_KEY := "music"
const BUS := &"Music"
## Geçişte kısılan parçanın indiği ses düzeyi (dB); duyulmaz.
const SILENT_DB := -60.0
## Müzik ses yolunun normal düzeyi (dB); parçaların kendi düzeyi tuning'den gelir.
const BUS_FULL_DB := 0.0
const STREAMS: Dictionary[Track, AudioStream] = {
	Track.MENU: preload("res://assets/music/menu.wav"),
	Track.GAME: preload("res://assets/music/game.wav"),
}

var _players: Dictionary[Track, AudioStreamPlayer] = {}
var _tweens: Dictionary[Track, Tween] = {}
var _current := Track.NONE
var _bus_tween: Tween
var _paused_for_ad := false


func _ready() -> void:
	for track: Track in STREAMS:
		var player := AudioStreamPlayer.new()
		player.stream = STREAMS[track]
		player.bus = BUS
		add_child(player)
		_players[track] = player
	_apply(is_enabled())
	Ads.full_screen_started.connect(_pause_for_ad)
	Ads.interstitial_closed.connect(_resume_after_ad)
	Ads.rewarded_completed.connect(_resume_after_ad.unbind(2))


## Verilen parçaya geçer; o parça zaten çalıyorsa bir şey yapmaz.
func play(track: Track) -> void:
	if _current == track:
		return
	if _current != Track.NONE:
		_fade(_current, SILENT_DB, true)
	_current = track
	var player := _players[track]
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	_fade(track, volume_of(track), false)


## Parçanın normal ses düzeyi (dB): menü müziği oyun müziğinden biraz kısıktır.
func volume_of(track: Track) -> float:
	if track == Track.MENU:
		return Tuning.settings.menu_music_volume_db
	return Tuning.settings.music_volume_db


func current() -> Track:
	return _current


func is_enabled() -> bool:
	var value: Variant = SaveStore.get_preference(PREFERENCE_KEY, true)
	return value if value is bool else true


func set_enabled(enabled: bool) -> void:
	SaveStore.set_preference(PREFERENCE_KEY, enabled)
	_apply(enabled)


func _apply(enabled: bool) -> void:
	AudioServer.set_bus_mute(_bus_index(), not enabled)


## Müziği hızla kısar, hold saniye öyle tutar, sonra normal düzeyine açar. Art arda gelirse son
## isteğe göre yeniden başlar. Reklam sırasında müzik zaten sustuğu için bir şey yapmaz.
func duck(hold: float) -> void:
	if _paused_for_ad:
		return
	var settings := Tuning.settings
	_kill_bus_tween()
	_bus_tween = create_tween()
	_bus_tween.tween_method(
		_set_bus_volume, _bus_volume(), settings.music_duck_db, settings.music_duck_time
	)
	_bus_tween.tween_interval(hold)
	_bus_tween.tween_method(
		_set_bus_volume, settings.music_duck_db, BUS_FULL_DB, settings.music_unduck_time
	)


## Reklam açılırken ses yolu hemen susturulur ve parçalar oldukları yerde duraklatılır.
func _pause_for_ad() -> void:
	_paused_for_ad = true
	_set_paused(true)
	_kill_bus_tween()
	_set_bus_volume(SILENT_DB)


## Reklam kapanınca parçalar kaldıkları yerden sürer, ses yolu yumuşakça açılır.
func _resume_after_ad() -> void:
	_paused_for_ad = false
	_set_paused(false)
	_kill_bus_tween()
	_bus_tween = create_tween()
	_bus_tween.tween_method(
		_set_bus_volume, _bus_volume(), BUS_FULL_DB, Tuning.settings.music_fade_time
	)


func _set_paused(paused: bool) -> void:
	for player: AudioStreamPlayer in _players.values():
		player.stream_paused = paused


func _kill_bus_tween() -> void:
	if _bus_tween != null:
		_bus_tween.kill()


func _set_bus_volume(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index(), volume_db)


func _bus_volume() -> float:
	return AudioServer.get_bus_volume_db(_bus_index())


func _bus_index() -> int:
	return AudioServer.get_bus_index(BUS)


## Parçanın ses düzeyini yumuşakça değiştirir; aynı parçanın yarım kalan geçişi iptal edilir
## (hızlı ekran değişiminde kısılmakta olan parça yeniden açılabilir).
func _fade(track: Track, volume_db: float, stop_after: bool) -> void:
	if _tweens.has(track):
		_tweens[track].kill()
	var player := _players[track]
	var tween := create_tween()
	_tweens[track] = tween
	tween.tween_property(player, "volume_db", volume_db, Tuning.settings.music_fade_time)
	if stop_after:
		tween.tween_callback(player.stop)
