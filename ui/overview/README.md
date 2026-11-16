# ui/overview

The overview screen, which is also the contract screen: map, contracts and fleet.

- `overview_screen.tscn` and `.gd`: the screen. The map on top, the launched ships under it, the upcoming launches at the bottom in thumb reach.
- `space_map_view.gd`: draws the map from `data/maps/`, with each launched ship parked round the body it went to.
- `launched_row.tscn`: one launched ship, with a picture of its hull exactly as packed (`ui/common/fixed_cargo_view.gd`).
- `upcoming_row.tscn`: one upcoming launch from `data/launches/`. These are placeholders until the contracts of milestone 6.

Owner: agents (code). The designer owns the theme and every texture it shows.
