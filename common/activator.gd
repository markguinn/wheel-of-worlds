class_name Activator
extends Area2D


signal activated(source: Activator)
signal become_candidate(prev_candidate: Activator)
signal resign_candidate(next_candidate: Activator)


static var candidates: Array[Activator] = []
static var active_candidate: Activator = null

@export var enabled := true
@export var label_text := ""

@onready var label: Label = $Label


func _ready() -> void:
	if label_text:
		label.text = label_text
	label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	become_candidate.connect(_become_active_candidate)
	resign_candidate.connect(_resign_active_candidate)
	if not self.get_collision_mask_value(2):
		Log.warn(self, self.get_path(), "will not detect the player. you should check the collision mask")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		candidates.append(self)
		update_active_candidate()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		candidates.erase(self)
		update_active_candidate()


func _become_active_candidate(_prev: Activator) -> void:
	label.show()


func _resign_active_candidate(_next: Activator) -> void:
	label.hide()


func _input(event: InputEvent):
	if event.is_action_pressed("interact") and active_candidate == self:
		Log.debug(self, self.name, "activated")
		get_viewport().set_input_as_handled()
		activated.emit(self)


static func get_active_candidate() -> Activator:
	return active_candidate


static func set_active_candidate(next_active: Activator) -> void:
	if active_candidate:
		active_candidate.resign_candidate.emit(next_active)
	if next_active:
		# NOTE: I'm not sure about this. It risks this candidate never being removed from the list
		if not candidates.has(next_active):
			candidates.append(next_active)
		next_active.become_candidate.emit(active_candidate)
	active_candidate = next_active


static func clear_candidates() -> void:
	set_active_candidate(null)
	candidates = []


# NOTE: the number of active candidates is always small, usually only one.
# so we don't have to be too clever here.
static func update_active_candidate() -> void:
	var player: Player = GameManager.get_player()
	if candidates.size() == 0:
		if active_candidate:
			set_active_candidate(null)
		return
	if player.is_holding_prop:
		clear_candidates()
		return

	var next_active: Activator = candidates[0]
	if candidates.size() > 1:
		var min_dist: float = 1_000_000.0
		for obj in candidates:
			var my_dist = obj.global_position.distance_squared_to(player.global_position)
			if my_dist < min_dist:
				next_active = obj

	if active_candidate != next_active:
		set_active_candidate(next_active)
