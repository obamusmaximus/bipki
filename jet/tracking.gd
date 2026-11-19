class_name Tracking
extends Node
## The jet's tracking (see docs/mechanics/jet.md): which enemies are tracked, for the weapons to aim at. The scanner, a
## pyramid in front of the view (ScannerShape), picks up an enemy that stays in it and in sight for
## `scanner_pickup_time`, up to `max_tracks`. A track lasts `track_time`, refreshed while the enemy is in the scanner.
## While the afterburner burns, scouting tracks every enemy in sight within `scout_range` in any direction at once, for
## `scout_track_time`. Game time throughout. Owned by JetLoadout, which calls `tick` at the start of each frame.

## The set of tracked enemies changed (picked up, run out, or gone).
signal tracks_changed(targets: Array[Enemy])

const SIGHT_MASK: int = 1 # World

var stats: TrackingStats

var _camera: Camera3D
var _motor: JetMotor
## Tracked enemy to the seconds its track has left.
var _tracks: Dictionary = {}
## Enemy in the scanner but not tracked yet, to the seconds it has been in it.
var _dwell: Dictionary = {}
var _active: bool = true


func setup(camera: Camera3D, motor: JetMotor, tracking_stats: TrackingStats) -> void:
	_camera = camera
	_motor = motor
	stats = tracking_stats


## The tracked enemies in the order they were picked up, oldest first (a refresh keeps an enemy's place).
func get_targets() -> Array[Enemy]:
	var targets: Array[Enemy] = []
	for enemy: Variant in _tracks:
		if is_instance_valid(enemy):
			targets.append(enemy as Enemy)
	return targets


## Seconds left on `enemy`'s track (0 if it isn't tracked).
func get_time_left(enemy: Enemy) -> float:
	return _tracks.get(enemy, 0.0)


func tick(delta: float) -> void:
	if not _active:
		return
	var changed: bool = _count_down(delta)
	var scouting: bool = _motor.is_afterburning()
	var in_scanner: Dictionary = {}
	var eye: Vector3 = _camera.global_position
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.health.is_dead():
			continue
		var center: Vector3 = enemy.get_center()
		var distance: float = eye.distance_to(center)
		var scanned: bool = distance <= stats.scanner_range and _in_scanner(center)
		var scouted: bool = scouting and distance <= stats.scout_range
		if not (scanned or scouted) or not _in_sight(center):
			continue
		if scouted:
			changed = changed or not _tracks.has(enemy)
			_tracks[enemy] = maxf(_tracks.get(enemy, 0.0), stats.scout_track_time)
		if not scanned:
			continue
		if _tracks.has(enemy):
			_tracks[enemy] = maxf(_tracks[enemy], stats.track_time)
			continue
		in_scanner[enemy] = true
		_dwell[enemy] = _dwell.get(enemy, 0.0) + delta
		if _dwell[enemy] >= stats.scanner_pickup_time and _tracks.size() < stats.max_tracks:
			_tracks[enemy] = stats.track_time
			changed = true
	# Leaving the scanner (or being tracked) starts the pickup over.
	for enemy: Variant in _dwell.keys():
		if not in_scanner.has(enemy):
			_dwell.erase(enemy)
	if changed:
		tracks_changed.emit(get_targets())


## Input off (dead, waiting for the rewind): nothing new is picked up, and pickups in progress are dropped.
func set_active(enabled: bool) -> void:
	_active = enabled
	_dwell.clear()


## Drops every track and pickup (a death: no markers during the rewind).
func clear() -> void:
	_dwell.clear()
	if not _tracks.is_empty():
		_tracks.clear()
		tracks_changed.emit(get_targets())


## Nothing is saved: the player comes back with no tracks, like the grapple comes back with the hook put away.
func rewind_restore() -> void:
	clear()


## Runs the tracks' time down and drops the ones that ran out or whose enemy is gone. True if any were dropped.
func _count_down(delta: float) -> bool:
	var dropped: bool = false
	for enemy: Variant in _tracks.keys():
		if not is_instance_valid(enemy) or (enemy as Enemy).health.is_dead():
			_tracks.erase(enemy)
			dropped = true
			continue
		_tracks[enemy] -= delta
		if _tracks[enemy] <= 0.0:
			_tracks.erase(enemy)
			dropped = true
	return dropped


func _in_scanner(point: Vector3) -> bool:
	if _camera.is_position_behind(point):
		return false
	var screen: Vector2 = _camera.get_viewport().get_visible_rect().size
	return ScannerShape.contains(_camera.unproject_position(point) - screen * 0.5, screen, stats)


## Nothing of the world between the camera and the point.
func _in_sight(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(_camera.global_position, point, SIGHT_MASK)
	return _camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
