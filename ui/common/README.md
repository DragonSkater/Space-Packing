# ui/common

Widgets shared by several screens.

- `presentation_tuning.gd`: the sizes, colours, timings and touch distances screens use. Its values are in `data/tuning/presentation.tres`.
- `gesture_reader.gd`: turns touches inside a control into taps, drags and swipes.
- `grid_view.gd`: draws a container's grid and converts between positions and cells.
- `item_painter.gd`, `label_painter.gd`: draw a piece, and the letters on placeholders.
- `fixed_cargo_view.gd`: a grid with a committed load drawn in it, read-only. Used on the launch screen and as the overview's thumbnails.

Owner: agents (code).
