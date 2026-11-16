## One launch, kept after the packing round that produced it: which round it
## was, its place in the order of launches, which scheduled launch it flew,
## and the load exactly as it was committed. The overview lists and draws
## these. It does not hold the bill or where the ship is in flight; those
## arrive with milestones 5 and 6. For now a ship arrives as it launches.
class_name LaunchRecord
extends RefCounted

# Where to look
#   Made by:    game/app/game_state.gd -> record_launch()
#   Its load:   core/packing/commit_record.gd
#   Flew:       game/launch/scheduled_launch.gd
#   Shown by:   ui/overview/launched_row.gd -> show_record()
#               ui/overview/space_map_view.gd -> _draw_fleet()
#   Tests:      tests/game/test_game_state.gd

## Counts from 1 in the order launches were recorded.
var number: int = 0
## The name of the round as the player saw it, such as a scenario's name.
var round_name: String = ""
## The container, its items and the moves, as they were at the commit.
var committed_load: CommitRecord
## The upcoming launch this flew, or null for a round played outside the
## schedule.
var scheduled: ScheduledLaunch


## Where the ship went, or null when it had nowhere to go.
func destination() -> Body:
	if scheduled == null:
		return null
	return scheduled.destination


## True when required cargo was left behind. The ship still flies, but the
## launch does not count towards opening the next one (PLAN.md section 3.5,
## D42).
func missed_requirements() -> bool:
	return committed_load != null and committed_load.required_left > 0
