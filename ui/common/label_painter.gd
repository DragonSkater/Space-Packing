## Draws a short piece of text centred in a rectangle, in the font of the
## control's theme. Placeholder spots and pieces are labelled with it until
## art replaces them. Text too small to read is left out. It lays nothing
## out and wraps nothing.
class_name LabelPainter
extends RefCounted

# Where to look
#   Used by:    ui/common/grid_view.gd -> _draw_entry()
#               ui/common/item_painter.gd -> draw_item()
#               ui/packing/stack_view.gd -> _draw_hidden_count()
#   Numbers:    ui/common/presentation_tuning.gd, label_scale and label_min_size


## The size of a placeholder's letters in a spot of this size, or 0 when
## they would be too small to read.
static func size_for_spot(spot: float, tuning: PresentationTuning) -> int:
	var font_size: int = int(spot * tuning.label_scale)
	if font_size < tuning.label_min_size:
		return 0
	return font_size


## Draws the text in the middle of the rectangle. A size of 0 draws nothing.
static func draw_centred(canvas: Control, rect: Rect2, text: String, font_size: int, colour: Color) -> void:
	if text.is_empty() or font_size <= 0:
		return
	var font: Font = canvas.get_theme_default_font()
	var ascent: float = font.get_ascent(font_size)
	var descent: float = font.get_descent(font_size)
	var baseline: float = rect.position.y + (rect.size.y + ascent - descent) / 2.0
	var start: Vector2 = Vector2(rect.position.x, baseline)
	canvas.draw_string(font, start, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, colour)
