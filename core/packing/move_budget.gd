## Counts the moves of one round: how many it began with, how many have
## been granted since, and how many are spent. It does not know what an
## action is or what one costs; PackingSession asks it whether a cost can be
## afforded and tells it what was spent.
class_name MoveBudget
extends RefCounted

var _starting_limit: int = 0
var _granted: int = 0
var _used: int = 0


func _init(starting_limit: int) -> void:
	_starting_limit = starting_limit


## The round's moves, including any granted since it began.
func limit() -> int:
	return _starting_limit + _granted


func used() -> int:
	return _used


func left() -> int:
	return limit() - _used


func can_afford(cost: int) -> bool:
	return cost <= left()


func spend(cost: int) -> void:
	_used += cost


func grant(count: int) -> void:
	_granted += count
