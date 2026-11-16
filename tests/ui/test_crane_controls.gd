## Tests for CraneControls: the control scheme of the packing screen, driven
## in cells with no screen (MILESTONES.md milestone 2, item 8). Several
## follow the designer's sanity checks for that milestone step by step.
## Whether the gestures feel right is the designer's to judge, not this file's.
extends TestCase

const ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"D....#",
	"#EEEE#",
]
# The stack is drawn to the left of the container, level with its top row.
const STACK_POINT: Vector2 = Vector2(-3.0, 1.5)

var _shaken: Array[int] = []
var _lit_items: Array[int] = []
var _lit_cells: Array[Vector2i] = []
var _moves_missed: int = 0


func test_tapping_the_stack_holds_the_top_piece_outside_the_nearest_door() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	assert_true(session.held() != null, "the crane has the piece")
	assert_eq(controls.held_lane().row, 1, "the top door is nearest the stack")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT, "taking a piece is free")
	controls.tap_stack(0, STACK_POINT)
	assert_true(session.held() == null, "tapping the stack again puts it back")
	controls.tap_stack(0, Vector2(-3.0, 3.4))
	assert_eq(controls.held_lane().row, 3, "from lower down, the bottom door is nearest")


func test_tapping_another_door_moves_the_held_piece_there_for_free() -> void:
	var session: PackingSession = _session(["X"])
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	controls.tap_door(_lane_at_row(session, 3))
	assert_eq(controls.held_lane().row, 3)
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT)


func test_sliding_a_held_piece_in_and_letting_go_loads_it_for_one_move() -> void:
	var session: PackingSession = _session(["X"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 3)
	assert_eq(session.state().items()[0].origin, Vector2i(3, 1), "stopped short of the back wall")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1)
	assert_true(controls.active_item() == null, "the crane has let go")


func test_a_slide_snaps_from_stop_to_stop_and_follows_the_finger_back() -> void:
	var session: PackingSession = _session(["X"])
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	assert_true(controls.begin_slide(Vector2i.RIGHT))
	controls.slide_by(0.8)
	assert_eq(controls.slide().current, Vector2i(-1, 1), "the door is not a stop: still nearer the outside")
	controls.slide_by(1.2)
	assert_eq(controls.slide().current, Vector2i(1, 1), "past halfway, it snaps to the first spot")
	controls.slide_by(9.0)
	assert_eq(controls.slide().current, Vector2i(4, 1), "no further than the back wall")
	controls.slide_by(0.0)
	controls.end_slide()
	assert_true(session.held() != null, "released where it started: still held")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT, "and nothing spent")


func test_a_buried_piece_will_not_slide_out_and_the_pieces_in_front_light_up() -> void:
	var session: PackingSession = _session(["X", "X", "X"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 3)
	_load(controls, session, 1, 2)
	_load(controls, session, 1, 1)
	var loaded: Array[PackItem] = session.state().items()
	controls.tap_cell(Vector2i(3, 1))
	assert_true(not controls.begin_slide(Vector2i.LEFT), "the deepest piece cannot start towards the door")
	assert_eq(_shaken, [loaded[0].id] as Array[int])
	assert_eq(_lit_items, [loaded[1].id, loaded[2].id] as Array[int], "both pieces in front")
	assert_eq(loaded[0].origin, Vector2i(3, 1), "nothing moved")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 3)


func test_dragging_the_front_piece_out_past_its_door_puts_it_on_top_of_the_stack() -> void:
	var session: PackingSession = _session(["X", "X", "XX"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 2)
	_load(controls, session, 1, 1)
	var front: PackItem = session.state().item_at(Vector2i(1, 1))
	var was_next: PackItem = session.stack()[0]
	controls.tap_cell(Vector2i(1, 1))
	assert_true(controls.begin_slide(Vector2i.LEFT))
	controls.slide_by(-2.0)
	controls.end_slide()
	assert_true(session.stack()[0] == front, "it is on top of the stack")
	assert_true(session.stack()[1] == was_next, "the piece about to be loaded is now under it")
	assert_true(controls.selected_item() == null)
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 3, "unloading costs a move")


func test_the_l_hooks_over_a_block_when_turned_about_its_foot() -> void:
	# The drawing in PLAN.md section 3.4.
	var session: PackingSession = _session(["X", "X\nXX"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 2, 4)
	_load(controls, session, 1, 2)
	controls.tap_cell(Vector2i(3, 2))
	controls.turn(true)
	var l_piece: PackItem = session.state().item_at(Vector2i(3, 2))
	assert_eq(CoreFixtures.sorted(l_piece.cells()), CoreFixtures.sorted([Vector2i(3, 1), Vector2i(4, 1), Vector2i(3, 2)]))
	assert_eq(controls.grip(), Vector2i(3, 2), "the grip does not move in a turn")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 3)


func test_a_turn_that_does_not_fit_shakes_the_piece_and_costs_nothing() -> void:
	var session: PackingSession = _session(["XX"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 1)
	var beam: PackItem = session.state().items()[0]
	controls.tap_cell(Vector2i(1, 1))
	controls.turn(false)
	assert_eq(_shaken, [beam.id] as Array[int], "it would swing up into the wall")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1)


func test_a_piece_turned_across_a_row_with_no_door_cannot_leave_until_turned_back() -> void:
	var rows: Array[String] = ["######", "D....#", "#....#", "######"]
	var session: PackingSession = CoreFixtures.session(rows, _manifest(["XX"]))
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 1)
	controls.tap_cell(Vector2i(1, 1))
	controls.turn(true)
	assert_true(not controls.begin_slide(Vector2i.LEFT), "half of it is behind a wall")
	assert_eq(_lit_cells, [Vector2i(0, 2)] as Array[Vector2i], "the wall in its way lights up")
	controls.turn(false)
	assert_true(controls.begin_slide(Vector2i.LEFT), "turned back, it can go")
	controls.slide_by(-3.0)
	controls.end_slide()
	assert_eq(session.stack().size(), 1)


func test_a_two_row_piece_is_offered_only_the_tall_opening() -> void:
	var rows: Array[String] = ["#######", "D..|..D", "#.....#", "D.....#", "D.....#", "#EEEEE#"]
	var session: PackingSession = CoreFixtures.session(rows, _manifest(["XX\nXX"]))
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	assert_eq(session.entry_lanes().size(), 1)
	assert_eq(controls.held_lane().door_cells, [Vector2i(0, 3), Vector2i(0, 4)] as Array[Vector2i])


func test_with_no_moves_left_nothing_slides_or_turns_and_the_attempt_is_reported() -> void:
	var session: PackingSession = CoreFixtures.session(ROWS, _manifest(["XX", "X"]), 1)
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 2)
	assert_eq(session.moves_left(), 0)
	controls.tap_cell(Vector2i(2, 1))
	assert_true(controls.selected_item() != null, "a piece can still be looked at")
	assert_true(not controls.begin_slide(Vector2i.RIGHT))
	controls.turn(true)
	assert_eq(_moves_missed, 2)
	assert_eq(session.state().items()[0].origin, Vector2i(2, 1))


func test_tapping_empty_space_deselects_and_the_crane_keeps_its_piece() -> void:
	var session: PackingSession = _session(["X", "XX", "X"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 1)
	controls.tap_cell(Vector2i(1, 1))
	controls.tap_cell(Vector2i(3, 3))
	assert_true(controls.selected_item() == null, "an empty spot is empty space")
	controls.tap_stack(0, STACK_POINT)
	controls.tap_empty()
	assert_true(session.held() != null, "the crane keeps the piece")
	controls.tap_stack(0, STACK_POINT)
	assert_true(session.held() == null, "tapping the stack puts it back")
	assert_eq(session.stack().size(), 2, "back on the stack")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1, "putting it back is free")


func test_the_grip_travels_with_a_piece_that_is_shifted() -> void:
	var session: PackingSession = _session(["XX"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 1)
	controls.tap_cell(Vector2i(2, 1))
	assert_true(controls.begin_slide(Vector2i.RIGHT))
	controls.slide_by(2.0)
	controls.end_slide()
	assert_eq(session.state().items()[0].origin, Vector2i(3, 1))
	assert_eq(controls.grip(), Vector2i(4, 1))
	assert_true(controls.selected_item() != null, "still selected")


func test_a_held_piece_turns_for_a_move_and_one_that_may_not_turn_shakes() -> void:
	var session: PackingSession = CoreFixtures.session(ROWS, [
		CoreFixtures.batch(CoreFixtures.item_type("XX"), 1),
		CoreFixtures.batch(CoreFixtures.item_type("XX", false), 1),
	])
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	controls.turn(true)
	assert_true(session.held().shape.matches(CellShape.from_text("X\nX")))
	assert_eq(controls.held_lane().door_cells.size(), 2, "upright, it waits at two doors")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1)
	_load(controls, session, 1, 1)
	controls.tap_stack(0, STACK_POINT)
	controls.turn(true)
	assert_eq(_shaken, [session.held().id] as Array[int])
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 2, "the refused turn was free")


func test_the_crane_waits_with_the_next_piece_while_a_loaded_one_is_worked() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	_load(controls, session, 1, 4)
	assert_true(controls.wants_fetch(), "the crane is empty and the stack is not")
	controls.fetch(STACK_POINT)
	var next: PackItem = session.held()
	assert_true(next != null and not controls.wants_fetch(), "it has fetched the next piece")
	assert_eq(controls.held_lane().row, 1, "to the door nearest the stack")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1, "fetching is free")
	controls.tap_cell(Vector2i(4, 1))
	assert_true(controls.active_item() == session.state().item_at(Vector2i(4, 1)), "the loaded piece is active")
	assert_true(session.held() == next, "and the crane still waits with the next")
	assert_true(controls.begin_slide(Vector2i.LEFT))
	controls.slide_by(-2.0)
	controls.end_slide()
	assert_eq(session.state().items()[0].origin, Vector2i(2, 1))
	controls.tap_door(controls.held_lane())
	assert_true(controls.active_item() == next, "a tap on its door makes the waiting piece active")


func test_putting_a_piece_back_by_hand_stops_the_crane_fetching_it_again() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	controls.fetch(STACK_POINT)
	controls.tap_stack(0, STACK_POINT)
	assert_true(not controls.wants_fetch(), "the crane waits for the player")
	controls.tap_stack(0, STACK_POINT)
	_load(controls, session, 1, 4)
	assert_true(controls.wants_fetch(), "taking a piece by hand starts it again")


func test_a_piece_dragged_from_the_stack_onto_a_door_waits_there() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	assert_true(controls.begin_carry(0, STACK_POINT))
	assert_true(controls.is_carrying() and not controls.wants_fetch())
	controls.carry_to(Vector2(-0.5, 3.5), _lane_at_row(session, 3))
	assert_eq(controls.carry_point(), Vector2(-0.5, 3.5))
	controls.end_carry()
	assert_true(not controls.is_carrying())
	assert_eq(controls.held_lane().row, 3, "dropped on the bottom door")
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT, "carrying is free")
	assert_true(not controls.begin_carry(0, STACK_POINT), "only an empty crane can be given one")


func test_a_piece_dropped_away_from_every_door_goes_back_on_the_stack() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	controls.begin_carry(0, STACK_POINT)
	controls.carry_to(Vector2(-3.0, 0.0), null)
	controls.end_carry()
	assert_true(session.held() == null)
	assert_eq(session.stack().size(), 2)
	assert_true(not controls.wants_fetch(), "the crane does not snatch it straight back")


func test_a_slide_says_what_letting_go_would_cost() -> void:
	var session: PackingSession = _session(["X", "X"])
	var controls: CraneControls = _controls(session)
	controls.tap_stack(0, STACK_POINT)
	controls.begin_slide(Vector2i.RIGHT)
	assert_eq(controls.pending_action(), CraneControls.NO_ACTION, "not moved yet: free")
	controls.slide_by(3.0)
	assert_eq(controls.pending_action(), PackingSession.ACTION_PUSH_IN)
	controls.end_slide()
	controls.tap_cell(Vector2i(2, 1))
	controls.begin_slide(Vector2i.RIGHT)
	controls.slide_by(1.0)
	assert_eq(controls.pending_action(), PackingSession.ACTION_SHIFT)
	controls.slide_by(-9.0)
	assert_eq(controls.pending_action(), PackingSession.ACTION_UNLOAD, "out past the door")
	assert_eq(controls.slide().finger_x, -1.0, "the finger is held at the furthest stop")
	controls.slide_by(0.0)
	assert_eq(controls.pending_action(), CraneControls.NO_ACTION)
	controls.end_slide()
	assert_eq(session.moves_left(), CoreFixtures.DEFAULT_MOVE_LIMIT - 1)


# Takes the top of the stack to the door of one row and leaves it with its
# left edge at a column.
func _load(controls: CraneControls, session: PackingSession, row: int, column: int) -> void:
	if session.held() == null:
		controls.tap_stack(0, STACK_POINT)
	controls.tap_door(_lane_at_row(session, row))
	controls.begin_slide(Vector2i.RIGHT)
	controls.slide_by(float(column - controls.held_lane().hold_origin.x))
	controls.end_slide()


func _lane_at_row(session: PackingSession, row: int) -> EntryLane:
	for lane: EntryLane in session.entry_lanes():
		if lane.row == row and lane.side == Vector2i.LEFT:
			return lane
	fail("no lane on the left at row %d" % row)
	return null


func _session(shapes: Array[String]) -> PackingSession:
	return CoreFixtures.session(ROWS, _manifest(shapes))


func _manifest(shapes: Array[String]) -> Array[Batch]:
	var manifest: Array[Batch] = []
	for shape_text: String in shapes:
		manifest.append(CoreFixtures.batch(CoreFixtures.item_type(shape_text), 1))
	return manifest


func _controls(session: PackingSession) -> CraneControls:
	var controls: CraneControls = CraneControls.new(session)
	controls.attempt_refused.connect(_on_attempt_refused)
	controls.moves_missed.connect(_on_moves_missed)
	return controls


func _on_attempt_refused(shaken_item_id: int, lit_item_ids: Array[int], lit_cells: Array[Vector2i]) -> void:
	_shaken.append(shaken_item_id)
	_lit_items.append_array(lit_item_ids)
	_lit_cells.append_array(lit_cells)


func _on_moves_missed() -> void:
	_moves_missed += 1
