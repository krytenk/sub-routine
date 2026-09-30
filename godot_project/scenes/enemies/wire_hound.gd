extends CharacterBody3D
class_name WireHound

# WireHound - Quadruped Scrap Canine Entity
# Built from tangled chassis rails, monitor-arm limbs, copper ribbon tendons, and burning LED sensor eyes.
# Fast pursuit predator ($6.8 m/s$) with quadrupedal trot mechanics and pounce attacks.

signal hound_attacked(damage: int)
signal hound_stunned(duration: float)

@export var max_health: int = 80
var current_health: int = 80

@export var base_speed: float = 6.8
@export var attack_range: float = 1.9
@export var base_damage: int = 20
@export var attack_cooldown: float = 1.2
@export var detection_range: float = 24.0

var current_target: RoxyVance = null
var current_cooldown: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_dead: bool = false

# Articulated Limb References
var leg_fl: Node3D = null
var leg_fr: Node3D = null
var leg_bl: Node3D = null
var leg_br: Node3D = null
var head_node: Node3D = null
var spine_node: Node3D = null
var tail_node: Node3D = null
var visual_root: Node3D = null

var rest_leg_fl_rot: Vector3 = Vector3.ZERO
var rest_leg_fr_rot: Vector3 = Vector3.ZERO
var rest_leg_bl_rot: Vector3 = Vector3.ZERO
var rest_leg_br_rot: Vector3 = Vector3.ZERO
var rest_head_rot: Vector3 = Vector3.ZERO

var trot_phase: float = 0.0
var bark_timer: float = 3.0
var trot_sound_timer: float = 0.0

@export var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0

# Audio Players
var audio_bark: AudioStreamPlayer3D = null
var audio_trot: AudioStreamPlayer3D = null
var audio_attack: AudioStreamPlayer3D = null

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
	leg_fl = find_child("Leg_FL", true, false) as Node3D
	leg_fr = find_child("Leg_FR", true, false) as Node3D
	leg_bl = find_child("Leg_BL", true, false) as Node3D
	leg_br = find_child("Leg_BR", true, false) as Node3D
	head_node = find_child("Head", true, false) as Node3D
	spine_node = find_child("Spine", true, false) as Node3D
	tail_node = find_child("Tail", true, false) as Node3D

	if leg_fl: rest_leg_fl_rot = leg_fl.rotation
	if leg_fr: rest_leg_fr_rot = leg_fr.rotation
	if leg_bl: rest_leg_bl_rot = leg_bl.rotation
	if leg_br: rest_leg_br_rot = leg_br.rotation
	if head_node: rest_head_rot = head_node.rotation

func _setup_audio() -> void:
	audio_bark = AudioStreamPlayer3D.new()
	audio_bark.name = "BarkAudio"
	audio_bark.max_distance = 28.0
	audio_bark.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(audio_bark)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_hound_bark.wav"):
		audio_bark.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_hound_bark.wav")

	audio_trot = AudioStreamPlayer3D.new()
	audio_trot.name = "TrotAudio"
	audio_trot.max_distance = 18.0
	audio_trot.volume_db = -6.0
	add_child(audio_trot)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_hound_trot.wav"):
		audio_trot.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_hound_trot.wav")

	audio_attack = AudioStreamPlayer3D.new()
	audio_attack.name = "AttackAudio"
	audio_attack.max_distance = 24.0
	add_child(audio_attack)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_hound_attack.wav"):
		audio_attack.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_hound_attack.wav")

func take_damage(amount: int, source_type: String = "emp") -> void:
	if is_dead:
		return
	if source_type == "emp":
		stagger(6.5)
	current_health = maxi(0, current_health - amount)
	print("[WireHound] Hit! Health: ", current_health, "/", max_health)
	if current_health <= 0:
		_die()

func stagger(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	hound_stunned.emit(duration)
	print("[WireHound] EMP Overload! Circuitry seized for ", duration, "s.")

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	print("[WireHound] Core crushed. Scrap hound disabled.")
	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("enemy_killed", "WireHound logic terminated. Deconstructing scrap matrix.")
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_stunned:
		stun_timer -= delta
		velocity = Vector3.ZERO
		if visual_root:
			visual_root.position = Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04))
		if stun_timer <= 0.0:
			is_stunned = false
			if visual_root:
				visual_root.position = Vector3.ZERO
		_update_trot_animation(delta, 0.0)
		return

	if current_cooldown > 0.0:
		current_cooldown -= delta

	if not current_target:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			current_target = players[0] as RoxyVance

	# Check player alive & stealth hiding status
	var player_available = current_target and current_target.current_health > 0
	if player_available and "is_hiding" in current_target and current_target.is_hiding:
		player_available = false
	if player_available and "is_invulnerable" in current_target and current_target.is_invulnerable:
		player_available = false

	# Ambient glitched canine barks
	bark_timer -= delta
	if bark_timer <= 0.0:
		if audio_bark and audio_bark.stream:
			audio_bark.pitch_scale = randf_range(0.85, 1.15)
			audio_bark.play()
		bark_timer = randf_range(4.0, 8.5)

	if player_available:
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= detection_range:
			var target_pos = current_target.global_position
			target_pos.y = global_position.y
			look_at(target_pos, Vector3.UP)

			if dist > attack_range:
				var dir = (target_pos - global_position).normalized()
				velocity.x = dir.x * base_speed
				velocity.z = dir.z * base_speed
				velocity.y = -9.8 * delta
				move_and_slide()
				_update_trot_audio(delta)
			else:
				velocity = Vector3.ZERO
				if current_cooldown <= 0.0:
					_perform_hound_attack()
			_update_trot_animation(delta, base_speed)
			return

	# Fallback to patrol waypoints or idle
	if patrol_points.size() > 0:
		var p_target = patrol_points[current_patrol_index]
		p_target.y = global_position.y
		var p_dist = global_position.distance_to(p_target)
		if p_dist < 1.5:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		else:
			look_at(p_target, Vector3.UP)
			var p_dir = (p_target - global_position).normalized()
			var p_speed = base_speed * 0.45
			velocity.x = p_dir.x * p_speed
			velocity.z = p_dir.z * p_speed
			velocity.y = -9.8 * delta
			move_and_slide()
			_update_trot_audio(delta)
			_update_trot_animation(delta, p_speed)
			return

	velocity = Vector3.ZERO
	_update_trot_animation(delta, 0.0)

func _update_trot_audio(delta: float) -> void:
	trot_sound_timer -= delta
	if trot_sound_timer <= 0.0:
		if audio_trot and audio_trot.stream:
			audio_trot.pitch_scale = randf_range(0.9, 1.2)
			audio_trot.play()
		trot_sound_timer = 0.22 # Rapid quad trot rhythm

func _perform_hound_attack() -> void:
	current_cooldown = attack_cooldown
	print("[WireHound] Pouncing bite attack on Roxy Vance for ", base_damage, " damage!")
	if audio_attack and audio_attack.stream:
		audio_attack.play()
	hound_attacked.emit(base_damage)
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(base_damage, "enemy")

func _update_trot_animation(delta: float, current_speed: float) -> void:
	if current_speed > 0.2 and not is_stunned:
		trot_phase += delta * current_speed * 3.8
		var swing = sin(trot_phase)
		var swing_angle = deg_to_rad(36.0)

		# Quadruped diagonal trot pairs: (FL + BR) vs (FR + BL)
		if leg_fl: leg_fl.rotation.x = rest_leg_fl_rot.x + swing * swing_angle
		if leg_br: leg_br.rotation.x = rest_leg_br_rot.x + swing * swing_angle
		if leg_fr: leg_fr.rotation.x = rest_leg_fr_rot.x - swing * swing_angle
		if leg_bl: leg_bl.rotation.x = rest_leg_bl_rot.x - swing * swing_angle

		# Predatory spine undulation & snarl bobbing
		if spine_node:
			spine_node.position.y = 0.45 + abs(sin(trot_phase)) * 0.06
		if head_node:
			head_node.rotation.x = rest_head_rot.x + sin(trot_phase * 2.0) * deg_to_rad(8.0)
		if tail_node:
			tail_node.rotation.y = sin(trot_phase * 1.5) * deg_to_rad(22.0)
	else:
		var blend = clampf(delta * 8.0, 0.0, 1.0)
		if leg_fl: leg_fl.rotation.x = lerp_angle(leg_fl.rotation.x, rest_leg_fl_rot.x, blend)
		if leg_fr: leg_fr.rotation.x = lerp_angle(leg_fr.rotation.x, rest_leg_fr_rot.x, blend)
		if leg_bl: leg_bl.rotation.x = lerp_angle(leg_bl.rotation.x, rest_leg_bl_rot.x, blend)
		if leg_br: leg_br.rotation.x = lerp_angle(leg_br.rotation.x, rest_leg_br_rot.x, blend)
		if head_node: head_node.rotation.x = lerp_angle(head_node.rotation.x, rest_head_rot.x, blend)
