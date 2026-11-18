class_name ScannerFrame
extends Control
## The thin blue frame in the middle of the screen showing the jet's scanner (Tracking): the same shape the scanner
## uses (ScannerShape), so an enemy inside it is in the scanner. Full screen and unscaled (in the Hud's Underlay),
## because the shape is a share of the screen. Look in TrackingStats ("Scanner frame").

var _stats: TrackingStats


func setup(tracking_stats: TrackingStats) -> void:
	_stats = tracking_stats
	_stats.changed.connect(queue_redraw)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _stats == null:
		return
	draw_polyline(ScannerShape.outline(size * 0.5, size, _stats), _stats.frame_color, _stats.frame_width, true)
