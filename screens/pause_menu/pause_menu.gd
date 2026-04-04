extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false


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
