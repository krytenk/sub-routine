extends CharacterBody3D
class_name KernelWardenBoss

# Kernel Warden (The Overseer's Core Avatar) - Sector 12 Act I End-of-Act Boss
# Multi-phase biomechanical core guardian protected by a Harmonic Phase-Shield.
# - Phase 1-3 (Shielded): Standard EMP pulses briefly phase-stagger the Warden (2.5s) and deal
#   reduced bleed damage (40). Overloading the 3 Harmonic Cooling Pylons around the rotunda
#   delivers massive 160-damage thermal feedback surges and shatters the Phase-Shield.
# - Phase 4 (Shield Shattered): Roxy's upgraded MK V EMP Discharger deals full 220 Zero-Point
#   Resonant damage directly to the exposed Kernel Core to destroy the Warden!

signal boss_defeated
signal boss_attacked(damage: int)
signal boss_staggered
signal phase_shield_shattered
signal boss_health_changed(current_hp: int, max_hp: int)

@export var max_health: int = 660
var current_health: int = 660

@export var walk_speed: float = 3.4
@export var enraged_speed: float = 4.6
@export var attack_damage: int = 28
@export var attack_cooldown: float = 2.0

var phase_shield_active: bool = true
var pylons_overloaded: int = 0
var current_target: CharacterBody3D = null
var current_cooldown: float = 0.0
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var shield_rot_angle: float = 0.0

@onready var core_light: OmniLight3D = find_child("KernelCoreLight", true, false)
@onready var phase_shield_mesh: MeshInstance3D = find_child("PhaseShieldRing", true, false)
@onready var slam_audio: AudioStreamPlayer3D = find_child("SlamAudio", true, false)
@onready var explode_audio: AudioStreamPlayer3D = find_child("ExplodeAudio", true, false)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	current_health = max_health
	_find_player()

func _find_player() -> void:
	if not is_inside_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		current_target = players[0] as CharacterBody3D

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if phase_shield_mesh and phase_shield_active:
		shield_rot_angle += delta * 2.2
		phase_shield_mesh.rotation.y = shield_rot_angle

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

		var spd = walk_speed if phase_shield_active else enraged_speed
		if dist > 3.2:
			var dir = (target_pos - global_position).normalized()
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
			velocity.y = -9.8 * delta
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			if current_cooldown <= 0.0:
				_perform_kernel_strike()
		return

	velocity = Vector3.ZERO

func _perform_kernel_strike() -> void:
	current_cooldown = attack_cooldown
	print("[KernelWardenBoss] Executing high-voltage Kernel Surge strike on Roxy Vance!")
	if slam_audio and slam_audio.stream:
		slam_audio.play()

	if current_target:
		if current_target.has_method("apply_trauma"):
			current_target.apply_trauma(0.42)
		if current_target.has_method("take_damage"):
			current_target.take_damage(attack_damage, "enemy")
	boss_attacked.emit(attack_damage)

func apply_pylon_overload_surge() -> void:
	if is_dead:
		return
	pylons_overloaded += 1
	is_stunned = true
	stun_timer = 3.5
	current_health = maxi(60, current_health - 160)
	boss_health_changed.emit(current_health, max_health)
	boss_staggered.emit()
	print("[KernelWardenBoss] Harmonic Pylon Overload Surge! Pylons overloaded: ", pylons_overloaded, "/3 | Boss HP: ", current_health, "/", max_health)

	if pylons_overloaded >= 3 and phase_shield_active:
		phase_shield_active = false
		if phase_shield_mesh:
			phase_shield_mesh.visible = false
		if core_light:
			core_light.light_color = Color(1.0, 0.25, 0.1, 1.0)
			core_light.light_energy = 7.5
		phase_shield_shattered.emit()
		print("[KernelWardenBoss] PHASE-SHIELD SHATTERED! Kernel Core is fully exposed to MK V EMP pulses!")

func take_damage(amount: int, source_type: String = "emp") -> void:
	if is_dead:
		return

	if source_type == "emp":
		if phase_shield_active:
			is_stunned = true
			stun_timer = 2.5
			var bleed = mini(40, amount)
			current_health = maxi(0, current_health - bleed)
			boss_health_changed.emit(current_health, max_health)
			boss_staggered.emit()
			print("[KernelWardenBoss] Phase-Shield dampened EMP blast to ", bleed, " bleed damage (2.5s stagger). HP: ", current_health, "/", max_health)
		else:
			is_stunned = true
			stun_timer = 3.0
			current_health = maxi(0, current_health - amount)
			boss_health_changed.emit(current_health, max_health)
			boss_staggered.emit()
			print("[KernelWardenBoss] DIRECT MK V EMP RESONANCE HIT! Dealt ", amount, " damage to exposed Kernel Core! HP: ", current_health, "/", max_health)

		if current_health <= 0:
			_trigger_defeat()
	elif source_type == "superweapon":
		current_health = 0
		boss_health_changed.emit(0, max_health)
		_trigger_defeat()

func _trigger_defeat() -> void:
	if is_dead:
		return
	is_dead = true
	current_health = 0
	print("[KernelWardenBoss] CRITICAL KERNEL PANIC! The Overseer's Core Avatar has been destroyed!")

	if core_light:
		core_light.light_energy = 15.0
		core_light.light_color = Color(0.2, 0.95, 1.0, 1.0)

	if explode_audio and explode_audio.stream:
		explode_audio.play()

	boss_defeated.emit()

	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector3(1.3, 0.08, 1.3), 1.6).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_callback(func():
				visible = false
				queue_free()
			)
		else:
			visible = false
	else:
		visible = false
