extends GutTest
## Oyun hızı seviyelerinin data/tuning.json ile uyumu.

const NORMAL_SPEED := 1.0


func test_speed_levels_count_matches_levels() -> void:
	assert_eq(Tuning.settings.speed_levels.size(), GameSpeed.Level.size())


func test_speed_levels_normal_keeps_original_speed() -> void:
	assert_eq(Tuning.settings.speed_levels[GameSpeed.Level.NORMAL], NORMAL_SPEED)


func test_speed_levels_ordered_slow_to_fast() -> void:
	var levels := Tuning.settings.speed_levels
	assert_lt(levels[GameSpeed.Level.SLOW], levels[GameSpeed.Level.NORMAL])
	assert_lt(levels[GameSpeed.Level.NORMAL], levels[GameSpeed.Level.FAST])
