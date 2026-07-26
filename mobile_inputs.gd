extends CanvasLayer


var active = false

@onready var vjoy: VirtualJoystick = $VirtualJoystick
@onready var pause_menu: CanvasLayer = %PauseMenu
@onready var interact_btn: TouchScreenButton = $Interact
@onready var music_box: TouchScreenButton = $MusicBox
@onready var tab_btn: TouchScreenButton = $TabButton


func _ready() -> void:
	active = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if active:
		Log.info(self, "mobile controls active")
	else:
		queue_free.call_deferred()
	#use_ui_events(true)
	#GameManager.scene_changed.connect(_on_scene_changed)
	#pause_menu.visibility_changed.connect(_on_scene_changed)


#func _on_scene_changed() -> void:
	#use_ui_events(!GameManager.is_in_game or pause_menu.visible)


func _process(_delta: float) -> void:
	var player = GameManager.get_player()
	music_box.visible = player.has_music_box
	interact_btn.visible = Activator.active_candidate != null or player.is_holding_prop
	tab_btn.visible = Activator.candidates.size() > 1
	visible = GameManager.is_in_game and !pause_menu.visible


#func use_ui_events(v: bool) -> void:
	#if active:
		#Log.info(self, "mobile ui events", v)
	#if v:
		#hide()
		##vjoy.action_up = "ui_up"
		##vjoy.action_down = "ui_down"
		##vjoy.action_left = "ui_left"
		##vjoy.action_right = "ui_right"
	#else:
		#show()
		##vjoy.action_up = "up"
		##vjoy.action_down = "down"
		##vjoy.action_left = "left"
		##vjoy.action_right = "right"
