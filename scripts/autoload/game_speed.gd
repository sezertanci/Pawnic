extends Node
## Oyuncunun seçtiği oyun hızı: kart uçuşları ve taş yürüyüşü bu hızla oynatılır. Seçim oyuncu
## tercihi olarak saklanır; seviyelerin çarpanları data/tuning.json içindedir. Botun bekleme
## süreleri hızdan etkilenmez.

enum Level { SLOW, NORMAL, FAST }

const PREFERENCE_KEY := "game_speed"
## Seviye düğmelerinin çeviri anahtarı öneki (SPEED_SLOW, SPEED_NORMAL, SPEED_FAST).
const LEVEL_KEY_PREFIX := "SPEED_"


func current() -> Level:
	return SaveStore.get_enum_preference(PREFERENCE_KEY, Level.values(), Level.NORMAL) as Level


func select(level: Level) -> void:
	SaveStore.set_preference(PREFERENCE_KEY, level)


## Seçili seviyenin animasyon hız çarpanı.
func speed_scale() -> float:
	return Tuning.settings.speed_levels[current()]


func level_key(level: Level) -> String:
	return LEVEL_KEY_PREFIX + str(Level.keys()[level])
