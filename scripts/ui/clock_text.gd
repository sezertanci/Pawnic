class_name ClockText
## Oyun süresinin saat yazısı: bir saatten kısaysa "dd:ss", uzunsa "s:dd:ss".

const SECONDS_PER_MINUTE := 60
const SECONDS_PER_HOUR := 3600


static func format(seconds: float) -> String:
	var minutes := floori(seconds / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	var rest := int(seconds) % SECONDS_PER_MINUTE
	if seconds < SECONDS_PER_HOUR:
		return "%02d:%02d" % [minutes, rest]
	return "%d:%02d:%02d" % [floori(seconds / SECONDS_PER_HOUR), minutes, rest]
