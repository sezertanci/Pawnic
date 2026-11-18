class_name DemoScreen
extends Control
## "Nasıl oynanır" demosu: kartları ve hamleleri adım adım gösterir. Her adımda taşlar adımın
## dizilimine konur, el gösterilir, oynanan kart ve taşın yolu vurgulanır, sonra kart atılanlara
## uçar ve taş yürür. Oyuncu İleri ve Geri ile adımlar arasında gezer, Geri önceki adımı
## baştan oynatır, aradaki yuvarlak düğme o anki adımı yeniden oynatır; kapat düğmesiyle demo
## her an kapanır.

## Demo kapatıldığında ya da son adımda Bitir'e basıldığında gelir.
signal closed

const COUNTER_FORMAT := "%d/%d"
const NEXT_KEY := "DEMO_NEXT"
const FINISH_KEY := "DEMO_FINISH"

var _demo: DemoScript
var _settings: GameSettings
var _board: BoardState
var _index := 0
## Her adım değişiminde artar; bekleyen animasyonlar kendi sayılarını görmezse durur.
var _run := 0

@onready var _counter: Label = %Counter
@onready var _deck_pile: PileView = %DeckPile
@onready var _discard_pile: PileView = %DiscardPile
@onready var _board_view: BoardView = %BoardView
@onready var _text: Label = %StepText
@onready var _hand_view: HandView = %HandView
@onready var _cards: CardAnimator = %CardLayer
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	_demo = DemoScript.load_from(DemoScript.PATH)
	(%CloseButton as Button).pressed.connect(close)
	_prev_button.pressed.connect(_on_prev_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	(%ReplayButton as Button).pressed.connect(_on_replay_pressed)
	_cards.deck_pile = _deck_pile
	_cards.discard_pile = _discard_pile


## Demoyu ilk adımdan başlatır.
func open() -> void:
	_settings = Tuning.settings
	_cards.settings = _settings
	_cards.speed_scale = _demo.speed
	_board_view.speed_scale = _demo.speed
	_hand_view.slot_count = _settings.hand_size + 1
	_board = _demo.new_board(_settings)
	_board_view.board = _board
	# Ekran yeni göründüğünde kapların düzeni henüz kurulmamıştır; kartlar yanlış yerden uçmasın
	# diye ilk adım bir kare sonra başlar.
	_run += 1
	var run := _run
	await get_tree().process_frame
	if run == _run:
		_show_step(0)


func close() -> void:
	_run += 1
	_board_view.stop_animation()
	_hand_view.clear()
	closed.emit()


func _on_prev_pressed() -> void:
	_show_step(_index - 1)


func _on_replay_pressed() -> void:
	_show_step(_index)


func _on_next_pressed() -> void:
	if _index == _demo.steps.size() - 1:
		close()
	else:
		_show_step(_index + 1)


func _show_step(index: int) -> void:
	_index = index
	_run += 1
	_board_view.stop_animation()
	_set_preview(null)
	var step := _demo.steps[index]
	step.place(_board)
	_board_view.queue_redraw()
	_counter.text = COUNTER_FORMAT % [index + 1, _demo.steps.size()]
	_text.text = step.text
	_prev_button.disabled = index == 0
	_next_button.text = FINISH_KEY if index == _demo.steps.size() - 1 else NEXT_KEY
	_deck_pile.set_count(_settings.deck_size())
	_discard_pile.set_top(null, _settings, Color.TRANSPARENT, Card.NO_VALUE)
	_show_hand(step)
	_play_step(step, _run)


## Eli gösterir; kartlar yalnızca gösterim içindir, basılmaları bir şey yapmaz.
func _show_hand(step: DemoStep) -> void:
	var playable: Array[bool] = []
	playable.resize(step.hand.size())
	playable.fill(true)
	_hand_view.show_cards(step.hand, _settings, playable)


## Adımın gösterimi: kart çekme, kartın ve hamlenin vurgulanması, kartın atılması ve hamle.
func _play_step(step: DemoStep, run: int) -> void:
	if step.draws and not await _draw_last(step, run):
		return
	if not step.uses_card() or not await _wait(run):
		return
	var move := step.find_move(_board, _demo.player_seat())
	var chosen := Card.NO_VALUE if move == null else move.value
	if step.discards:
		_hand_view.mark_discard()
	_hand_view.highlight(step.card_index)
	if step.played_card().type == Card.Type.JOKER:
		_hand_view.show_chosen(step.card_index, chosen)
	_set_preview(move)
	if not await _wait(run):
		return
	_set_preview(null)
	if not await _send_card(step, chosen, run) or move == null:
		return
	var path := _board.move_path(move)
	var before := _board_view.pawn_centers()
	_board.apply(move)
	await _board_view.animate_move(move, path, before)


## Elin son kartı desteden uçarak gelir; adım bu arada değişmediyse true döner.
func _draw_last(step: DemoStep, run: int) -> bool:
	var last := step.hand.size() - 1
	_hand_view.hold(last)
	await _cards.draw_card(_hand_view.card_rect(last), step.hand[last])
	if run != _run:
		return false
	_show_hand(step)
	return true


## Oynanan kart elden kalkıp atılanlara iner; adım bu arada değişmediyse true döner.
func _send_card(step: DemoStep, chosen: int, run: int) -> bool:
	var color := Skins.current.seat_color(_demo.player_seat())
	var rect := _hand_view.card_rect(step.card_index)
	_hand_view.hold(step.card_index)
	await _cards.discard_card(rect, step.played_card(), color, chosen)
	if run != _run:
		return false
	_discard_pile.set_top(step.played_card(), _settings, color, chosen)
	return true


## Gösterim arasındaki bekleme; adım bu arada değişmediyse true döner.
func _wait(run: int) -> bool:
	await get_tree().create_timer(_demo.pause).timeout
	return run == _run


## Hamlede yürüyecek taşı ve yolunu vurgular; null verilirse vurguyu kaldırır.
func _set_preview(move: Move) -> void:
	var paths: Array[PackedInt32Array] = []
	if move != null:
		paths.append(PackedInt32Array(_board.move_path(move)))
	_board_view.selected_pawn = Move.NO_PAWN if move == null else move.pawn
	_board_view.preview_paths = paths
	_board_view.preview_seat = _demo.player_seat()
	_board_view.queue_redraw()
