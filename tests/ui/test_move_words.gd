## Tests for MoveWords: the text the packing screen uses to say what a move
## is and what it costs. The costs must come from the session's tuning as
## it is now, never from the words themselves.
extends TestCase

const ROWS: Array[String] = ["#####", "D...#", "#####"]


func test_a_spent_note_names_the_action_and_its_cost() -> void:
	assert_eq(MoveWords.spent(PackingSession.ACTION_PUSH_IN, 1), "Load  -1")
	assert_eq(MoveWords.spent(PackingSession.ACTION_UNLOAD, 2), "Unload  -2")


func test_letting_go_says_the_action_and_the_count_or_that_it_is_free() -> void:
	assert_eq(MoveWords.let_go(PackingSession.ACTION_SHIFT, 1), "Let go: Slide, 1 move")
	assert_eq(MoveWords.let_go(PackingSession.ACTION_PUSH_IN, 3), "Let go: Load, 3 moves")
	assert_eq(MoveWords.let_go(PackingSession.ACTION_TURN, 0), "Let go: Turn, free")
	assert_eq(MoveWords.let_go(CraneControls.NO_ACTION, 0), "Let go: no move")


func test_the_cost_list_follows_the_tuning() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.push_in_cost = 2
	tuning.held_turn_cost = 0
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("X"), 1)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest, CoreFixtures.DEFAULT_MOVE_LIMIT, tuning)
	assert_eq(MoveWords.cost_list(session), "Load 2  ·  Slide 1  ·  Turn 1  ·  Turn on crane 0  ·  Unload 1")
	tuning.push_in_cost = 1
	assert_true(MoveWords.cost_list(session).begins_with("Load 1"), "read when asked, not when made")
