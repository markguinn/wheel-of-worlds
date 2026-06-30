extends Stage


@export var required_stones := 3

@onready var block_zone: Area2D = $WaterfallBlockZone
@onready var waterfall_particles: GPUParticles2D = $WaterfallParticles
@onready var waterfall_bottom: CPUParticles2D = $WaterfallBottomSplash


# TODO: we need to save the waterfall state


func _ready() -> void:
	block_zone.body_entered.connect(_on_stone_entered_block_zone)


func _on_stone_entered_block_zone(_body: Node2D) -> void:
	var waterfall_material: ParticleProcessMaterial = waterfall_particles.process_material
	if required_stones > 0:
		required_stones -= 1
		if required_stones > 0:
			waterfall_particles.amount_ratio *= 0.5
			waterfall_material.emission_sphere_radius *= 0.8
			Log.info(self, "waterfall diminished", required_stones, waterfall_particles.amount)
		else:
			Log.info(self, "waterfall stopped")
			waterfall_particles.amount_ratio = 0.01
			waterfall_material.emission_sphere_radius = 10
			waterfall_bottom.global_position = waterfall_particles.global_position
			for n in get_tree().get_nodes_in_group("waterfall_barriers"):
				Log.info(self, "waterfall stopping", n)
				if n is CollisionShape2D:
					n.disabled = true
				if n is Area2D:
					n.monitoring = false
					n.monitorable = false
				if n is StaticBody2D:
					n.collision_layer = 0
