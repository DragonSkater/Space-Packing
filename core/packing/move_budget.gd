## Counts the moves of one round: how many it began with, how many have
## been granted since, and how many are spent. It does not know what an
## action is or what one costs; PackingSession asks it whether a cost can be
## afforded and tells it what was spent.
class_name MoveBudget
extends RefCounted

# Where to look
#   Used by:    core/packing/packing_session.gd -> _spend(), grant_moves(), moves_left()
#   Costs:      core/packing/packing_tuning.gd
#   Tests:      tests/core/test_packing_session.gd

var _starting_limit: int = 0
var _granted: int = 0
var _used: int = 0


# starting_limit is the round's moves before any are granted.
func _init(starting_limit: int) -> void:
	_starting_limit = starting_limit


## The round's moves, including any granted since it began.
func limit() -> int:
	return _starting_limit + _granted


## Moves spent so far.
func used() -> int:
	return _used


## Moves still to spend.
func left() -> int:
	return limit() - _used


## True when the moves left cover a cost.
func can_afford(cost: int) -> bool:
	return cost <= left()


## Records moves as spent. Called by PackingSession._spend.
func spend(cost: int) -> void:
	_used += cost


## Adds moves to the round. Called by PackingSession.grant_moves.
func grant(count: int) -> void:
	_granted += count
