extends Node2D


@export var required_stones := 3

@onready var block_zone: Area2D = $BlockZone
@onready var waterfall_particles: GPUParticles2D = $WaterfallParticles
@onready var waterfall_bottom: CPUParticles2D = $BottomSplash

var remaining_stones: int
var starting_width: float
var waterfall_material: ParticleProcessMaterial

# NOTE: the waterfall state is automatically persistent because
# the stones are persistent. So when you reenter the level, the
# stones retrigger body_entered and the waterfall starts off closed


func _ready() -> void:
	block_zone.body_entered.connect(_on_stone_entered_block_zone)
	remaining_stones = required_stones
	waterfall_material = waterfall_particles.process_material
	starting_width = waterfall_material.emission_sphere_radius


func _on_stone_entered_block_zone(_body: Node2D) -> void:
	if remaining_stones > 0:
		remaining_stones -= 1
		_apply_blockage.call_deferred()


func _apply_blockage() -> void:
	if remaining_stones > 0:
		var r := inverse_lerp(0, required_stones, remaining_stones)
		waterfall_particles.amount_ratio = r
		waterfall_material.emission_sphere_radius = lerpf(0, starting_width, r)
		Log.info(self, "waterfall diminished", remaining_stones, waterfall_particles.amount)
	else:
		Log.info(self, "waterfall stopped")
		waterfall_particles.amount_ratio = 0.01
		waterfall_material.emission_sphere_radius = 10
		waterfall_bottom.global_position = waterfall_particles.global_position
		for n in get_tree().get_nodes_in_group("waterfall_barriers"):
			if n is CollisionShape2D:
				n.disabled = true
			if n is Area2D:
				n.monitoring = false
				n.monitorable = false
			if n is StaticBody2D:
				n.collision_layer = 0
