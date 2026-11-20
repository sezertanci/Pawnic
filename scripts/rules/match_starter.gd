class_name MatchStarter
extends RefCounted
## Yeni oyunda ilk turdan önce oyuna başlayacak oyuncunun seçimi.


## Başlayacak oyuncuyu sıra düzenindeki yerler arasından rastgele seçer.
static func choose(game: GameMatch, rng: RandomNumberGenerator) -> void:
	game.starter = rng.randi_range(0, game.seats.size() - 1)
