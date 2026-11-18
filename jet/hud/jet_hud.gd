class_name JetHud
extends LoadoutHud
## The jet loadout's HUD: a crosshair (centre), the scanner frame and the track markers (under the visor), the fuel
## gauge (right edge), the hover and surge indicators (next to the health bar), and the speedometer's A/B tag while the
## afterburner burns. See docs/mechanics/jet.md.

@onready var _fuel: FuelGauge = $Right/FuelGauge
@onready var _abilities: JetAbilityBar = $AbilityRow/Abilities
@onready var _scanner: ScannerFrame = $Underlay/ScannerFrame
@onready var _markers: TrackMarkers = $Underlay/TrackMarkers

var _motor: JetMotor
var _hud: Hud


## Called by JetLoadout after `Hud.mount`.
func setup(motor: JetMotor, tracking: Tracking, camera: Camera3D, hud: Hud, hud_stats: HudStats) -> void:
	_motor = motor
	_hud = hud
	_fuel.setup(motor)
	_abilities.setup(motor, hud_stats)
	_scanner.setup(tracking.stats)
	_markers.setup(tracking, camera, tracking.stats)
	motor.thrust_changed.connect(_on_thrust_changed)


func _on_thrust_changed(thrust: int) -> void:
	_hud.set_speed_tag("A/B" if thrust == JetMotor.Thrust.AFTERBURNER else "")
