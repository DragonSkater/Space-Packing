## Builds small legends, layouts, item types and sessions for the core tests
## in code, so that each test can show its whole situation in a few lines.
## Layouts are given as one string per row. It holds no assertions and none
## of the game's own content.
class_name CoreFixtures
extends RefCounted

const WALL_TAG: StringName = &"wall"
const MOTOR_TAG: StringName = &"motor"
const MARKED_TAG: StringName = &"marked"
const DEFAULT_MOVE_LIMIT: int = 20
# Items placed straight into a state need ids that cannot collide with a
# session's, which count up from zero.
const FIRST_LOOSE_ID: int = 1000

static var _next_loose_id: int = FIRST_LOOSE_ID


## '#' wall, '.' storable cell, 'D' door, '|' bulkhead, 'E' motor (blocked),
## 'G' an overlay letter that marks a cell.
static func legend() -> LayoutLegend:
	var result: LayoutLegend = LayoutLegend.new()
	result.entries = [
		entry("#", false, false, [WALL_TAG]),
		entry(".", true, true, []),
		entry("D", true, false, []),
		entry("|", false, false, []),
		entry("E", false, false, [MOTOR_TAG]),
		entry("G", true, true, [MARKED_TAG]),
	]
	return result


static func entry(symbol: String, passable: bool, storable: bool, tags: Array[StringName]) -> LegendEntry:
	var result: LegendEntry = LegendEntry.new()
	result.symbol = symbol
	result.passable = passable
	result.storable = storable
	result.tags = tags
	return result


static func layout(rows: Array[String], overlay_rows: Array[String] = []) -> ContainerLayout:
	return ContainerLayout.parse("\n".join(rows), legend(), "\n".join(overlay_rows))


static func state(rows: Array[String]) -> PackState:
	return PackState.new(layout(rows))


static func item_type(shape_text: String, can_rotate: bool = true) -> PackItemType:
	var result: PackItemType = PackItemType.new()
	result.id = StringName("item_" + shape_text.replace("\n", "_"))
	result.display_name = String(result.id)
	result.shape_text = shape_text
	result.can_rotate = can_rotate
	return result


## Puts a new item straight into a state, without going through a door.
static func put(into: PackState, shape_text: String, origin: Vector2i, can_rotate: bool = true) -> PackItem:
	var item: PackItem = PackItem.new(_next_loose_id, item_type(shape_text, can_rotate), 0)
	_next_loose_id += 1
	into.place(item, origin)
	return item


static func batch(type: PackItemType, count: int, required: bool = true) -> Batch:
	var result: Batch = Batch.new()
	result.item_type = type
	result.count = count
	result.required = required
	return result


static func session(rows: Array[String], manifest: Array[Batch], move_limit: int = DEFAULT_MOVE_LIMIT, tuning: PackingTuning = null) -> PackingSession:
	var used_tuning: PackingTuning = tuning
	if used_tuning == null:
		used_tuning = PackingTuning.new()
	return PackingSession.new(layout(rows), manifest, used_tuning, move_limit)


## Cells in a fixed order, so two lists can be compared whatever order they
## were built in.
static func sorted(cells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = cells.duplicate()
	result.sort()
	return result
