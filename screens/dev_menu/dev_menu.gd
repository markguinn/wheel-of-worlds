extends CanvasLayer

@onready var first_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ToughMode


func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	Log.info(self, "wtf", event)
	if GameManager.DEV_MODE and event.is_action_pressed("dev_menu"):
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true
			first_button.grab_focus()


func _on_tough_mode_toggled(toggled_on: bool) -> void:
	GameManager.get_player().tough_mode = toggled_on


func _on_fast_mode_toggled(toggled_on: bool) -> void:
	var p := GameManager.get_player()
	if toggled_on:
		p.speed_multiplier = 4.0
		p.jump_multiplier = 2.0
		get_viewport().get_camera_2d().position_smoothing_speed = 10.0
	else:
		p.speed_multiplier = 1.0
		p.jump_multiplier = 1.0
		get_viewport().get_camera_2d().position_smoothing_speed = 5.0


func _drop(prop: Node2D) -> void:
	var player := GameManager.get_player()
	if player:
		player.get_parent().add_child(prop)
		prop.global_position = player.global_position - Vector2(randf_range(-100, 100), 200)


func _on_drop_plank_pressed() -> void:
	var prop: Node2D = load("res://props/plank/plank.tscn").instantiate()
	_drop(prop)


func _on_drop_stone_1_pressed() -> void:
	var prop: Node2D = load("res://props/stone/square_stone.tscn").instantiate()
	_drop(prop)


func _on_drop_stone_2_pressed() -> void:
	var prop: Node2D = load("res://props/stone/triangle_stone.tscn").instantiate()
	_drop(prop)


func _on_drop_orb_pressed() -> void:
	var prop: Node2D = load("res://props/orb/orb.tscn").instantiate()
	_drop(prop)
