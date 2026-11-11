class_name CityLayout
extends RefCounted
## Turns `CitySettings` into a `CityPlan`: the street grid, then one building site per lot.
## Pure data with no nodes, so it runs headless and gives the same city for the same seed.

const MIN_LOT: float = 16.0  ## Lot size at density 0, metres.
const MAX_LOT: float = 32.0  ## Lot size at density 1, metres.
const SETBACK: float = 1.0  ## Gap between a building and its lot edge, metres.
const MIN_STRETCH: float = 0.5  ## Least a model's height may be stretched to reach its target.
const MAX_STRETCH: float = 1.6  ## Most a model's height may be stretched.
const CANDIDATES: int = 3  ## A site picks at random among this many best-scoring options.


static func build(settings: CitySettings) -> CityPlan:
	var plan := CityPlan.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = settings.seed_value
	var lot: float = lerpf(MIN_LOT, MAX_LOT, settings.density)
	plan.pitch = lot * settings.lots_per_block + BuildingCatalog.METRES_PER_UNIT
	var reach: int = maxi(1, roundi(settings.extent * 0.5 / plan.pitch))
	for k: int in range(-reach, reach + 1):
		plan.street_coords.append(k * plan.pitch)

	# Each block sits between two streets, inset by half a road tile on every side.
	var inset: float = BuildingCatalog.METRES_PER_UNIT * 0.5
	for i: int in range(-reach, reach):
		for j: int in range(-reach, reach):
			var block_corner := Vector2(i * plan.pitch + inset, j * plan.pitch + inset)
			for a: int in settings.lots_per_block:
				for b: int in settings.lots_per_block:
					if rng.randf() < settings.empty_lot_chance:
						continue
					var centre: Vector2 = block_corner + Vector2((a + 0.5) * lot, (b + 0.5) * lot)
					_add_site(plan, rng, settings, centre, lot)
	return plan


static func _add_site(plan: CityPlan, rng: RandomNumberGenerator, settings: CitySettings, centre: Vector2, lot: float) -> void:
	var target: float = _target_height(settings, rng, centre)
	var options: Array[Vector4] = _options(target, lot, settings.density)
	if options.is_empty():
		return
	options.sort_custom(func(x: Vector4, y: Vector4) -> bool: return x.w < y.w)
	var pick: Vector4 = options[rng.randi_range(0, mini(CANDIDATES, options.size()) - 1)]

	var site := CityPlan.Site.new()
	site.position = Vector3(centre.x, 0.0, centre.y)
	site.model = int(pick.x)
	site.quarter_turns = int(pick.y)
	site.height_scale = pick.z
	plan.sites.append(site)


## Every (model, quarter turns) that fits the lot, with its height stretch and a score (lower is
## better). Vector4 = (model, turns, stretch, score).
static func _options(target: float, lot: float, density: float) -> Array[Vector4]:
	var found: Array[Vector4] = []
	var avail: float = lot - 2.0 * SETBACK
	var want_share: float = lerpf(0.45, 0.9, density)
	for model: int in BuildingCatalog.count():
		var box: AABB = BuildingCatalog.bounds(model)
		var footprint := Vector2(box.size.x, box.size.z) * BuildingCatalog.METRES_PER_UNIT
		var native_height: float = box.size.y * BuildingCatalog.METRES_PER_UNIT
		var stretch: float = clampf(target / native_height, MIN_STRETCH, MAX_STRETCH)
		var height_error: float = absf(log(stretch * native_height / target))
		for turns: int in 4:
			var fp: Vector2 = footprint if turns % 2 == 0 else Vector2(footprint.y, footprint.x)
			if fp.x > avail or fp.y > avail:
				continue
			var share_error: float = absf(maxf(fp.x, fp.y) / lot - want_share)
			found.append(Vector4(model, turns, stretch, height_error + 2.0 * share_error))
	return found


## Taller towards the centre. A landmark roll gives the maximum height.
static func _target_height(settings: CitySettings, rng: RandomNumberGenerator, centre: Vector2) -> float:
	if rng.randf() < settings.landmark_chance:
		return settings.max_height
	var nearness: float = 1.0 - clampf(centre.length() / (settings.extent * 0.5), 0.0, 1.0)
	var roll: float = pow(rng.randf(), 1.5) * lerpf(0.3, 1.0, nearness)
	return lerpf(settings.min_height, settings.max_height, roll)
