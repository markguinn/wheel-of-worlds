extends Stage

func _ready() -> void:
	super._ready()
	get_tree().create_timer(1.0).timeout.connect(_stand_up)

#func _input(event: InputEvent) -> void:
	#if event.is_pressed():
		#var p := GameManager.get_player()
		#p.perma_ragdoll = false
		#await get_tree().physics_frame
		#p._input(event)

func _stand_up() -> void:
	var p := GameManager.get_player()
	p.perma_ragdoll = false
