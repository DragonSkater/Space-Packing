## GameState holds what the player has done (PLAN.md section 4.4). So far
## that is the list of launches, each with its load as it was committed.
## Earnings, unlocked ships, completed contracts, the fleet and the clock
## arrive in milestone 6. It does not load content or tuning values; those
## belong to Catalog and Tuning. Nothing is saved between sessions (PLAN.md section 1).
extends Node

# Where to look
#   Told by:    ui/boot/boot.gd -> _on_round_committed()
#   Records:    game/launch/launch_record.gd
#   Registered: project.godot, under [autoload]
#   Tests:      tests/game/test_game_state.gd

## A launch was added to the list.
signal launch_recorded(record: LaunchRecord)

var _launches: Array[LaunchRecord] = []


## Keeps a committed load as the next launch and returns its record. Until
## the launch screen exists (milestone 5) a round counts as launched when
## the player presses Done; from then on the launch button calls this.
func record_launch(round_name: String, committed_load: CommitRecord) -> LaunchRecord:
	var record: LaunchRecord = LaunchRecord.new()
	record.number = _launches.size() + 1
	record.round_name = round_name
	record.committed_load = committed_load
	_launches.append(record)
	launch_recorded.emit(record)
	return record


## Every launch so far, oldest first. A copy of the list, so the caller
## cannot change what is kept.
func launches() -> Array[LaunchRecord]:
	return _launches.duplicate()


## Forgets every launch. For tests and, later, for resetting progress from
## the debug overlay (MILESTONES.md milestone 6, item 11).
func clear_launches() -> void:
	_launches.clear()
