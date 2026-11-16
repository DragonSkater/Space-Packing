## The strip at the top of the packing screen: the scenario's name, the
## moves left as a large number, a note each time moves are spent saying
## what they paid for, a line listing what each action costs, and the four
## stat slots. Only Weight is live until milestone 4; it is the sum of the
## weights of the loaded pieces. It shows what the round reports and changes nothing.
class_name TopStrip
extends VBoxContainer

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named TopStrip
#   Shown by:   ui/packing/packing_screen.gd -> _start_round()
#   Reads:      core/packing/packing_session.gd -> moves_left(), cost_of()
#               core/packing/pack_state.gd -> total_weight()
#   Slots:      ui/packing/stat_slot.gd -> show_value()
#   Words:      ui/packing/move_words.gd -> spent(), cost_list()
#   Numbers:    ui/common/presentation_tuning.gd, the Animation and Moves feedback groups

const WHOLE_NUMBER_TEXT: String = "%d"
const DECIMAL_TEXT: String = "%.1f"

var _session: PackingSession
var _tuning: PresentationTuning
var _flash: Tween
var _note_tween: Tween

@onready var _name_label: Label = %ScenarioName
@onready var _moves_number: Label = %MovesNumber
@onready var _moves_row: HBoxContainer = %MovesRow
@onready var _moves_caption: Label = %MovesCaption
@onready var _spent_note: Label = %SpentNote
@onready var _costs_line: Label = %CostsLine
@onready var _weight: StatSlot = %Weight


## Shows a new round. Called by PackingScreen._start_round.
func show_round(display_name: String, session: PackingSession, tuning: PresentationTuning) -> void:
	_session = session
	_tuning = tuning
	_name_label.text = display_name
	_session.moves_changed.connect(_on_moves_changed)
	_session.moves_spent.connect(_on_moves_spent)
	_session.state().changed.connect(_show_weight)
	_on_moves_changed(_session.moves_left())
	_spent_note.modulate = Color.TRANSPARENT
	_show_costs()
	_show_weight()


## Flashes the moves number: something was tried that the moves left could
## not pay for.
func flash_moves() -> void:
	if _flash != null:
		_flash.kill()
	_moves_number.modulate = Color.WHITE
	_flash = create_tween()
	var half: float = _tuning.moves_flash_duration / 2.0
	for _count: int in _tuning.moves_flash_count:
		_flash.tween_property(_moves_number, "modulate", _tuning.attention_colour, half)
		_flash.tween_property(_moves_number, "modulate", Color.WHITE, half)


# Shows the moves left whenever the session reports a change.
func _on_moves_changed(moves_left: int) -> void:
	_moves_number.text = WHOLE_NUMBER_TEXT % moves_left


# Says what the moves just spent paid for, beside the moves number, rising
# as it fades.
func _on_moves_spent(action: StringName, cost: int) -> void:
	_spent_note.text = MoveWords.spent(action, cost)
	_spent_note.reset_size()
	var gap: float = float(_moves_row.get_theme_constant("separation"))
	var start: Vector2 = Vector2(_moves_caption.size.x + gap, 0.0)
	_spent_note.position = start
	_spent_note.modulate = _tuning.attention_colour
	if _note_tween != null:
		_note_tween.kill()
	_note_tween = create_tween().set_parallel()
	var fade_to: Color = _tuning.attention_colour
	fade_to.a = 0.0
	_note_tween.tween_property(_spent_note, "position", start - Vector2(0.0, _tuning.spent_note_rise), _tuning.spent_note_duration)
	_note_tween.tween_property(_spent_note, "modulate", fade_to, _tuning.spent_note_duration)


# Lists what each action costs, and what is free.
func _show_costs() -> void:
	_costs_line.text = "%s
%s" % [MoveWords.cost_list(_session), MoveWords.FREE_LINE]


# Shows the Weight stat: the sum of the loaded pieces' weights.
func _show_weight() -> void:
	var weight: float = _session.state().total_weight()
	if is_equal_approx(weight, roundf(weight)):
		_weight.show_value(WHOLE_NUMBER_TEXT % roundi(weight))
	else:
		_weight.show_value(DECIMAL_TEXT % weight)
