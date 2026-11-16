## Opens the packing screen with each example scenario and presses its
## buttons, to prove the scene's parts are joined up: Done is never refused
## and hands the load on, Overview asks to leave, Restart starts again. It
## cannot see the screen or make a gesture; the gestures are tested in
## test_gesture_reader.gd and what they do in test_crane_controls.gd.
extends TestCase

const SCREEN_PATH: String = "res://ui/packing/packing_screen.tscn"


func test_done_hands_on_the_load_in_every_scenario() -> void:
	var screen: PackingScreen = _open_screen()
	var handed_on: Array[CommitRecord] = []
	screen.round_committed.connect(func(_name: String, record: CommitRecord) -> void: handed_on.append(record))
	for scenario: PackingScenario in Catalog.scenarios():
		screen.open_scenario(scenario)
		_press(screen, "%DoneButton")
	assert_eq(handed_on.size(), Catalog.scenarios().size(), "Done is never refused")
	screen.free()


func test_the_load_handed_on_says_what_was_left_behind() -> void:
	var screen: PackingScreen = _open_screen()
	var handed_on: Array[CommitRecord] = []
	screen.round_committed.connect(func(_name: String, record: CommitRecord) -> void: handed_on.append(record))
	screen.open_scenario(Catalog.scenarios()[0])
	_press(screen, "%DoneButton")
	assert_eq(handed_on[0].moves_used, 0)
	assert_eq(handed_on[0].moves_allowed, 12)
	assert_eq(handed_on[0].required_left, 6)
	screen.free()


func test_the_overview_button_asks_to_leave() -> void:
	var screen: PackingScreen = _open_screen()
	var asked: Array[bool] = []
	screen.overview_requested.connect(asked.append.bind(true))
	screen.open_scenario(Catalog.scenarios()[0])
	_press(screen, "%OverviewButton")
	assert_eq(asked.size(), 1)
	screen.free()


func test_the_top_strip_shows_the_scenario_and_its_moves() -> void:
	var screen: PackingScreen = _open_screen()
	var scenario: PackingScenario = Catalog.scenarios()[1]
	screen.open_scenario(scenario)
	assert_eq((screen.get_node("%ScenarioName") as Label).text, scenario.display_name)
	assert_eq((screen.get_node("%MovesNumber") as Label).text, "16")
	screen.free()


# The screen has to be in the tree for its parts to find each other.
func _open_screen() -> PackingScreen:
	var packed: PackedScene = load(SCREEN_PATH) as PackedScene
	var screen: PackingScreen = packed.instantiate() as PackingScreen
	scene_host.add_child(screen)
	return screen


func _press(owner_node: Node, button_name: String) -> void:
	(owner_node.get_node(button_name) as Button).pressed.emit()
