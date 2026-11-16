## Draws the gantry beside the container: an upright on each side that has
## a door, a crane arm at every door, and, while a piece is held, which
## doors it can go through (lit) and which it cannot (dimmed). It also says
## which lane a point belongs to, as the one place that knows where the arms
## are. It changes nothing; CraneControls decides what a tap on a door means.
class_name GantryView
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named GantryView
#   Used by:    ui/packing/loading_bay.gd -> show_round(), _on_tapped(), _on_drag_started(), _on_drag_moved(), _apron()
#   Draws on:   ui/common/grid_view.gd -> cell_rect(), point_of()
#   Lanes from: core/packing/packing_session.gd -> entry_lanes()
#   Carry from: ui/packing/crane_controls.gd -> is_carrying(), carry_lane()
#   Numbers:    ui/common/presentation_tuning.gd, the Gantry and Colours groups

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT]

var _grid: GridView
var _session: PackingSession
var _controls: CraneControls
var _tuning: PresentationTuning


## Shows a new round. Called by LoadingBay.show_round.
func show_round(grid: GridView, session: PackingSession, controls: CraneControls, tuning: PresentationTuning) -> void:
	_grid = grid
	_session = session
	_controls = controls
	_tuning = tuning
	_session.held_changed.connect(queue_redraw)
	_controls.view_changed.connect(queue_redraw)
	queue_redraw()


## The doors that open to one side of the container: in each row, the first
## cell met coming in from that side, when it is a door.
static func entrance_doors(layout: ContainerLayout, side: Vector2i) -> Array[Vector2i]:
	var doors: Array[Vector2i] = []
	var width: int = layout.size().x
	for row: int in layout.size().y:
		for step: int in width:
			var column: int = step
			if side == Vector2i.RIGHT:
				column = width - 1 - step
			var cell: Vector2i = Vector2i(column, row)
			if layout.is_outside(cell):
				continue
			if layout.is_door(cell):
				doors.append(cell)
			break
	return doors


## The offered lane whose door and arm this point is on, or null. The point
## is in cells. A lane's rows are widened to the minimum touch target, and
## where two lanes then overlap the nearer one wins.
func lane_at(grid_point: Vector2) -> EntryLane:
	var held: PackItem = _session.held()
	if held == null:
		return null
	var half_target: float = _tuning.min_touch_target / _grid.spot_size() / 2.0
	var height: float = float(held.shape.bounds().size.y)
	var found: EntryLane = null
	var found_distance: float = INF
	for lane: EntryLane in _session.entry_lanes():
		if not _is_beside(lane, grid_point.x):
			continue
		var distance: float = absf(grid_point.y - (float(lane.row) + height / 2.0))
		if distance <= maxf(height / 2.0, half_target) and distance < found_distance:
			found = lane
			found_distance = distance
	return found


# Paints an upright on each side that has doors, then every arm and door.
func _draw() -> void:
	if _session == null:
		return
	var holding: bool = _session.held() != null
	var lit_doors: Array[Vector2i] = []
	for lane: EntryLane in _session.entry_lanes():
		lit_doors.append_array(lane.door_cells)
	for side: Vector2i in SIDES:
		var doors: Array[Vector2i] = entrance_doors(_grid.layout(), side)
		if doors.is_empty():
			continue
		var upright: Rect2 = _upright(side)
		draw_rect(upright, _tuning.gantry_colour)
		for door: Vector2i in doors:
			var lit: bool = lit_doors.has(door)
			_draw_arm(upright, door, side, lit)
			if lit:
				draw_rect(_grid.cell_rect(door), _tuning.door_lit_colour, false, _tuning.outline_width)
			elif holding:
				draw_rect(_grid.cell_rect(door), _tuning.door_dimmed_colour)
	_draw_drop_target()


# While a piece is carried over a door, outlines that door in the active
# colour: letting go there hands the piece to its crane arm.
func _draw_drop_target() -> void:
	var lane: EntryLane = _controls.carry_lane()
	if not _controls.is_carrying() or lane == null:
		return
	for door: Vector2i in lane.door_cells:
		draw_rect(_grid.cell_rect(door), _tuning.active_colour, false, _tuning.outline_width)


# One arm, from the upright to its door, with a bar across the end.
func _draw_arm(upright: Rect2, door: Vector2i, side: Vector2i, lit: bool) -> void:
	var door_rect: Rect2 = _grid.cell_rect(door)
	var height: float = door_rect.get_center().y
	var from: Vector2 = Vector2(upright.end.x, height)
	var to: Vector2 = Vector2(door_rect.position.x, height)
	if side == Vector2i.RIGHT:
		from = Vector2(upright.position.x, height)
		to = Vector2(door_rect.end.x, height)
	var colour: Color = _tuning.gantry_colour
	if lit:
		colour = _tuning.door_lit_colour
	draw_line(from, to, colour, _tuning.arm_width)
	# The gripper: a short bar across the end of the arm.
	var reach: Vector2 = Vector2(0.0, door_rect.size.y * _tuning.arm_gripper_scale / 2.0)
	draw_line(to - reach, to + reach, colour, _tuning.arm_width)


# The upright stands at the outer edge of its side's apron.
func _upright(side: Vector2i) -> Rect2:
	var rows: float = float(_grid.layout().size().y)
	var left: float = _grid.point_of(Vector2(-_grid.apron_left(), 0.0)).x
	if side == Vector2i.RIGHT:
		var right_edge: float = float(_grid.layout().size().x + _grid.apron_right())
		left = _grid.point_of(Vector2(right_edge, 0.0)).x - _tuning.gantry_width
	var top: float = _grid.point_of(Vector2.ZERO).y
	return Rect2(left, top, _tuning.gantry_width, rows * _grid.spot_size())


# True when the column is on the lane's side of the container, anywhere
# from the upright to the lane's door.
func _is_beside(lane: EntryLane, column: float) -> bool:
	var width: int = _grid.layout().size().x
	if lane.side == Vector2i.LEFT:
		var inner: int = 0
		for door: Vector2i in lane.door_cells:
			inner = maxi(inner, door.x + 1)
		return column >= float(-_grid.apron_left()) and column < float(inner)
	var outer: int = width
	for door: Vector2i in lane.door_cells:
		outer = mini(outer, door.x)
	return column >= float(outer) and column < float(width + _grid.apron_right())
