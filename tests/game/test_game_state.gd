## Tests for the launches GameState keeps: each committed load is kept in
## order, with its number and round name, and the list handed out cannot
## change what is kept. A fresh GameState is made for each test, so the
## running game's own list is left alone.
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
