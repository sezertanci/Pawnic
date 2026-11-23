class_name MatchEvent
extends RefCounted
## Hakemin (MatchReferee) oyunda olan bir şeyi bildirdiği olay. Ekran olayları sırayla çizer;
## hakem her olaydan sonra ekranın bitirdiğini bekler.

enum Kind {
	## Deste boştu; atılanlar karıştırılıp yeni deste yapıldı.
	RESHUFFLED,
	## Geçiş reklamı zamanı geldi; saat reklam boyunca durur.
	AD_DUE,
	## Sıradaki oyuncu (seat) sırasına başladı; drew, desteden kart çektiyse true.
	TURN_STARTED,
	## Oyuncu card_index'teki kartı oynamak ya da atmak üzere açtı; value jokerde seçilen sayıdır.
	CARD_REVEALED,
	## Hamle (move) uygulandı; path, taşın hamleden önce hesaplanan yoludur.
	MOVE_PLAYED,
	## card_index'teki kart oynanmadan atıldı.
	DISCARDED,
	## Oyuncu (seat) bütün taşlarını eve getirdi; place kaçıncı bitiren olduğudur.
	PLAYER_FINISHED,
	## Oyun bitti.
	MATCH_OVER,
	## Oyuncu (seat) ödüllü reklamı başlattı; offers, desteden teklif edilen kartlardır.
	## Sıra süresi ve saat ödül bitene kadar durur.
	REWARD_STARTED,
	## Ödül bitti: card_index'teki kart desteden alınan kartla (card) değişti; card_index
	## NO_CARD ise kart alınmadı.
	REWARD_ENDED,
}

## Kart sırası verilmediğinde kullanılır.
const NO_CARD := -1
## Mesaj sözlüğünün anahtarları.
const KEY_DREW := "drew"
const KEY_PATH := "path"
const KEY_PLACE := "place"
const KEY_CARD := "card"
const KEY_OFFERS := "offers"
const KEY_TOP_DISCARD := "top_discard"
## Ödül olayları; sıradaki oyuncunun niyeti bu olaylarda da beklenmeye devam eder.
const REWARD_KINDS: Array[Kind] = [Kind.REWARD_STARTED, Kind.REWARD_ENDED]
## Kartı yalnızca oyuncunun kendisine yazılan (gizli) olaylar.
const PRIVATE_CARD_KINDS: Array[Kind] = [Kind.TURN_STARTED, Kind.REWARD_ENDED]

var kind: Kind
var seat := BoardLayout.NO_SEAT
var card_index := NO_CARD
var value := Card.NO_VALUE
var drew := false
var move: Move
var path: Array[int] = []
var place := 0
## TURN_STARTED'da çekilen kart; CARD_REVEALED, MOVE_PLAYED ve DISCARDED'da açılan kart.
var card: Card
## REWARD_STARTED'da desteden teklif edilen kartlar; yalnızca oyuncunun kendisine yazılır.
var offers: Array[Card] = []
## REWARD_ENDED'da atılanlardan alınan kartın yerine üste konan kart; üst değişmediyse null.
## Herkese yazılır.
var top_discard: Card
## TURN_STARTED'da tur ve hakemin saatindeki geçen süre; istemci saatini buna eşitler.
var round_number := 0
var elapsed := 0.0
## Ağ oyununda hostun olaya verdiği sıra numarası; istemci olayı bitirince hosta geri gönderir.
var serial := 0


func _init(event_kind: Kind, event_seat := BoardLayout.NO_SEAT) -> void:
	kind = event_kind
	seat = event_seat


## Ağ mesajı için sözlüğe çevirir. Çekilen kart ve ödül kartları gizlidir: TURN_STARTED ve
## REWARD_ENDED'da kart, REWARD_STARTED'da teklifler yalnızca oyuncunun kendisine
## (viewer_seat == seat) yazılır.
func to_dict(viewer_seat: int) -> Dictionary:
	var data := {
		MessageData.KEY_KIND: kind,
		MessageData.KEY_SEAT: seat,
		MessageData.KEY_CARD_INDEX: card_index,
		Card.KEY_VALUE: value,
		KEY_DREW: drew,
		KEY_PATH: path,
		KEY_PLACE: place,
		GameMatch.KEY_ROUND: round_number,
		GameMatch.KEY_ELAPSED: elapsed,
	}
	if move != null:
		data[MessageData.KEY_MOVE] = move.to_dict()
	if card != null and (not PRIVATE_CARD_KINDS.has(kind) or viewer_seat == seat):
		data[KEY_CARD] = card.to_dict()
	if not offers.is_empty() and viewer_seat == seat:
		data[KEY_OFFERS] = Card.write_all(offers)
	if top_discard != null:
		data[KEY_TOP_DISCARD] = top_discard.to_dict()
	return data


## Mesajdan okur; tür tanınmıyorsa ya da bir alan bozuksa null döner.
static func from_dict(data: Dictionary) -> MatchEvent:
	var event_kind := MessageData.read_int(data, MessageData.KEY_KIND)
	if not MessageData.is_enum_value(event_kind, Kind.values()):
		return null
	var event := MatchEvent.new(
		event_kind as Kind, MessageData.read_int(data, MessageData.KEY_SEAT)
	)
	event.card_index = MessageData.read_int(data, MessageData.KEY_CARD_INDEX)
	event.value = MessageData.read_int(data, Card.KEY_VALUE)
	event.place = MessageData.read_int(data, KEY_PLACE)
	event.round_number = MessageData.read_int(data, GameMatch.KEY_ROUND)
	var numbers: Array[int] = [
		event.seat, event.card_index, event.value, event.place, event.round_number
	]
	var event_path: Variant = MessageData.read_ints(data, KEY_PATH)
	var drew_flag: Variant = data.get(KEY_DREW)
	var clock: Variant = data.get(GameMatch.KEY_ELAPSED)
	if numbers.has(MessageData.INVALID) or event_path == null:
		return null
	if not drew_flag is bool or not MessageData.is_number(clock):
		return null
	event.path = event_path
	event.drew = drew_flag
	event.elapsed = float(clock)
	return event if event._read_parts(data) else null


## İsteğe bağlı hamle, kartlar ve teklifleri okur; anahtar varsa ama içeriği bozuksa false.
func _read_parts(data: Dictionary) -> bool:
	if data.has(MessageData.KEY_MOVE):
		move = Move.from_dict(MessageData.read_dict(data, MessageData.KEY_MOVE))
		if move == null:
			return false
	if data.has(KEY_CARD):
		card = Card.from_dict(MessageData.read_dict(data, KEY_CARD))
		if card == null:
			return false
	if data.has(KEY_TOP_DISCARD):
		top_discard = Card.from_dict(MessageData.read_dict(data, KEY_TOP_DISCARD))
		if top_discard == null:
			return false
	return not data.has(KEY_OFFERS) or Card.read_all(data[KEY_OFFERS], offers)
