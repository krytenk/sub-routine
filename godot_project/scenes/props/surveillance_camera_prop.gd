extends Node3D
class_name SurveillanceCameraProp

# Sub-Routine Autonomous Surveillance Camera
# Psychological horror surveillance prop:
# Tracks Roxy smoothly when her back is turned.
# When Roxy faces the camera, it instantly freezes or snaps away, extinguishing its red recording light.

@export var max_tracking_distance: float = 22.0
@export var tracking_speed: float = 2.5
@export var is_active: bool = true

var player: CharacterBody3D = null
var gimbal: Node3D = null
var tally_light: OmniLight3D = null
var tally_mesh: MeshInstance3D = null
var audio_servo: AudioStreamPlayer3D = null
var audio_click: AudioStreamPlayer3D = null

var was_observed: bool = false
var is_currently_tracking: bool = false
var servo_cooldown: float = 0.0
var disabled_timer: float = 0.0

func _ready() -> void:
	_build_visuals()
	_build_audio()
	add_to_group("surveillance_cameras")

func _build_visuals() -> void:
	# Base mounting bracket
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.3, 0.3, 0.2)
	var mat_base = StandardMaterial3D.new()
	mat_base.albedo_color = Color(0.12, 0.12, 0.14, 1.0)
	mat_base.metallic = 0.9
	mat_base.roughness = 0.3

	var base_inst = MeshInstance3D.new()
	base_inst.name = "BaseBracket"
	base_inst.mesh = base_mesh
	base_inst.material_override = mat_base
	add_child(base_inst)

	# Gimbal swivel arm
	gimbal = Node3D.new()
	gimbal.name = "GimbalArm"
	gimbal.position = Vector3(0, -0.15, 0.1)
	add_child(gimbal)

	# Camera body
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.22, 0.2, 0.4)
	var body_inst = MeshInstance3D.new()
	body_inst.name = "CameraHousing"
	body_inst.mesh = body_mesh
	body_inst.material_override = mat_base
	body_inst.position = Vector3(0, 0, 0.15)
	gimbal.add_child(body_inst)

	# Camera lens
	var lens_mesh = CylinderMesh.new()
	lens_mesh.top_radius = 0.07
	lens_mesh.bottom_radius = 0.08
	lens_mesh.height = 0.12
	var mat_lens = StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.02, 0.02, 0.03, 1.0)
	mat_lens.metallic = 0.95
	mat_lens.roughness = 0.1

	var lens_inst = MeshInstance3D.new()
	lens_inst.name = "Lens"
	lens_inst.mesh = lens_mesh
	lens_inst.material_override = mat_lens
	lens_inst.rotation = Vector3(PI / 2.0, 0, 0)
	lens_inst.position = Vector3(0, 0, 0.38)
	gimbal.add_child(lens_inst)

	# Blinking Red Recording Tally LED
	var led_mesh = SphereMesh.new()
	led_mesh.radius = 0.025
	led_mesh.height = 0.05
	var mat_led = StandardMaterial3D.new()
	mat_led.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
	mat_led.emission_enabled = true
	mat_led.emission = Color(1.0, 0.1, 0.1, 1.0)
	mat_led.emission_energy_multiplier = 3.5

	tally_mesh = MeshInstance3D.new()
	tally_mesh.name = "TallyLED"
	tally_mesh.mesh = led_mesh
	tally_mesh.material_override = mat_led
	tally_mesh.position = Vector3(0.08, 0.08, 0.35)
	gimbal.add_child(tally_mesh)

	tally_light = OmniLight3D.new()
	tally_light.name = "TallyLight"
	tally_light.light_color = Color(1.0, 0.1, 0.1, 1.0)
	tally_light.light_energy = 0.6
	tally_light.omni_range = 3.0
	tally_light.position = Vector3(0.08, 0.08, 0.4)
	gimbal.add_child(tally_light)

func _build_audio() -> void:
	audio_servo = AudioStreamPlayer3D.new()
	audio_servo.name = "AudioServo"
	audio_servo.max_distance = 16.0
	audio_servo.bus = "Master"
	add_child(audio_servo)

	audio_click = AudioStreamPlayer3D.new()
	audio_click.name = "AudioClick"
	audio_click.max_distance = 18.0
	audio_click.bus = "Master"
	add_child(audio_click)

	var servo_path = "res://assets/audio/sfx/camera_servo_pan.wav"
	if ResourceLoader.exists(servo_path):
		audio_servo.stream = ResourceLoader.load(servo_path)

	var click_path = "res://assets/audio/sfx/camera_click.wav"
	if ResourceLoader.exists(click_path):
		audio_click.stream = ResourceLoader.load(click_path)

func _process(delta: float) -> void:
	if not is_active:
		return

	if disabled_timer > 0.0:
		disabled_timer -= delta
		if tally_light:
			tally_light.visible = false
		if tally_mesh:
			tally_mesh.visible = false
		return

	if servo_cooldown > 0.0:
		servo_cooldown -= delta

	if not player:
		_find_player()
		if not player:
			return

	var dist = global_position.distance_to(player.global_position)
	if dist > max_tracking_distance:
		_set_tracking_state(false)
		return

	# Determine if Roxy is looking at the camera
	var is_observed = _is_player_facing_camera()

	if is_observed:
		# Player is looking! Instantly freeze and kill recording LED!
		if not was_observed and is_currently_tracking:
			_on_spotted()
		was_observed = true
		_set_tracking_state(false)
	else:
		# Player's back is turned! Resume silent surveillance tracking
		was_observed = false
		_set_tracking_state(true)
		_track_player(delta)

func _is_player_facing_camera() -> bool:
	if not player:
		return false

	var cam = get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null
	var look_dir: Vector3
	var origin: Vector3

	if cam:
		look_dir = -cam.global_transform.basis.z.normalized()
		origin = cam.global_position
	else:
		look_dir = -player.global_transform.basis.z.normalized()
		origin = player.global_position + Vector3(0, 1.5, 0)

	var to_camera = (global_position - origin).normalized()
	var dot = look_dir.dot(to_camera)
	# Dot > 0.40 means camera is in the player's forward cone (~130 degree field of view)
	return dot > 0.40

func _track_player(delta: float) -> void:
	if not gimbal:
		return

	var target_pos = player.global_position + Vector3(0, 1.2, 0)
	var current_rot = gimbal.global_transform.basis
	var target_transform = gimbal.global_transform.looking_at(target_pos, Vector3.UP)

	# Slerp toward player position
	var new_rot = current_rot.slerp(target_transform.basis, delta * tracking_speed)
	gimbal.global_transform.basis = new_rot

	# Play faint servo noise occasionally while moving
	if servo_cooldown <= 0.0:
		if audio_servo and audio_servo.stream and not audio_servo.playing:
			audio_servo.play()
			servo_cooldown = 2.8

func _set_tracking_state(tracking: bool) -> void:
	is_currently_tracking = tracking
	if tally_light:
		tally_light.visible = tracking
	if tally_mesh:
		tally_mesh.visible = tracking

func _on_spotted() -> void:
	# Subtle shutter lock sound when player catches the camera
	if audio_click and audio_click.stream:
		audio_click.play()

func take_damage(_dmg: int, type: String = "") -> void:
	if type == "emp":
		# EMP shockwave overloads camera circuits
		disabled_timer = 14.0
		_set_tracking_state(false)
		if audio_click and audio_click.stream:
			audio_click.play()

func _find_player() -> void:
	if is_inside_tree() and get_tree().root:
		player = get_tree().root.find_child("RoxyVance", true, false) as CharacterBody3D
