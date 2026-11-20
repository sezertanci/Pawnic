class_name MatchReferee
extends Node
## Oyunun hakemi: sıra akışını yürütür, botları oynatır, oyuncunun niyetini doğrulayıp uygular
## ve oyun süresini sayar. Arayüzü bilmez; olan her şeyi olay (MatchEvent) olarak yayar ve
## ekranın olayı çizip acknowledge() çağırmasını bekler. Ağ oyununda eşlerin ekranları da
## beklenir: olayı dinleyen her bekletme (hold) bırakılana (release) kadar sıradaki olay yayılmaz.
## Kayıt verildiyse her sıranın başında oyun kaydedilir, oyun bitince kayıt silinir (ağ oyununda
## kayıt yoktur). Sıra süresi verildiyse (ağ oyunu) insan oyuncunun niyeti beklenmeye başlayınca
## süre işler; süre dolarsa o hamleyi bot oynar, koltuk oyuncuda kalır.

## Bir olay yayıldı; dinleyen, olayı bitirince acknowledge() çağırır.
signal event_emitted(event: MatchEvent)
## Ekran ve bütün bekletmeler olayı bitirdi (ya da hakem durdu).
signal acknowledged
## İnsan oyuncunun sıra süresi başladı: seconds saniye içinde niyet gelmezse hamleyi bot oynar.
## Cihaz durup (uygulama arka plandaydı) devam edince kalan süreyle yeniden yayılır.
signal turn_timer_started(seat: int, seconds: float)

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
## Sıra süresi işlemiyorken kalan süre yerine verilir.
const NO_TURN_TIMER := -1.0

## Yarım kalan oyunun yazıldığı kayıt; null ise oyun kaydedilmez.
var store: SaveStoreScript
## false ise oyun içi geçiş reklamı zamanı hiç gelmez (ağ oyunu).
var in_game_ads := true
## İnsan oyuncunun bir sırada niyetini verme süresi (saniye); 0 ise süre yoktur (yerel oyun).
var turn_time_limit := 0.0
## Yönetilen oyun; durunca null.
var game: GameMatch

## Bütün bot oyuncuların ortak botu.
var _bot: Bot
## Oyun sürerken true; geçen süre yalnızca bu sırada sayılır.
var _clock_running := false
## Yayılan olayın bitirilmesi bekleniyorsa true.
var _waiting_ack := false
## Ekranın son olayı bitirmesi bekleniyorsa true.
var _screen_busy := false
## Son olayı ekranla birlikte bitirmesi beklenen başka taraf sayısı (ağ oyununda eşler).
var _holds := 0
## Sıradaki insan oyuncunun niyeti bekleniyorsa true.
var _awaiting_intent := false
## Olayı yayılmış bitiren oyuncu sayısı.
var _announced := 0
## Sıra süresinden kalan (saniye); süre işlemiyorsa NO_TURN_TIMER.
var _turn_time_left := NO_TURN_TIMER


## Oyunu devralır; ilk sıra begin() ile başlar (ekran arada başlangıç kurasını gösterebilir).
func start(match_game: GameMatch) -> void:
	stop()
	game = match_game
	_announced = match_game.finishers.size()
	# Her oyunun botu kendi üretecini kullanır: önceki oyunun süren araması onunla çakışmaz.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_bot = Bot.new(match_game.settings.bot_profiles[match_game.bot_level], match_game.settings, rng)


## Saati başlatır ve sıradaki oyuncunun sırasını açar.
func begin() -> void:
	_clock_running = true
	_start_turn()


## Oyunu bırakır; bekleyen olaylar ve bot adımları oyun değiştiği için kendiliğinden sonlanır.
func stop() -> void:
	game = null
	_clock_running = false
	_stop_awaiting()
	_screen_busy = false
	_holds = 0
	_settle()


## Oyuncu oyundan çıkıyor: sıra başındaki kayıt durur, yalnızca geçen süre güncellenir.
func leave() -> void:
	if game != null and store != null and store.has_match():
		var saved := store.load_match()
		saved[GameMatch.KEY_ELAPSED] = game.elapsed
		store.store_match(saved)
	stop()


## Ekran son olayı bitirdi; bekletme kalmadıysa hakem akışa devam eder.
func acknowledge() -> void:
	_screen_busy = false
	_settle()


## Son olayı bir taraf daha bitirmeli; event_emitted dinleyicisinde çağrılır.
func hold() -> void:
	_holds += 1


## Bekletmelerden biri olayı bitirdi (ya da artık beklenmiyor).
func release() -> void:
	if _holds > 0:
		_holds -= 1
		_settle()


## Koltuğu bota verir (ağ oyununda çıkan ya da bağlantısı kopan oyuncu); sıra o koltuktaysa ve
## niyeti bekleniyorsa hamleyi hemen bot oynar.
func hand_to_bot(seat: int) -> void:
	var index := game.seats.find(seat)
	if index == GameMatch.NO_INDEX or game.bots[index]:
		return
	game.bots[index] = true
	if _awaiting_intent and game.current == index:
		_stop_awaiting()
		_play_bot_turn()


## Bota verilen koltuğu oyuncuya geri verir (bağlantısı kopan oyuncu döndü). Süren bot hamlesi
## biter; oyuncu sonraki sırasında oynar.
func take_back(seat: int) -> void:
	var index := game.seats.find(seat)
	if index != GameMatch.NO_INDEX:
		game.bots[index] = false


## Sıradaki insan oyuncunun niyeti bekleniyorsa true.
func is_awaiting_intent() -> bool:
	return _awaiting_intent


## Sıra süresinden kalan (saniye); süre işlemiyorsa NO_TURN_TIMER.
func turn_time_left() -> float:
	return _turn_time_left


## Niyeti doğrular ve geçerliyse uygular; geçersizse (sıra onun değil, hamle yasal değil) false.
func submit(intent: MatchIntent) -> bool:
	if not _awaiting_intent or intent.seat != game.current_seat():
		return false
	var legal := game.legal_moves()
	if intent.kind == MatchIntent.Kind.DISCARD:
		if not legal.is_empty() or not _is_hand_card(intent.card_index):
			return false
		_stop_awaiting()
		_carry_out(intent.card_index, null)
		return true
	var index := legal.find_custom(func(move: Move) -> bool: return move.equals(intent.move))
	if index == GameMatch.NO_INDEX:
		return false
	_stop_awaiting()
	_carry_out(legal[index].card_index, legal[index])
	return true


func _process(delta: float) -> void:
	if _clock_running:
		game.elapsed += delta
	if _turn_time_left == NO_TURN_TIMER:
		return
	if _is_device_pause(delta):
		turn_timer_started.emit(game.current_seat(), _turn_time_left)
	else:
		_count_turn_time(delta)


## Sessizlik sınırından uzun kare, cihazın durduğunu gösterir; o süre sıra süresinden düşülmez,
## çünkü kimse hamle yapamadı.
func _is_device_pause(delta: float) -> bool:
	return delta * ClientSource.MSEC_PER_SECOND > game.settings.silence_limit_ms


func _is_hand_card(card_index: int) -> bool:
	return card_index >= 0 and card_index < game.current_hand().size()


## Olayı yayar ve ekranla bütün bekletmelerin bitirmesini bekler; beklerken oyun değiştiyse
## (hakem durdu) false döner. Dinleyiciler olayı yayılırken bitirirse beklenmez.
func _emit(event: MatchEvent) -> bool:
	var current := game
	_screen_busy = true
	_holds = 0
	event_emitted.emit(event)
	if _screen_busy or _holds > 0:
		_waiting_ack = true
		await acknowledged
	return current == game and current != null


func _settle() -> void:
	if _waiting_ack and not _screen_busy and _holds == 0:
		_waiting_ack = false
		acknowledged.emit()


func _save() -> void:
	if store != null:
		store.store_match(game.to_dict())


# --- Sıra akışı ---


## Sıradaki oyuncu çekmeden önce: deste boşsa karıştırılır, zamanı geldiyse reklam olayı yayılır.
## Ardından oyun kaydedilir ve oyuncu kart çeker.
func _start_turn() -> void:
	if game.reshuffle_if_empty() and not await _emit(MatchEvent.new(MatchEvent.Kind.RESHUFFLED)):
		return
	if in_game_ads and AdSchedule.is_due(game) and not await _show_ad():
		return
	_save()
	var hand_before := game.current_hand().size()
	game.begin_turn()
	var event := MatchEvent.new(MatchEvent.Kind.TURN_STARTED, game.current_seat())
	event.drew = game.current_hand().size() > hand_before
	event.card = game.current_hand().back() if event.drew else null
	event.round_number = game.round_number
	event.elapsed = game.elapsed
	if not await _emit(event):
		return
	if game.is_bot_turn():
		_play_bot_turn()
	else:
		_await_intent()


## İnsan oyuncunun niyeti beklenir; sıra süresi varsa işlemeye başlar.
func _await_intent() -> void:
	_awaiting_intent = true
	if turn_time_limit > 0.0:
		_turn_time_left = turn_time_limit
		turn_timer_started.emit(game.current_seat(), turn_time_limit)


func _stop_awaiting() -> void:
	_awaiting_intent = false
	_turn_time_left = NO_TURN_TIMER


## Sıra süresi dolunca niyet artık kabul edilmez ve bu hamleyi bot oynar; koltuk oyuncuda kalır.
func _count_turn_time(delta: float) -> void:
	_turn_time_left -= delta
	if _turn_time_left <= 0.0:
		_stop_awaiting()
		_play_bot_turn()


## Oyun reklamdan önce kaydedilir ki uygulama reklamda kapanırsa aynı yerden dönülsün ve reklam
## orada yeniden çıkmasın; saat reklam boyunca durur.
func _show_ad() -> bool:
	game.last_ad_at = game.elapsed
	_save()
	_clock_running = false
	var resumed: bool = await _emit(MatchEvent.new(MatchEvent.Kind.AD_DUE, game.current_seat()))
	if resumed:
		_clock_running = true
	return resumed


## Bot hamlesini arka planda düşünür; ekran bu sırada akıcı kalır. Kart, en az bot_delay kadar
## beklendikten ve düşünme bittikten sonra açılır.
func _play_bot_turn() -> void:
	var current := game
	var bot := _bot
	var result: Array[Move] = []
	var task := WorkerThreadPool.add_task(func() -> void: result.append(bot.choose_move(current)))
	await get_tree().create_timer(current.settings.bot_delay).timeout
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	if current != game:
		return
	var move := result[0]
	var card_index := bot.choose_discard(game.current_hand()) if move == null else move.card_index
	_carry_out(card_index, move)


## Kart açılır, sonra hamle (move null ise kartı atma) uygulanır ve sıra biter.
func _carry_out(card_index: int, move: Move) -> void:
	var reveal := MatchEvent.new(MatchEvent.Kind.CARD_REVEALED, game.current_seat())
	reveal.card_index = card_index
	reveal.card = game.current_hand()[card_index]
	reveal.value = Card.NO_VALUE if move == null else move.value
	if not await _emit(reveal):
		return
	if not await _emit(_apply(card_index, move)):
		return
	_finish_turn()


func _apply(card_index: int, move: Move) -> MatchEvent:
	var seat := game.current_seat()
	var card := game.current_hand()[card_index]
	if move == null:
		game.discard(card_index)
		var discarded := MatchEvent.new(MatchEvent.Kind.DISCARDED, seat)
		discarded.card_index = card_index
		discarded.card = card
		return discarded
	var played := MatchEvent.new(MatchEvent.Kind.MOVE_PLAYED, seat)
	played.card_index = card_index
	played.card = card
	played.move = move
	played.path = game.board.move_path(move)
	game.play(move)
	return played


func _finish_turn() -> void:
	if MatchResult.is_over(game):
		_end_match()
		return
	if not await _announce_finishers():
		return
	game.next_turn()
	_start_turn()


## Bu sırada yeni bitiren oyuncular için olay yayılır.
func _announce_finishers() -> bool:
	while _announced < game.finishers.size():
		var event := MatchEvent.new(MatchEvent.Kind.PLAYER_FINISHED, game.finishers[_announced])
		_announced += 1
		event.place = _announced
		if not await _emit(event):
			return false
	return true


## Oyun bitti: saat durur, kayıt silinir. Bu olaydan sonra beklenecek bir şey yoktur.
func _end_match() -> void:
	_clock_running = false
	if store != null:
		store.clear_match()
	event_emitted.emit(MatchEvent.new(MatchEvent.Kind.MATCH_OVER))
