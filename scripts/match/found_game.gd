class_name FoundGame
extends RefCounted
## Yerel ağda yayınıyla bulunan oyun: hostun adresi, oyun portu ve oyuncu sayısı.

var address := ""
var port := 0
var players := 0
## Son yayının geldiği an (Time.get_ticks_msec).
var seen_msec := 0
