class_name DemoStep
extends RefCounted
## Demodaki tek adım: açıklama metni, taşların dizilimi, oyuncunun eli ve (varsa) oynanan ya da
## atılan kart. Hamle, kural motorunun o kartla bulduğu yasal hamleler arasından seçilir;
## böylece demo kurallar değişince kendiliğinden yanlış bir hamle gösteremez.

const NO_CARD := -1
## Adım sözlüğünün anahtarları.
const KEY_TEXT := "text"
const KEY_PAWNS := "pawns"
const KEY_HAND := "hand"
const KEY_DRAW := "draw"
const KEY_CARD := "card"
const KEY_PAWN := "pawn"
const KEY_TARGET := "target"
const KEY_TO := "to"
const KEY_DISCARD := "discard"
const REQUIRED_KEYS: Array[String] = [KEY_TEXT, KEY_PAWNS, KEY_HAND]

## Açıklamanın çeviri anahtarı.
var text := ""
## Her taşın kare adı; başlangıçtaki taş BoardState.BASE_NAME'dir.
var squares: Array = []
var hand: Array[Card] = []
## true ise elin son kartı desteden çekilerek gelir.
var draws := false
## Oynanan ya da atılan kartın eldeki sırası; kart oynanmayan adımda NO_CARD.
var card_index := NO_CARD
## Hamlede seçilen taş (geri yollamada rakip taş) ve yer değiştirmede karşı taş.
var pawn := Move.NO_PAWN
var target := Move.NO_PAWN
## Hamleden sonra pawn'ın durduğu kare adı.
var to := ""
## true ise kart oynanmaz, atılır.
var discards := false


## Sözlükten okur; gerekli anahtar eksikse ya da elde tanınmayan kart varsa null döner.
static func from_dict(data: Dictionary) -> DemoStep:
	if not data.has_all(REQUIRED_KEYS):
		return null
	var step := DemoStep.new()
	step.text = str(data[KEY_TEXT])
	step.squares = data[KEY_PAWNS]
	for entry: Dictionary in data[KEY_HAND]:
		var card := Card.from_dict(entry)
		if card == null:
			return null
		step.hand.append(card)
	step.draws = bool(data.get(KEY_DRAW, false))
	step.card_index = int(data.get(KEY_CARD, NO_CARD))
	step.pawn = int(data.get(KEY_PAWN, Move.NO_PAWN))
	step.target = int(data.get(KEY_TARGET, Move.NO_PAWN))
	step.to = str(data.get(KEY_TO, ""))
	step.discards = bool(data.get(KEY_DISCARD, false))
	return step


## Bu adımda bir kart oynanıyor ya da atılıyorsa true.
func uses_card() -> bool:
	return card_index != NO_CARD


func played_card() -> Card:
	return hand[card_index]


## Taşları adımın dizilimine koyar; kare bilinmiyorsa ya da taş sayısı tutmuyorsa false döner.
func place(board: BoardState) -> bool:
	# load_dict sahipleri temizleyip yeniden doldurur; aynı dizi verilirse boşalır, kopyası verilir.
	var data := {
		BoardState.KEY_OWNERS: board.owners.duplicate(),
		BoardState.KEY_POSITIONS: squares,
	}
	return board.load_dict(data)


## Oynanan kartla yapılabilecek, seçili taşı (ve karşı taşı) to karesine götüren yasal hamle;
## kart atılıyorsa ya da böyle bir hamle yoksa null.
func find_move(board: BoardState, seat: int) -> Move:
	if not uses_card() or discards:
		return null
	var goal := board.layout.index_of(to)
	for move: Move in board.moves_for_card(seat, played_card(), card_index):
		if move.pawn != pawn or (target != Move.NO_PAWN and move.target != target):
			continue
		var after := board.clone()
		after.apply(move)
		if after.positions[pawn] == goal:
			return move
	return null
