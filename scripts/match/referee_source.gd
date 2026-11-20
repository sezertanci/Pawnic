class_name RefereeSource
extends MatchSource
## Hakemden (MatchReferee) beslenen oyun kaynağı: yerel oyunda ve ağ oyununda hostta. Kaynak,
## kurulduğu andaki oyuna bağlıdır; hakem başka oyuna geçince ya da durunca kaynak bayatlar.
## Yerel oyunda görünüm sırası gelen insan oyuncunundur (sıra botta ise bitirmemiş ilk insanın);
## ağ oyununda hostun kendi koltuğunundur. Hakem düğümü silinirse (host odayı kapattı) kaynak da
## bayatlar.

var _referee: MatchReferee
var _game: GameMatch
## Ağ oyununda hostun koltuğu; yerel oyunda NO_SEAT.
var _own_seat: int
## Ağ oyununda odanın kodu; yerel oyunda boş.
var _room_code: String


## Hakemin start()'ından sonra kurulur.
func _init(referee: MatchReferee, own_seat := BoardLayout.NO_SEAT, room_code := "") -> void:
	_referee = referee
	_game = referee.game
	_own_seat = own_seat
	_room_code = room_code
	_referee.event_emitted.connect(_on_event)


func view() -> MatchView:
	return MatchView.of(_game, _viewer())


func elapsed() -> float:
	return _game.elapsed


func begin() -> void:
	if is_live():
		_referee.begin()


func acknowledge(_event: MatchEvent) -> void:
	if is_live():
		_referee.acknowledge()


func submit(intent: MatchIntent) -> void:
	if not is_live() or not _referee.submit(intent):
		push_warning("Hakem niyeti reddetti: koltuk %d, tür %d" % [intent.seat, intent.kind])
		intent_rejected.emit()


func is_awaiting_intent() -> bool:
	return is_live() and _referee.is_awaiting_intent()


func turn_time_left() -> float:
	return _referee.turn_time_left() if is_live() else MatchReferee.NO_TURN_TIMER


func leave() -> void:
	if is_live():
		_referee.leave()


func detach() -> void:
	if is_instance_valid(_referee) and _referee.event_emitted.is_connected(_on_event):
		_referee.event_emitted.disconnect(_on_event)


func is_live() -> bool:
	return is_instance_valid(_referee) and _referee.game == _game


func is_networked() -> bool:
	return _own_seat != BoardLayout.NO_SEAT


func is_host() -> bool:
	return is_networked()


func room_code() -> String:
	return _room_code


func shares_device() -> bool:
	return not is_networked() and _game.playing_human_count() > 1


func skips_end_ad() -> bool:
	return AdSchedule.skips_end_ad(_game)


func bot_level() -> Bot.Level:
	return _game.bot_level


func speed_scale() -> float:
	return GameSpeed.speed_scale()


func _viewer() -> int:
	if is_networked():
		return _own_seat
	if not _game.is_bot_turn():
		return _game.current_seat()
	for index: int in range(_game.seats.size()):
		if not _game.bots[index] and _game.is_playing(index):
			return _game.seats[index]
	return BoardLayout.NO_SEAT


func _on_event(event: MatchEvent) -> void:
	if is_live():
		event_emitted.emit(event)
