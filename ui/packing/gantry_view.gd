## Draws the gantry beside the container, under the pieces: an upright on
## each side with doors, an arm at every door, lit and dimmed doors while a
## piece is held, and the arms holding it in the active colour. It says which
## lane or arm a point is on, and changes nothing. CraneGripView draws the
## grip above the held piece; CraneControls decides what a tap means.
class_name GantryView
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named GantryView
#   Used by:    ui/packing/loading_bay.gd -> show_round(), _on_tapped(), _on_drag_started(), _on_drag_moved(), _apron()
#   Draws on:   ui/common/grid_view.gd -> cell_rect(), point_of()
#   Lanes from: core/packing/packing_session.gd -> entry_lanes()
#   Holding:    ui/packing/crane_controls.gd -> held_doors(), carry_doors()
#   Grip:       ui/packing/crane_grip_view.gd, drawn above the pieces
#   Numbers:    ui/common/presentation_tuning.gd, the Gantry and Colours groups

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT]
# A door's row is hit from half a cell above its middle to half below.
const HALF_CELL: float = 0.5

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


## True when the point, in cells, is on any door's crane arm, lit or
## dimmed: beside the container, from the upright to the door, within the
## door's row widened to the minimum touch target.
func is_on_an_arm(grid_point: Vector2) -> bool:
	var half_target: float = _tuning.min_touch_target / _grid.spot_size() / 2.0
	var reach: float = maxf(HALF_CELL, half_target)
	for side: Vector2i in SIDES:
		for door: Vector2i in entrance_doors(_grid.layout(), side):
			var door_cells: Array[Vector2i] = [door]
			var in_row: bool = absf(grid_point.y - (float(door.y) + HALF_CELL)) <= reach
			if in_row and _is_beside_doors(side, door_cells, grid_point.x):
				return true
	return false


# Paints an upright on each side that has doors, then every arm and door.
# The arms holding the piece, and their doors, are drawn in the active
# colour, so it is plain which crane has it even when no door will take it.
func _draw() -> void:
	if _session == null:
		return
	var holding: bool = _session.held() != null
	var lit_doors: Array[Vector2i] = []
	for lane: EntryLane in _session.entry_lanes():
		lit_doors.append_array(lane.door_cells)
	var holding_doors: Array[Vector2i] = _controls.held_doors()
	for side: Vector2i in SIDES:
		var doors: Array[Vector2i] = entrance_doors(_grid.layout(), side)
		if doors.is_empty():
			continue
		var upright: Rect2 = _upright(side)
		draw_rect(upright, _tuning.gantry_colour)
		for door: Vector2i in doors:
			var colour: Color = _tuning.gantry_colour
			if holding_doors.has(door):
				colour = _tuning.active_colour
			elif lit_doors.has(door):
				colour = _tuning.door_lit_colour
			_draw_arm(upright, door, side, colour)
			if lit_doors.has(door):
				draw_rect(_grid.cell_rect(door), _tuning.door_lit_colour, false, _tuning.outline_width)
			elif holding:
				draw_rect(_grid.cell_rect(door), _tuning.door_dimmed_colour)
	_outline_doors(holding_doors)
	_outline_doors(_controls.carry_doors())


# Outlines door cells in the active colour: the doors whose cranes hold the
# piece, or, while a piece is carried, the door letting go would hand it to.
func _outline_doors(doors: Array[Vector2i]) -> void:
	for door: Vector2i in doors:
		draw_rect(_grid.cell_rect(door), _tuning.active_colour, false, _tuning.outline_width)


# One arm, from the upright to its door, with a bar across the end.
func _draw_arm(upright: Rect2, door: Vector2i, side: Vector2i, colour: Color) -> void:
	var door_rect: Rect2 = _grid.cell_rect(door)
	var height: float = door_rect.get_center().y
	var from: Vector2 = Vector2(upright.end.x, height)
	var to: Vector2 = Vector2(door_rect.position.x, height)
	if side == Vector2i.RIGHT:
		from = Vector2(upright.position.x, height)
		to = Vector2(door_rect.end.x, height)
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
	return _is_beside_doors(lane.side, lane.door_cells, column)


# True when the column is on this side of the container, anywhere from the
# upright to these doors.
func _is_beside_doors(side: Vector2i, door_cells: Array[Vector2i], column: float) -> bool:
	var width: int = _grid.layout().size().x
	if side == Vector2i.LEFT:
		var inner: int = 0
		for door: Vector2i in door_cells:
			inner = maxi(inner, door.x + 1)
		return column >= float(-_grid.apron_left()) and column < float(inner)
	var outer: int = width
	for door: Vector2i in door_cells:
		outer = mini(outer, door.x)
	return column >= float(outer) and column < float(width + _grid.apron_right())
