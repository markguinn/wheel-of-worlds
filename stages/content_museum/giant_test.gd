extends Stage

var time: float = 0

func _on_ready() -> void:
	$ParallaxBush/AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	time += delta
	if time > 3:
		time = 0
		_jump_props(delta)
		$ParallaxBush/AnimatedSprite2D.play("default")


func _jump_props(_delta: float) -> void:
	$Plank.apply_impulse(Vector2(0, -40), $Plank.global_position)
	$Plank2.apply_impulse(Vector2(0, -40), $Plank2.global_position)
	$Orb.apply_impulse(Vector2(0, -0.5), $Orb.global_position)
	$Player.velocity.y += -50
