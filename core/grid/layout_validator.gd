## Catches hand-authoring mistakes in a layout and describes each in a plain
## sentence. Problems mean the layout cannot be played at all; warnings mean
## it can, but is probably not what was intended. Columns and rows in the
## sentences count from 1, as a text editor does. It never changes a layout
## and never refuses one; the caller decides what to do with the sentences.
class_name LayoutValidator
extends RefCounted

# Where to look
#   Checks:     core/grid/container_layout.gd -> unknown_symbols(), storable_cells(), overlay_cells()
#   Used by:    core/packing/packing_scenario.gd -> problems(), warnings()
#   Tests:      tests/core/test_layout_validator.gd

const NEIGHBOUR_STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## The layout cannot be played: an unknown character, no cell where an item
## can rest, or no door.
static func problems(layout: ContainerLayout) -> Array[String]:
	var found: Array[String] = []
	var unknown: Dictionary[Vector2i, String] = layout.unknown_symbols()
	for cell: Vector2i in unknown:
		found.append("The character '%s' at %s is not in the legend." % [unknown[cell], _place(cell)])
	var overlay_unknown: Dictionary[Vector2i, String] = layout.overlay_unknown_symbols()
	for cell: Vector2i in overlay_unknown:
		found.append("The overlay character '%s' at %s is not in the legend." % [overlay_unknown[cell], _place(cell)])
	if layout.storable_cells().is_empty():
		found.append("The layout has no cell where an item can rest.")
	if not _has_door(layout):
		found.append("The layout has no door.")
	return found


## The layout can be played, but something in it is probably a mistake.
static func warnings(layout: ContainerLayout) -> Array[String]:
	var found: Array[String] = []
	for cell: Vector2i in layout.storable_cells():
		if _touches_outside(layout, cell):
			found.append("The storable cell at %s is open to the outside." % _place(cell))
	found.append_array(_unreachable_run_warnings(layout))
	found.append_array(_overlay_warnings(layout))
	return found


# True when at least one cell is a door.
static func _has_door(layout: ContainerLayout) -> bool:
	for row: int in layout.size().y:
		for column: int in layout.size().x:
			if layout.is_door(Vector2i(column, row)):
				return true
	return false


# True when a side of the cell faces an outside cell.
static func _touches_outside(layout: ContainerLayout, cell: Vector2i) -> bool:
	for step: Vector2i in NEIGHBOUR_STEPS:
		if layout.is_outside(cell + step):
			return true
	return false


# A run is a stretch of storable cells side by side in one row. A run that a
# single-cell item could not slide into from either side, even with the
# container empty, can never be used.
static func _unreachable_run_warnings(layout: ContainerLayout) -> Array[String]:
	var found: Array[String] = []
	var width: int = layout.size().x
	for row: int in layout.size().y:
		var column: int = 0
		while column < width:
			if not layout.is_storable(Vector2i(column, row)):
				column += 1
				continue
			var first: int = column
			while column < width and layout.is_storable(Vector2i(column, row)):
				column += 1
			var last: int = column - 1
			var open_from_left: bool = _row_is_open(layout, row, 0, first)
			var open_from_right: bool = _row_is_open(layout, row, last + 1, width)
			if not open_from_left and not open_from_right:
				found.append("No item can reach columns %d to %d of row %d: nothing leads to them from a door." % [first + 1, last + 1, row + 1])
	return found


# True when every cell of the row from one column up to, but not including,
# another can be passed through.
static func _row_is_open(layout: ContainerLayout, row: int, from_column: int, to_column: int) -> bool:
	for column: int in range(from_column, to_column):
		if not layout.is_passable(Vector2i(column, row)):
			return false
	return true


# An overlay of the wrong size, or a mark on a cell where nothing can rest.
static func _overlay_warnings(layout: ContainerLayout) -> Array[String]:
	var found: Array[String] = []
	var overlay_size: Vector2i = layout.overlay_size()
	if overlay_size == Vector2i.ZERO:
		return found
	if overlay_size != layout.size():
		found.append("The overlay is %d columns by %d rows, but the layout is %d by %d." % [overlay_size.x, overlay_size.y, layout.size().x, layout.size().y])
	for cell: Vector2i in layout.overlay_cells():
		if not layout.is_storable(cell):
			found.append("The overlay marks %s, which is not a cell where an item can rest." % _place(cell))
	return found


# A cell as the sentences name it, counting from 1.
static func _place(cell: Vector2i) -> String:
	return "column %d, row %d" % [cell.x + 1, cell.y + 1]
