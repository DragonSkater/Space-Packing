## The star chart on the launch screen: the fan-shaped panel of the routing
## mockup. It is decoration only, a picture slot with no information in it
## and nothing to tap (PLAN.md section 2, D37). With no picture assigned it
## draws a placeholder fan of stars joined into small constellations.
class_name StarChart
extends Control

# Where to look
#   Scene:      ui/reports/launch_screen.tscn, with the launch button in front of it
#   Picture:    ui/common/presentation_tuning.gd -> star_chart_texture, the Launch screen group
#   Tests:      tests/ui/test_launch_screen.gd

# The placeholder joins this many stars into each constellation.
const STARS_PER_CONSTELLATION: int = 4


# The picture when there is one, otherwise the placeholder fan.
func _draw() -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	if tuning.star_chart_texture != null:
		draw_texture_rect(tuning.star_chart_texture, Rect2(Vector2.ZERO, size), false)
		return
	var centre: Vector2 = Vector2(size.x / 2.0, size.y)
	var outer: float = minf(size.x / 2.0, size.y)
	# The fan's inner edge hugs the launch button, which sits at its hinge.
	var inner: float = tuning.launch_button_size / 2.0
	var half_spread: float = deg_to_rad(tuning.star_chart_spread_degrees) / 2.0
	var first: float = -PI / 2.0 - half_spread
	var last: float = -PI / 2.0 + half_spread
	_draw_fan(centre, inner, outer, first, last, tuning)
	_draw_stars(centre, inner, outer, first, last, tuning)


# Two arcs and the two straight edges between them.
func _draw_fan(centre: Vector2, inner: float, outer: float, first: float, last: float, tuning: PresentationTuning) -> void:
	var colour: Color = tuning.star_chart_colour
	draw_arc(centre, outer, first, last, 48, colour, tuning.map_link_width)
	draw_arc(centre, inner, first, last, 24, colour, tuning.map_link_width)
	for angle: float in [first, last]:
		var along: Vector2 = Vector2.from_angle(angle)
		draw_line(centre + along * inner, centre + along * outer, colour, tuning.map_link_width)


# Stars at fixed places picked by the seed, so the sky does not change
# between frames; every few are joined by lines.
func _draw_stars(centre: Vector2, inner: float, outer: float, first: float, last: float, tuning: PresentationTuning) -> void:
	var picker: RandomNumberGenerator = RandomNumberGenerator.new()
	picker.seed = tuning.star_chart_seed
	var margin: float = tuning.star_size * 2.0
	var previous: Vector2 = Vector2.ZERO
	for index: int in tuning.star_chart_star_count:
		var angle: float = picker.randf_range(first, last)
		var reach: float = picker.randf_range(inner + margin, outer - margin)
		var star: Vector2 = centre + Vector2.from_angle(angle) * reach
		if index % STARS_PER_CONSTELLATION != 0:
			draw_line(previous, star, tuning.star_chart_colour, tuning.map_link_width)
		draw_circle(star, tuning.star_size, tuning.star_colour)
		previous = star
