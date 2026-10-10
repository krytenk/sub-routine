extends CharacterBody3D
class_name CyberHusk

# CyberHusk - Re-animated Cybernetic Corpse Entity
# Former station engineers whose neural implants and motorized prosthetics have been
# hijacked by corrupted machine subroutines. Shambling, twitching humanoid horror
# with pneumatic pincer strikes, arcing electrical discharges, and high armor durability.

signal husk_attacked(damage: int)
signal husk_stunned(duration: float)

@export var max_health: int = 110
var current_health: int = 110

@export var base_speed: float = 3.4
@export var lunge_speed: float = 5.6
@export var attack_range: float = 2.2
@export var base_damage: int = 24
@export var attack_cooldown: float = 1.4
@export var detection_range: float = 12.5
@export var patrol_points: Array[Vector3] = []

var current_patrol_index: int = 0
var current_target: RoxyVance = null
var current_cooldown: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_dead: bool = false

# Articulated Body References
var visual_root: Node3D = null
var torso_node: Node3D = null
var head_node: Node3D = null
var arm_l: Node3D = null
var arm_r: Node3D = null
var leg_l: Node3D = null
var leg_r: Node3D = null
var ocular_light: OmniLight3D = null
var spark_particles: CPUParticles3D = null

var rest_arm_l_rot: Vector3 = Vector3.ZERO
var rest_arm_r_rot: Vector3 = Vector3.ZERO
var rest_leg_l_rot: Vector3 = Vector3.ZERO
var rest_leg_r_rot: Vector3 = Vector3.ZERO
var rest_head_rot: Vector3 = Vector3.ZERO

var walk_phase: float = 0.0
var step_sound_timer: float = 0.0
var vocal_timer: float = 3.5

# Audio Players
var audio_vocal: AudioStreamPlayer3D = null
var audio_step: AudioStreamPlayer3D = null
var audio_attack: AudioStreamPlayer3D = null
var audio_spark: AudioStreamPlayer3D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_setup_limbs()
	_setup_audio()

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		current_target = players[0] as RoxyVance

func _setup_limbs() -> void:
	visual_root = find_child("VisualRoot", true, false) as Node3D
	torso_node = find_child("Torso", true, false) as Node3D
	head_node = find_child("Head", true, false) as Node3D
	arm_l = find_child("Arm_L", true, false) as Node3D
	arm_r = find_child("Arm_R", true, false) as Node3D # Cybernetic pincer arm
	leg_l = find_child("Leg_L", true, false) as Node3D # Motorized prosthetic leg
	leg_r = find_child("Leg_R", true, false) as Node3D # Shambling organic leg
	ocular_light = find_child("OcularLight", true, false) as OmniLight3D
	spark_particles = find_child("Sparks", true, false) as CPUParticles3D

	if arm_l: rest_arm_l_rot = arm_l.rotation
	if arm_r: rest_arm_r_rot = arm_r.rotation
	if leg_l: rest_leg_l_rot = leg_l.rotation
	if leg_r: rest_leg_r_rot = leg_r.rotation
	if head_node: rest_head_rot = head_node.rotation

func _setup_audio() -> void:
	audio_vocal = AudioStreamPlayer3D.new()
	audio_vocal.name = "VocalAudio"
	audio_vocal.max_distance = 24.0
	audio_vocal.volume_db = -2.0
	audio_vocal.pitch_scale = 0.7
	audio_vocal.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(audio_vocal)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_glitch_growl.wav"):
		audio_vocal.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_glitch_growl.wav")

	audio_step = AudioStreamPlayer3D.new()
	audio_step.name = "StepAudio"
	audio_step.max_distance = 16.0
	audio_step.volume_db = -4.0
	add_child(audio_step)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_metal_footstep.wav"):
		audio_step.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_metal_footstep.wav")

	audio_attack = AudioStreamPlayer3D.new()
	audio_attack.name = "AttackAudio"
	audio_attack.max_distance = 22.0
	audio_attack.volume_db = 0.0
	add_child(audio_attack)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_steam_hiss.wav"):
		audio_attack.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_steam_hiss.wav")

	audio_spark = AudioStreamPlayer3D.new()
	audio_spark.name = "SparkAudio"
	audio_spark.max_distance = 18.0
	audio_spark.volume_db = -3.0
	add_child(audio_spark)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_electric_spark.wav"):
		audio_spark.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_electric_spark.wav")

func take_damage(amount: int, source_type: String = "emp") -> void:
	if is_dead:
		return
	if source_type == "emp":
		stagger(6.0)
	current_health = maxi(0, current_health - amount)
	print("[CyberHusk] Hit! Health: ", current_health, "/", max_health)
	if current_health <= 0:
		_die()

func stagger(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	husk_stunned.emit(duration)
	print("[CyberHusk] Cybernetic implants overloaded! Seized for ", duration, "s.")
	if spark_particles:
		spark_particles.emitting = true
	if audio_spark and audio_spark.stream:
		audio_spark.play()

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	print("[CyberHusk] Cyber-core terminated. Husk collapsed.")
	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("enemy_killed", "Cybernetic husk severed from kernel loop. Firmware flushed.")
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_stunned:
		stun_timer -= delta
		velocity = Vector3.ZERO
		# Violent electric seizure twitch
		if visual_root:
			visual_root.position = Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06))
		if head_node:
			head_node.rotation.z = randf_range(-0.3, 0.3)
		if ocular_light:
			ocular_light.light_energy = randf_range(0.2, 3.5)
		if stun_timer <= 0.0:
			is_stunned = false
			if visual_root:
				visual_root.position = Vector3.ZERO
			if spark_particles:
				spark_particles.emitting = false
		_update_shamble_animation(delta, 0.0)
		return

	if current_cooldown > 0.0:
		current_cooldown -= delta

	if not current_target:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			current_target = players[0] as RoxyVance

	var player_available = current_target and current_target.current_health > 0
	if player_available and "is_hiding" in current_target and current_target.is_hiding:
		player_available = false
	if player_available and "is_invulnerable" in current_target and current_target.is_invulnerable:
		player_available = false
	if player_available and current_target.has_method("_is_modal_ui_open") and current_target._is_modal_ui_open():
		player_available = false

	# Creepy vocal synthesizer groan
	vocal_timer -= delta
	if vocal_timer <= 0.0:
		if audio_vocal and audio_vocal.stream:
			audio_vocal.pitch_scale = randf_range(0.6, 0.8)
			audio_vocal.play()
		vocal_timer = randf_range(4.5, 9.0)

	if player_available:
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= detection_range:
			var target_pos = current_target.global_position
			target_pos.y = global_position.y
			look_at(target_pos, Vector3.UP)

			# Speed surge when close: relentless lunge
			var speed = base_speed
			if dist < 6.0:
				speed = lunge_speed

			if dist > attack_range:
				var dir = (target_pos - global_position).normalized()
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				velocity.y = -9.8 * delta
				move_and_slide()
				_update_footstep_audio(delta)
			else:
				velocity = Vector3.ZERO
				if current_cooldown <= 0.0:
					_perform_cyber_attack()
			_update_shamble_animation(delta, speed)
			return

	# Out of detection range or player hidden: Patrol assigned waypoints
	if patrol_points.size() > 0:
		var p_target = patrol_points[current_patrol_index]
		p_target.y = global_position.y
		var p_dist = global_position.distance_to(p_target)
		if p_dist < 1.4:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		else:
			look_at(p_target, Vector3.UP)
			var p_dir = (p_target - global_position).normalized()
			var p_speed = base_speed * 0.45
			velocity.x = p_dir.x * p_speed
			velocity.z = p_dir.z * p_speed
			velocity.y = -9.8 * delta
			move_and_slide()
			_update_footstep_audio(delta)
			_update_shamble_animation(delta, p_speed)
			return

	velocity = Vector3.ZERO
	_update_shamble_animation(delta, 0.0)

func _update_footstep_audio(delta: float) -> void:
	step_sound_timer -= delta
	if step_sound_timer <= 0.0:
		if audio_step and audio_step.stream:
			audio_step.pitch_scale = randf_range(0.7, 0.95)
			audio_step.play()
		step_sound_timer = 0.55 # Shambling limp cadence

func _perform_cyber_attack() -> void:
	current_cooldown = attack_cooldown
	print("[CyberHusk] Pneumatic pincer strike on Roxy Vance for ", base_damage, " damage!")
	if audio_attack and audio_attack.stream:
		audio_attack.play()
	if audio_spark and audio_spark.stream:
		audio_spark.play()

	# Violent cyber-arm swing tween
	if arm_r:
		var tw = create_tween()
		if tw:
			tw.tween_property(arm_r, "rotation:x", deg_to_rad(-85.0), 0.12)
			tw.tween_property(arm_r, "rotation:y", deg_to_rad(45.0), 0.08)
			tw.tween_property(arm_r, "rotation:x", rest_arm_r_rot.x, 0.25)
			tw.tween_property(arm_r, "rotation:y", rest_arm_r_rot.y, 0.25)

	if ocular_light:
		ocular_light.light_energy = 4.5

	husk_attacked.emit(base_damage)
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(base_damage, "enemy")

func _update_shamble_animation(delta: float, current_speed: float) -> void:
	if current_speed > 0.2 and not is_stunned:
		walk_phase += delta * current_speed * 3.2
		var swing = sin(walk_phase)

		# Asymmetrical limp: Prosthetic Leg_L kicks forward, Organic Leg_R drags
		if leg_l: leg_l.rotation.x = rest_leg_l_rot.x + swing * deg_to_rad(32.0)
		if leg_r: leg_r.rotation.x = rest_leg_r_rot.x - swing * deg_to_rad(18.0)

		# Twitching torso and twitching cyber-arm
		if torso_node:
			torso_node.rotation.z = sin(walk_phase) * deg_to_rad(6.0)
			torso_node.position.y = 0.9 + abs(sin(walk_phase)) * 0.06
		if arm_l:
			arm_l.rotation.x = rest_arm_l_rot.x - swing * deg_to_rad(24.0)
		if arm_r:
			# Motorized pincer twitching aggressively forward
			arm_r.rotation.x = rest_arm_r_rot.x + sin(walk_phase * 1.5) * deg_to_rad(15.0) - deg_to_rad(35.0)

		# Head twitching / optical targeting scan
		if head_node:
			head_node.rotation.y = rest_head_rot.y + sin(walk_phase * 2.0) * deg_to_rad(14.0)
			head_node.rotation.z = deg_to_rad(8.0) # Unnerving cocked head tilt

		if ocular_light:
			ocular_light.light_energy = 1.8 + sin(walk_phase * 5.0) * 0.4
	else:
		var blend = clampf(delta * 6.0, 0.0, 1.0)
		if leg_l: leg_l.rotation.x = lerp_angle(leg_l.rotation.x, rest_leg_l_rot.x, blend)
		if leg_r: leg_r.rotation.x = lerp_angle(leg_r.rotation.x, rest_leg_r_rot.x, blend)
		if arm_l: arm_l.rotation.x = lerp_angle(arm_l.rotation.x, rest_arm_l_rot.x, blend)
		if arm_r: arm_r.rotation.x = lerp_angle(arm_r.rotation.x, rest_arm_r_rot.x - deg_to_rad(20.0), blend)
		if head_node: head_node.rotation.y = lerp_angle(head_node.rotation.y, rest_head_rot.y, blend)
		if ocular_light: ocular_light.light_energy = lerpf(ocular_light.light_energy, 1.4, blend)
