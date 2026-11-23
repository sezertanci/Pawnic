extends GutTest
## Oyun hızı seviyelerinin data/tuning.json ile uyumu ve seçim değişince haber verilmesi.
## Oyuncunun kayıtlı hız tercihi her testten sonra eski haline döner.

const NORMAL_SPEED := 1.0

var _old_level := GameSpeed.Level.NORMAL


func before_each() -> void:
	_old_level = GameSpeed.current()


func after_each() -> void:
	GameSpeed.select(_old_level)


func test_select_stores_level_and_emits_changed() -> void:
	watch_signals(GameSpeed)

	GameSpeed.select(GameSpeed.Level.FAST)

	assert_eq(GameSpeed.current(), GameSpeed.Level.FAST)
	assert_signal_emitted(GameSpeed, "changed")


func test_speed_levels_count_matches_levels() -> void:
	assert_eq(Tuning.settings.speed_levels.size(), GameSpeed.Level.size())


func test_speed_levels_normal_keeps_original_speed() -> void:
	assert_eq(Tuning.settings.speed_levels[GameSpeed.Level.NORMAL], NORMAL_SPEED)


func test_speed_levels_ordered_slow_to_fast() -> void:
	var levels := Tuning.settings.speed_levels
	assert_lt(levels[GameSpeed.Level.SLOW], levels[GameSpeed.Level.NORMAL])
	assert_lt(levels[GameSpeed.Level.NORMAL], levels[GameSpeed.Level.FAST])
