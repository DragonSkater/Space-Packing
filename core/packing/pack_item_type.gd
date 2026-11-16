## A kind of item: its outline, its tags and its numbers. Rules match on the
## tags, which are plain names stored in data. A type describes; it is not
## one particular item on the stack or in the container. PackItem is that.
class_name PackItemType
extends Resource

# Where to look
#   Listed in:  core/packing/batch.gd
#   Its shape:  core/grid/cell_shape.gd -> from_text()
#   Tests:      tests/core/test_packing_session.gd

@export var id: StringName
@export var display_name: String = ""
## Rules match on these names. Free text; invent new ones at will.
@export var tags: Array[StringName] = []
## The outline as a drawing: X is a filled cell. Any connected shape.
@export_multiline var shape_text: String = "X"
## Off for an item that may not be turned.
@export var can_rotate: bool = true
## Per item.
@export var weight: float = 1.0
## Per item.
@export var base_value: float = 0.0
## The flat colour drawn when no texture is assigned.
@export var colour: Color = Color.SLATE_GRAY
## Stretched over the item's bounding box; drawn unturned.
@export var texture: Texture2D


## The outline as drawn in shape_text, before any turning.
func shape() -> CellShape:
	return CellShape.from_text(shape_text)


## Plain sentences for mistakes that make this type unusable.
func problems() -> Array[String]:
	var found: Array[String] = []
	var drawn: CellShape = shape()
	if drawn.cells.is_empty():
		found.append("The shape of %s is empty: its drawing has no X." % _name())
	elif not drawn.is_one_piece():
		found.append("The shape of %s is not one connected piece." % _name())
	return found


# The name used in problem sentences.
func _name() -> String:
	if display_name.is_empty():
		return String(id)
	return display_name
