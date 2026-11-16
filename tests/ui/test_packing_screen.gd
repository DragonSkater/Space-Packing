## Opens the packing screen with each example scenario and presses its
## buttons, to prove the scene's parts are joined up: Done is never refused
## and shows the summary, Restart starts again. It cannot see the screen or
## make a gesture; the gestures are tested in test_gesture_reader.gd and
## what they do in test_crane_controls.gd.
extends TestCase

const SCREEN_PATH: String = "res://ui/packing/packing_screen.tscn"


func test_done_shows_the_summary_and_restart_clears_it_in_every_scenario() -> void:
	var screen: PackingScreen = _open_screen()
	var summary: RoundSummary = screen.get_node("%RoundSummary") as RoundSummary
	for scenario: PackingScenario in Catalog.scenarios():
		screen.open_scenario(scenario)
		assert_true(not summary.visible, "%s opens on the round" % scenario.display_name)
		_press(screen, "%DoneButton")
		assert_true(summary.visible, "Done is never refused")
		_press(summary, "%SummaryRestart")
		assert_true(not summary.visible, "Restart goes back to the round")
	screen.free()


func test_the_summary_says_what_was_left_behind() -> void:
	var screen: PackingScreen = _open_screen()
	screen.open_scenario(Catalog.scenarios()[0])
	_press(screen, "%DoneButton")
	var summary: RoundSummary = screen.get_node("%RoundSummary") as RoundSummary
	assert_eq((summary.get_node("%MovesUsed") as Label).text, "Moves used: 0 of 12")
	var left_behind: Label = summary.get_node("%LeftBehind") as Label
	assert_true(left_behind.visible)
	assert_eq(left_behind.text, "Required pieces left behind: 6")
	screen.free()


func test_the_screen_asks_for_the_next_scenario_from_the_summary() -> void:
	var screen: PackingScreen = _open_screen()
	var asked: Array[bool] = []
	screen.next_scenario_requested.connect(asked.append.bind(true))
	screen.open_scenario(Catalog.scenarios()[0])
	_press(screen, "%DoneButton")
	_press(screen.get_node("%RoundSummary"), "%NextScenario")
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
