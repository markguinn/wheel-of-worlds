extends Button

@export var target_scene: PackedScene
@export var hud_visible: bool = true
@export var is_primary: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	if is_primary:
		grab_focus()


func _on_pressed() -> void:
	GameManager.change_scene(target_scene, hud_visible)
