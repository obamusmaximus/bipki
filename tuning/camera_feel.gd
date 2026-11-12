class_name CameraFeel
extends Resource
## Tunable numbers for how the camera feels: FOV, shake, walk bob and mouse look. Kept in the debug panel while it is being
## tuned; later these get simplified (e.g. one shake intensity) and move into GameSettings.
## One .tres per preset (tuning/camera_feel_default.tres). The Player scene holds it in `feel`.

@export_group("Dynamic FOV")
## Extra FOV (degrees) at full_speed.
@export var fov_max_extra: float = 14.0
## Speed (m/s) where the FOV widening starts.
@export var fov_start_speed: float = 18.0
## Speed (m/s) where the FOV widening is complete.
@export var fov_full_speed: float = 45.0
## How fast the FOV follows speed (per second).
@export var fov_smoothing: float = 6.0
## How fast a FOV kick fades (per second).
@export var fov_kick_decay: float = 5.0
## Extra FOV (degrees) punched in when a launch fires.
@export var launch_fov_kick: float = 8.0

@export_group("Camera shake")
## Shake strength (0-1) when the grapple attaches or detaches.
@export var grapple_shake: float = 0.8
## Largest frustum offset at full trauma (m).
@export var shake_max_offset: float = 0.2
## Largest roll at full trauma (degrees).
@export var shake_max_roll_degrees: float = 2.5
## Trauma lost per second.
@export var shake_decay: float = 2.5

@export_group("Walk bob")
## Vertical bob (m).
@export var bob_height: float = 0.03
## Sideways sway (m).
@export var bob_sway: float = 0.02
## Phase speed in radians per second (about two footsteps per second at walking pace).
@export var bob_step_speed: float = 12.0
## How fast the bob blends in and out (per second).
@export var bob_blend_speed: float = 8.0

@export_group("Mouse look")
## Radians per pixel at the default setting. The player's sensitivity option (GameSettings) scales it.
@export var mouse_sensitivity: float = 0.002
