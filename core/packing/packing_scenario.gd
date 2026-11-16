## A ready-made round of packing, as data: the container drawn as text, an
## optional overlay that marks designated cells, the legend both are read
## with, the manifest and the number of moves. It describes a round and can
## start one. PackingSession plays the round; nothing here says how it is
## drawn or judged.
class_name PackingScenario
extends Resource

# Where to look
#   Starts:     core/packing/packing_session.gd -> _init(), set_stack_bottom_reachable()
#   Parses via: core/grid/container_layout.gd -> parse()
#   Checked by: core/grid/layout_validator.gd -> problems(), warnings()
#   Its lines:  core/packing/batch.gd
#   Tests:      tests/core/test_packing_scenario.gd

const USE_DEFAULT_LIMIT: int = 0

@export var display_name: String = ""
## The container, one character per cell, read with the legend below.
@export_multiline var layout_text: String = ""
## Optional. A second drawing of the same size as the layout: a letter marks
## a designated cell, a dot or a space marks nothing.
@export_multiline var designation_text: String = ""
## What each character in the two drawings means.
@export var legend: LayoutLegend
## The stack, listed from the top down.
@export var manifest: Array[Batch] = []
## Moves in this round. Zero means use the tuning default.
@export_range(0, 99) var move_limit: int = USE_DEFAULT_LIMIT
## When on, the item at the bottom of the stack can be taken as well as
## the one on top, so the player can work the stack from either end.
@export var stack_bottom_reachable: bool = false


## The container this round is played in, parsed afresh on every call.
func layout() -> ContainerLayout:
	var used_legend: LayoutLegend = legend
	if used_legend == null:
		# Every character is then unknown, which problems() reports.
		used_legend = LayoutLegend.new()
	return ContainerLayout.parse(layout_text, used_legend, designation_text)


## The moves this round gets: its own limit, or the tuning default.
func move_limit_with(tuning: PackingTuning) -> int:
	if move_limit == USE_DEFAULT_LIMIT:
		return tuning.default_move_limit
	return move_limit


## A new round of this scenario, with nothing loaded and no moves spent.
func start(tuning: PackingTuning) -> PackingSession:
	var session: PackingSession = PackingSession.new(layout(), manifest, tuning, move_limit_with(tuning))
	session.set_stack_bottom_reachable(stack_bottom_reachable)
	return session


## Plain sentences for mistakes that make this round unplayable.
func problems() -> Array[String]:
	var found: Array[String] = []
	if legend == null:
		found.append("The scenario has no legend.")
	found.append_array(LayoutValidator.problems(layout()))
	for batch: Batch in manifest:
		if batch == null:
			found.append("A line of the manifest is empty.")
		else:
			found.append_array(batch.problems())
	return found


## Playable, but probably not what was intended.
func warnings() -> Array[String]:
	return LayoutValidator.warnings(layout())
