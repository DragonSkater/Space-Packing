## Tests for PackingScenario, the description of a round as data, and for
## the small things core/ offers a screen so that it can draw a round: the
## weight aboard, how far an item has been turned, and what is in an item's
## way. The scenarios here are built in code; the example files under data/
## are checked in tests/data/.
extends TestCase

const ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"######",
]


func test_a_scenario_starts_a_round_with_its_own_stack_and_move_limit() -> void:
	var scenario: PackingScenario = _scenario(7)
	var session: PackingSession = scenario.start(PackingTuning.new())
	assert_eq(session.stack().size(), 3)
	assert_eq(session.moves_left(), 7)
	assert_eq(session.state().layout.size(), Vector2i(6, 4))


func test_a_move_limit_of_zero_means_the_tuning_default() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.default_move_limit = 9
	assert_eq(_scenario(0).start(tuning).moves_left(), 9)


func test_the_designation_text_reaches_the_layout_as_an_overlay() -> void:
	var scenario: PackingScenario = _scenario(5)
	scenario.designation_text = "......\n...GG.\n......\n......"
	var marked: Array[Vector2i] = scenario.layout().cells_with_tag(CoreFixtures.MARKED_TAG)
	assert_eq(marked, [Vector2i(3, 1), Vector2i(4, 1)] as Array[Vector2i])
	assert_true(scenario.layout().is_storable(Vector2i(3, 1)), "a marked cell is still a cell to rest on")


func test_a_sound_scenario_has_no_problems() -> void:
	assert_eq(_scenario(5).problems(), [] as Array[String])


func test_a_scenario_reports_a_missing_legend_a_bad_layout_and_a_bad_batch() -> void:
	var no_legend: PackingScenario = _scenario(5)
	no_legend.legend = null
	assert_true(no_legend.problems().has("The scenario has no legend."))
	var no_door: PackingScenario = _scenario(5)
	no_door.layout_text = "####\n#..#\n####"
	assert_true(no_door.problems().has("The layout has no door."))
	var bad_batch: PackingScenario = _scenario(5)
	bad_batch.manifest = [CoreFixtures.batch(CoreFixtures.item_type("X.X"), 1)]
	assert_eq(bad_batch.problems().size(), 1, "an item type in two parts")


func test_the_weight_aboard_is_the_sum_of_the_loaded_items() -> void:
	var session: PackingSession = _scenario(9).start(PackingTuning.new())
	assert_almost_eq(session.state().total_weight(), 0.0)
	_load_top(session)
	_load_top(session)
	assert_almost_eq(session.state().total_weight(), 5.0, DEFAULT_TOLERANCE, "2.5 each")
	session.unload(session.state().items()[1].id, Vector2i.LEFT)
	assert_almost_eq(session.state().total_weight(), 2.5)


func test_an_item_counts_its_quarter_turns_clockwise_and_wraps_after_four() -> void:
	var session: PackingSession = _scenario(20).start(PackingTuning.new())
	session.pick_from_stack(0)
	var item: PackItem = session.held()
	assert_eq(item.quarter_turns, 0)
	session.turn_held(true)
	assert_eq(item.quarter_turns, 1)
	session.turn_held(false)
	session.turn_held(false)
	assert_eq(item.quarter_turns, 3, "one turn anticlockwise from the start")
	session.turn_held(true)
	session.push_in(session.entry_lanes()[0], 0)
	assert_true(session.turn(item.id, Vector2i(1, 1), true), "a turn inside the container counts too")
	assert_eq(item.quarter_turns, 1)


func test_the_session_names_the_items_in_the_way_of_a_slide_out() -> void:
	var session: PackingSession = _scenario(9).start(PackingTuning.new())
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 3)
	_load_top(session)
	var deep: PackItem = session.state().items()[0]
	var front: PackItem = session.state().items()[1]
	assert_eq(session.blockers(deep.id, Vector2i.LEFT), [front.id] as Array[int])
	assert_eq(session.blockers(deep.id, Vector2i.RIGHT), [] as Array[int], "a wall, not an item")


# Pushes the top of the stack into the first cell of the top row.
func _load_top(session: PackingSession) -> void:
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 0)


func _scenario(move_limit: int) -> PackingScenario:
	var single: PackItemType = CoreFixtures.item_type("X")
	single.weight = 2.5
	var scenario: PackingScenario = PackingScenario.new()
	scenario.display_name = "Test round"
	scenario.layout_text = "\n".join(ROWS)
	scenario.legend = CoreFixtures.legend()
	scenario.manifest = [CoreFixtures.batch(single, 3)]
	scenario.move_limit = move_limit
	return scenario
