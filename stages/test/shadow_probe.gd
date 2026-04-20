"""
https://www.reddit.com/r/godot/comments/1gf586u/2d_light_detection/
Light detection works with a Sprite with a 1x1 texture
"""
class_name ShadowProbe
extends Sprite2D

@export var lit_value: float = 0.0:
	get(): return 0. if is_nan(lit_value) else lit_value

@export var refresh_after_loops: int = 2
@export var refresh_delay: int = 0

#TODO: inconsistent values when viewport is not on default size, but not within web build?

## The original color of the 1x1 texture
var luminance_base: float = Color.from_rgba8(128,128,128,255).get_luminance()
func _process(_delta: float) -> void: if has_node("DebugLabel"): $DebugLabel.text = "%.3f" % lit_value
func _ready() -> void: RenderingServer.frame_post_draw.connect(_on_viewport_frame_post_draw)

@onready var loops_until_measurement: int = refresh_delay
func _on_viewport_frame_post_draw() -> void:
	# Do not update value every loop
	if 0 < loops_until_measurement:
		loops_until_measurement -= 1
		return

	# Update value in this loop
	loops_until_measurement = refresh_after_loops
	var canvas_origin: Vector2 = get_global_transform_with_canvas().get_origin()
	var viewport_image: Image = get_viewport().get_texture().get_image()
	if ( # Do not probe shadow when position is out of viewport
		0. > canvas_origin.x || 0. > canvas_origin.y
		|| viewport_image.get_size().x < canvas_origin.x
		|| viewport_image.get_size().y < canvas_origin.y
	):
		lit_value = 0.
		return
	var pixel_after_render: Color = viewport_image.get_pixelv(canvas_origin)
	pixel_after_render /= max(0.001, pixel_after_render.a) # We need to divide the colors by their alpha, otherwise the color will be muted from empty space
	lit_value = (pixel_after_render.get_luminance() - luminance_base)
