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
}

## Kart sırası verilmediğinde kullanılır.
const NO_CARD := -1

var kind: Kind
var seat := BoardLayout.NO_SEAT
var card_index := NO_CARD
var value := Card.NO_VALUE
var drew := false
var move: Move
var path: Array[int] = []
var place := 0


func _init(event_kind: Kind, event_seat := BoardLayout.NO_SEAT) -> void:
	kind = event_kind
	seat = event_seat
