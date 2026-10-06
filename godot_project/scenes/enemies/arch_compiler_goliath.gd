extends CharacterBody3D
class_name ArchCompilerGoliath

# Arch-Compiler Goliath - Sector 07 Apex Boss Entity
# Heavily armored cybernetic core guardian. Armored composite plating deflects
# standard EMP bursts. Only vulnerable to a direct shot from the prototype
# Hyper-Flux Singularity Cannon into its exposed chest exhaust.

signal boss_defeated
signal boss_attacked(damage: int)
signal boss_staggered

@export var max_health: int = 500
var current_health: int = 500

@export var walk_speed: float = 3.2
@export var attack_damage: int = 35
@export var attack_cooldown: float = 2.2

var current_target: CharacterBody3D = null
var current_cooldown: float = 0.0
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

@onready var chest_core_light: OmniLight3D = find_child("ChestCoreLight", true, false)
@onready var slam_audio: AudioStreamPlayer3D = find_child("SlamAudio", true, false)
@onready var explode_audio: AudioStreamPlayer3D = find_child("ExplodeAudio", true, false)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	current_health = max_health
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		current_target = players[0] as CharacterBody3D

func _physics_process(delta: float) -> void:
	if is_dead:
		return

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

	if current_target and current_target.current_health > 0:
		var target_pos = current_target.global_position
		target_pos.y = global_position.y
		look_at(target_pos, Vector3.UP)
		var dist = global_position.distance_to(target_pos)

		if dist > 3.4:
			var dir = (target_pos - global_position).normalized()
			velocity.x = dir.x * walk_speed
			velocity.z = dir.z * walk_speed
			velocity.y = -9.8 * delta
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			if current_cooldown <= 0.0:
				_perform_heavy_strike()
		return

	velocity = Vector3.ZERO

func _perform_heavy_strike() -> void:
	current_cooldown = attack_cooldown
	print("[ArchCompilerGoliath] Boss heavy claw strike on Roxy Vance!")
	if slam_audio and slam_audio.stream:
		slam_audio.play()

	if current_target:
		if current_target.has_method("apply_trauma"):
			current_target.apply_trauma(0.4)
		if current_target.has_method("take_damage"):
			current_target.take_damage(attack_damage, "enemy")
	boss_attacked.emit(attack_damage)

func take_damage(_amount: int, source_type: String = "emp") -> void:
	if is_dead:
		return
	if source_type == "emp":
		# Micro-stagger only from regular EMP
		is_stunned = true
		stun_timer = 1.0
		boss_staggered.emit()
		print("[ArchCompilerGoliath] Standard EMP blast deflected by hardened ceramic plating! (1.0s micro-stagger)")
	elif source_type == "superweapon":
		take_superweapon_hit()

func take_superweapon_hit() -> void:
	if is_dead:
		return
	is_dead = true
	current_health = 0
	print("[ArchCompilerGoliath] CRITICAL CORE BREACH! Singularity Cannon penetrated thermal radiator exhaust!")

	if chest_core_light:
		chest_core_light.light_energy = 14.0
		chest_core_light.light_color = Color(1.0, 0.9, 0.4, 1.0)

	if explode_audio and explode_audio.stream:
		explode_audio.play()

	boss_defeated.emit()

	var tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector3(1.2, 0.1, 1.2), 1.5).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(func():
			visible = false
			queue_free()
		)
	else:
		queue_free()
