## One slide in progress: the piece under the finger, every place along its
## row where it could be left, and where it is shown right now. Nothing has
## moved in the round until the finger lifts; CraneControls then tells the
## session where the piece was left. This is only a record with one sum in
## it, the snap to the nearest stop.
class_name SlidePreview
extends RefCounted

# Where to look
#   Made by:    ui/packing/crane_controls.gd -> begin_slide()
#   Drawn by:   ui/packing/item_layer.gd -> _targets()
#   Stops from: core/packing/entry_lane.gd, core/packing/shift_range.gd
#   Tests:      tests/ui/test_crane_controls.gd

var item: PackItem
## Where the piece was when the slide began. Being left here costs nothing.
var start: Vector2i = Vector2i.ZERO
## Every origin the piece may be left at, including the start.
var stops: Array[Vector2i] = []
## The stops that are outside a door, each with the side it leaves by. A
## loaded piece left on one of these is unloaded.
var exits: Dictionary[Vector2i, Vector2i] = {}
## The stop the piece would be left at if the finger lifted now.
var current: Vector2i = Vector2i.ZERO
## The column under the finger, held between the first and last stops, so
## the piece can be drawn following the finger between stops.
var finger_x: float = 0.0


# A slide starts with one stop: where the piece already is.
func _init(sliding_item: PackItem, start_origin: Vector2i) -> void:
	item = sliding_item
	start = start_origin
	current = start_origin
	finger_x = float(start_origin.x)
	stops.append(start_origin)


## A held piece about to go in through a door: it may be left at any stop of
## its lane. With no lane there is nowhere to go.
static func entering(held_item: PackItem, lane: EntryLane) -> SlidePreview:
	if lane == null:
		return SlidePreview.new(held_item, Vector2i.ZERO)
	var preview: SlidePreview = SlidePreview.new(held_item, lane.hold_origin)
	preview.stops.append_array(lane.stops)
	return preview


## A loaded piece sliding along its row: it may be left at any stop in its
## reach, or outside a door it can leave by.
static func shifting(loaded_item: PackItem, reach: ShiftRange, layout_width: int) -> SlidePreview:
	var preview: SlidePreview = SlidePreview.new(loaded_item, loaded_item.origin)
	preview.stops.append_array(reach.stops)
	for direction: Vector2i in reach.exits:
		# Where the piece is shown once it has slid clear of the container.
		var outside: Vector2i = Vector2i(layout_width, loaded_item.origin.y)
		if direction == Vector2i.LEFT:
			outside.x = -loaded_item.shape.bounds().size.x
		preview.stops.append(outside)
		preview.exits[outside] = direction
	return preview


## True when there is somewhere to go on that side of the start.
func has_stop_towards(direction: Vector2i) -> bool:
	for stop: Vector2i in stops:
		if signi(stop.x - start.x) == direction.x:
			return true
	return false


# The column of the stop furthest towards one side.
func _furthest(direction: Vector2i) -> int:
	var furthest: int = start.x
	for stop: Vector2i in stops:
		if (stop.x - furthest) * direction.x > 0:
			furthest = stop.x
	return furthest


## Moves the piece to the stop nearest the finger, given how far the finger
## is from where it began, in cells. Returns true when the piece moved.
func snap_to(cells_from_start: float) -> bool:
	var wanted: float = float(start.x) + cells_from_start
	finger_x = clampf(wanted, float(_furthest(Vector2i.LEFT)), float(_furthest(Vector2i.RIGHT)))
	var nearest: Vector2i = current
	var nearest_distance: float = absf(float(current.x) - wanted)
	for stop: Vector2i in stops:
		var distance: float = absf(float(stop.x) - wanted)
		if distance < nearest_distance:
			nearest = stop
			nearest_distance = distance
	if nearest == current:
		return false
	current = nearest
	return true
