## GameState holds what the player has done (PLAN.md section 4.4). So far
## that is the list of launches, each with its load as it was committed and
## the scheduled launch it flew, and from that, which scheduled launches are
## open. Earnings, unlocked ships, the clock and travel arrive in milestone 6.
## It does not load content or tuning values; those belong to Catalog and
## Tuning. Nothing is saved between sessions (PLAN.md section 1).
extends Node

# Where to look
#   Told by:    ui/boot/boot.gd -> _on_launch_pressed()
#   Records:    game/launch/launch_record.gd
#   Judges:     game/launch/scheduled_launch.gd
#   Read by:    ui/overview/overview_screen.gd -> _redraw()
#   Registered: project.godot, under [autoload]
#   Tests:      tests/game/test_game_state.gd

## A launch was added to the list.
signal launch_recorded(record: LaunchRecord)

var _launches: Array[LaunchRecord] = []


## Keeps a committed load as the next launch and returns its record. The
## launch button on the launch screen is what calls this; scheduled is the
## upcoming launch that was flown, or null outside the schedule.
func record_launch(round_name: String, committed_load: CommitRecord, scheduled: ScheduledLaunch = null) -> LaunchRecord:
	var record: LaunchRecord = LaunchRecord.new()
	record.number = _launches.size() + 1
	record.round_name = round_name
	record.committed_load = committed_load
	record.scheduled = scheduled
	_launches.append(record)
	launch_recorded.emit(record)
	return record


## Every launch so far, oldest first. A copy of the list, so the caller
## cannot change what is kept.
func launches() -> Array[LaunchRecord]:
	return _launches.duplicate()


## How many times a scheduled launch has been flown, whatever was left behind.
func times_flown(scheduled: ScheduledLaunch) -> int:
	var count: int = 0
	for record: LaunchRecord in _launches:
		if record.scheduled == scheduled:
			count += 1
	return count


## True once a scheduled launch has been flown with no required cargo left
## behind. A launch that missed a requirement flies, but the level does not
## advance (PLAN.md section 3.5, D42).
func is_fulfilled(scheduled: ScheduledLaunch) -> bool:
	for record: LaunchRecord in _launches:
		if record.scheduled == scheduled and not record.missed_requirements():
			return true
	return false


## True when a scheduled launch can be flown: it needs nothing first, or
## what it needs has been fulfilled. Played in order, and replayable (D36).
func is_open(scheduled: ScheduledLaunch) -> bool:
	return scheduled.requires == null or is_fulfilled(scheduled.requires)


## Forgets every launch. For tests and, later, for resetting progress from
## the debug overlay (MILESTONES.md milestone 6, item 11).
func clear_launches() -> void:
	_launches.clear()
