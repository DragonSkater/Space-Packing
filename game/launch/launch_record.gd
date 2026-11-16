## One launch, kept after the packing round that produced it: which round it
## was, its place in the order of launches, and the load exactly as it was
## committed. The overview and launch screens read these once they exist
## (MILESTONES.md milestones 5 and 6). For now it does not hold the ship,
## the contract, the bill or where the ship is; those fields arrive with
## the milestones that make them.
class_name LaunchRecord
extends RefCounted

# Where to look
#   Made by:    game/app/game_state.gd -> record_launch()
#   Its load:   core/packing/commit_record.gd
#   Tests:      tests/game/test_game_state.gd

## Counts from 1 in the order launches were recorded.
var number: int = 0
## The name of the round as the player saw it, such as a scenario's name.
var round_name: String = ""
## The container, its items and the moves, as they were at the commit.
var committed_load: CommitRecord
