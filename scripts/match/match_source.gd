class_name MatchSource
extends RefCounted
## Oyun ekranının çizdiği oyunun kaynağı. Yerel oyunda ve ağ oyununda hostta hakemin kendisidir
## (RefereeSource), istemcide hosttan gelen görünüm ve olaylardır (ClientSource). Ekran oyunu
## yalnızca view() ile görür, olayları sırayla çizip acknowledge() ile bitirir ve oyuncunun
## seçtiği hamleyi submit() ile niyet olarak verir. Bu sınıf arayüzdür; yöntemler türeyende yazılır.

## Bir olay çizilmeli; ekran bitirince acknowledge(event) çağırır.
signal event_emitted(event: MatchEvent)
## Verilen niyet reddedildi; oyuncunun seçimi yeniden açılabilir.
signal intent_rejected
## Görünüm baştan değişti (istemciye görünümün tamamı yeniden geldi); ekran baştan çizer.
signal view_reset
## Oyun bu cihazın dışında sona erdi: by_host true ise host oyunu kapattı, değilse hosta artık
## ulaşılamıyor.
signal ended(by_host: bool)
## Ağ oyununda hostla bağlantı koptu (lost true) ya da düzeldi.
signal connection_changed(lost: bool)
## Ağ oyununda hostta oturan katılımcılar azaldı; has_guests() değişmiş olabilir.
signal guests_changed
## Ağ oyununda host oyunu molaya aldı (paused true) ya da moladan çıkardı.
signal pause_changed(paused: bool)
## Oyun hızı değişti (yerel oyunda ya da hostta menüden, istemcide hosttan); speed_scale() yenidir.
signal speed_changed


## Oyunun bu cihazda görünen hâli; her olaydan önce güncellenir.
func view() -> MatchView:
	return null


## Oyunun geçen süresi (saniye).
func elapsed() -> float:
	return 0.0


## Ekran hazır (başlangıç kurası bitti); olaylar akmaya başlar.
func begin() -> void:
	pass


## Ekran olayı çizmeyi bitirdi.
func acknowledge(_event: MatchEvent) -> void:
	pass


## Oyuncunun niyetini verir; reddedilirse intent_rejected gelir.
func submit(_intent: MatchIntent) -> void:
	pass


## Bu cihazdaki oyuncunun niyeti bekleniyorsa true.
func is_awaiting_intent() -> bool:
	return false


## Sıradaki oyuncunun sıra süresinden kalan (saniye); süre işlemiyorsa
## MatchReferee.NO_TURN_TIMER.
func turn_time_left() -> float:
	return MatchReferee.NO_TURN_TIMER


## Ağ oyununda koltuğun oyuncusu bağlantısı koptuğu için bekleniyorsa, koltuğu bot alana kadar
## kalan saniye (süre dolduysa 0); oyuncu bağlıysa ya da oyun yerelse SeatPresence.PRESENT.
func seat_wait(_seat: int) -> float:
	return SeatPresence.PRESENT


## Oyun moladaysa true (ağ oyununda hostun molası, yerel oyunda açık menü).
func is_paused() -> bool:
	return false


## Molanın başından beri geçen süre (saniye); mola yoksa MatchReferee.NOT_PAUSED.
func pause_time() -> float:
	return MatchReferee.NOT_PAUSED


## Oyunu hakemi tutan cihaz molaya alır (ağ oyununda host, yerel oyunda menü açılınca);
## konukta bir şey yapmaz.
func pause() -> void:
	pass


## Oyunu hakemi tutan cihaz moladan çıkarır; konukta bir şey yapmaz.
func resume() -> void:
	pass


## Oyuncu oyundan çıkıyor.
func leave() -> void:
	pass


## Ekran bu kaynağı bırakıyor; kaynak artık sinyal yaymaz.
func detach() -> void:
	pass


## Oyun bu kaynakta sürüyorsa (bırakılmadıysa) true.
func is_live() -> bool:
	return false


## Ağ oyunuysa true.
func is_networked() -> bool:
	return false


## Ağ oyununu bu cihaz kurduysa true.
func is_host() -> bool:
	return false


## Ağ oyununda hostun oyununda hâlâ oturan (bağlı ya da kopuk) katılımcı varsa true; yalnızca
## o zaman aynı oyuncularla yeniden oynanabilir.
func has_guests() -> bool:
	return false


## Ağ oyununun oda kodu; yerel oyunda boş.
func room_code() -> String:
	return ""


## Birden çok insan aynı cihazda sırayla oynuyorsa true (eller sıra devrinde gizlenir).
func shares_device() -> bool:
	return false


## Oyun sonu geçiş reklamı atlanacaksa true (oyun içi reklam az önce gösterildi).
func skips_end_ad() -> bool:
	return false


## Botların seviyesi.
func bot_level() -> Bot.Level:
	return Bot.Level.MEDIUM


## Animasyonların hız çarpanı.
func speed_scale() -> float:
	return 1.0
