## One readout in the STATS row: a stat's name over its value. A stat that
## is not live yet shows a dash. It works nothing out; whoever owns the
## number gives it the text to show.
class_name StatSlot
extends PanelContainer

# Where to look
#   Scene:      ui/packing/stat_slot.tscn, placed four times in ui/packing/packing_screen.tscn
#   Filled by:  ui/packing/top_strip.gd -> _show_weight()

const NOT_LIVE_TEXT: String = "-"

## The stat's name, as the player reads it.
@export var title: String = ""

@onready var _title_label: Label = %Title
@onready var _value_label: Label = %Value


# Shows the title and a dash.
func _ready() -> void:
	_title_label.text = title
	_value_label.text = NOT_LIVE_TEXT


## Shows a value. Called by TopStrip._show_weight.
func show_value(text: String) -> void:
	_value_label.text = text
