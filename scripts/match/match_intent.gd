class_name MatchIntent
extends RefCounted
## Oyuncunun hakeme (MatchReferee) bildirdiği niyet: bir hamle oynamak ya da oynayamadığı için
## kart atmak. Hakem niyeti doğrular; geçersiz niyet uygulanmaz.

enum Kind { PLAY, DISCARD }

var kind: Kind
var seat: int
var card_index := MatchEvent.NO_CARD
var move: Move


static func play(player_seat: int, chosen: Move) -> MatchIntent:
	var intent := MatchIntent.new()
	intent.kind = Kind.PLAY
	intent.seat = player_seat
	intent.card_index = chosen.card_index
	intent.move = chosen
	return intent


static func discard(player_seat: int, card: int) -> MatchIntent:
	var intent := MatchIntent.new()
	intent.kind = Kind.DISCARD
	intent.seat = player_seat
	intent.card_index = card
	return intent
