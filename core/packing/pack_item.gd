## One item, whether it is on the stack, on the loader or in the container.
## It keeps its id for the whole round, and its shape as it is currently
## turned. It does not move itself: PackState and PackingSession change its
## shape and origin, and nothing else should.
class_name PackItem
extends RefCounted

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


func _init(item_id: int, item_type: PackItemType, from_batch: int) -> void:
	id = item_id
	type = item_type
	batch_index = from_batch
	shape = item_type.shape()


## The grid cells the item covers. Meaningful only inside the container.
func cells() -> Array[Vector2i]:
	return shape.cells_at(origin)
