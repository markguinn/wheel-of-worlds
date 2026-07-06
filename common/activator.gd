class_name Activator
extends Area2D


@warning_ignore("unused_signal")
signal activated(source: Activator)
signal become_candidate(prev_candidate: Activator)
signal resign_candidate(next_candidate: Activator)


static var candidates: Array[Activator] = []
static var active_candidate: Activator = null
static var chosen_candidate: int = -1

@export var enabled := true
## If false, the player's "interact" will activate
## If ture, something else in the scene will
@export var manually_activated := false
## Only set if you need to override the default
@export var label_text := ""
## Higher priorities will always take the active candidate if preset
@export var candidate_priority := 10

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


func _exit_tree() -> void:
	if self in candidates:
		candidates.erase(self)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		candidates.append(self)
		chosen_candidate = -1
		update_active_candidate()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		candidates.erase(self)
		chosen_candidate = -1
		update_active_candidate()


func _become_active_candidate(_prev: Activator) -> void:
	label.show()


func _resign_active_candidate(_next: Activator) -> void:
	label.hide()


func is_active_candidate() -> bool:
	return active_candidate == self


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


static func rotate_candidate() -> void:
	if chosen_candidate < 0:
		chosen_candidate = candidates.find(active_candidate)
	chosen_candidate = (chosen_candidate + 1) % candidates.size()
	set_active_candidate(candidates[chosen_candidate])


# NOTE: the number of active candidates is always small, usually only one.
# so we don't have to be too clever here.
static func update_active_candidate() -> void:
	var player: Player = GameManager.get_player()
	if candidates.size() == 0:
		if active_candidate:
			set_active_candidate(null)
		return
	if player.is_holding_prop:
		if active_candidate:
			set_active_candidate(null)
		return
	if player.state_machine.get_active() == "Push":
		if active_candidate:
			set_active_candidate(null)
		return
	if chosen_candidate >= 0:
		return

	var next_active: Activator = candidates[0] if candidates.size() > 0 and candidates[0].enabled else null
	if candidates.size() > 1:
		var min_dist: float = 1_000_000.0
		var max_pri := 0
		for obj in candidates:
			var my_dist = obj.global_position.distance_squared_to(player.global_position)
			if obj.enabled and my_dist < min_dist and obj.candidate_priority >= max_pri:
				next_active = obj
				max_pri = obj.candidate_priority
				min_dist = my_dist

	if active_candidate != next_active:
		set_active_candidate(next_active)
