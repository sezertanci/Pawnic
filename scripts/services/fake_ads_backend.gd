class_name FakeAdsBackend
extends AdsBackend
## Geliştirme ve testte kullanılan sahte reklam: reklam göstermez, ödülü hemen verir.

var grant_rewards := true
var interstitials_shown := 0


func is_rewarded_ready() -> bool:
	return true


func show_rewarded(placement: String) -> void:
	rewarded_completed.emit.call_deferred(placement, grant_rewards)


func show_interstitial() -> void:
	interstitials_shown += 1
