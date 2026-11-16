# ui/packing

The packing screen: stack, gantry, hull, stats and checks.

- `packing_screen.tscn` and `.gd`: the screen. It starts a round and joins the parts below.
- `crane_controls.gd`: the control scheme, in cells: what a tap, a grab, a slide, a turn and a carry from the stack mean, and when the crane fetches the next piece. `slide_preview.gd`, `door_choice.gd` and `crane_refusals.gd` are its helpers.
- `move_words.gd`: the words for each action and its cost, shared by the moves note, the note under a sliding piece and the cost list.
- `loading_bay.gd`: reads gestures on the middle of the screen and tells the controls what was touched.
- `stack_view.gd`, `gantry_view.gd`, `item_layer.gd`: draw the stack, the gantry and the pieces.
- `top_strip.gd`, `stat_slot.tscn`: the scenario name, the moves left and the STATS row.
- `round_summary.tscn`: the plain panel after Done, which also says which launch the load was kept as. The launch screen replaces it in milestone 5.

Owner: agents (code). The designer owns the theme and every texture it shows.
