## A placeholder for one upcoming launch on the overview: where the ship is
## headed and what it carries. Either it plays a ready-made scenario, hull
## included, or it carries a cargo stack and is flown in a ship: the one it
## names, or one the player picks (MILESTONES.md milestone 6, item 7). It
## stands in for milestone 6's contracts. GameState says whether it is open.
class_name ScheduledLaunch
extends Resource

# Where to look
#   Files:      data/launches/
#   Loaded by:  game/app/catalog.gd -> scheduled_launches()
#   Judged by:  game/app/game_state.gd -> is_open(), times_flown()
#   Shown by:   ui/overview/upcoming_row.gd -> show_launch()
#               ui/overview/ship_picker.gd -> offer()
#   Opened by:  ui/boot/boot.gd -> _open_packing()
#   Ships:      game/ships/ship_type.gd
#   Tests:      tests/game/test_game_state.gd, tests/game/test_scheduled_launch.gd,
#               tests/data/test_example_ships.gd

const ROUND_NAME_TEXT: String = "%s, in %s"

## The name on the overview, such as "Supplies for Planet A".
@export var display_name: String
## Where the ship flies when it is launched.
@export var destination: Body
## A ready-made packing round, hull included. When it is set, the cargo
## and ship below are not used and no ship is picked.
@export var scenario: PackingScenario
## The launch that must be flown first, with nothing required left behind
## (PLAN.md section 3.9, D36). Empty means it is open from the start.
@export var requires: ScheduledLaunch
@export_multiline var description: String

@export_group("Cargo and ship")
## The cargo stack, listed from the top down. Used when no scenario is set.
@export var manifest: Array[Batch] = []
## Moves for the round. Zero means use the tuning default.
@export_range(0, 99) var move_limit: int = PackingScenario.USE_DEFAULT_LIMIT
## Optional. The one ship this launch is flown in (PLAN.md D43). Empty
## means the player picks any ship that has a hull.
@export var ship: ShipType
## Optional, and only with a ship named above: designated spots drawn over
## that ship's hull, a letter on each spot and dots elsewhere.
@export_multiline var designation_text: String = ""


## True when the player picks the ship: there is no ready-made scenario
## and no ship is named.
func chooses_ship() -> bool:
	return scenario == null and ship == null


## True when this launch can be flown in the given ship.
func can_fly_in(candidate: ShipType) -> bool:
	if scenario != null or candidate == null or not candidate.has_hull():
		return false
	return ship == null or ship == candidate


## The packing round for this launch. chosen is the ship the player
## picked; it is ignored when a scenario is set or a ship is named.
## Returns null when there is no ship to fly.
func round_in(chosen: ShipType) -> PackingScenario:
	if scenario != null:
		return scenario
	var flown: ShipType = chosen
	if ship != null:
		flown = ship
	if flown == null:
		return null
	var built: PackingScenario = PackingScenario.new()
	built.display_name = ROUND_NAME_TEXT % [display_name, flown.display_name]
	built.layout_text = flown.hull_layout_text
	built.legend = flown.legend
	built.designation_text = designation_text
	built.manifest = manifest
	built.move_limit = move_limit
	return built


## How many cargo spots the whole stack covers, optional cargo included.
func cargo_spots_needed() -> int:
	var spots: int = 0
	for batch: Batch in _manifest_in_use():
		if batch != null and batch.item_type != null:
			spots += batch.count * batch.item_type.shape().cells.size()
	return spots


## Spots left over when the whole stack is in the given ship: zero when
## they match, negative when the ship is too small (the overview warns).
func spare_spots_in(candidate: ShipType) -> int:
	return candidate.cargo_spot_count() - cargo_spots_needed()


## Plain sentences for mistakes that make the launch unplayable.
func problems() -> Array[String]:
	var found: Array[String] = []
	if scenario != null:
		return found
	if manifest.is_empty():
		found.append("%s has neither a scenario nor a cargo stack." % display_name)
	if not designation_text.strip_edges().is_empty() and ship == null:
		found.append("%s draws designated spots but names no ship to draw them on (PLAN.md D43)." % display_name)
	for batch: Batch in manifest:
		if batch == null:
			found.append("A line of the cargo stack of %s is empty." % display_name)
		else:
			found.append_array(batch.problems())
	return found


# The stack the round will use: the scenario's when one is set.
func _manifest_in_use() -> Array[Batch]:
	if scenario != null:
		return scenario.manifest
	return manifest
