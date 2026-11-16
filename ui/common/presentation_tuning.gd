## The sizes, colours, timings and touch distances that screens draw and
## read input with. Everything here changes how the game looks or feels;
## nothing here changes a rule or a score. The values live in
## data/tuning/presentation.tres and are read at the moment they are used.
class_name PresentationTuning
extends Resource

# Where to look
#   Values:     data/tuning/presentation.tres
#   Loaded by:  game/app/tuning.gd -> _ready()
#   Read by:    ui/common/grid_view.gd, ui/common/gesture_reader.gd, ui/common/item_painter.gd,
#               ui/common/label_painter.gd and every script in ui/packing/
#   The Crane group: ui/packing/loading_bay.gd -> _process(), ui/packing/item_layer.gd -> _process()
#   The Overview group: ui/overview/space_map_view.gd -> _draw()
#   The Launch screen group: ui/reports/star_chart.gd -> _draw(), ui/reports/launch_button.gd -> _draw()
#   Tests:      tests/game/test_catalog.gd

@export_group("Spots")
## The largest a spot of the grid is drawn, in screen units. A grid that
## does not fit at this size is drawn smaller.
@export_range(16.0, 96.0, 1.0) var spot_size: float = 40.0
## A grid that needs spots smaller than this is too cramped to play, and
## the game says so in the console.
@export_range(8.0, 64.0, 1.0) var spot_size_min: float = 24.0
## The gap between the edge of a piece and the edge of its spots.
@export_range(0.0, 8.0, 0.5) var piece_inset: float = 2.0
## The thickness of outlines: a piece's border, the selection, a lit door.
@export_range(1.0, 6.0, 0.5) var outline_width: float = 2.0
## The size of the letters on placeholder spots and pieces, as a share of
## the spot they are drawn in.
@export_range(0.1, 0.8, 0.01) var label_scale: float = 0.3
## Letters that would come out smaller than this are not drawn at all,
## as on the small pieces waiting in the stack.
@export_range(1, 24) var label_min_size: int = 8
## The radius of the grip pin, as a share of the spot.
@export_range(0.05, 0.5, 0.01) var grip_pin_scale: float = 0.18
## How strongly a designated spot's colour is laid over the spot beneath.
@export_range(0.0, 1.0, 0.05) var designation_opacity: float = 0.4

@export_group("Gantry")
## The width of the gantry's upright, in screen units.
@export_range(2.0, 24.0, 1.0) var gantry_width: float = 6.0
## The thickness of a crane arm.
@export_range(1.0, 12.0, 0.5) var arm_width: float = 3.0
## The length of the bar across the end of a crane arm, as a share of the
## spot.
@export_range(0.1, 1.0, 0.05) var arm_gripper_scale: float = 0.5

@export_group("Stack")
## The size of one spot of a piece waiting in the stack.
@export_range(8.0, 48.0, 1.0) var stack_spot_size: float = 22.0
## The gap between two pieces in the pile.
@export_range(0.0, 24.0, 1.0) var stack_gap: float = 4.0
## The extra gap under a piece that can be taken, which raises it clear of
## the pile.
@export_range(0.0, 48.0, 1.0) var stack_raise: float = 14.0
## How solid the pieces that cannot be taken yet are drawn.
@export_range(0.1, 1.0, 0.05) var stack_buried_opacity: float = 0.55

@export_group("Crane")
## When on, an empty crane fetches the top piece of the stack to the nearest
## door by itself, so the next piece is waiting while the player works in
## the container. Off (the designer's choice, 16 November 2026), every piece
## is taken by hand: tapped, or dragged from the stack onto a door.
@export var crane_auto_fetch: bool = false
## Seconds an empty crane waits before it fetches the next piece. In that
## time the player can tap the stack, or drag its top piece onto a door.
@export_range(0.0, 3.0, 0.05) var crane_fetch_delay: float = 0.6
## How fast the crane carries a piece, in spots per second: from the stack
## to its door, from door to door, and back to rest after the finger lets go.
@export_range(1.0, 40.0, 0.5) var crane_speed: float = 9.0
## How fast a piece follows the finger along its row, in spots per second.
## Lower makes a piece feel heavier and a quick flick carry it less far.
@export_range(1.0, 60.0, 0.5) var piece_follow_speed: float = 14.0
## How far the Active box stands off the edge of the active piece.
@export_range(0.0, 12.0, 0.5) var active_box_margin: float = 4.0

@export_group("Moves feedback")
## Seconds the note saying what moves were spent on stays up.
@export_range(0.1, 3.0, 0.05) var spent_note_duration: float = 1.1
## How far the note rises while it fades, in screen units.
@export_range(0.0, 60.0, 1.0) var spent_note_rise: float = 18.0
## The size of the note under a sliding piece that says what letting go
## would cost.
@export_range(6, 24) var cost_note_font_size: int = 11

@export_group("Screen margins")
## Kept clear at the top of the screen, for a phone's notch.
@export_range(0.0, 120.0, 1.0) var margin_top: float = 54.0
## Kept clear at the bottom of the screen, for a phone's home bar.
@export_range(0.0, 120.0, 1.0) var margin_bottom: float = 34.0
## Kept clear at the left and right edges, where a phone browser takes
## swipes for itself.
@export_range(0.0, 48.0, 1.0) var edge_guard: float = 12.0

@export_group("Touch")
## How far a finger may move and still count as a tap.
@export_range(0.0, 40.0, 1.0) var tap_max_travel: float = 10.0
## How far a finger must travel before a swipe's direction locks to
## left-right or up-down.
@export_range(4.0, 80.0, 1.0) var swipe_lock_distance: float = 16.0
## The smallest size of anything meant to be tapped.
@export_range(24.0, 88.0, 1.0) var min_touch_target: float = 44.0

@export_group("Colours")
## The thin line round every placeholder spot.
@export var grid_line_colour: Color = Color(0.0, 0.0, 0.0, 0.35)
## The letters on placeholder spots, and the count under the stack.
@export var cell_label_colour: Color = Color(1.0, 1.0, 1.0, 0.75)
## The name written on a placeholder piece.
@export var piece_label_colour: Color = Color(0.08, 0.09, 0.12)
## How much darker than its fill a piece's border is drawn.
@export_range(0.0, 1.0, 0.05) var piece_border_darkening: float = 0.4
## The outline of the selected or held piece.
@export var selection_colour: Color = Color(1.0, 1.0, 1.0)
## The pin on the spot a piece is gripped by.
@export var grip_colour: Color = Color(0.95, 0.2, 0.25)
## Laid over whatever is in the way of a refused slide.
@export var in_the_way_colour: Color = Color(1.0, 0.25, 0.2, 0.7)
## The gantry's uprights and its arms at rest.
@export var gantry_colour: Color = Color(0.42, 0.45, 0.52)
## A door, and its arm, that the held piece can go through.
@export var door_lit_colour: Color = Color(1.0, 0.85, 0.3)
## Laid over a door the held piece cannot use.
@export var door_dimmed_colour: Color = Color(0.0, 0.0, 0.0, 0.55)
## The box round the active piece: the one the next slide or turn acts on.
@export var active_colour: Color = Color(0.35, 0.85, 1.0)
## The note under a sliding piece when letting go would spend moves.
@export var costly_note_colour: Color = Color(1.0, 0.85, 0.3)
## The note under a sliding piece when letting go is free.
@export var free_note_colour: Color = Color(0.7, 0.75, 0.8)
## Flashed on the moves number, and worn by Done and Restart when the
## moves have run out.
@export var attention_colour: Color = Color(1.0, 0.45, 0.3)

@export_group("Animation")
## Seconds a refused piece shakes for.
@export_range(0.0, 1.0, 0.01) var shake_duration: float = 0.25
## How far a refused piece shakes to either side, in screen units.
@export_range(0.0, 16.0, 0.5) var shake_distance: float = 4.0
## How many times it goes back and forth.
@export_range(1, 8) var shake_count: int = 3
## Seconds whatever was in the way stays lit.
@export_range(0.0, 3.0, 0.05) var in_the_way_duration: float = 0.7
## Seconds for one flash of the moves number.
@export_range(0.02, 1.0, 0.01) var moves_flash_duration: float = 0.12
## How many times the moves number flashes.
@export_range(1, 8) var moves_flash_count: int = 2

@export_group("Overview")
## The radius of a body on the map, in screen units, when it has no texture.
@export_range(4.0, 48.0, 1.0) var map_body_radius: float = 16.0
## The radius of home, which is drawn larger so its pads fit round it.
@export_range(4.0, 64.0, 1.0) var map_home_radius: float = 26.0
## The size of one numbered launch pad drawn round a body.
@export_range(4.0, 24.0, 1.0) var map_pad_size: float = 11.0
## The size of a launched ship's marker on the map.
@export_range(4.0, 24.0, 1.0) var map_ship_size: float = 9.0
## The angle between two ships' markers parked round the same body, in degrees.
@export_range(10.0, 90.0, 1.0) var map_fleet_spacing_degrees: float = 32.0
## The size of the names and distances on the map.
@export_range(6, 24) var map_font_size: int = 11
## The length of one dash of a route, and of the gap after it.
@export_range(2.0, 16.0, 0.5) var map_dash_length: float = 5.0
## The thickness of a route.
@export_range(0.5, 4.0, 0.5) var map_link_width: float = 1.5
## Behind the map.
@export var map_backdrop_colour: Color = Color(0.07, 0.08, 0.12)
## The dashed routes between bodies.
@export var map_link_colour: Color = Color(0.6, 0.65, 0.75, 0.7)
## Names and distances on the map.
@export var map_label_colour: Color = Color(0.85, 0.88, 0.95)
## A launched ship's marker. A ship that left required cargo behind wears
## the attention colour instead.
@export var map_ship_colour: Color = Color(0.4, 0.95, 0.6)

@export_group("Launch screen")
## The picture in the star chart. It is decoration and shows no information
## (PLAN.md section 2, D37). Empty draws a placeholder fan of stars.
@export var star_chart_texture: Texture2D
## How wide the placeholder fan opens, in degrees.
@export_range(30.0, 180.0, 1.0) var star_chart_spread_degrees: float = 120.0
## How many stars the placeholder fan holds.
@export_range(0, 80) var star_chart_star_count: int = 22
## The radius of one star in the placeholder fan.
@export_range(0.5, 6.0, 0.5) var star_size: float = 2.0
## Picks where the placeholder's stars fall. Any number gives a fixed sky.
@export_range(0, 9999) var star_chart_seed: int = 7
## The fan's outline and the lines between its stars.
@export var star_chart_colour: Color = Color(0.55, 0.62, 0.8, 0.8)
## The stars.
@export var star_colour: Color = Color(0.95, 0.95, 1.0)
## The diameter of the round launch button.
@export_range(44.0, 160.0, 1.0) var launch_button_size: float = 76.0
## The launch button's face.
@export var launch_button_colour: Color = Color(0.85, 0.3, 0.25)
## The L on the launch button, and its rim.
@export var launch_button_letter_colour: Color = Color(1.0, 0.95, 0.9)


## The values the running game uses, from the Tuning autoload.
static func current() -> PresentationTuning:
	var loaded: PresentationTuning = Tuning.presentation as PresentationTuning
	if loaded == null:
		push_error("PresentationTuning: presentation.tres is missing; using the script's defaults.")
		return PresentationTuning.new()
	return loaded
