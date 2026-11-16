## The loading rule and the turning rule, as questions asked of a container.
##
## Loading: an item goes in and comes out in a straight line through a door.
## It may stop on any free cells along the way. It cannot pass through a wall
## or another item, and can leave only by sliding straight back out of a door.
##
## Turning: an item makes a quarter turn about the cell it is gripped by. The
## turn is allowed when every cell it would cover afterwards is a free cell
## where an item can rest. Only the end position is tested, not the swing.
##
## This class only answers. It never changes the state, and it knows nothing
## about the stack or what an action costs; PackingSession acts on its answers.
class_name AccessSolver
extends RefCounted

# Where to look
#   Asked by:   core/packing/packing_session.gd -> entry_lanes(), shift_range(), blockers(), turn()
#   Answers in: core/packing/entry_lane.gd, core/packing/shift_range.gd, core/packing/turn_option.gd
#   Reads:      core/packing/pack_state.gd -> fits(), is_free()
#               core/grid/container_layout.gd -> is_passable(), in_bounds(), is_door()
#   Tests:      tests/core/test_access_solver.gd

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT]


## Every way the shape could enter an otherwise untouched state, one lane per
## side and row offset that has at least one place to stop.
static func entry_lanes(state: PackState, shape: CellShape) -> Array[EntryLane]:
	var lanes: Array[EntryLane] = []
	var height: int = shape.bounds().size.y
	for side: Vector2i in SIDES:
		# Every row offset at which the shape overlaps the layout's rows.
		for row: int in range(1 - height, state.layout.size().y):
			var lane: EntryLane = _lane_from(state, shape, side, row)
			if not lane.stops.is_empty():
				lanes.append(lane)
	return lanes


## Where an item in the container can slide to, and the sides it can leave by.
static func shift_range(state: PackState, item_id: int) -> ShiftRange:
	var result: ShiftRange = ShiftRange.new()
	var item: PackItem = state.item_by_id(item_id)
	if item == null:
		return result
	for direction: Vector2i in SIDES:
		var origin: Vector2i = item.origin
		# Ends at a wall, at another item, or once the item is fully outside.
		while true:
			origin += direction
			if not _is_clear(state, item.shape, origin, item_id):
				break
			if _is_fully_outside(state.layout, item.shape, origin):
				result.exits.append(direction)
				break
			if state.fits(item.shape, origin, item_id):
				result.stops.append(origin)
	return result


## The ids of the other items in the way of an item's straight path out in
## one direction, up to the first cell nothing can pass. An empty result for
## a side the item cannot leave by means a wall is in the way, not an item.
static func blockers(state: PackState, item_id: int, direction: Vector2i) -> Array[int]:
	var ids: Array[int] = []
	var item: PackItem = state.item_by_id(item_id)
	if item == null:
		return ids
	var origin: Vector2i = item.origin
	while true:
		origin += direction
		if _is_fully_outside(state.layout, item.shape, origin):
			break
		var cells: Array[Vector2i] = item.shape.cells_at(origin)
		for cell: Vector2i in cells:
			if not state.layout.is_passable(cell):
				return ids
		for cell: Vector2i in cells:
			var other: PackItem = state.item_at(cell)
			if other != null and other.id != item_id and not ids.has(other.id):
				ids.append(other.id)
	return ids


## The result of a quarter turn about the gripped cell, or null when the
## turn is refused: the item's type may not turn, the grip is not one of the
## item's cells, or the item would not be at rest afterwards.
static func turn_option(state: PackState, item_id: int, grip: Vector2i, clockwise: bool) -> TurnOption:
	var item: PackItem = state.item_by_id(item_id)
	if item == null or not item.type.can_rotate:
		return null
	var cells: Array[Vector2i] = item.cells()
	if not cells.has(grip):
		return null
	var turned: Array[Vector2i] = []
	for cell: Vector2i in cells:
		turned.append(grip + _quarter_turn(cell - grip, clockwise))
	var option: TurnOption = TurnOption.new()
	option.shape = CellShape.from_cells(turned)
	option.origin = _top_left_of(turned)
	if not state.fits(option.shape, option.origin, item_id):
		return null
	return option


# Starts fully outside on one side and slides inward one cell at a time
# while the next position is clear. Every position at rest is a stop.
static func _lane_from(state: PackState, shape: CellShape, side: Vector2i, row: int) -> EntryLane:
	var layout_width: int = state.layout.size().x
	var shape_width: int = shape.bounds().size.x
	var lane: EntryLane = EntryLane.new()
	lane.side = side
	lane.row = row
	if side == Vector2i.LEFT:
		lane.hold_origin = Vector2i(-shape_width, row)
	else:
		lane.hold_origin = Vector2i(layout_width, row)
	var origin: Vector2i = lane.hold_origin
	# One slide more than this and the shape would be out the far side.
	for _slide: int in layout_width + shape_width - 1:
		origin += lane.inward()
		if not _is_clear(state, shape, origin, PackState.NO_ITEM):
			break
		if state.fits(shape, origin):
			lane.stops.append(origin)
		elif lane.stops.is_empty():
			_add_door_cells(state.layout, shape, origin, lane.door_cells)
	return lane


# Clear: each cell is outside, or can be passed and holds no other item.
static func _is_clear(state: PackState, shape: CellShape, origin: Vector2i, ignore_item_id: int) -> bool:
	for cell: Vector2i in shape.cells_at(origin):
		if not state.layout.is_passable(cell):
			return false
		if not state.is_free(cell, ignore_item_id):
			return false
	return true


# Fully outside: every cell is beyond the layout's bounding rectangle.
static func _is_fully_outside(layout: ContainerLayout, shape: CellShape, origin: Vector2i) -> bool:
	for cell: Vector2i in shape.cells_at(origin):
		if layout.in_bounds(cell):
			return false
	return true


# Notes the door cells a shape covers at one position, for EntryLane.door_cells.
static func _add_door_cells(layout: ContainerLayout, shape: CellShape, origin: Vector2i, door_cells: Array[Vector2i]) -> void:
	for cell: Vector2i in shape.cells_at(origin):
		if layout.is_door(cell) and not door_cells.has(cell):
			door_cells.append(cell)


# On screen y grows downward, so clockwise takes "right" to "down".
static func _quarter_turn(offset: Vector2i, clockwise: bool) -> Vector2i:
	if clockwise:
		return Vector2i(-offset.y, offset.x)
	return Vector2i(offset.y, -offset.x)


# The top-left corner of the rectangle round some cells: an item's origin.
static func _top_left_of(cells: Array[Vector2i]) -> Vector2i:
	var corner: Vector2i = cells[0]
	for cell: Vector2i in cells:
		corner = corner.min(cell)
	return corner
