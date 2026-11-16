## One way a held item can enter the container: through the doors on one
## side, at one row offset, with every place along the way where it could be
## left. AccessSolver makes these; a lane is only a record and decides
## nothing itself.
class_name EntryLane
extends RefCounted

# Where to look
#   Made by:    core/packing/access_solver.gd -> entry_lanes()
#   Used by:    core/packing/packing_session.gd -> push_in()
#   Tests:      tests/core/test_access_solver.gd

## The side of the container the lane starts on: Vector2i.LEFT or RIGHT.
var side: Vector2i = Vector2i.LEFT
## The row of the item's top-left corner as it slides in.
var row: int = 0
## The door cells the item crosses on its way to the first stop.
var door_cells: Array[Vector2i] = []
## Where the loader holds the item: its last origin fully outside.
var hold_origin: Vector2i = Vector2i.ZERO
## Origins where the item can be left, in order from the door inward.
var stops: Array[Vector2i] = []


## The direction the item slides to go in: away from its side.
func inward() -> Vector2i:
	return -side


## True when both lanes enter from the same side at the same row.
func is_same_lane(other: EntryLane) -> bool:
	return side == other.side and row == other.row


## True when both lanes have a stop at this index and it is the same cell.
func has_same_stop(other: EntryLane, stop_index: int) -> bool:
	if stop_index < 0 or stop_index >= stops.size() or stop_index >= other.stops.size():
		return false
	return stops[stop_index] == other.stops[stop_index]
