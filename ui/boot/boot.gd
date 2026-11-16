## The first scene the game opens. For now it shows the packing screen and
## hands it one example scenario at a time from the Catalog, moving to the
## next when the screen asks, and passes each committed load to GameState to
## be kept as a launch. It holds no rules of its own. The overview
## screen takes over choosing what is played in milestone 6.
extends Control

# Where to look
#   Scene:      ui/boot/boot.tscn, the project's main scene
#   Opens:      ui/packing/packing_screen.gd -> open_scenario()
#   Content:    game/app/catalog.gd -> scenarios()
#   Keeps:      game/app/game_state.gd -> record_launch()

var _scenario_index: int = 0

@onready var _packing_screen: PackingScreen = %PackingScreen


# Opens the first scenario and listens for the screen asking for another.
func _ready() -> void:
	_packing_screen.next_scenario_requested.connect(_open_next_scenario)
	_packing_screen.round_committed.connect(_on_round_committed)
	_open_scenario(_scenario_index)


# Called when Next scenario is pressed on the summary panel.
func _open_next_scenario() -> void:
	_open_scenario(_scenario_index + 1)


# Until the launch screen exists (milestone 5), Done is the launch.
func _on_round_committed(round_name: String, record: CommitRecord) -> void:
	GameState.record_launch(round_name, record)


# Past the last scenario it starts again from the first.
func _open_scenario(index: int) -> void:
	var scenarios: Array[PackingScenario] = Catalog.scenarios()
	if scenarios.is_empty():
		push_error("Boot: data/scenarios/ holds no scenario to open.")
		return
	_scenario_index = index % scenarios.size()
	_packing_screen.open_scenario(scenarios[_scenario_index])
