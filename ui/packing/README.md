# ui/packing

The packing screen: stack, gantry, hull, stats and checks.

- `packing_screen.tscn` and `.gd`: the screen. It starts a round and joins the parts below.
- `crane_controls.gd`: the control scheme, in cells: what a tap, a grab, a slide, a turn and a carry from the stack mean, and when the crane fetches the next piece. `slide_preview.gd`, `door_choice.gd` and `crane_refusals.gd` are its helpers.
- `move_words.gd`: the words for each action and its cost, shared by the moves note, the note under a sliding piece and the cost list.
- `loading_bay.gd`: reads gestures on the middle of the screen and tells the controls what was touched.
- `stack_view.gd`, `gantry_view.gd`, `item_layer.gd`: draw the stack, the gantry and the pieces. `crane_grip_view.gd` draws, above the pieces, the crane holding the held piece, whether or not a door will take it.
- `top_strip.gd`, `stat_slot.tscn`: the scenario name, the moves left and the STATS row.
- After Done the screen hands the committed load to whoever opened it; `ui/reports/launch_screen.tscn` shows it. The Overview button leaves the round without launching.

Owner: agents (code). The designer owns the theme and every texture it shows.
