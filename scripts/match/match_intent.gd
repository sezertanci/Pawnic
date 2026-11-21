class_name MatchIntent
extends RefCounted
## Oyuncunun hakeme (MatchReferee) bildirdiği niyet: bir hamle oynamak, oynayamadığı için
## kart atmak ya da ödüllü reklamla desteden kart almak. Hakem niyeti doğrular; geçersiz niyet
## uygulanmaz.

enum Kind {
	PLAY,
	DISCARD,
	## Ödüllü reklamı başlatır; hakem desteden kart tekliflerini hazırlar.
	REWARD_START,
	## Teklif edilen kartlardan offer_index'tekini card_index'teki kartın yerine alır.
	REWARD_TAKE,
	## Reklam izlenmedi ya da oyuncu vazgeçti; ödül kart verilmeden kapanır.
	REWARD_CANCEL,
}

## Mesaj sözlüğünün anahtarı.
const KEY_OFFER_INDEX := "offer_index"
## Teklif sırası verilmediğinde kullanılır.
const NO_OFFER := -1

var kind: Kind
var seat: int
var card_index := MatchEvent.NO_CARD
var move: Move
var offer_index := NO_OFFER


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


## Ödül niyeti (REWARD_START, REWARD_TAKE ya da REWARD_CANCEL).
static func reward(
	reward_kind: Kind, player_seat: int, offer := NO_OFFER, card := MatchEvent.NO_CARD
) -> MatchIntent:
	var intent := MatchIntent.new()
	intent.kind = reward_kind
	intent.seat = player_seat
	intent.offer_index = offer
	intent.card_index = card
	return intent


## Ödül niyetiyse true.
func is_reward() -> bool:
	return kind >= Kind.REWARD_START


## Ağ mesajı için sözlüğe çevirir.
func to_dict() -> Dictionary:
	var data := {
		MessageData.KEY_KIND: kind,
		MessageData.KEY_SEAT: seat,
		MessageData.KEY_CARD_INDEX: card_index,
		KEY_OFFER_INDEX: offer_index,
	}
	if move != null:
		data[MessageData.KEY_MOVE] = move.to_dict()
	return data


## Mesajdan okur; bozuksa null döner. Oynama niyetinde hamle zorunludur. Yasallığı hakem denetler.
static func from_dict(data: Dictionary) -> MatchIntent:
	var intent_kind := MessageData.read_int(data, MessageData.KEY_KIND)
	var player_seat := MessageData.read_int(data, MessageData.KEY_SEAT)
	var card := MessageData.read_int(data, MessageData.KEY_CARD_INDEX)
	var offer := MessageData.read_int(data, KEY_OFFER_INDEX)
	if not MessageData.is_enum_value(intent_kind, Kind.values()):
		return null
	if [player_seat, card, offer].has(MessageData.INVALID):
		return null
	if intent_kind >= Kind.REWARD_START:
		return reward(intent_kind as Kind, player_seat, offer, card)
	if intent_kind == Kind.DISCARD:
		return discard(player_seat, card)
	var chosen := Move.from_dict(MessageData.read_dict(data, MessageData.KEY_MOVE))
	return null if chosen == null else play(player_seat, chosen)
