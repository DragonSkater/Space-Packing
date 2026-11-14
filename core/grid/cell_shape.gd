## A set of grid cells, such as the outline of one item. Cells are offsets
## from the shape's own top-left corner and are kept normalised: the smallest
## x and the smallest y are both 0. A shape does not know where it sits in a
## container, what it is made of, or whether it is allowed to turn.
class_name CellShape
extends Resource

const FILLED_SYMBOL: String = "X"
const NEIGHBOUR_STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var cells: Array[Vector2i] = []


## Reads a drawing: 'X' is a filled cell and anything else is empty.
static func from_text(text: String) -> CellShape:
	var found: Array[Vector2i] = []
	var lines: PackedStringArray = text.split("\n")
	for row: int in lines.size():
		var line: String = lines[row]
		for column: int in line.length():
			if line[column] == FILLED_SYMBOL:
				found.append(Vector2i(column, row))
	return from_cells(found)


## Builds a normalised shape from cells given anywhere on the grid.
static func from_cells(any_cells: Array[Vector2i]) -> CellShape:
	var shape: CellShape = CellShape.new()
	shape.cells = any_cells.duplicate()
	return shape.normalised()


## The same shape moved so its smallest x and y are 0, cells in a fixed order.
func normalised() -> CellShape:
	var result: CellShape = CellShape.new()
	if cells.is_empty():
		return result
	var corner: Vector2i = bounds().position
	for cell: Vector2i in cells:
		result.cells.append(cell - corner)
	result.cells.sort()
	return result


## A quarter turn clockwise as seen on screen, where y grows downward.
func rotated_clockwise() -> CellShape:
	var turned: Array[Vector2i] = []
	for cell: Vector2i in cells:
		turned.append(Vector2i(-cell.y, cell.x))
	return from_cells(turned)


func rotated_anticlockwise() -> CellShape:
	var turned: Array[Vector2i] = []
	for cell: Vector2i in cells:
		turned.append(Vector2i(cell.y, -cell.x))
	return from_cells(turned)


## True when every cell can be reached from every other through shared sides.
## The milestone brief calls this is_connected, a name the engine already
## uses on every object for signals.
func is_one_piece() -> bool:
	if cells.is_empty():
		return false
	var reached: Array[Vector2i] = [cells[0]]
	var index: int = 0
	while index < reached.size():
		for step: Vector2i in NEIGHBOUR_STEPS:
			var neighbour: Vector2i = reached[index] + step
			if cells.has(neighbour) and not reached.has(neighbour):
				reached.append(neighbour)
		index += 1
	return reached.size() == cells.size()


func bounds() -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var lowest: Vector2i = cells[0]
	var highest: Vector2i = cells[0]
	for cell: Vector2i in cells:
		lowest = lowest.min(cell)
		highest = highest.max(cell)
	return Rect2i(lowest, highest - lowest + Vector2i.ONE)


## The grid cells this shape covers when its top-left corner is at origin.
func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	for cell: Vector2i in cells:
		placed.append(origin + cell)
	return placed


func matches(other: CellShape) -> bool:
	return normalised().cells == other.normalised().cells
