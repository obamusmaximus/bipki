class_name BuildingCatalog
extends RefCounted
## The Kenney City Kit (Commercial) buildings usable as towers, with cached model bounds.
## Low-detail models and the detail props (awnings, parasols) are left out on purpose.

## Both Kenney kits share one grid: one model unit (one road tile) is 10 m.
const METRES_PER_UNIT: float = 10.0
const DIR: String = "res://IMPORTS/kenney_city-kit-commercial_2.1/Models/GLB format/"
const NAMES: PackedStringArray = [
	"building-a", "building-b", "building-c", "building-d", "building-e", "building-f",
	"building-g", "building-h", "building-i", "building-j", "building-k", "building-l",
	"building-m", "building-n", "building-skyscraper-a", "building-skyscraper-b",
	"building-skyscraper-c", "building-skyscraper-d", "building-skyscraper-e",
]

static var _bounds: Dictionary = {}


static func count() -> int:
	return NAMES.size()


static func instantiate(index: int) -> Node3D:
	return (load(DIR + NAMES[index] + ".glb") as PackedScene).instantiate() as Node3D


## The meshes of model `index`, in model space (base at y = 0).
static func parts(index: int) -> Array[MeshPart]:
	return MeshPart.from_scene(DIR + NAMES[index] + ".glb")


## Model-space bounds (unscaled, base at y = 0), cached after the first call.
static func bounds(index: int) -> AABB:
	if not _bounds.has(index):
		_bounds[index] = MeshPart.bounds(parts(index))
	return _bounds[index]


## Uniform scale that gets close to `height` while keeping the footprint within `max_footprint`.
static func fit_scale(index: int, height: float, max_footprint: float) -> float:
	var box: AABB = bounds(index)
	return minf(height / box.size.y, max_footprint / maxf(box.size.x, box.size.z))


## Picks a model whose fitted height is at least 80% of `height`; `seed_value` makes the pick
## deterministic. Falls back to the tallest achievable model.
static func pick(height: float, max_footprint: float, seed_value: int) -> int:
	var fits: Array[int] = []
	var best: int = 0
	var best_height: float = 0.0
	for i: int in count():
		var achieved: float = fit_scale(i, height, max_footprint) * bounds(i).size.y
		if achieved >= height * 0.8:
			fits.append(i)
		if achieved > best_height:
			best_height = achieved
			best = i
	if fits.is_empty():
		return best
	return fits[absi(seed_value) % fits.size()]
