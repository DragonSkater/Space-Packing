## What is where inside the container: which item covers which cell. It
## answers "does this shape fit here?" and records placements and removals.
## It knows nothing about doors, the stack or moves; AccessSolver decides
## what may slide where, and PackingSession decides what an action costs.
class_name PackState
extends RefCounted

# Where to look
#   Changed by: core/packing/packing_session.gd -> push_in(), shift(), turn(), unload()
#   Asked by:   core/packing/access_solver.gd -> entry_lanes(), shift_range(), turn_option()
#   Its grid:   core/grid/container_layout.gd
#   Tests:      tests/core/test_access_solver.gd, tests/core/test_packing_scenario.gd

signal changed

const NO_ITEM: int = -1

var layout: ContainerLayout

# Items in the order they were placed.
var _items: Array[PackItem] = []
var _occupant_ids: Dictionary[Vector2i, int] = {}


# Starts empty.
func _init(container_layout: ContainerLayout) -> void:
	layout = container_layout


## True when every cell the shape would cover is in bounds, storable and
## free. An item named by ignore_item_id does not count as being in the way.
func fits(shape: CellShape, origin: Vector2i, ignore_item_id: int = NO_ITEM) -> bool:
	for cell: Vector2i in shape.cells_at(origin):
		if not layout.is_storable(cell):
			return false
		if not is_free(cell, ignore_item_id):
			return false
	return true


## True when no item, other than the one ignored, covers the cell.
func is_free(cell: Vector2i, ignore_item_id: int = NO_ITEM) -> bool:
	if not _occupant_ids.has(cell):
		return true
	return _occupant_ids[cell] == ignore_item_id


## Puts an item into the container at an origin where it fits.
func place(item: PackItem, origin: Vector2i) -> void:
	if not fits(item.shape, origin):
		push_error("PackState.place: item %d does not fit at %s." % [item.id, origin])
		return
	item.origin = origin
	_items.append(item)
	_cover_cells(item)
	changed.emit()


## Takes an item out of the container and returns it.
func remove(item_id: int) -> PackItem:
	var item: PackItem = item_by_id(item_id)
	if item == null:
		return null
	_uncover_cells(item)
	_items.erase(item)
	changed.emit()
	return item


## Gives an item already in the container a new shape and origin. Used by
## shifting and turning.
func move(item_id: int, shape: CellShape, origin: Vector2i) -> void:
	var item: PackItem = item_by_id(item_id)
	if item == null or not fits(shape, origin, item_id):
		push_error("PackState.move: item %d cannot be moved to %s." % [item_id, origin])
		return
	_uncover_cells(item)
	item.shape = shape
	item.origin = origin
	_cover_cells(item)
	changed.emit()


## The item covering a cell, or null when the cell is empty.
func item_at(cell: Vector2i) -> PackItem:
	if not _occupant_ids.has(cell):
		return null
	return item_by_id(_occupant_ids[cell])


## The item with this id, or null when it is not in the container.
func item_by_id(item_id: int) -> PackItem:
	for item: PackItem in _items:
		if item.id == item_id:
			return item
	return null


## Every item in the container, in the order they were placed.
func items() -> Array[PackItem]:
	return _items.duplicate()


## The share of storable cells that are covered, from 0 to 1.
func fill_ratio() -> float:
	var storable_count: int = layout.storable_cells().size()
	if storable_count == 0:
		return 0.0
	return float(_occupant_ids.size()) / float(storable_count)


## The weights of every item in the container, added up.
func total_weight() -> float:
	var total: float = 0.0
	for item: PackItem in _items:
		total += item.type.weight
	return total


# Records the item as the occupant of each cell it covers.
func _cover_cells(item: PackItem) -> void:
	for cell: Vector2i in item.cells():
		_occupant_ids[cell] = item.id


# Clears the item from the cells it covers.
func _uncover_cells(item: PackItem) -> void:
	for cell: Vector2i in item.cells():
		_occupant_ids.erase(cell)
