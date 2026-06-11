class_name EdgeTexture
extends Resource

@export var texture: Texture2D
@export var flip: bool = false
@export_range(-360, 360, 0.1, "radians_as_degrees") var min_angle: float
@export_range(-360, 360, 0.1, "radians_as_degrees") var max_angle: float
