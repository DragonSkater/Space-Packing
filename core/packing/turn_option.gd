## The result of a quarter turn that fits: the item's new outline and where
## its top-left corner ends up. AccessSolver makes these; an option is only
## a record, and nothing has turned until PackingSession applies it.
class_name TurnOption
extends RefCounted

# Where to look
#   Made by:    core/packing/access_solver.gd -> turn_option()
#   Used by:    core/packing/packing_session.gd -> turn()
#   Tests:      tests/core/test_access_solver.gd

var shape: CellShape
var origin: Vector2i = Vector2i.ZERO
