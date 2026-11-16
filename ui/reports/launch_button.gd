## The launch button of the routing mockup: a circle with an L in it. It is
## an ordinary button drawn round; pressing it commits the launch, and it is
## never disabled (PLAN.md section 3.5). What a press does is decided by
## whoever listens to its pressed signal.
class_name LaunchButton
extends Button

# Where to look
#   Scene:      ui/reports/launch_screen.tscn
#   Pressed:    ui/reports/launch_screen.gd -> _ready(), which passes it on as launch_pressed
#   Numbers:    ui/common/presentation_tuning.gd, the Launch screen group
#   Tests:      tests/ui/test_launch_screen.gd

const LETTER: String = "L"
# The L's height as a share of the button's diameter.
const LETTER_SHARE: float = 0.5


## Sizes the button from presentation.tres. Called by LaunchScreen.show_load.
func apply_tuning(tuning: PresentationTuning) -> void:
	custom_minimum_size = Vector2.ONE * tuning.launch_button_size
	queue_redraw()


# A filled circle with a rim and the L, darker while held down.
func _draw() -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	var diameter: float = minf(size.x, size.y)
	var centre: Vector2 = size / 2.0
	var face: Color = tuning.launch_button_colour
	if get_draw_mode() == DRAW_PRESSED:
		face = face.darkened(tuning.piece_border_darkening)
	draw_circle(centre, diameter / 2.0, face)
	draw_circle(centre, diameter / 2.0, tuning.launch_button_letter_colour, false, tuning.outline_width)
	var square: Rect2 = Rect2(centre - Vector2.ONE * diameter / 2.0, Vector2.ONE * diameter)
	LabelPainter.draw_centred(self, square, LETTER, int(diameter * LETTER_SHARE), tuning.launch_button_letter_colour)
