extends CanvasLayer


@onready var options_menu: CanvasLayer = $OptionsMenu
@onready var resume_button: Button = $ResumeButton

func _ready() -> void:
	visible = false
	options_menu.visible = false
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		get_tree().paused = true
		AudioManager.set_music_damping(1.0)
		resume_button.grab_focus()
		$UISFX.play_menu_open()
	else:
		options_menu.visible = false
		get_tree().paused = false
		AudioManager.reset_music_damping()
		$UISFX.play_menu_close()


func _input(event: InputEvent) -> void: 
	if event.is_action_pressed("pause_menu"):
		if get_tree().paused:
			visible = false
		elif GameManager.is_in_game:
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
