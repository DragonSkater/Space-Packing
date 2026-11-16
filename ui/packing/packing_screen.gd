## The packing screen: it starts a round of one scenario and joins its
## parts together, the top strip, the loading bay and the buttons. It never
## changes the round itself: Done calls PackingSession.commit(), Restart
## starts a fresh session, and everything else goes through CraneControls.
## Which scenario comes next is for whoever opened this screen to decide.
class_name PackingScreen
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn
#   Opened by:  ui/boot/boot.gd -> _open_scenario()
#   The round:  core/packing/packing_scenario.gd -> start()
#               core/packing/packing_session.gd -> commit(), commit_record()
#   Kept by:    ui/boot/boot.gd -> _on_round_committed(), which tells game/app/game_state.gd -> record_launch()
#   Its parts:  ui/packing/top_strip.gd, ui/packing/loading_bay.gd, ui/packing/round_summary.gd,
#               ui/packing/crane_controls.gd
#   Numbers:    game/app/tuning.gd; ui/common/presentation_tuning.gd, the Screen margins group
#   Tests:      tests/ui/test_packing_screen.gd

## The player asked, from the summary panel, for a different scenario.
signal next_scenario_requested
## The round was committed. The record is a copy of the container as it was
## left; whoever opened the screen decides whether it is kept.
signal round_committed(round_name: String, record: CommitRecord)

var _scenario: PackingScenario
var _session: PackingSession
var _controls: CraneControls
var _tuning: PresentationTuning

@onready var _margins: MarginContainer = %Margins
@onready var _top_strip: TopStrip = %TopStrip
@onready var _bay: LoadingBay = %Bay
@onready var _notice: Label = %Notice
@onready var _restart_button: Button = %RestartButton
@onready var _done_button: Button = %DoneButton
@onready var _summary: RoundSummary = %RoundSummary


# Applies the margins and touch sizes from presentation.tres and connects the buttons.
func _ready() -> void:
	_tuning = PresentationTuning.current()
	_margins.add_theme_constant_override("margin_top", roundi(_tuning.margin_top))
	_margins.add_theme_constant_override("margin_bottom", roundi(_tuning.margin_bottom))
	_margins.add_theme_constant_override("margin_left", roundi(_tuning.edge_guard))
	_margins.add_theme_constant_override("margin_right", roundi(_tuning.edge_guard))
	_restart_button.custom_minimum_size.y = _tuning.min_touch_target
	_done_button.custom_minimum_size.y = _tuning.min_touch_target
	_restart_button.pressed.connect(_start_round)
	_done_button.pressed.connect(_on_done_pressed)
	_summary.restart_pressed.connect(_start_round)
	_summary.next_scenario_pressed.connect(next_scenario_requested.emit)


## Starts a fresh round of this scenario.
func open_scenario(scenario: PackingScenario) -> void:
	_scenario = scenario
	for problem: String in scenario.problems():
		push_error("%s: %s" % [scenario.display_name, problem])
	_start_round()


# Starts a fresh session and hands it to every part. Also what Restart does.
func _start_round() -> void:
	if _scenario == null:
		return
	_summary.hide()
	_session = _scenario.start(Tuning.packing)
	_controls = CraneControls.new(_session)
	_session.moves_changed.connect(_on_moves_changed)
	_session.finished.connect(_on_finished)
	_controls.moves_missed.connect(_top_strip.flash_moves)
	_top_strip.show_round(_scenario.display_name, _session, _tuning)
	_bay.show_round(_session, _controls, _tuning)
	_on_moves_changed(_session.moves_left())


# PLAN.md section 3.5: finishing is never refused, whatever is on the stack.
func _on_done_pressed() -> void:
	_session.commit()


# The session was committed: hand the load on, then show the summary panel.
func _on_finished(_reason: StringName) -> void:
	var record: CommitRecord = _session.commit_record()
	round_committed.emit(_scenario.display_name, record)
	_summary.show_result(record, _kept_as(record), _tuning)


# The number of the launch this load was kept as, or 0 when nobody kept it.
func _kept_as(record: CommitRecord) -> int:
	var launches: Array[LaunchRecord] = GameState.launches()
	if not launches.is_empty() and launches.back().committed_load == record:
		return launches.back().number
	return 0


# When the moves run out the round does not end by itself (PLAN.md section
# 3.5): the crane stops, and the two ways on are pointed out.
func _on_moves_changed(moves_left: int) -> void:
	var stopped: bool = moves_left <= 0
	var tint: Color = Color.WHITE
	# The notice is faded out, not removed, so the layout does not jump.
	_notice.modulate = Color.TRANSPARENT
	if stopped:
		tint = _tuning.attention_colour
		_notice.modulate = tint
	_restart_button.modulate = tint
	_done_button.modulate = tint
