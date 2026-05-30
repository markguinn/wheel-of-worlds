extends CanvasLayer


@onready var options_menu: CanvasLayer = $OptionsMenu
@onready var resume_button: Button = $ResumeButton


func _ready() -> void:
	visible = false
	options_menu.visible = false
	visibility_changed.connect(_on_visibility_changed)
	options_menu.visibility_changed.connect(_on_options_menu_visibility_changed)


func _on_visibility_changed() -> void:
	if not visible:
		options_menu.visible = false
		get_tree().paused = false
		AudioManager.reset_music_damping()
	else:
		get_tree().paused = true
		AudioManager.set_music_damping(1.0)
		resume_button.grab_focus()


func _on_options_menu_visibility_changed() -> void:
	if not options_menu.visible:
		resume_button.grab_focus()
	for n in get_tree().get_nodes_in_group("hidden_for_options"):
		n.visible = !options_menu.visible


func _input(event: InputEvent) -> void: 
	if event.is_action_pressed("pause_menu"):
		if get_tree().paused:
			visible = false
		else:
			visible = true
			options_menu.visible = false


func _on_resume_button_pressed() -> void:
	visible = false


func _on_options_button_pressed() -> void:
	options_menu.visible = true


func _on_title_button_pressed() -> void:
	# TODO: ask first?
	GameManager.quit_to_title()
	visible = false
