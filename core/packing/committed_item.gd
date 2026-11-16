## One item as it stood when its round was committed: its type, how it was
## turned, and where it lay. It is a copy, so later rounds cannot change it.
## It belongs to a CommitRecord and decides nothing.
class_name CommittedItem
extends RefCounted

# Where to look
#   Made by:    core/packing/commit_record.gd -> from_session()
#   Copied from: core/packing/pack_item.gd
#   Tests:      tests/core/test_commit_record.gd

var item_id: int = -1
var type: PackItemType
## Which line of the manifest the item came from.
var batch_index: int = -1
## The outline as it was turned at the commit.
var shape: CellShape
## Quarter turns clockwise from the way its type draws it, 0 to 3.
var quarter_turns: int = 0
## The cell of the shape's top-left corner. Meaningful only for items that
## were inside the container.
var origin: Vector2i = Vector2i.ZERO
## How many other items were in the container when it last entered.
var others_present_when_placed: int = 0


## A copy of an item as it is now.
static func copy_of(item: PackItem) -> CommittedItem:
	var copy: CommittedItem = CommittedItem.new()
	copy.item_id = item.id
	copy.type = item.type
	copy.batch_index = item.batch_index
	copy.shape = CellShape.from_cells(item.shape.cells)
	copy.quarter_turns = item.quarter_turns
	copy.origin = item.origin
	copy.others_present_when_placed = item.others_present_when_placed
	return copy


## The container cells the item covered.
func cells() -> Array[Vector2i]:
	return shape.cells_at(origin)
