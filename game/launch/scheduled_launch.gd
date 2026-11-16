## A placeholder for one upcoming launch on the overview: a packing round
## and where the packed ship is headed. It stands in for the contracts of
## milestone 6, which will add a reward, unlocks and requirements of their
## own. It decides nothing; GameState says whether it is open yet.
class_name ScheduledLaunch
extends Resource

# Where to look
#   Files:      data/launches/
#   Loaded by:  game/app/catalog.gd -> scheduled_launches()
#   Judged by:  game/app/game_state.gd -> is_open(), times_flown()
#   Shown by:   ui/overview/upcoming_row.gd -> show_launch()
#   Tests:      tests/game/test_game_state.gd

## The name on the overview, such as "Supplies for Planet A".
@export var display_name: String
## Where the ship flies when it is launched.
@export var destination: Body
## The packing round: container, cargo stack and moves.
@export var scenario: PackingScenario
## The launch that must be flown first, with nothing required left behind
## (PLAN.md section 3.9, D36). Empty means it is open from the start.
@export var requires: ScheduledLaunch
@export_multiline var description: String
