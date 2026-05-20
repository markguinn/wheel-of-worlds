extends CanvasLayer

@onready var first_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ToughMode


func _ready() -> void:
	hide()
	GameManager.scene_changed.connect(_on_new_scene)
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/walk_acceleration.button_pressed = Flags.walk_acceleration
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/wall_bounce.button_pressed = Flags.wall_bounce
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/plank_struggle_mode.button_pressed = Flags.plank_struggle_mode


func _on_new_scene() -> void:
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ToughMode.button_pressed = false
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/FastMode.button_pressed = false


func _input(event: InputEvent) -> void:
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
	else:
		p.speed_multiplier = 1.0
		p.jump_multiplier = 1.0


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


func _on_drop_lantern_pressed() -> void:
	var prop: Node2D = load("res://props/lantern/lantern.tscn").instantiate()
	_drop(prop)


func _on_flag_toggled(toggled_on: bool, source: Node) -> void:
	Flags.set(source.name, toggled_on)
