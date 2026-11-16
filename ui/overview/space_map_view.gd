## Draws the map of screens/overview-screen.png: bodies at their map
## positions, dashed routes labelled with their distance in light-seconds,
## numbered pads round each body that has them, and a marker for every
## launched ship, parked round the body it went to. It takes no input and
## decides nothing; a ship marker is drawn where its record says it went.
class_name SpaceMapView
extends Control

# Where to look
#   Shown by:   ui/overview/overview_screen.gd -> _redraw()
#   Draws:      game/space/space_map.gd, game/space/body.gd, game/space/space_link.gd,
#               game/launch/launch_record.gd -> destination(), missed_requirements()
#   Numbers:    ui/common/presentation_tuning.gd, the Overview group
#   Tests:      tests/ui/test_overview_screen.gd

const DISTANCE_TEXT: String = "%s ls"
# Pads are spread round a body starting from its upper left.
const FIRST_PAD_ANGLE: float = -PI * 0.75

var _map: SpaceMap
var _launches: Array[LaunchRecord] = []
var _tuning: PresentationTuning


## Shows a map and the ships launched so far. map may be null, which draws
## an empty backdrop.
func show_map(map: SpaceMap, launches: Array[LaunchRecord], tuning: PresentationTuning) -> void:
	_map = map
	_launches = launches
	_tuning = tuning
	queue_redraw()


## Where a body is drawn inside this control. The map's corners are kept
## clear by home's radius so nothing is cut off at the edge.
func point_of(body: Body) -> Vector2:
	var inset: Vector2 = Vector2.ONE * _tuning.map_home_radius
	return inset + (size - inset * 2.0) * body.map_position


# Backdrop, routes, bodies, then the ships on top.
func _draw() -> void:
	if _tuning == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), _tuning.map_backdrop_colour)
	if _map == null:
		return
	for link: SpaceLink in _map.links:
		_draw_link(link)
	for body: Body in _map.bodies:
		_draw_body(body)
	_draw_fleet()


# A dashed line between two bodies, with its distance at the middle.
func _draw_link(link: SpaceLink) -> void:
	if link == null or link.from_body == null or link.to_body == null:
		return
	var start: Vector2 = point_of(link.from_body)
	var end: Vector2 = point_of(link.to_body)
	draw_dashed_line(start, end, _tuning.map_link_colour, _tuning.map_link_width, _tuning.map_dash_length)
	_draw_label((start + end) / 2.0, DISTANCE_TEXT % String.num(link.distance_ls, 1))


# The body's picture, or a coloured circle; its name below; its pads round it.
func _draw_body(body: Body) -> void:
	var centre: Vector2 = point_of(body)
	var radius: float = _radius_of(body)
	if body.texture != null:
		draw_texture_rect(body.texture, Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
	else:
		draw_circle(centre, radius, body.colour)
		draw_circle(centre, radius, body.colour.darkened(_tuning.piece_border_darkening), false, _tuning.outline_width)
	# The name sits below the ring of pads, so a pad never covers it.
	var below: float = radius + font_height() / 2.0
	if body.pads > 0:
		below += _tuning.map_pad_size
	_draw_label(centre + Vector2(0.0, below), body.display_name)
	_draw_pads(body, centre, radius)


# Small numbered squares standing on the body's rim, counted from 1.
func _draw_pads(body: Body, centre: Vector2, radius: float) -> void:
	for index: int in body.pads:
		var angle: float = FIRST_PAD_ANGLE + TAU * index / body.pads
		var spot: Vector2 = centre + Vector2.from_angle(angle) * (radius + _tuning.map_pad_size / 2.0)
		var square: Rect2 = Rect2(spot - Vector2.ONE * _tuning.map_pad_size / 2.0, Vector2.ONE * _tuning.map_pad_size)
		draw_rect(square, _tuning.map_link_colour)
		LabelPainter.draw_centred(self, square, str(index + 1), _tuning.label_min_size, _tuning.map_backdrop_colour)


# Each ship as a numbered triangle, parked in a ring round where it went.
# A ship with nowhere to go is parked round home.
func _draw_fleet() -> void:
	var parked_at: Dictionary[Body, int] = {}
	for record: LaunchRecord in _launches:
		var body: Body = record.destination()
		if body == null or not _map.bodies.has(body):
			body = _map.home
		if body == null:
			continue
		var place_in_ring: int = parked_at.get(body, 0)
		parked_at[body] = place_in_ring + 1
		var angle: float = -PI / 2.0 + deg_to_rad(_tuning.map_fleet_spacing_degrees) * place_in_ring
		var reach: float = _radius_of(body) + _tuning.map_pad_size + _tuning.map_ship_size
		_draw_ship(point_of(body) + Vector2.from_angle(angle) * reach, angle, record)


# A triangle pointing away from the body, with the launch number beside it.
func _draw_ship(at: Vector2, angle: float, record: LaunchRecord) -> void:
	var colour: Color = _tuning.map_ship_colour
	if record.missed_requirements():
		colour = _tuning.attention_colour
	var length: float = _tuning.map_ship_size
	var tip: Vector2 = at + Vector2.from_angle(angle) * length
	var left: Vector2 = at + Vector2.from_angle(angle + PI * 0.75) * length
	var right: Vector2 = at + Vector2.from_angle(angle - PI * 0.75) * length
	draw_colored_polygon(PackedVector2Array([tip, left, right]), colour)
	_draw_label(at + Vector2.from_angle(angle) * length * 2.0, str(record.number))


## The height of a line of text on the map.
func font_height() -> float:
	return get_theme_default_font().get_height(_tuning.map_font_size)


# Text centred on a point, in the map's label colour.
func _draw_label(centre: Vector2, text: String) -> void:
	var font: Font = get_theme_default_font()
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _tuning.map_font_size)
	LabelPainter.draw_centred(self, Rect2(centre - text_size / 2.0, text_size), text, _tuning.map_font_size, _tuning.map_label_colour)


# Home is drawn larger than the other bodies, so its pads fit round it.
func _radius_of(body: Body) -> float:
	if body == _map.home:
		return _tuning.map_home_radius
	return _tuning.map_body_radius
