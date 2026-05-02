extends Sprite2D

@export var openTimeMin = 0.75
@export var openTimeMax = 3.5
@export var blinkTimeMin = 0.1
@export var blinkTimeMax = 0.3

var delay = 0.0

func _process(delta):
	delay -= delta
	if delay <= 0:
		if !visible: # eyes are open - time to blink
			visible = true # close your eyes very briefly
			delay = randf_range(blinkTimeMin, blinkTimeMax)
		else:	# eyes are closed - time to reopen
			visible = false # open your eyes for a long time
			delay = randf_range(openTimeMin, openTimeMax)
