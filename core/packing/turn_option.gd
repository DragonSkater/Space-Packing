## The result of a quarter turn that fits: the item's new outline and where
## its top-left corner ends up. AccessSolver makes these; an option is only
## a record, and nothing has turned until PackingSession applies it.
class_name TurnOption
extends RefCounted

var shape: CellShape
var origin: Vector2i = Vector2i.ZERO
