extends Node3D
class_name StalkerShadowProp

# Sub-Routine Stalker Shadow Apparition
# Psychological horror prop:
# Stands motionless at the periphery. Vanishes into glitched static when approached or observed.

@export var vanish_distance: float = 8.0
@export var is_active: bool = true

var player: CharacterBody3D = null
var shadow_mesh: MeshInstance3D = null
var audio_whisper: AudioStreamPlayer3D = null
var has_vanished: bool = false
var gaze_timer: float = 0.0

func _ready() -> void:
	_build_visuals()
	_build_audio()
	add_to_group("stalker_shadows")

func _build_visuals() -> void:
	# Slender, tall humanoid shadow silhouette
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 1.85

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.01, 0.01, 0.02, 0.95)
	mat.roughness = 0.9
	mat.metallic = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.1, 0.15, 1.0)
	mat.emission_energy_multiplier = 0.5

	shadow_mesh = MeshInstance3D.new()
	shadow_mesh.name = "ShadowMesh"
	shadow_mesh.mesh = mesh
	shadow_mesh.material_override = mat
	shadow_mesh.position = Vector3(0, 0.95, 0)
	add_child(shadow_mesh)

func _build_audio() -> void:
	audio_whisper = AudioStreamPlayer3D.new()
	audio_whisper.name = "AudioWhisper"
	audio_whisper.max_distance = 25.0
	audio_whisper.bus = "Master"
	add_child(audio_whisper)

	var sfx_path = "res://assets/audio/sfx/stalker_shadow_whisper.wav"
	if ResourceLoader.exists(sfx_path):
		audio_whisper.stream = ResourceLoader.load(sfx_path)

func _process(delta: float) -> void:
	if not is_active or has_vanished:
		return

	if not player:
		_find_player()
		if not player:
			return

	var dist = global_position.distance_to(player.global_position)
	if dist <= vanish_distance:
		vanish()
		return

	# If player looks directly at the shadow
	if _is_player_looking_at_me():
		gaze_timer += delta
		if gaze_timer >= 0.8:
			vanish()
	else:
		gaze_timer = maxf(0.0, gaze_timer - delta * 0.5)

func _is_player_looking_at_me() -> bool:
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

	var to_shadow = (global_position + Vector3(0, 1.0, 0) - origin).normalized()
	return look_dir.dot(to_shadow) > 0.85

func vanish() -> void:
	if has_vanished:
		return
	has_vanished = true
	print("[StalkerShadow] Apparition vanished into static at ", global_position)

	if audio_whisper and audio_whisper.stream:
		audio_whisper.play()

	# Glitch dissolve animation
	if shadow_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(shadow_mesh, "scale", Vector3(1.4, 0.1, 1.4), 0.25)
			tween.parallel().tween_property(shadow_mesh, "modulate:a", 0.0, 0.25)
			tween.tween_callback(queue_free)
	else:
		queue_free()

func _find_player() -> void:
	if is_inside_tree() and get_tree().root:
		player = get_tree().root.find_child("RoxyVance", true, false) as CharacterBody3D
