## Tests for PackingSession: the stack, the loader, what each action costs,
## and what happens when an action is refused or the moves run out
## (PLAN.md sections 3.2 and 3.5). Where an item may slide is tested in
## test_access_solver.gd.
extends TestCase

const ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"######",
]

var _refusals: Array[StringName] = []
var _finishes: Array[StringName] = []


func test_the_stack_holds_count_items_per_batch_with_the_first_batch_on_top() -> void:
	var pair: PackItemType = CoreFixtures.item_type("XX")
	var single: PackItemType = CoreFixtures.item_type("X")
	var manifest: Array[Batch] = [CoreFixtures.batch(pair, 2), CoreFixtures.batch(single, 3)]
	var stack: Array[PackItem] = CoreFixtures.session(ROWS, manifest).stack()
	assert_eq(stack.size(), 5)
	assert_true(stack[0].type == pair and stack[1].type == pair, "the first batch is on top")
	assert_true(stack[2].type == single and stack[4].type == single, "the second batch is under it")


func test_each_action_deducts_its_own_cost() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.held_turn_cost = 4
	tuning.push_in_cost = 1
	tuning.shift_cost = 2
	tuning.turn_cost = 3
	tuning.unload_cost = 5
	var session: PackingSession = _session_of_singles_and_a_pair(30, tuning)
	session.pick_from_stack(0)
	assert_eq(session.moves_left(), 30, "picking is free")
	assert_true(session.turn_held(true), "a turn on the loader")
	assert_eq(session.moves_left(), 26)
	assert_true(session.push_in(session.entry_lanes()[0], 1), "a push in")
	assert_eq(session.moves_left(), 25)
	var item: PackItem = session.state().items()[0]
	assert_true(session.shift(item.id, Vector2i(3, 1)), "a shift")
	assert_eq(session.moves_left(), 23)
	assert_true(session.turn(item.id, Vector2i(3, 1), true), "a turn in the container")
	assert_eq(session.moves_left(), 20)
	assert_true(session.unload(item.id, Vector2i.LEFT), "an unload")
	assert_eq(session.moves_left(), 15)
	assert_eq(session.moves_used(), 15)


func test_every_spend_names_its_action_and_cost_is_read_from_the_tuning() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.held_turn_cost = 4
	tuning.shift_cost = 2
	var session: PackingSession = _session_of_singles_and_a_pair(30, tuning)
	var spent: Array[String] = []
	session.moves_spent.connect(func(action: StringName, cost: int) -> void: spent.append("%s %d" % [action, cost]))
	session.pick_from_stack(0)
	session.turn_held(true)
	session.push_in(session.entry_lanes()[0], 1)
	var item: PackItem = session.state().items()[0]
	session.shift(item.id, Vector2i(3, 1))
	session.unload(item.id, Vector2i.LEFT)
	assert_eq(spent, ["held_turn 4", "push_in 1", "shift 2", "unload 1"] as Array[String], "picking spends nothing")
	assert_eq(session.cost_of(PackingSession.ACTION_SHIFT), 2)
	tuning.shift_cost = 5
	assert_eq(session.cost_of(PackingSession.ACTION_SHIFT), 5, "read when asked")
	assert_eq(session.cost_of(&"not_an_action"), 0)


func test_a_turn_that_leaves_an_item_on_the_same_cells_is_free() -> void:
	var manifest: Array[Batch] = [
		CoreFixtures.batch(CoreFixtures.item_type("X"), 1),
		CoreFixtures.batch(CoreFixtures.item_type("XX
XX"), 1),
		CoreFixtures.batch(CoreFixtures.item_type("XX"), 1),
	]
	var session: PackingSession = _watched(CoreFixtures.session(ROWS, manifest, 10))
	var spent: Array[StringName] = []
	session.moves_spent.connect(func(action: StringName, _cost: int) -> void: spent.append(action))
	session.pick_from_stack(0)
	assert_true(session.turn_held(true), "a single item on the loader")
	assert_eq(session.held().quarter_turns, 1, "its picture still turns")
	session.push_in(session.entry_lanes()[0], 0)
	var single: PackItem = session.state().items()[0]
	assert_true(session.turn(single.id, single.origin, false), "a single item in the container")
	session.pick_from_stack(0)
	assert_true(session.turn_held(true), "a square on the loader")
	assert_eq(session.moves_left(), 9, "only the load was paid for")
	assert_eq(spent, [PackingSession.ACTION_PUSH_IN] as Array[StringName], "a free turn says nothing")


func test_a_turn_that_moves_any_cell_costs_its_full_price() -> void:
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("XX"), 1)]
	var session: PackingSession = _watched(CoreFixtures.session(ROWS, manifest, 10))
	session.pick_from_stack(0)
	session.turn_held(true)
	assert_eq(session.moves_left(), 9)


func test_free_turns_can_be_switched_off() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.free_turn_when_unchanged = false
	var session: PackingSession = _session_of_singles_and_a_pair(10, tuning)
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 0)
	session.pick_from_stack(0)
	session.turn_held(true)
	assert_eq(session.moves_left(), 8, "the pair's load and the single's turn are both paid for")


func test_the_bottom_of_the_stack_can_be_taken_only_when_the_round_allows_it() -> void:
	var session: PackingSession = _session_of_singles_and_a_pair(10, PackingTuning.new())
	var bottom: PackItem = session.stack()[3]
	assert_true(not session.can_pick(3))
	assert_true(not session.pick_from_stack(3), "out of reach by default")
	session.set_stack_bottom_reachable(true)
	assert_true(session.stack_reachable(0) and session.stack_reachable(3))
	assert_true(not session.stack_reachable(2), "the middle stays out of reach")
	assert_true(session.pick_from_stack(3))
	assert_true(session.held() == bottom)
	assert_true(not session.can_pick(0), "nothing can be taken while the loader is full")
	assert_true(session.stack_reachable(0), "though the top is still within reach")
	session.put_back()
	assert_true(session.stack()[0] == bottom, "put back, it goes on top")


func test_a_shift_costs_the_same_whatever_the_distance() -> void:
	var session: PackingSession = _session_with_one_single_loaded(10)
	var item: PackItem = session.state().items()[0]
	var before: int = session.moves_left()
	session.shift(item.id, Vector2i(4, 1))
	assert_eq(before - session.moves_left(), 1, "three cells, one move")


func test_a_refused_action_costs_nothing_and_changes_nothing() -> void:
	var session: PackingSession = _session_with_one_single_loaded(10)
	var item: PackItem = session.state().items()[0]
	var before: int = session.moves_left()
	assert_true(not session.shift(item.id, Vector2i(1, 2)), "another row is not a stop")
	assert_true(not session.turn(item.id, Vector2i(4, 2), true), "a grip that is not on the item")
	assert_true(not session.unload(item.id, Vector2i.RIGHT), "there is no door on the right")
	assert_eq(session.moves_left(), before)
	assert_eq(item.origin, Vector2i(1, 1))
	assert_eq(_refusals, [PackingSession.REFUSED_BLOCKED, PackingSession.REFUSED_CANNOT_TURN, PackingSession.REFUSED_NO_DOOR] as Array[StringName])


func test_an_action_is_refused_when_no_moves_are_left() -> void:
	var session: PackingSession = _session_with_one_single_loaded(1)
	assert_eq(session.moves_left(), 0)
	var item: PackItem = session.state().items()[0]
	assert_true(not session.shift(item.id, Vector2i(2, 1)), "a shift")
	session.pick_from_stack(0)
	assert_true(not session.push_in(session.entry_lanes()[0], 0), "a push in")
	assert_true(session.held() != null, "the item is still on the loader")
	assert_true(session.turn_held(true), "turning a single item changes nothing, so it is free even now")
	assert_eq(_refusals, [PackingSession.REFUSED_NO_MOVES, PackingSession.REFUSED_NO_MOVES] as Array[StringName])
	assert_eq(session.moves_left(), 0)


func test_running_out_of_moves_does_not_end_the_round_and_committing_always_can() -> void:
	var session: PackingSession = _session_with_one_single_loaded(1)
	assert_eq(_finishes, [] as Array[StringName], "no moves left, and the round goes on")
	assert_true(session.required_items_left() > 0, "with required items still on the stack")
	session.commit()
	assert_eq(_finishes, [PackingSession.FINISHED_COMMITTED] as Array[StringName])


func test_pushing_in_along_a_lane_or_to_a_stop_that_is_not_offered_is_refused() -> void:
	var session: PackingSession = _session_with_one_single_loaded(10)
	session.pick_from_stack(0)
	var made_up: EntryLane = EntryLane.new()
	made_up.side = Vector2i.RIGHT
	made_up.row = 1
	made_up.stops = [Vector2i(4, 1)]
	assert_true(not session.push_in(made_up, 0), "there is no door on the right")
	var real: EntryLane = session.entry_lanes()[0]
	assert_true(not session.push_in(real, real.stops.size()), "one past the last stop")
	assert_eq(_refusals, [PackingSession.REFUSED_NO_DOOR, PackingSession.REFUSED_BLOCKED] as Array[StringName])
	assert_eq(session.state().items().size(), 1)


func test_only_the_top_of_the_stack_can_be_picked_at_depth_one() -> void:
	var session: PackingSession = _session_of_singles_and_a_pair(10, PackingTuning.new())
	assert_true(not session.pick_from_stack(1), "the second from the top")
	assert_true(session.pick_from_stack(0), "the top")
	assert_true(not session.pick_from_stack(0), "the loader is already holding one")


func test_the_top_two_can_be_picked_at_depth_two() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	tuning.stack_pick_depth = 2
	var session: PackingSession = _session_of_singles_and_a_pair(10, tuning)
	var second: PackItem = session.stack()[1]
	assert_true(not session.pick_from_stack(2), "the third from the top")
	assert_true(session.pick_from_stack(1), "the second from the top")
	assert_true(session.held() == second)


func test_tuning_is_read_when_it_is_used_not_when_the_round_begins() -> void:
	var tuning: PackingTuning = PackingTuning.new()
	var session: PackingSession = _session_of_singles_and_a_pair(10, tuning)
	tuning.stack_pick_depth = 2
	assert_true(session.pick_from_stack(1), "a depth changed mid-round applies at once")


func test_putting_back_an_untouched_item_is_free_and_returns_it_to_the_top() -> void:
	var session: PackingSession = _session_of_singles_and_a_pair(10, PackingTuning.new())
	var top: PackItem = session.stack()[0]
	session.pick_from_stack(0)
	session.put_back()
	assert_true(session.held() == null)
	assert_true(session.stack()[0] == top)
	assert_eq(session.moves_left(), 10)


func test_an_unloaded_item_lands_on_top_of_the_stack_and_keeps_its_turn() -> void:
	var session: PackingSession = _session_of_singles_and_a_pair(20, PackingTuning.new())
	session.pick_from_stack(0)
	session.turn_held(true)
	session.push_in(session.entry_lanes()[0], 0)
	var item: PackItem = session.state().items()[0]
	var waiting_before: PackItem = session.stack()[0]
	assert_true(session.unload(item.id, Vector2i.LEFT))
	assert_true(session.stack()[0] == item, "it is on top")
	assert_true(session.stack()[1] == waiting_before, "the item that was next is now under it")
	assert_true(item.shape.matches(CellShape.from_text("X\nX")), "still upright, as it was turned")
	assert_eq(session.state().items().size(), 0)


func test_granting_moves_raises_the_moves_left() -> void:
	var session: PackingSession = _session_with_one_single_loaded(5)
	session.grant_moves(2)
	assert_eq(session.moves_left(), 6)
	assert_eq(session.moves_allowed(), 7)
	assert_eq(session.moves_used(), 1)


func test_required_items_left_counts_down_as_they_are_loaded() -> void:
	var required: PackItemType = CoreFixtures.item_type("X")
	var optional: PackItemType = CoreFixtures.item_type("XX")
	var manifest: Array[Batch] = [CoreFixtures.batch(required, 2), CoreFixtures.batch(optional, 1, false)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest)
	assert_eq(session.required_items_left(), 2, "the optional batch is not counted")
	session.pick_from_stack(0)
	assert_eq(session.required_items_left(), 2, "on the loader is not in the container")
	session.push_in(session.entry_lanes()[0], 0)
	assert_eq(session.required_items_left(), 1)
	var loaded: PackItem = session.state().items()[0]
	session.unload(loaded.id, Vector2i.LEFT)
	assert_eq(session.required_items_left(), 2, "unloading it counts it again")


func test_pushing_in_records_how_many_other_items_were_already_inside() -> void:
	var session: PackingSession = _session_of_singles_and_a_pair(20, PackingTuning.new())
	_push_to_the_back(session, 0)
	_push_to_the_back(session, 0)
	_push_to_the_back(session, 1)
	var loaded: Array[PackItem] = session.state().items()
	assert_eq(loaded[0].others_present_when_placed, 0)
	assert_eq(loaded[2].others_present_when_placed, 2)
	assert_true(session.shift(loaded[2].id, Vector2i(2, 2)))
	assert_eq(loaded[2].others_present_when_placed, 2, "a shift does not change it")


# Takes the top of the stack and pushes it as deep as one lane allows.
func _push_to_the_back(session: PackingSession, lane_index: int) -> void:
	session.pick_from_stack(0)
	var lane: EntryLane = session.entry_lanes()[lane_index]
	session.push_in(lane, lane.stops.size() - 1)


func test_a_manifest_line_with_no_item_type_is_skipped_and_reported_as_a_problem() -> void:
	var empty_line: Batch = Batch.new()
	var manifest: Array[Batch] = [empty_line, CoreFixtures.batch(CoreFixtures.item_type("X"), 2)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest)
	assert_eq(session.stack().size(), 2)
	assert_eq(session.required_items_left(), 2)
	assert_eq(empty_line.problems().size(), 1)
	assert_eq(manifest[1].problems(), [] as Array[String])


func test_an_item_type_whose_drawing_is_empty_or_in_two_parts_is_a_problem() -> void:
	assert_eq(CoreFixtures.item_type("..").problems().size(), 1, "no X at all")
	assert_eq(CoreFixtures.item_type("X.X").problems().size(), 1, "two separate cells")
	assert_eq(CoreFixtures.item_type("X.
XX").problems(), [] as Array[String], "an L is fine")


func _session_of_singles_and_a_pair(move_limit: int, tuning: PackingTuning) -> PackingSession:
	var manifest: Array[Batch] = [
		CoreFixtures.batch(CoreFixtures.item_type("XX"), 1),
		CoreFixtures.batch(CoreFixtures.item_type("X"), 3),
	]
	return _watched(CoreFixtures.session(ROWS, manifest, move_limit, tuning))


# One single pushed into the cell beside the top door, which costs one move.
func _session_with_one_single_loaded(move_limit: int) -> PackingSession:
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("X"), 3)]
	var session: PackingSession = _watched(CoreFixtures.session(ROWS, manifest, move_limit))
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 0)
	return session


func _watched(session: PackingSession) -> PackingSession:
	session.action_refused.connect(_on_action_refused)
	session.finished.connect(_on_finished)
	return session


func _on_action_refused(reason: StringName, _item_ids: Array[int]) -> void:
	_refusals.append(reason)


func _on_finished(reason: StringName) -> void:
	_finishes.append(reason)
