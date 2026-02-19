class_name SceneChangeButton
extends Button

########################################################
## A button that switches the current scene when pressed.
## This can go to a stage or a UI scene.
########################################################


## The scene that loads when the button is clicked
@export_file("*.tscn") var target_scene: String

## Should the button grab focus?
@export var is_primary: bool = false

## Passed to the init_with_state method. Scene specific. For stages, this can optionally have a target_portal key which controls where the player starts.
@export var params: Dictionary


func _ready() -> void:
	pressed.connect(_on_pressed)
	if is_primary:
		grab_focus()


func _on_pressed() -> void:
	GameManager.change_scene(target_scene, params)
