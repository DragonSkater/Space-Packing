## One place on the map: home, a planet, an asteroid, a satellite or the
## station (PLAN.md section 3.9). It is data: a name, how many launch pads
## it has, where it is drawn, and its art. Where it sits on the map is for
## drawing only; distances live on the links between bodies.
class_name Body
extends Resource

# Where to look
#   Files:      data/bodies/
#   Joined by:  game/space/space_link.gd, game/space/space_map.gd
#   Drawn by:   ui/overview/space_map_view.gd -> _draw_body()
#   Tests:      tests/game/test_space_map.gd

## A short name that never changes, used to tell bodies apart in code.
@export var id: StringName
## The name the player reads on the map.
@export var display_name: String
## What sort of body this is, for the player to read: "planet", "asteroid".
## Display only. No code may branch on it.
@export var kind: String
## How many launch pads it has. Pads are drawn round the body and numbered
## from 1. Only home's pads are used in the demo; launching from the
## station is deferred (PLAN.md section 1).
@export_range(0, 8) var pads: int = 0
## Where it is drawn, as a share of the map's width and height: (0, 0) is
## the top-left corner and (1, 1) the bottom-right. Visual only.
@export var map_position: Vector2 = Vector2(0.5, 0.5)
## The placeholder colour, used when there is no texture.
@export var colour: Color = Color(0.6, 0.65, 0.75)
## The body's picture. Empty draws a coloured, labelled circle.
@export var texture: Texture2D
@export_multiline var description: String
