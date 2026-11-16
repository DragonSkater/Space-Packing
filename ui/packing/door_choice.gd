## Chooses which door a held piece waits outside: the one nearest a given
## point (MILESTONES.md milestone 2, item 8, "the nearest door that offers a
## lane"). When no door offers one it still names a door to wait at, so the
## piece stays in view and can be turned. Points are in cells, so no screen
## is needed. AccessSolver, not this, decides which lanes exist.
class_name DoorChoice
extends RefCounted

# Where to look
#   Used by:    ui/packing/crane_controls.gd -> fetch(), tap_stack(), turn(), held_origin()
#   Lanes from: core/packing/packing_session.gd -> entry_lanes()
#   Doors from: ui/packing/gantry_view.gd -> entrance_doors()
#   Tests:      tests/ui/test_crane_controls.gd

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT]


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
	return centre_at(lane.hold_origin, item)


## The middle of a piece whose top-left corner is at this origin, in cells.
static func centre_at(origin: Vector2i, item: PackItem) -> Vector2:
	return Vector2(origin) + Vector2(item.shape.bounds().size) / 2.0


## Where a piece that no door will take waits: outside the door nearest the
## point, as it would wait for a lane there, kept within the container's
## rows. PLAN.md section 3.4: outside the container a turn always fits, so
## from here the player can turn it until a door will take it. With no
## doors on either side it waits at the point itself.
static func waiting_origin(layout: ContainerLayout, item: PackItem, point: Vector2) -> Vector2i:
	var bounds: Vector2i = item.shape.bounds().size
	var fallback: Vector2 = point - Vector2(bounds) / 2.0
	var chosen: Vector2i = Vector2i(roundi(fallback.x), roundi(fallback.y))
	var chosen_distance: float = INF
	var lowest_row: int = maxi(0, layout.size().y - bounds.y)
	for side: Vector2i in SIDES:
		for door: Vector2i in GantryView.entrance_doors(layout, side):
			var origin: Vector2i = Vector2i(-bounds.x, clampi(door.y, 0, lowest_row))
			if side == Vector2i.RIGHT:
				origin.x = layout.size().x
			var distance: float = centre_at(origin, item).distance_to(point)
			if distance < chosen_distance:
				chosen = origin
				chosen_distance = distance
	return chosen
