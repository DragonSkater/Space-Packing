## Tuning holds the tuning resources from data/tuning/ and hands them to the
## code that reads them (PLAN.md section 4.4). Announcing changes, resetting
## and saving arrive with the tuning panel in milestone 3. It does not decide
## what any number means; the code that reads a value does.
extends Node

# Where to look
#   Reads:      data/tuning/packing_tuning.tres, data/tuning/presentation.tres
#   Fields:     core/packing/packing_tuning.gd, ui/common/presentation_tuning.gd
#   Used by:    ui/packing/packing_screen.gd -> _start_round()
#               ui/common/presentation_tuning.gd -> current()
#   Registered: project.godot, under [autoload]
#   Tests:      tests/game/test_catalog.gd

const PACKING_PATH: String = "res://data/tuning/packing_tuning.tres"
const PRESENTATION_PATH: String = "res://data/tuning/presentation.tres"

## What each loader action costs and how many moves a round gets.
var packing: PackingTuning
## Sizes, colours, timings and touch distances for screens. Its class lives
## in ui/, which game/ may not name (CLAUDE.md, Layers), so it is held here
## as a plain Resource. Screens read it through PresentationTuning.current().
var presentation: Resource


# Loads both tuning files once, when the game starts.
func _ready() -> void:
	packing = ResourceLoader.load(PACKING_PATH) as PackingTuning
	if packing == null:
		push_error("Tuning: %s did not load; using the script's defaults." % PACKING_PATH)
		packing = PackingTuning.new()
	presentation = ResourceLoader.load(PRESENTATION_PATH)
	if presentation == null:
		push_error("Tuning: %s did not load." % PRESENTATION_PATH)
