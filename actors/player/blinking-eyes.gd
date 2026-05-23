extends AnimatedSprite2D

@export var openTimeMin = 0.75
@export var openTimeMax = 3.5
@export var blinkTimeMin = 0.1
@export var blinkTimeMax = 0.3

var delay = 0.0

func _process(delta):
	delay -= delta
	if delay <= 0:
		if animation == "default":
			play("blink")
			delay = randf_range(blinkTimeMin, blinkTimeMax)
		elif animation == "blink":
			play("default")
			delay = randf_range(openTimeMin, openTimeMax)
		else:
			# another emotion was already in flight
			pass
