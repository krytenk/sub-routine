extends CharacterBody3D
class_name DredgeTitan

# Dredge Titan - Invincible 4-Meter Sub-Core Behemoth
# Patrolls the Primary Assembly Trench floor below the overhead air ducts.
# Heavy seismic stomps vibrate the player's camera. Ground encounters are lethal;
# players must crawl through the high overhead ventilation shafts to bypass its territory.

signal titan_stomped(distance: float)
signal titan_attacked(damage: int)

@export var patrol_points: Array[Vector3] = []
@export var walk_speed: float = 2.8
@export var charge_speed: float = 5.8
@export var slam_damage: int = 80
@export var detection_range: float = 14.0

var current_patrol_index: int = 0
var current_target: CharacterBody3D = null
var current_cooldown: float = 0.0
var stomp_timer: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0

@onready var ocular_light: SpotLight3D = find_child("SearchlightBeam", true, false)
@onready var step_audio: AudioStreamPlayer3D = find_child("StepAudio", true, false)
@onready var slam_audio: AudioStreamPlayer3D = find_child("SlamAudio", true, false)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("titans")
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		current_target = players[0] as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not current_target:
		_find_player()

	if is_stunned:
		stun_timer -= delta
		velocity = Vector3.ZERO
		if stun_timer <= 0.0:
			is_stunned = false
		return

	if current_cooldown > 0.0:
		current_cooldown -= delta

	# Check if player is on the ground level (below Y = 2.5m) and in range
	var player_vulnerable = false
	if current_target and current_target.current_health > 0:
		if not ("is_in_duct" in current_target and current_target.is_in_duct):
			if not ("is_hiding" in current_target and current_target.is_hiding):
				if current_target.global_position.y < 2.5: # On trench floor
					var d = global_position.distance_to(current_target.global_position)
					if d <= detection_range:
						player_vulnerable = true

	if player_vulnerable and current_target:
		# Alert pursuit on ground floor
		var target_pos = current_target.global_position
		target_pos.y = global_position.y
		look_at(target_pos, Vector3.UP)
		var dist = global_position.distance_to(target_pos)

		if dist > 3.0:
			var dir = (target_pos - global_position).normalized()
			velocity.x = dir.x * charge_speed
			velocity.z = dir.z * charge_speed
			velocity.y = -9.8 * delta
			move_and_slide()
			_process_stomps(delta, 0.45)
		else:
			velocity = Vector3.ZERO
			if current_cooldown <= 0.0:
				_perform_ground_slam()
		return

	# Patrol trench waypoints
	if patrol_points.size() > 0:
		var p_target = patrol_points[current_patrol_index]
		p_target.y = global_position.y
		var p_dist = global_position.distance_to(p_target)
		if p_dist < 2.0:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		else:
			look_at(p_target, Vector3.UP)
			var p_dir = (p_target - global_position).normalized()
			velocity.x = p_dir.x * walk_speed
			velocity.z = p_dir.z * walk_speed
			velocity.y = -9.8 * delta
			move_and_slide()
			_process_stomps(delta, 0.75)
			return

	velocity = Vector3.ZERO

func _process_stomps(delta: float, interval: float) -> void:
	stomp_timer -= delta
	if stomp_timer <= 0.0:
		stomp_timer = interval
		if step_audio and step_audio.stream:
			step_audio.play()

		# Screen shake when near player
		if current_target:
			var dist = global_position.distance_to(current_target.global_position)
			if dist < 22.0:
				var trauma = lerpf(0.18, 0.02, dist / 22.0)
				if current_target.has_method("apply_trauma"):
					current_target.apply_trauma(trauma)
				titan_stomped.emit(dist)

func _perform_ground_slam() -> void:
	current_cooldown = 1.8
	print("[DredgeTitan] Devastating ground slam executed on trench floor!")
	if slam_audio and slam_audio.stream:
		slam_audio.play()

	if current_target and current_target.has_method("apply_trauma"):
		current_target.apply_trauma(0.55)

	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(slam_damage, "enemy")
	titan_attacked.emit(slam_damage)

func take_damage(_amount: int, source_type: String = "emp") -> void:
	if source_type == "emp":
		is_stunned = true
		stun_timer = 2.0 # Micro-stagger only
		print("[DredgeTitan] EMP shockwave deflected by composite armor; micro-staggered for 2.0s.")
	else:
		print("[DredgeTitan] Kinetic damage deflected by reinforced chassis.")
