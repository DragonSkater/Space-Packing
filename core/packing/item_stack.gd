## The pile of items waiting to be loaded, top first, and which of them can
## be taken: the top few, as deep as stack_pick_depth reaches, and, in a
## round that allows it, the one at the bottom. Items put back or unloaded
## go on top. It knows nothing about the loader, the container or moves.
class_name ItemStack
extends RefCounted

# Where to look
#   Owned by:   core/packing/packing_session.gd -> _init(), pick_from_stack(), put_back(), unload()
#   Depth from: core/packing/packing_tuning.gd, stack_pick_depth
#   Tests:      tests/core/test_packing_session.gd

## When on, the item at the bottom can be taken as well as those at the top.
var bottom_reachable: bool = false

# Index 0 is the top.
var _items: Array[PackItem] = []


## The items, top first. A copy, so the caller cannot rearrange the pile.
func items() -> Array[PackItem]:
	return _items.duplicate()


## How many items are waiting.
func size() -> int:
	return _items.size()


## True when the item this far from the top can be taken: it is within the
## pick depth, or it is the bottom one and the bottom is reachable.
func can_take(index_from_top: int, pick_depth: int) -> bool:
	if index_from_top < 0 or index_from_top >= _items.size():
		return false
	if index_from_top < pick_depth:
		return true
	return bottom_reachable and index_from_top == _items.size() - 1


## Removes and returns the item this far from the top. The caller has
## checked can_take first.
func take(index_from_top: int) -> PackItem:
	var item: PackItem = _items[index_from_top]
	_items.remove_at(index_from_top)
	return item


## Puts an item on top, as putting back and unloading both do.
func put_on_top(item: PackItem) -> void:
	_items.insert(0, item)


## Adds an item under the rest, as the stack is built from the manifest.
func put_at_bottom(item: PackItem) -> void:
	_items.append(item)
