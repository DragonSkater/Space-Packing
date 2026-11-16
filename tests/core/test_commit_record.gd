## Tests for CommitRecord: the copy of a round taken when it is committed.
## It must show every item where it lay and as it was turned, count what was
## left behind, and stay as it was when the session carries on afterwards.
extends TestCase

const ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"######",
]


func test_the_record_holds_each_loaded_item_where_it_lay_and_as_it_was_turned() -> void:
	var session: PackingSession = _session(["XX", "X"])
	session.pick_from_stack(0)
	session.turn_held(true)
	_push_deepest(session, 1)
	session.pick_from_stack(0)
	_push_deepest(session, 1)
	var record: CommitRecord = session.commit_record()
	assert_eq(record.loaded.size(), 2)
	var upright: CommittedItem = record.loaded[0]
	assert_eq(upright.quarter_turns, 1, "turned once on the crane")
	assert_true(upright.shape.matches(CellShape.from_text("X\nX")))
	assert_eq(CoreFixtures.sorted(upright.cells()), CoreFixtures.sorted([Vector2i(4, 1), Vector2i(4, 2)]))
	assert_eq(record.loaded[1].others_present_when_placed, 1)
	assert_true(record.item_at(Vector2i(4, 2)) == upright)
	assert_true(record.item_at(Vector2i(1, 2)) == null)


func test_the_record_counts_the_stack_and_the_crane_as_left_behind() -> void:
	var session: PackingSession = _session(["X", "X", "X"])
	session.pick_from_stack(0)
	_push_deepest(session, 1)
	session.pick_from_stack(0)
	var record: CommitRecord = session.commit_record()
	assert_eq(record.left_behind.size(), 2, "one on the crane, one on the stack")
	assert_eq(record.left_behind[0].item_id, session.held().id, "the crane's piece counts as the top")
	assert_eq(record.required_left, 2)
	assert_eq(record.moves_used, 1)
	assert_eq(record.moves_allowed, CoreFixtures.DEFAULT_MOVE_LIMIT)


func test_the_record_does_not_change_when_the_round_carries_on() -> void:
	var session: PackingSession = _session(["X"])
	session.pick_from_stack(0)
	_push_deepest(session, 1)
	var record: CommitRecord = session.commit_record()
	var item: PackItem = session.state().items()[0]
	session.shift(item.id, Vector2i(1, 1))
	session.turn(item.id, Vector2i(1, 1), true)
	assert_eq(record.loaded[0].origin, Vector2i(4, 1), "still where it was committed")
	assert_eq(record.loaded[0].quarter_turns, 0)
	assert_eq(record.moves_used, 1)


func test_the_record_weighs_only_what_went_in() -> void:
	var heavy: PackItemType = CoreFixtures.item_type("X")
	heavy.weight = 2.5
	var manifest: Array[Batch] = [CoreFixtures.batch(heavy, 2)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest)
	session.pick_from_stack(0)
	_push_deepest(session, 1)
	assert_almost_eq(session.commit_record().loaded_weight(), 2.5)


func _session(shapes: Array[String]) -> PackingSession:
	var manifest: Array[Batch] = []
	for shape_text: String in shapes:
		manifest.append(CoreFixtures.batch(CoreFixtures.item_type(shape_text), 1))
	return CoreFixtures.session(ROWS, manifest)


# Slides the held piece in at a row as far as it will go.
func _push_deepest(session: PackingSession, row: int) -> void:
	var lane: EntryLane = _lane_at_row(session, row)
	assert_true(session.push_in(lane, lane.stops.size() - 1), "pushed in at row %d" % row)


func _lane_at_row(session: PackingSession, row: int) -> EntryLane:
	for lane: EntryLane in session.entry_lanes():
		if lane.row == row:
			return lane
	fail("no lane at row %d" % row)
	return null
