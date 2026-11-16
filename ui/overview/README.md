# ui/overview

The overview screen, which is also the contract screen: map, contracts and fleet.

- `overview_screen.tscn` and `.gd`: the screen. The map on top, the launched ships under it, the upcoming launches at the bottom in thumb reach. How to pack opens over it from the ! button beside the title.
- `space_map_view.gd`: draws the map from `data/maps/`, with each launched ship parked round the body it went to.
- `launched_row.tscn`: one launched ship, with a picture of its hull exactly as packed (`ui/common/fixed_cargo_view.gd`).
- `ship_picker.gd`: the panel, part of `overview_screen.tscn`, that opens when a launch leaves the ship to the player. It lists every ship with a hull and flags a stack that is bigger or smaller than the hull.
- `ship_row.tscn`: one ship in the picker, with a picture of its empty hull.
- `upcoming_row.tscn`: one upcoming launch from `data/launches/`. These are placeholders until the contracts of milestone 6.

Owner: agents (code). The designer owns the theme and every texture it shows.
