class_name FoundGame
extends RefCounted
## Yerel ağda yayınıyla bulunan oyun: hostun adresi, oyun portu, oyuncu sayısı ve tahtanın
## kimliği. Tahta bu cihazda bilinmeyebilir (yeni sürümde eklenen tahta); o zaman katılırken
## ayar özeti tutmaz ve host sürüm uyuşmazlığıyla reddeder.

var address := ""
var port := 0
var players := 0
var board := ""
## Son yayının geldiği an (Time.get_ticks_msec).
var seen_msec := 0
