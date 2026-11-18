class_name BotProfile
extends RefCounted
## Bir bot seviyesinin davranışı. Değerler data/tuning.json → bot.levels içindedir.

## Botun en iyi hamle yerine rastgele bir yasal hamle yapma olasılığı (0–1).
var random_chance := 0.0
## Hamle seçerken karşılığı hesaplanan rakip sayısı, sıradaki rakipten başlayarak (0: hiçbiri).
var reply_rivals := 0
## Bot, taşların sıradaki turda çarpılma olasılığını görünmeyen kartlardan hesaplar.
var read_threats := false
## Aday hamle başına ileri oynatılan olası oyun sayısı (0: arama yok). Bkz. RolloutSearch.
var rollouts := 0
## Aramaya giren en iyi aday sayısı.
var shortlist := 0


static func from_dict(data: Dictionary) -> BotProfile:
	var profile := BotProfile.new()
	profile.random_chance = float(data["random_chance"])
	profile.reply_rivals = int(data["reply_rivals"])
	profile.read_threats = bool(data["read_threats"])
	profile.rollouts = int(data["rollouts"])
	profile.shortlist = int(data["shortlist"])
	return profile
