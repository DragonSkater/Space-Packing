## Works out what to light when a slide cannot start: the pieces in the
## way, or, when a wall is in the way, the wall cells the piece could not
## pass. CraneControls asks and then announces it; this helper changes
## nothing and announces nothing.
class_name CraneRefusals
extends RefCounted

# Where to look
#   Used by:    ui/packing/crane_controls.gd -> begin_slide(), _on_action_refused()
#   Asks:       core/packing/packing_session.gd -> blockers()
#   Tests:      tests/ui/test_crane_controls.gd


## The pieces in the way of a loaded piece's slide to one side. A held piece
## outside the container has nothing in its way, only nowhere to go.
static func items_in_the_way(session: PackingSession, item: PackItem, direction: Vector2i) -> Array[int]:
	if item == session.held():
		return []
	return session.blockers(item.id, direction)


## The wall cells a loaded piece would run into one step to that side, when
## no piece is what stops it.
static func walls_in_the_way(session: PackingSession, item: PackItem, direction: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if item == session.held() or not items_in_the_way(session, item, direction).is_empty():
		return cells
	for cell: Vector2i in item.shape.cells_at(item.origin + direction):
		if not session.state().layout.is_passable(cell):
			cells.append(cell)
	return cells


## The ids to light when the session refused an action on the active piece:
## everything it named except that piece itself.
static func others(item_ids: Array[int], active: PackItem) -> Array[int]:
	var lit: Array[int] = item_ids.duplicate()
	if active != null:
		lit.erase(active.id)
	return lit
