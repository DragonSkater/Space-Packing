## The table that says what each character in a layout text means. A legend
## is data: adding an entry adds a new kind of cell with no code. It does not
## parse layouts; ContainerLayout does that with a legend in hand.
class_name LayoutLegend
extends Resource

# Where to look
#   Entries:    core/grid/legend_entry.gd
#   Used by:    core/grid/container_layout.gd -> parse()
#   Tests:      tests/core/test_container_layout.gd

@export var entries: Array[LegendEntry] = []


## The entry for a character, or null when the legend does not list it.
func entry_for(symbol: String) -> LegendEntry:
	for entry: LegendEntry in entries:
		if entry.symbol == symbol:
			return entry
	return null
