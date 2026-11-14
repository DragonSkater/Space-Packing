## Several items of one type, listed together in a round's manifest. Batches
## are listed from the top of the stack down; to interleave types, list
## batches of one. A batch is only a line in a list: it holds no items.
class_name Batch
extends Resource

@export var item_type: PackItemType
@export_range(1, 32) var count: int = 1
## The round insists that every item of this batch is in the container.
@export var required: bool = true
