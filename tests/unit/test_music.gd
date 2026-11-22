extends GutTest
## Müzik ve ses efekti ayarlarının birbirinden bağımsızlığı, müzik ayarlarının tuning ile uyumu,
## tam ekran reklamda müziğin duraklayıp sürmesi, kutlama seslerinde müziğin kısılıp
## yeniden açılması. Oyuncunun kayıtlı tercihleri ve reklam
## duraklatması her testten sonra eski haline döner.

## Geçişin bitmesi için fazladan beklenen süre ve ses düzeyi karşılaştırmasındaki pay.
const FADE_MARGIN_SEC := 0.2
const VOLUME_TOLERANCE_DB := 0.01

var _music_was_enabled := true
var _sound_was_enabled := true


func before_each() -> void:
	_music_was_enabled = Music.is_enabled()
	_sound_was_enabled = Sound.is_enabled()


func after_each() -> void:
	Music.set_enabled(_music_was_enabled)
	Sound.set_enabled(_sound_was_enabled)
	Ads.interstitial_closed.emit()


func test_set_enabled_off_mutes_only_music_bus() -> void:
	Sound.set_enabled(true)

	Music.set_enabled(false)

	assert_true(_is_muted(Music.BUS))
	assert_false(_is_muted(Sound.BUS))


func test_set_enabled_off_for_sound_keeps_music_playing() -> void:
	Music.set_enabled(true)

	Sound.set_enabled(false)

	assert_true(_is_muted(Sound.BUS))
	assert_false(_is_muted(Music.BUS))


func test_set_enabled_saves_preference() -> void:
	Music.set_enabled(false)

	assert_false(Music.is_enabled())


func test_buses_are_separate_from_master() -> void:
	assert_ne(AudioServer.get_bus_index(Music.BUS), -1)
	assert_ne(AudioServer.get_bus_index(Sound.BUS), -1)
	assert_ne(AudioServer.get_bus_index(Music.BUS), AudioServer.get_bus_index(Sound.BUS))


func test_music_volume_stays_below_effects() -> void:
	assert_lt(Tuning.settings.music_volume_db, 0.0)
	assert_gt(Tuning.settings.music_fade_time, 0.0)


func test_menu_music_is_quieter_than_game_music() -> void:
	var menu_db := Music.volume_of(Music.Track.MENU)
	var game_db := Music.volume_of(Music.Track.GAME)

	assert_eq(menu_db, Tuning.settings.menu_music_volume_db)
	assert_eq(game_db, Tuning.settings.music_volume_db)
	assert_lt(menu_db, game_db)


func test_streams_loop() -> void:
	for track: Music.Track in Music.STREAMS:
		var stream := Music.STREAMS[track] as AudioStreamWAV
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)


func test_full_screen_ad_pauses_music_and_silences_bus() -> void:
	Music.play(Music.Track.MENU)

	Ads.full_screen_started.emit()

	assert_true(_player(Music.Track.MENU).stream_paused)
	assert_eq(_bus_volume(), Music.SILENT_DB)


func test_ad_closed_resumes_music_and_restores_bus() -> void:
	Music.play(Music.Track.MENU)
	Ads.full_screen_started.emit()

	Ads.rewarded_completed.emit("test", true)
	await wait_seconds(Tuning.settings.music_fade_time + FADE_MARGIN_SEC)

	assert_false(_player(Music.Track.MENU).stream_paused)
	assert_almost_eq(_bus_volume(), Music.BUS_FULL_DB, VOLUME_TOLERANCE_DB)


func test_play_ducking_sound_lowers_music_bus() -> void:
	Sound.set_enabled(true)

	Sound.play(Sound.HOME)
	await wait_seconds(Tuning.settings.music_duck_time + FADE_MARGIN_SEC)

	assert_almost_eq(_bus_volume(), Tuning.settings.music_duck_db, VOLUME_TOLERANCE_DB)


func test_duck_restores_music_bus_after_hold() -> void:
	var settings := Tuning.settings

	Music.duck(0.0)
	await wait_seconds(settings.music_duck_time + settings.music_unduck_time + FADE_MARGIN_SEC)

	assert_almost_eq(_bus_volume(), Music.BUS_FULL_DB, VOLUME_TOLERANCE_DB)


func test_duck_during_full_screen_ad_keeps_bus_silent() -> void:
	Ads.full_screen_started.emit()

	Music.duck(0.0)
	await wait_seconds(Tuning.settings.music_duck_time + FADE_MARGIN_SEC)

	assert_eq(_bus_volume(), Music.SILENT_DB)


func _player(track: Music.Track) -> AudioStreamPlayer:
	for player: AudioStreamPlayer in Music.get_children():
		if player.stream == Music.STREAMS[track]:
			return player
	return null


func _bus_volume() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Music.BUS))


func _is_muted(bus: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))
