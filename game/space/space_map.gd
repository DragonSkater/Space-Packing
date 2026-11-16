## The map of space as a graph: bodies, and the links between them with
## their distances (PLAN.md section 3.9). It names which body is home, where
## every launch starts. Finding the shortest route and timing a trip arrive
## with milestone 6; so far the map is only drawn.
class_name SpaceMap
extends Resource

# Where to look
#   Files:      data/maps/
#   Loaded by:  game/app/catalog.gd -> space_maps()
#   Drawn by:   ui/overview/space_map_view.gd -> show_map()
#   Tests:      tests/game/test_space_map.gd

@export var display_name: String
## Where every launch starts. It must also be in the list of bodies.
@export var home: Body
@export var bodies: Array[Body] = []
@export var links: Array[SpaceLink] = []


## Sentences for each mistake that would make the map unreadable: no home,
## or a link to a body that is not on the map. Empty when it is sound.
func problems() -> Array[String]:
	var found: Array[String] = []
	if home == null or not bodies.has(home):
		found.append("The map has no home body, or its home is not in its list of bodies.")
	for index: int in links.size():
		var link: SpaceLink = links[index]
		if link == null or not bodies.has(link.from_body) or not bodies.has(link.to_body):
			found.append("Link %d joins a body that is not on the map." % (index + 1))
	return found
