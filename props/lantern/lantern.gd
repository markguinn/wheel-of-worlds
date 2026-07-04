class_name Lantern
extends MoveableRigidBody2D

signal persisted_state_changed(node: Node)


@export var starting_hp := 3
@export var fixed := false
@export var hit_threshold := 500.0

var hp: int

var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float
var start_light_scale: float
var start_light_energy: float

@onready var sfx_impact: AudioStreamPlayer2D = $ImpactSFX
@onready var vfx_dust: CPUParticles2D = $DustParticles
@onready var light: PointLight2D = $PointLight2D
@onready var glow: Node = $Glow
@onready var grab_box: GrabBox = $GrabBox

func _ready() -> void:
	super._ready()
	start_pos = global_position
	start_rot = global_rotation
	start_light_energy = light.energy
	start_light_scale = light.texture_scale
	glow.hide()
	grab_box.become_candidate.connect(_on_become_active_candidate)
	grab_box.resign_candidate.connect(_on_resign_active_candidate)

	hp = starting_hp
	if fixed:
		$GrabBox.enabled = false
		freeze = true
	else:
		impact.connect(_on_impact)


func _on_impact(pos: Vector2, vel: Vector2, _obj: Node, _part) -> void:
	sfx_impact.play()
	vfx_dust.global_position = pos
	vfx_dust.emitting = true
	Log.debug(self, "impact", vel.length())
	if vel.length() >= hit_threshold and starting_hp > 0:
		hp -= 1
		if hp > 0:
			var fraction: float = float(hp) / float(starting_hp)
			light.texture_scale -= fraction
			light.energy -= fraction
			Log.debug(self, "damaged hp=", hp, fraction, light.energy, light.texture_scale)
		else:
			_die.call_deferred()

func _die() -> void:
	Log.debug(self, "damaged hp=", hp)
	var t = create_tween()
	t.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	await t.finished
	reset_after_fall()


func set_checkpoint() -> void:
	start_pos = position


func reset_after_fall() -> void:
	# TODO: make a fun animation
	set_next_global_position(start_pos)
	set_next_global_rotation(start_rot)
	set_next_angular_velocity(0.0)
	set_next_linear_velocity(Vector2.ZERO)
	hp = starting_hp
	self.modulate = Color.WHITE
	light.energy = start_light_energy
	light.texture_scale = start_light_scale


func get_persisted_state() -> Dictionary:
	return { 
		"position": global_position,
		"rotation": global_rotation,
		"hp": hp,
	}


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		global_position = data.get("position")
	if "rotation" in data:
		global_rotation = data.get("rotation")
	if "hp" in data:
		hp = data.get("hp")


func _physics_process(_delta: float) -> void:
	if global_position != last_pos or global_rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = global_position
		last_rot = global_rotation


func _on_become_active_candidate(_prev: Activator) -> void:
	glow.show()


func _on_resign_active_candidate(_next: Activator) -> void:
	glow.hide()
