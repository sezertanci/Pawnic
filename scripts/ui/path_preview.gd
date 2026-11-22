class_name PathPreview
extends RefCounted
## Kart seçilince oynanabilir taşların gideceği yolu gösterir: yol üstündeki karelerde küçük
## noktalar, varış karesinde nabız gibi yavaşça parlayıp sönen yumuşak bir ışık.
## Uzunluklar kare boyuna oranlanır, renk oyuncu renginin açık tonudur. Varış ışığı görünürken
## çizen düğüm her karede yeniden çizilmelidir.

## Renk, oyuncu renginin bu oranda açılmış tonudur.
const LIGHTEN := 0.35
## Yol noktasının yarıçapı.
const DOT_RATIO := 0.1
## Varış ışığının bir parlayıp sönme süresi (saniye).
const PULSE_PERIOD := 1.4
## Varış ışığının en sönük ve en parlak saydamlığı.
const GLOW_MIN := 0.25
const GLOW_MAX := 0.75
## Karenin içindeki dolgunun, kenardaki ışığa göre saydamlık oranı.
const GLOW_FILL := 0.5
## Işığın kareden dışarı taşma genişliği ve köşe yuvarlaklığı.
const GLOW_SPREAD := 0.25
const GLOW_CORNER := 0.2


## Yol üstündeki kare merkezlerine konturlu noktalar çizer.
static func draw_dots(
	canvas: CanvasItem, centers: Array[Vector2], color: Color, ink: Color, cell: float, line: float
) -> void:
	var fill := color.lightened(LIGHTEN)
	for center: Vector2 in centers:
		SmoothDraw.circle(canvas, center, cell * DOT_RATIO, fill, ink, line)


## Varış karesini yarı saydam doldurur, çevresine dışa doğru solan ışık çizer; saydamlık nabız
## gibi GLOW_MIN ile GLOW_MAX arasında gidip gelir. round true ise kare çemberdir.
static func draw_target(
	canvas: CanvasItem, rect: Rect2, color: Color, cell: float, round: bool
) -> void:
	var pulse := (1.0 - cos(TAU * PulseWave.phase(PULSE_PERIOD))) / 2.0
	var lit := Color(color.lightened(LIGHTEN), lerpf(GLOW_MIN, GLOW_MAX, pulse))
	var radius := rect.size.x / 2.0 if round else cell * GLOW_CORNER
	var spread := cell * GLOW_SPREAD
	var inner := SmoothDraw.rounded_rect(rect, radius)
	var outer := SmoothDraw.rounded_rect(rect.grow(spread), radius + spread)
	canvas.draw_colored_polygon(inner, Color(lit, lit.a * GLOW_FILL))
	inner.append(inner[0])
	outer.append(outer[0])
	SmoothDraw.ribbon(
		canvas,
		inner,
		outer,
		SmoothDraw.filled(lit, inner.size()),
		SmoothDraw.filled(Color(lit, 0.0), outer.size())
	)
