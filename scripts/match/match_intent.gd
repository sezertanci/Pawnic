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


## Ağ mesajı için sözlüğe çevirir.
func to_dict() -> Dictionary:
	var data := {
		MessageData.KEY_KIND: kind,
		MessageData.KEY_SEAT: seat,
		MessageData.KEY_CARD_INDEX: card_index
	}
	if move != null:
		data[MessageData.KEY_MOVE] = move.to_dict()
	return data


## Mesajdan okur; bozuksa null döner. Oynama niyetinde hamle zorunludur. Yasallığı hakem denetler.
static func from_dict(data: Dictionary) -> MatchIntent:
	var intent_kind := MessageData.read_int(data, MessageData.KEY_KIND)
	var player_seat := MessageData.read_int(data, MessageData.KEY_SEAT)
	var card := MessageData.read_int(data, MessageData.KEY_CARD_INDEX)
	if not MessageData.is_enum_value(intent_kind, Kind.values()):
		return null
	if player_seat == MessageData.INVALID or card == MessageData.INVALID:
		return null
	if intent_kind == Kind.DISCARD:
		return discard(player_seat, card)
	var chosen := Move.from_dict(MessageData.read_dict(data, MessageData.KEY_MOVE))
	return null if chosen == null else play(player_seat, chosen)
