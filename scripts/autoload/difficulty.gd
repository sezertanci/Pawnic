extends Node
## Oyuncunun yeni oyun ekranında en son seçtiği bot zorluk seviyesi; oyuncu tercihi olarak
## saklanır. İlk açılışta Orta seçilidir.

const PREFERENCE_KEY := "bot_level"
## Seviye adlarının çeviri anahtarı öneki (BOT_EASY, BOT_MEDIUM, BOT_HARD, BOT_EXPERT).
const LEVEL_KEY_PREFIX := "BOT_"


func current() -> Bot.Level:
	return (
		SaveStore.get_enum_preference(PREFERENCE_KEY, Bot.Level.values(), Bot.Level.MEDIUM)
		as Bot.Level
	)


func select(level: Bot.Level) -> void:
	SaveStore.set_preference(PREFERENCE_KEY, level)


func level_key(level: Bot.Level) -> String:
	return LEVEL_KEY_PREFIX + str(Bot.Level.keys()[level])
