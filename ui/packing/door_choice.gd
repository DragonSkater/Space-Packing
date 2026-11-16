## Chooses which door a held piece waits outside: the one nearest a given
## point (MILESTONES.md milestone 2, item 8, "the nearest door that offers a
## lane"). Points are in cells, so no screen is needed. It only chooses
## among the lanes it is given; AccessSolver decides which lanes exist.
class_name DoorChoice
extends RefCounted

# Where to look
#   Used by:    ui/packing/crane_controls.gd -> fetch(), tap_stack(), turn()
#   Lanes from: core/packing/packing_session.gd -> entry_lanes()
#   Tests:      tests/ui/test_crane_controls.gd


## The lane whose waiting place is nearest the point, or null when there
## are no lanes.
static func nearest(lanes: Array[EntryLane], item: PackItem, point: Vector2) -> EntryLane:
	var chosen: EntryLane = null
	var chosen_distance: float = INF
	for lane: EntryLane in lanes:
		var distance: float = hold_centre(lane, item).distance_to(point)
		if distance < chosen_distance:
			chosen = lane
			chosen_distance = distance
	return chosen


## The middle of a piece as it waits outside a lane's door, in cells.
static func hold_centre(lane: EntryLane, item: PackItem) -> Vector2:
	return Vector2(lane.hold_origin) + Vector2(item.shape.bounds().size) / 2.0
