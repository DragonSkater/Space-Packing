## One kind of ship, as data: its name and the hull the player packs, drawn
## as text and read with a legend (PLAN.md sections 3.8 and 5). This is the
## greybox start of milestone 5's ShipType; costs, flight numbers and the
## switches join it there. It does not know which launches it suits; a
## launch compares its own cargo against the hull (ScheduledLaunch).
# ============================================================
# EXTENSION POINT: ships
# To add one: a new file in data/ships/. No code changes.
# To add a ship switch: a new field here, read in the one place that cares.
# ============================================================
class_name ShipType
extends Resource

# Where to look
#   Files:      data/ships/
#   Loaded by:  game/app/catalog.gd -> ships()
#   Flown by:   game/launch/scheduled_launch.gd -> round_in()
#   Parses via: core/grid/container_layout.gd -> parse()
#   Shown by:   ui/overview/ship_row.gd -> show_ship()
#   Tests:      tests/game/test_ship_type.gd, tests/data/test_example_ships.gd

@export_group("Identity")
@export var id: StringName
## The name the player sees, such as "R0-KET".
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Hull")
## The hull, one character per spot, read with the legend below. The same
## drawing as a scenario's layout (PLAN.md section 5, Ship type).
@export_multiline var hull_layout_text: String = ""
## What each character in the hull drawing means.
@export var legend: LayoutLegend


## The hull, parsed afresh on every call. overlay_text draws designated
## spots over it, as a launch that names this ship may do.
func layout(overlay_text: String = "") -> ContainerLayout:
	var used_legend: LayoutLegend = legend
	if used_legend == null:
		# Every character is then unknown, which problems() reports.
		used_legend = LayoutLegend.new()
	return ContainerLayout.parse(hull_layout_text, used_legend, overlay_text)


## True when the ship has a hold the player packs. A craft with an empty
## hull drawing has none (PLAN.md section 3.8).
func has_hull() -> bool:
	return not hull_layout_text.strip_edges().is_empty()


## How many spots in the hull can hold cargo.
func cargo_spot_count() -> int:
	if not has_hull():
		return 0
	return layout().storable_cells().size()


## Plain sentences for mistakes that make the hull unplayable. A ship with
## no hull has none to report.
func problems() -> Array[String]:
	var found: Array[String] = []
	if display_name.is_empty():
		found.append("The ship %s has no name." % resource_path.get_file())
	if not has_hull():
		return found
	if legend == null:
		found.append("The ship %s has no legend." % display_name)
	found.append_array(LayoutValidator.problems(layout()))
	return found


## Playable, but probably not what was intended.
func warnings() -> Array[String]:
	if not has_hull():
		return []
	return LayoutValidator.warnings(layout())
