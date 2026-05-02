extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false
	visibility_changed.connect(func():
		if !visible:
			$OptionsMenu.visible = false)
	$OptionsMenu.visibility_changed.connect(func():
		for i in get_children():
			if i != $OptionsMenu:
				if !$OptionsMenu.visible:
					i.visible = true
				else:
					i.visible = false
	)


func _input(event: InputEvent) -> void: 
	if event.is_action_pressed("pause_menu"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true


func _on_resume_button_pressed() -> void:
	visible = false
	get_tree().paused = false


func _on_options_button_pressed() -> void:
	$OptionsMenu.visible = true
