# ui/reports

The launch screen: the packed ship, the checks and the bill.

- `launch_screen.tscn` and `.gd`: FIXED CARGO, CHECKS, TIME, APPROVAL (a placeholder until the bill of milestone 5), the star chart and the launch button, plus Back to packing.
- `star_chart.gd`: decoration only (D37). Assign `star_chart_texture` in `data/tuning/presentation.tres` to replace the drawn placeholder.
- `launch_button.gd`: the round button with an L. It is never disabled.

Owner: agents (code). The designer owns the theme and every texture it shows.
