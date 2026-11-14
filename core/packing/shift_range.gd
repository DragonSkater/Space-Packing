## Where an item already in the container can slide to along its row, and
## which sides it can leave by. AccessSolver makes these; a range is only a
## record and decides nothing itself.
class_name ShiftRange
extends RefCounted

## Origins where the item can be left, not including where it already is.
## Those to the left come first, each side listed nearest first.
var stops: Array[Vector2i] = []
## The directions (Vector2i.LEFT, Vector2i.RIGHT) in which the item can
## slide all the way out through a door.
var exits: Array[Vector2i] = []


func has_stop(origin: Vector2i) -> bool:
	return stops.has(origin)


func can_leave(direction: Vector2i) -> bool:
	return exits.has(direction)
