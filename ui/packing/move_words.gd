## The words the packing screen uses for each crane action, so the moves
## label, the note under a sliding piece and the list of costs all call an
## action by the same name. It turns costs into text and decides no cost;
## the costs come from PackingSession, which reads packing_tuning.tres.
class_name MoveWords
extends RefCounted

# Where to look
#   Used by:    ui/packing/top_strip.gd -> _on_moves_spent(), _show_costs()
#               ui/packing/item_layer.gd -> _draw_cost_note()
#   Costs from: core/packing/packing_session.gd -> cost_of()
#   Tests:      tests/ui/test_move_words.gd

# The order the costs are listed in on screen.
const LISTED: Array[StringName] = [
	PackingSession.ACTION_PUSH_IN,
	PackingSession.ACTION_SHIFT,
	PackingSession.ACTION_TURN,
	PackingSession.ACTION_HELD_TURN,
	PackingSession.ACTION_UNLOAD,
]
const NAMES: Dictionary[StringName, String] = {
	PackingSession.ACTION_PUSH_IN: "Load",
	PackingSession.ACTION_SHIFT: "Slide",
	PackingSession.ACTION_TURN: "Turn",
	PackingSession.ACTION_HELD_TURN: "Turn on crane",
	PackingSession.ACTION_UNLOAD: "Unload",
}
const UNKNOWN_NAME: String = "Move"
const SPENT_TEXT: String = "%s  -%d"
const LIST_ENTRY_TEXT: String = "%s %d"
const LIST_SEPARATOR: String = "  ·  "
const FREE_LINE: String = "Free: taking, putting back, choosing a door, turning a crate"
const LET_GO_TEXT: String = "Let go: %s, %s"
const LET_GO_FREE_TEXT: String = "Let go: no move"
const ONE_MOVE_TEXT: String = "1 move"
const MOVES_TEXT: String = "%d moves"
const FREE_TEXT: String = "free"


## The player's word for an action.
static func name_of(action: StringName) -> String:
	return NAMES.get(action, UNKNOWN_NAME)


## The note shown when moves are spent, such as "Load  -1".
static func spent(action: StringName, cost: int) -> String:
	return SPENT_TEXT % [name_of(action), cost]


## "1 move", "2 moves", or "free".
static func count(cost: int) -> String:
	if cost == 0:
		return FREE_TEXT
	if cost == 1:
		return ONE_MOVE_TEXT
	return MOVES_TEXT % cost


## What letting go of a sliding piece would cost, such as "Let go: Load, 1 move".
static func let_go(action: StringName, cost: int) -> String:
	if action == CraneControls.NO_ACTION:
		return LET_GO_FREE_TEXT
	return LET_GO_TEXT % [name_of(action), count(cost)]


## One line listing what each action costs in this session, as it is now.
static func cost_list(session: PackingSession) -> String:
	var entries: PackedStringArray = []
	for action: StringName in LISTED:
		entries.append(LIST_ENTRY_TEXT % [name_of(action), session.cost_of(action)])
	return LIST_SEPARATOR.join(entries)
