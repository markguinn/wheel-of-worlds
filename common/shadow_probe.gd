"""
https://www.reddit.com/r/godot/comments/1gf586u/2d_light_detection/
Light detection works with a Sprite with a 1x1 texture
"""
class_name ShadowProbe
extends Sprite2D

@export var lit_value: float = 0.0:
	get(): return 0. if is_nan(lit_value) else lit_value

func _process(delta: float) -> void:
	#lit_value = -get_viewport().get_texture().get_image().get_pixelv(
		#get_global_transform_with_canvas().get_origin()  - Vector2(45., 109.)
	#).get_luminance()
	if has_node("DebugLabel"): $DebugLabel.text = "%.3f" % lit_value
	#if has_node("DebugLabel"): $DebugLabel.text = str(
		#get_global_transform_with_canvas().get_origin()
	#)

func _ready() -> void:
	# we need to save the viewport position of the sprite before drawing,
	# otherwise the position will be off and we might not mask to the sprite correctly.
	RenderingServer.frame_pre_draw.connect(_on_viewport_frame_pre_draw)
	# and we need to do the light check after drawing.
	RenderingServer.frame_post_draw.connect(_on_viewport_frame_post_draw)

var last_sprite_tex: Texture = null # texture before frame draw.
var last_crop_rect: Rect2i = Rect2i() # position before frame draw.
var pixel_to_compare: Color = Color.WHITE
func _on_viewport_frame_pre_draw() -> void:
	#pixel_to_compare = get_viewport().get_texture().get_image().get_pixelv(
		#get_global_transform_with_canvas().get_origin()
	#)
	#pixel_to_compare /= max(0.001, pixel_to_compare.a)
	last_sprite_tex = texture
	var viewport_scale: Vector2 = get_viewport_transform().get_scale()
	var screen_pos = get_screen_transform().origin * viewport_scale
	last_crop_rect = Rect2i(
		screen_pos-((last_sprite_tex.get_size()/2.0)*viewport_scale),
		last_sprite_tex.get_size()*viewport_scale
	)

func _on_viewport_frame_post_draw() -> void:
	#var pixel_after_render: Color = get_viewport().get_texture().get_image().get_pixelv(
		#get_global_transform_with_canvas().get_origin()
	#)
	#pixel_after_render /= max(0.001, pixel_after_render.a)
	##lit_value = round((pixel_after_render.get_luminance() - pixel_to_compare.get_luminance()) / 0.05) * 0.05
	#lit_value = ((pixel_after_render.get_luminance() - pixel_to_compare.get_luminance()))
	if last_sprite_tex == null:
		return Color(0,0,0,0)
	var view_img: Image = get_viewport().get_texture().get_image()
	var sprite_img: Image = last_sprite_tex.get_image()
	view_img = view_img.get_region(last_crop_rect)
	# resize the image back down to sprite level scale;
	# I think you might only need to do this if your project stretch_mode is canvas_items. But I'm unsure.
	view_img.resize(last_sprite_tex.get_size().x, last_sprite_tex.get_size().y)
	# Convert the image to match the last_sprite_tex format, otherwise we won't be allowed to mask with it.
	view_img.convert(sprite_img.get_format())
	var final_img = Image.create_empty(last_sprite_tex.get_size().x, last_sprite_tex.get_size().y, false, Image.FORMAT_RGBA8)
	# Use the sprite_img to mask now.
	final_img.blit_rect_mask(view_img, sprite_img, Rect2i(Vector2i(), last_sprite_tex.get_size()), Vector2i())
	# Important! if the alpha isn't fixed, the final color will be off, and the whole thing will break.
	final_img.fix_alpha_edges()
	# Resize them down so you can get their total color, I found INTERPOLATE_LANCZOS to be the only method to work.
	final_img.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	sprite_img.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	# Get the view color
	var final_color = final_img.get_pixel(0, 0)
	# Get the sprites color as well, this way we can compare luminance levels.
	var base_color = sprite_img.get_pixel(0, 0)
	# We need to divide the colors by their alpha, otherwise the color will be muted from empty space.
	final_color = (final_color/max(final_color.a, 0.0001))
	base_color = (base_color/max(base_color.a, 0.0001))
	# We then need to subtract the base_color to compare the two colors luminance. Which will be the lit_value.
	lit_value = round((final_color.get_luminance() - base_color.get_luminance()) / 0.05) * 0.05
