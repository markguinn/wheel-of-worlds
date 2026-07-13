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

## If greater than 0.01, prevents [method _on_pressed] until the debounce timer finishes after each press.
@export var debounce_time: float = 0.25

## If set to true, when pressed it will set the flag [member press_disabled] to true.
@export var disable_when_pressed: bool = false

## Prevents the method [method _on_pressed] from running.
var press_disabled: bool = false

func _ready() -> void:
	enable_press()
	pressed.connect(_on_pressed)
	if is_primary:
		grab_focus()

## Sets flag [member press_disabled] to true.
func enable_press(): press_disabled = false

var _debounce: Tween
func debounce() -> bool: ## Returns true if debouncer is running (prevent), or false if OK to continue.
	if debounce_time < 0.01:
		return false
	
	if _debounce:
		## Debounce is running
		return true
	else:
		## Debounce isn't running.
		## Start the debounce
		_debounce = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_debounce.tween_interval(debounce_time)
		return false

func _on_pressed() -> void:
	if press_disabled:
		Log.debug(self, "Pressed but has already been pressed once, so it is disabled.")
		return
	
	if debounce():
		Log.debug(self, "Debouncer prevented button _on_pressed.")
		return
	
	if target_scene:
		GameManager.change_scene(target_scene, params)
	
	if disable_when_pressed:
		press_disabled = true
