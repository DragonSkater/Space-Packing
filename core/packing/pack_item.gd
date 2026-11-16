## One item, whether it is on the stack, on the loader or in the container.
## It keeps its id for the whole round, and its shape as it is currently
## turned. It does not move itself: PackState and PackingSession change its
## shape and origin, and nothing else should.
class_name PackItem
extends RefCounted

# Where to look
#   Made by:    core/packing/packing_session.gd -> _init()
#   Moved by:   core/packing/pack_state.gd -> place(), move(), remove()
#   Turned by:  core/packing/packing_session.gd -> turn(), turn_held()
#   Its type:   core/packing/pack_item_type.gd
#   Tests:      tests/core/test_packing_session.gd, tests/core/test_packing_scenario.gd

const FULL_TURN: int = 4

## Unique within a round, and never reused.
var id: int = -1
var type: PackItemType
## The outline as the item is turned right now.
var shape: CellShape
## Which line of the manifest this item came from.
var batch_index: int = -1
## The grid cell of the shape's top-left corner. Meaningful only while the
## item is inside the container.
var origin: Vector2i = Vector2i.ZERO
## How many other items were in the container when this one last entered.
var others_present_when_placed: int = 0
## Quarter turns clockwise since the round began, from 0 to 3. Screens use
## it to turn the item's picture; the shape above is already turned.
var quarter_turns: int = 0


# Starts turned the way its type draws it. Called by PackingSession._init.
func _init(item_id: int, item_type: PackItemType, from_batch: int) -> void:
	id = item_id
	type = item_type
	batch_index = from_batch
	shape = item_type.shape()


## The grid cells the item covers. Meaningful only inside the container.
func cells() -> Array[Vector2i]:
	return shape.cells_at(origin)


## Counts one quarter turn. The caller has already changed the shape.
func note_quarter_turn(clockwise: bool) -> void:
	var step: int = 1
	if not clockwise:
		step = FULL_TURN - 1
	quarter_turns = (quarter_turns + step) % FULL_TURN
