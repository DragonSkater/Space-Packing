## The container exactly as a round left it at the commit: the layout, each
## item inside it with its turn and position, the items still waiting on the
## stack, and the moves spent. It is a set of copies taken at that moment,
## so a later round, or a restart, cannot change it. It scores nothing and
## stores nothing; whoever asked for it decides where it is kept.
class_name CommitRecord
extends RefCounted

# Where to look
#   Made by:    core/packing/packing_session.gd -> commit_record()
#   Its items:  core/packing/committed_item.gd
#   Tests:      tests/core/test_commit_record.gd

## The container's grid, designated cells included.
var layout: ContainerLayout
## The items inside the container, in the order they were placed.
var loaded: Array[CommittedItem] = []
## The items still on the stack, top first. Their origins mean nothing.
var left_behind: Array[CommittedItem] = []
var moves_used: int = 0
## The round's moves, including any granted during it.
var moves_allowed: int = 0
## Items of required batches that were not inside the container.
var required_left: int = 0


## Copies everything a session holds right now. An item on the loader has
## not gone in, so it is counted as left behind, on top of the stack.
static func from_session(session: PackingSession) -> CommitRecord:
	var record: CommitRecord = CommitRecord.new()
	record.layout = session.state().layout
	for item: PackItem in session.state().items():
		record.loaded.append(CommittedItem.copy_of(item))
	if session.held() != null:
		record.left_behind.append(CommittedItem.copy_of(session.held()))
	for item: PackItem in session.stack():
		record.left_behind.append(CommittedItem.copy_of(item))
	record.moves_used = session.moves_used()
	record.moves_allowed = session.moves_allowed()
	record.required_left = session.required_items_left()
	return record


## The loaded item covering a cell, or null.
func item_at(cell: Vector2i) -> CommittedItem:
	for item: CommittedItem in loaded:
		if item.cells().has(cell):
			return item
	return null


## The sum of the weights of the loaded items.
func loaded_weight() -> float:
	var total: float = 0.0
	for item: CommittedItem in loaded:
		total += item.type.weight
	return total
