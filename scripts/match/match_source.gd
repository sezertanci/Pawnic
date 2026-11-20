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
## Oyun bu cihazın dışında sona erdi (host oyunu kapattı ya da bağlantı koptu).
signal ended


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
