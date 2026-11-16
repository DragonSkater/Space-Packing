## A route between two bodies, with its distance typed in by hand in
## light-seconds (PLAN.md section 3.9, D14). It goes both ways. It does not
## work out travel time; that waits for TravelCalculator in milestone 6.
class_name SpaceLink
extends Resource

# Where to look
#   Held by:    game/space/space_map.gd
#   Drawn by:   ui/overview/space_map_view.gd -> _draw_link()
#   Tests:      tests/game/test_space_map.gd

@export var from_body: Body
@export var to_body: Body
## How far apart the two bodies are, in light-seconds.
@export_range(0.0, 1000.0, 0.1) var distance_ls: float = 1.0


## True when the link joins this body to another.
func touches(body: Body) -> bool:
	return from_body == body or to_body == body
