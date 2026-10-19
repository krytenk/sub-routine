extends CharacterBody3D
class_name ThermalOverlordBoss

# Thermal Overlord - Sector 16 Act II End-of-Act Boss
# Multi-phase superheated furnace colossus armored in 1,800C molten silicon slag:
# - Phase 1-3 (Molten Slag Armor): Standard EMP pulses briefly stagger the Overlord (2.5s)
#   and deal minor 35 bleed damage because the molten slag dissipates electromagnetic induction.
#   Opening the 3 Cryogenic Heat-Sink Valves around the Central Reactor Spire floods the arena
#   with liquid-nitrogen coolant, dealing 175 thermal-shock damage per valve.
# - Phase 4 (Cryo-Frozen Brittle State): Once all 3 Cryogenic Valves are opened, the Overlord's
#   molten slag armor flash-freezes into brittle crystalline glass. Roxy's MK V EMP Discharger
#   now delivers full 220 Zero-Point Resonant damage to shatter the Thermal Overlord!

signal boss_defeated
signal boss_attacked(damage: int)
signal boss_staggered
signal slag_armor_frozen
signal boss_health_changed(current_hp: int, max_hp: int)

@export var max_health: int = 720
var current_health: int = 720

@export var walk_speed: float = 3.5
@export var brittle_speed: float = 4.5
@export var attack_damage: int = 30
@export var attack_cooldown: float = 2.0

var slag_armor_molten: bool = true
var cryo_valves_opened: int = 0
var current_target: CharacterBody3D = null
var current_cooldown: float = 0.0
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var mantle_rot_angle: float = 0.0

@onready var core_light: OmniLight3D = find_child("ThermalCoreLight", true, false)
@onready var slag_mantle_mesh: MeshInstance3D = find_child("MoltenSlagMantle", true, false)
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

	if slag_mantle_mesh and slag_armor_molten:
		mantle_rot_angle += delta * 1.8
		slag_mantle_mesh.rotation.y = mantle_rot_angle

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

		var spd = walk_speed if slag_armor_molten else brittle_speed
		if dist > 3.2:
			var dir = (target_pos - global_position).normalized()
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
			velocity.y = -9.8 * delta
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			if current_cooldown <= 0.0:
				_perform_thermal_slam()
		return

	velocity = Vector3.ZERO

func _perform_thermal_slam() -> void:
	current_cooldown = attack_cooldown
	print("[ThermalOverlordBoss] Executing superheated Thermal Surge strike on Roxy Vance!")
	if slam_audio and slam_audio.stream:
		slam_audio.play()

	if current_target:
		if current_target.has_method("apply_trauma"):
			current_target.apply_trauma(0.45)
		if current_target.has_method("take_damage"):
			current_target.take_damage(attack_damage, "enemy")
	boss_attacked.emit(attack_damage)

func apply_cryo_valve_quench() -> void:
	if is_dead:
		return
	cryo_valves_opened += 1
	is_stunned = true
	stun_timer = 3.5
	current_health = maxi(65, current_health - 175)
	boss_health_changed.emit(current_health, max_health)
	boss_staggered.emit()
	print("[ThermalOverlordBoss] Cryogenic Heat-Sink Quench! Valves opened: ", cryo_valves_opened, "/3 | Boss HP: ", current_health, "/", max_health)

	if cryo_valves_opened >= 3 and slag_armor_molten:
		slag_armor_molten = false
		if slag_mantle_mesh:
			slag_mantle_mesh.visible = false
		if core_light:
			core_light.light_color = Color(0.2, 0.9, 1.0, 1.0)
			core_light.light_energy = 7.0
		slag_armor_frozen.emit()
		print("[ThermalOverlordBoss] MOLTEN SLAG ARMOR FLASH-FROZEN! Chassis is brittle and vulnerable to MK V EMP pulses!")

func take_damage(amount: int, source_type: String = "emp") -> void:
	if is_dead:
		return

	if source_type == "emp":
		if slag_armor_molten:
			is_stunned = true
			stun_timer = 2.5
			var bleed = mini(35, amount)
			current_health = maxi(0, current_health - bleed)
			boss_health_changed.emit(current_health, max_health)
			boss_staggered.emit()
			print("[ThermalOverlordBoss] Molten Slag Armor absorbed EMP blast to ", bleed, " bleed damage (2.5s stagger). HP: ", current_health, "/", max_health)
		else:
			is_stunned = true
			stun_timer = 3.0
			current_health = maxi(0, current_health - amount)
			boss_health_changed.emit(current_health, max_health)
			boss_staggered.emit()
			print("[ThermalOverlordBoss] DIRECT MK V EMP RESONANCE SHATTER HIT! Dealt ", amount, " damage to Cryo-Frozen Chassis! HP: ", current_health, "/", max_health)

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
	print("[ThermalOverlordBoss] THERMAL OVERLORD SHATTERED! Deep Core Elevator unlocked!")

	if core_light:
		core_light.light_energy = 14.0
		core_light.light_color = Color(0.25, 0.95, 1.0, 1.0)

	if explode_audio and explode_audio.stream:
		explode_audio.play()

	boss_defeated.emit()

	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector3(1.35, 0.08, 1.35), 1.6).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_callback(func():
				visible = false
				queue_free()
			)
		else:
			visible = false
	else:
		visible = false
