class_name WinOverlay
extends Control
## Oyun sonunda tahtanın üstünü karartan kutlama: kazananın taşı, dev başlık, sonuç tablosu ve
## iki düğme. Başlık ve tablo, okunsun diye oyuncunun renginde buzlu camın üstündedir.
## Oyun sürerken bir oyuncu bitirince aynı katman kısa bir duyuru olarak da açılır: karartma, tablo
## ve düğmeler görünmez, dokunuşlar tahtaya geçer ve duyuru kendiliğinden kapanır.
## İçerik küçükten büyüyerek zıplayarak açılır, üstten oyuncu renklerinde konfeti dökülür.

signal replay_pressed
signal home_pressed

## Sıra etiketlerinin çeviri anahtarı (RANK_1 … RANK_4).
const RANK_KEY := "RANK_%d"
## Bitirmeyen oyuncunun tur sütununda görünen işaret.
const NO_ROUND := "—"
## Tablodaki taşların satır yüksekliğine oranı.
const ROW_PAWN_SCALE := 1.6
## Tablo yazılarının tema türü.
const RESULT_STYLE := &"ResultLabel"
const MAIN_MENU_KEY := "MAIN_MENU"
const NEW_GAME_KEY := "NEW_GAME"

var _tween: Tween

@onready var _dim: Control = %Dim
@onready var _content: Control = %Content
@onready var _pawn: PawnIcon = %Pawn
@onready var _title: Label = %Title
@onready var _glass: FrostedGlass = %Glass
@onready var _results: GridContainer = %Results
@onready var _buttons: Control = %Buttons
@onready var _confetti: Confetti = %Confetti


func _ready() -> void:
	(%ReplayButton as Button).pressed.connect(replay_pressed.emit)
	(%HomeButton as Button).pressed.connect(home_pressed.emit)


## Ağ oyununda yeniden oyna düğmesi gizlenir, ana ekran düğmesi yeni oyun kurmaya götürür.
func set_networked(networked: bool) -> void:
	(%ReplayButton as Button).visible = not networked
	(%HomeButton as Button).text = NEW_GAME_KEY if networked else MAIN_MENU_KEY


## Oyun sonunu gösterir: ranking sıralamadaki oyuncuların renkleri (kaplamadaki renk sırası),
## rounds her birinin bitirdiği tur (bitirmediyse MatchResult.NO_ROUND), colors konfetinin
## renkleridir.
func open(ranking: Array[int], rounds: Array[int], colors: Array[Color]) -> void:
	_set_banner(false)
	_show_color(ranking[0], tr("WIN") % Skins.current.seat_name(ranking[0]))
	_fill_results(ranking, rounds)
	_pop(colors)


## Oyun sürerken bitiren oyuncuyu (rengiyle) kısa süre duyurur; place 1'den başlar.
func announce(color: int, place: int, colors: Array[Color]) -> void:
	_set_banner(true)
	_show_color(color, tr("FINISHED") % [Skins.current.seat_name(color), tr(RANK_KEY % place)])
	_pop(colors)
	_tween.tween_interval(Tuning.settings.finish_banner_time)
	_tween.tween_callback(close)


func close() -> void:
	if _tween != null:
		_tween.kill()
	_confetti.stop()
	hide()


## Taşı ve başlığı gösterir; yazıların arkasındaki cam oyuncunun rengini alır.
func _show_color(color: int, title: String) -> void:
	_pawn.color = color
	_title.text = title
	_glass.set_tint(Skins.current.seat_color(color))


## Duyuruda karartma, tablo ve düğmeler gizlenir; katman dokunuşları engellemez.
func _set_banner(banner: bool) -> void:
	_dim.visible = not banner
	_results.visible = not banner
	_buttons.visible = not banner


func _fill_results(ranking: Array[int], rounds: Array[int]) -> void:
	Nodes.free_children(_results)
	for index: int in range(ranking.size()):
		_add_label(tr(RANK_KEY % (index + 1)))
		var pawn := PawnIcon.new()
		_results.add_child(pawn)
		_add_label(Skins.current.seat_name(ranking[index]))
		var finish_round := rounds[index]
		var text := (
			NO_ROUND if finish_round == MatchResult.NO_ROUND else tr("ROUND_N") % finish_round
		)
		_add_label(text)
		pawn.color = ranking[index]
		pawn.custom_minimum_size = Vector2.ONE * _row_height() * ROW_PAWN_SCALE


func _add_label(text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = RESULT_STYLE
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results.add_child(label)


func _row_height() -> float:
	return get_theme_font_size(ThemeKeys.FONT_SIZE, RESULT_STYLE)


func _pop(colors: Array[Color]) -> void:
	if _tween != null:
		_tween.kill()
	show()
	_confetti.burst(colors)
	# Kapların düzeni bir kare sonra kurulur; ölçek merkezden büyüsün diye boy beklenir.
	_content.scale = Vector2.ONE * Tuning.settings.win_pop_start_scale
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_center_pivot)
	_tween.tween_property(_content, ^"scale", Vector2.ONE, Tuning.settings.win_pop_time)


func _center_pivot() -> void:
	_content.pivot_offset = _content.size / 2.0
