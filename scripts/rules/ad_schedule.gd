class_name AdSchedule
extends RefCounted
## Oyun içi geçiş reklamının zamanlaması. Süre, duraklatmalarda durmayan gerçek saat değil,
## kayda yazılan oyun süresidir (GameMatch.elapsed); böylece oyun kapanıp açılınca aynı yerde
## reklam yeniden çıkmaz.

## Oyunda henüz reklam gösterilmediğini belirtir.
const NO_AD := -1.0


## İnsan oyuncunun sırası başlarken reklam zamanı geldiyse true: son reklamdan (yoksa oyunun
## başından) bu yana en az reklam aralığı kadar oynanmıştır.
static func is_due(game: GameMatch) -> bool:
	if game.is_bot_turn():
		return false
	return game.elapsed - maxf(game.last_ad_at, 0.0) >= game.settings.interstitial_interval


## Oyun içi reklam yakın zamanda gösterildiyse oyun sonu reklamı atlanır.
static func skips_end_ad(game: GameMatch) -> bool:
	return is_recent(game.last_ad_at, game.elapsed, game.settings)


## Oyun süresi elapsed iken last_ad_at anındaki oyun içi reklam, oyun sonu reklamını atlatacak
## kadar yakınsa true (ağ oyununda istemci de kendi saydığı anla kullanır).
static func is_recent(last_ad_at: float, elapsed: float, settings: GameSettings) -> bool:
	if last_ad_at == NO_AD:
		return false
	return elapsed - last_ad_at < settings.end_ad_cooldown
