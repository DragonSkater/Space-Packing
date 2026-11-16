## Tests for the launches GameState keeps: each committed load is kept in
## order, with its number, round name and the scheduled launch it flew; the
## list handed out cannot change what is kept; and a scheduled launch opens
## only when the one before it was flown with nothing required left behind.
## A fresh GameState is made for each test, so the running game's own list
## is left alone.
extends TestCase

const GAME_STATE_PATH: String = "res://game/app/game_state.gd"
const ROWS: Array[String] = ["#####", "D...#", "#####"]


func test_launches_are_kept_in_order_and_numbered_from_one() -> void:
	var state: Node = _fresh_game_state()
	var first: LaunchRecord = state.record_launch("First round", _committed_record())
	var second: LaunchRecord = state.record_launch("Second round", _committed_record())
	var kept: Array[LaunchRecord] = state.launches()
	assert_eq(kept.size(), 2)
	assert_true(kept[0] == first and kept[1] == second, "oldest first")
	assert_eq(first.number, 1)
	assert_eq(second.number, 2)
	assert_eq(second.round_name, "Second round")
	assert_eq(first.committed_load.loaded.size(), 1, "the load is kept with it")
	state.free()


func test_the_list_handed_out_is_a_copy() -> void:
	var state: Node = _fresh_game_state()
	state.record_launch("A round", _committed_record())
	var handed_out: Array[LaunchRecord] = state.launches()
	handed_out.clear()
	assert_eq(state.launches().size(), 1)
	state.free()


func test_each_launch_is_announced() -> void:
	var state: Node = _fresh_game_state()
	var heard: Array[LaunchRecord] = []
	state.launch_recorded.connect(heard.append)
	var record: LaunchRecord = state.record_launch("A round", _committed_record())
	assert_eq(heard.size(), 1)
	assert_true(heard[0] == record)
	state.free()


func test_clearing_forgets_every_launch_and_numbering_starts_again() -> void:
	var state: Node = _fresh_game_state()
	state.record_launch("A round", _committed_record())
	state.clear_launches()
	assert_eq(state.launches().size(), 0)
	assert_eq(state.record_launch("Another", _committed_record()).number, 1)
	state.free()


func test_a_scheduled_launch_with_nothing_required_first_is_open() -> void:
	var state: Node = _fresh_game_state()
	var first: ScheduledLaunch = ScheduledLaunch.new()
	assert_true(state.is_open(first))
	assert_eq(state.times_flown(first), 0)
	state.free()


func test_the_next_launch_opens_once_the_one_before_is_fulfilled() -> void:
	var state: Node = _fresh_game_state()
	var first: ScheduledLaunch = ScheduledLaunch.new()
	var second: ScheduledLaunch = ScheduledLaunch.new()
	second.requires = first
	assert_true(not state.is_open(second), "waiting for the first")
	var record: LaunchRecord = state.record_launch("First", _committed_record(), first)
	assert_true(record.scheduled == first, "the record knows what it flew")
	assert_true(state.is_fulfilled(first))
	assert_true(state.is_open(second))
	state.free()


func test_a_launch_that_left_required_cargo_behind_flies_but_opens_nothing() -> void:
	var state: Node = _fresh_game_state()
	var first: ScheduledLaunch = ScheduledLaunch.new()
	var second: ScheduledLaunch = ScheduledLaunch.new()
	second.requires = first
	var record: LaunchRecord = state.record_launch("First", _record_left_on_stack(), first)
	assert_true(record.missed_requirements())
	assert_eq(state.times_flown(first), 1, "it still flew (D42)")
	assert_true(not state.is_fulfilled(first))
	assert_true(not state.is_open(second), "the level does not advance")
	state.record_launch("First again", _committed_record(), first)
	assert_eq(state.times_flown(first), 2, "a launch can be flown again (D36)")
	assert_true(state.is_open(second))
	state.free()


func _fresh_game_state() -> Node:
	var script: GDScript = load(GAME_STATE_PATH) as GDScript
	return script.new() as Node


# A round with one item loaded, committed.
func _committed_record() -> CommitRecord:
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("X"), 1)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest)
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 0)
	session.commit()
	return session.commit_record()


# A round committed with its one required item still on the stack.
func _record_left_on_stack() -> CommitRecord:
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("X"), 1)]
	var session: PackingSession = CoreFixtures.session(ROWS, manifest)
	session.commit()
	return session.commit_record()
