extends CharacterBody3D
class_name GlitchWalker

# The Glitch Walker
# Low-polygon, faceless humanoid wireframe wrapped in pulsating AI fleshy texture.
# Speed and damage scale with DifficultyManager (Story to Nightmare).

signal attack_landed(damage_dealt: int)
signal enemy_defeated

@export var max_health: int = 60
var current_health: int = 60
var is_dead: bool = false

@export var base_speed: float = 3.2
@export var base_damage: int = 20
@export var detection_range: float = 14.0
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.2

@export var is_dormant: bool = false
@export var patrol_points: Array[Vector3] = []
var was_initially_dormant: bool = false
var current_patrol_index: int = 0
var growl_timer: float = 2.5
var footstep_timer: float = 0.0

var sfx_growl: AudioStream = null
var sfx_step: AudioStream = null

var current_target: RoxyVance = null
var current_cooldown: float = 0.0
var pulse_time: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0

var initial_spawn_position: Vector3
var initial_spawn_rotation: Vector3

# Articulated Limb Nodes & Predatory Walk Cycle Animation
var leg_l: Node3D = null
var leg_r: Node3D = null
var arm_l: Node3D = null
var arm_r: Node3D = null
var torso: Node3D = null
var head: Node3D = null

var rest_leg_l_rot: Vector3 = Vector3.ZERO
var rest_leg_r_rot: Vector3 = Vector3.ZERO
var rest_arm_l_rot: Vector3 = Vector3.ZERO
var rest_arm_r_rot: Vector3 = Vector3.ZERO
var rest_arm_l_pos: Vector3 = Vector3.ZERO
var rest_arm_r_pos: Vector3 = Vector3.ZERO
var rest_torso_pos: Vector3 = Vector3.ZERO
var rest_torso_rot: Vector3 = Vector3.ZERO
var rest_head_pos: Vector3 = Vector3.ZERO
var rest_head_rot: Vector3 = Vector3.ZERO

var stalk_cycle_phase: float = 0.0

@onready var visual_mesh: Node3D = $ModelAnchor
@onready var audio_spatial: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
    current_health = max_health
    initial_spawn_position = global_position
    initial_spawn_rotation = rotation
    was_initially_dormant = is_dormant
    _init_audio()
    _setup_limbs()
    _update_difficulty_parameters()
    if has_node("/root/DifficultyManager"):
        get_node("/root/DifficultyManager").difficulty_changed.connect(_on_difficulty_changed)

func _init_audio() -> void:
    if ResourceLoader.exists("res://assets/audio/sfx/sfx_glitch_growl.wav"):
        sfx_growl = ResourceLoader.load("res://assets/audio/sfx/sfx_glitch_growl.wav")
    if ResourceLoader.exists("res://assets/audio/sfx/sfx_metal_footstep.wav"):
        sfx_step = ResourceLoader.load("res://assets/audio/sfx/sfx_metal_footstep.wav")

func _play_horror_sound(stream: AudioStream, db_vol: float = -6.0) -> void:
    if not stream or not audio_spatial or not is_inside_tree():
        return
    if not audio_spatial.playing:
        audio_spatial.stream = stream
        audio_spatial.volume_db = db_vol
        audio_spatial.play()

func _setup_limbs() -> void:
    leg_l = find_child("Leg_L", true, false) as Node3D
    leg_r = find_child("Leg_R", true, false) as Node3D
    arm_l = find_child("Arm_L", true, false) as Node3D
    arm_r = find_child("Arm_R", true, false) as Node3D
    torso = find_child("Torso", true, false) as Node3D
    head = find_child("Head", true, false) as Node3D

    if leg_l:
        rest_leg_l_rot = leg_l.rotation
    if leg_r:
        rest_leg_r_rot = leg_r.rotation
    if arm_l:
        rest_arm_l_rot = arm_l.rotation
        rest_arm_l_pos = arm_l.position
    if arm_r:
        rest_arm_r_rot = arm_r.rotation
        rest_arm_r_pos = arm_r.position
    if torso:
        rest_torso_pos = torso.position
        rest_torso_rot = torso.rotation
    if head:
        rest_head_rot = head.rotation
        rest_head_pos = head.position

    
    var players = get_tree().get_nodes_in_group("player")
    if not players.is_empty():
        current_target = players[0] as RoxyVance
        if not current_target.player_died.is_connected(_on_player_died):
            current_target.player_died.connect(_on_player_died)

    call_deferred("_connect_to_pickups")

func _connect_to_pickups() -> void:
    if not is_inside_tree():
        return
    var root = get_tree().current_scene
    if root:
        var pickups = root.find_children("", "MemoryCorePickupProp", true, false)
        for p in pickups:
            if not p.core_collected.is_connected(_on_core_collected):
                p.core_collected.connect(_on_core_collected)

func _on_core_collected(_core_id: String) -> void:
    if is_dormant:
        wake_up()

func wake_up() -> void:
    if not is_dormant:
        return
    is_dormant = false
    print("[GlitchWalker] Stasis lockdown disengaged! Engaging pursuit.")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue(
            "navmesh_warning",
            "WARNING: Entity active in sector! Defense protocol engaged. Use [F] to discharge your EMP shockwave!"
        )

func _on_player_died() -> void:
    is_stunned = false
    stun_timer = 0.0
    current_health = max_health
    global_position = initial_spawn_position
    rotation = initial_spawn_rotation
    velocity = Vector3.ZERO
    current_cooldown = 3.5
    is_dormant = was_initially_dormant
    print("[GlitchWalker] Player died. AI state reset to sector spawn position.")



func _on_difficulty_changed(_val: float, _name: String) -> void:
    _update_difficulty_parameters()

func _update_difficulty_parameters() -> void:
    if has_node("/root/DifficultyManager"):
        var dm = get_node("/root/DifficultyManager")
        print("[GlitchWalker] Updated parameters for difficulty: ", dm.get_difficulty_name())

func get_effective_speed() -> float:
    var mult = 1.0
    if has_node("/root/DifficultyManager"):
        mult = get_node("/root/DifficultyManager").get_enemy_speed_multiplier()
    return base_speed * mult

func get_effective_damage() -> int:
    var mult = 1.0
    if has_node("/root/DifficultyManager"):
        mult = get_node("/root/DifficultyManager").get_enemy_damage_multiplier()
    return int(round(base_damage * mult))

func take_damage(amount: int, damage_source: String = "emp") -> void:
    if is_dead:
        return
    if is_dormant:
        wake_up()
    current_health = maxi(0, current_health - amount)
    print("[GlitchWalker] Hit by ", damage_source, "! Health: ", current_health, "/", max_health)
    if current_health <= 0:
        _die()
    else:
        stagger(4.5)


func _die() -> void:
    if is_dead:
        return
    is_dead = true
    enemy_defeated.emit()
    velocity = Vector3.ZERO
    print("[GlitchWalker] Entity de-allocated! Overloaded by EMP burst.")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue(
            "enemy_killed",
            "Glitch Walker entity memory deallocated. Threat neutralized, Roxy."
        )
    if visual_mesh:
        var tween = create_tween()
        if tween:
            tween.tween_property(visual_mesh, "scale", Vector3.ZERO, 0.35)
            tween.tween_callback(queue_free)
            return
    queue_free()

func stagger(duration: float = 8.5) -> void:
    if is_dead:
        return
    is_stunned = true
    stun_timer = duration
    velocity = Vector3.ZERO
    print("[GlitchWalker] Staggered by EMP burst! AI loop frozen for ", duration, "s.")

func _physics_process(delta: float) -> void:
    # If Map Viewer or Subroutine Terminal modal is open, freeze pursuit so player can inspect undisturbed
    if is_inside_tree():
        var root = get_tree().root
        if root:
            var map_modal = root.find_child("MapViewerModal", true, false)
            if map_modal and ("is_open" in map_modal and map_modal.is_open or map_modal.visible):
                velocity = Vector3.ZERO
                _update_stalk_animation(delta)
                return
            var term = root.find_child("SubroutineTerminal", true, false)
            if term and term.visible:
                velocity = Vector3.ZERO
                _update_stalk_animation(delta)
                return

    # Stun state from EMP blast
    if is_stunned:
        stun_timer -= delta
        velocity = Vector3.ZERO
        _update_stalk_animation(delta)
        if visual_mesh:
            visual_mesh.position = Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06))
        if stun_timer <= 0.0:
            is_stunned = false
            if visual_mesh:
                visual_mesh.position = Vector3.ZERO
            print("[GlitchWalker] Stun state expired. Resuming pursuit thread.")
        return

    # Pulsating organic glitch distortion animation
    pulse_time += delta * 4.0
    if visual_mesh:
        var scale_pulse = 1.0 + 0.06 * sin(pulse_time)
        visual_mesh.scale = Vector3(scale_pulse, 1.0 + 0.04 * cos(pulse_time * 1.3), scale_pulse)

    if current_cooldown > 0:
        current_cooldown -= delta

    if not current_target:
        var players = get_tree().get_nodes_in_group("player")
        if not players.is_empty():
            current_target = players[0] as RoxyVance
            if not current_target.player_died.is_connected(_on_player_died):
                current_target.player_died.connect(_on_player_died)

    if not current_target or current_target.current_health <= 0:
        velocity = Vector3.ZERO
        _update_stalk_animation(delta)
        return

    # If player is hiding in a locker or in post-death reboot invulnerability, drop aggro
    if ("is_invulnerable" in current_target and current_target.is_invulnerable) or ("is_hiding" in current_target and current_target.is_hiding):
        if patrol_points.size() > 0 and not is_dormant:
            var p_target = patrol_points[current_patrol_index]
            p_target.y = global_position.y
            var p_dist = global_position.distance_to(p_target)
            if p_dist < 1.8:
                current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
            else:
                look_at(p_target, Vector3.UP)
                var p_dir = (p_target - global_position).normalized()
                var p_speed = get_effective_speed() * 0.35
                velocity.x = p_dir.x * p_speed
                velocity.z = p_dir.z * p_speed
                velocity.y = -9.8 * delta
                move_and_slide()
        else:
            velocity = Vector3.ZERO
        _update_stalk_animation(delta)
        return

    # If dormant in stasis, check if player has breached the security corridor or approached closely
    if is_dormant:
        var dist_to_player = global_position.distance_to(current_target.global_position)
        if dist_to_player < 6.0 or current_target.global_position.z > 3.0:
            wake_up()
        else:
            velocity = Vector3.ZERO
            _update_stalk_animation(delta)
            return

    # Footstep and growl timers for suspense and horror
    growl_timer -= delta
    if growl_timer <= 0.0 and not is_dormant and not is_dead and not is_stunned:
        _play_horror_sound(sfx_growl, -6.0)
        growl_timer = randf_range(5.0, 9.0)

    var h_spd = Vector2(velocity.x, velocity.z).length()
    if h_spd > 0.2 and not is_dead and not is_stunned:
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            _play_horror_sound(sfx_step, -12.0)
            footstep_timer = 0.65

    var dist = global_position.distance_to(current_target.global_position)
    var is_player_sprinting = (current_target.velocity.length() > 5.0)
    var effective_detection_range = 22.0 if is_player_sprinting else detection_range

    if dist <= effective_detection_range:
        var target_pos = current_target.global_position
        target_pos.y = global_position.y
        look_at(target_pos, Vector3.UP)

        if dist > attack_range:
            var dir = (target_pos - global_position).normalized()
            velocity.x = dir.x * get_effective_speed()
            velocity.z = dir.z * get_effective_speed()
            velocity.y = -9.8 * delta
            move_and_slide()
        else:
            velocity = Vector3.ZERO
            if current_cooldown <= 0:
                _perform_attack()
    elif patrol_points.size() > 0 and not is_dormant:
        var p_target = patrol_points[current_patrol_index]
        p_target.y = global_position.y
        var p_dist = global_position.distance_to(p_target)
        if p_dist < 1.8:
            current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
        else:
            look_at(p_target, Vector3.UP)
            var p_dir = (p_target - global_position).normalized()
            var p_speed = get_effective_speed() * 0.45
            velocity.x = p_dir.x * p_speed
            velocity.z = p_dir.z * p_speed
            velocity.y = -9.8 * delta
            move_and_slide()
    else:
        velocity = Vector3.ZERO

    _update_stalk_animation(delta)

func _update_stalk_animation(delta: float) -> void:
    var h_speed = Vector2(velocity.x, velocity.z).length()

    if h_speed > 0.15 and not is_dead and not is_stunned:
        # Advance predatory stalk rhythm based on movement speed
        stalk_cycle_phase += delta * h_speed * 2.5
        var swing = sin(stalk_cycle_phase)

        # Digitigrade raptor leg stride
        var leg_swing_angle = deg_to_rad(38.0)
        if leg_l:
            leg_l.rotation.x = rest_leg_l_rot.x + swing * leg_swing_angle
        if leg_r:
            leg_r.rotation.x = rest_leg_r_rot.x - swing * leg_swing_angle

        # Predatory talons reaching forward and slashing in rhythm
        var arm_swing_angle = deg_to_rad(28.0)
        if arm_l:
            arm_l.rotation.x = rest_arm_l_rot.x - swing * arm_swing_angle + deg_to_rad(14.0)
        if arm_r:
            arm_r.rotation.x = rest_arm_r_rot.x + swing * arm_swing_angle + deg_to_rad(14.0)

        # Hunched predatory torso bobbing and prowling twist
        var bob = abs(sin(stalk_cycle_phase)) * 0.045
        if torso:
            torso.position.y = rest_torso_pos.y - bob
            torso.rotation.x = rest_torso_rot.x + deg_to_rad(8.0)
            torso.rotation.y = rest_torso_rot.y + swing * deg_to_rad(4.0)

        # Predatory twitching skull
        if head:
            head.position.y = rest_head_pos.y - bob
            head.rotation.x = rest_head_rot.x - deg_to_rad(6.0) + sin(stalk_cycle_phase * 2.0) * deg_to_rad(3.0)

        if arm_l:
            arm_l.position.y = rest_arm_l_pos.y - bob
        if arm_r:
            arm_r.position.y = rest_arm_r_pos.y - bob
    else:
        # Smooth interpolation back to rest pose
        var blend_speed = clampf(delta * 8.0, 0.0, 1.0)
        if leg_l:
            leg_l.rotation.x = lerp_angle(leg_l.rotation.x, rest_leg_l_rot.x, blend_speed)
        if leg_r:
            leg_r.rotation.x = lerp_angle(leg_r.rotation.x, rest_leg_r_rot.x, blend_speed)
        if arm_l:
            arm_l.rotation.x = lerp_angle(arm_l.rotation.x, rest_arm_l_rot.x, blend_speed)
            arm_l.position.y = lerp(arm_l.position.y, rest_arm_l_pos.y, blend_speed)
        if arm_r:
            arm_r.rotation.x = lerp_angle(arm_r.rotation.x, rest_arm_r_rot.x, blend_speed)
            arm_r.position.y = lerp(arm_r.position.y, rest_arm_r_pos.y, blend_speed)

        if torso:
            torso.position = torso.position.lerp(rest_torso_pos, blend_speed)
            torso.rotation.x = lerp_angle(torso.rotation.x, rest_torso_rot.x, blend_speed)
            torso.rotation.y = lerp_angle(torso.rotation.y, rest_torso_rot.y, blend_speed)

        if head:
            head.position.y = lerp(head.position.y, rest_head_pos.y, blend_speed)
            head.rotation.x = lerp_angle(head.rotation.x, rest_head_rot.x, blend_speed)

func _perform_attack() -> void:
    current_cooldown = attack_cooldown
    var dmg = get_effective_damage()
    print("[GlitchWalker] Attacking Roxy for ", dmg, " damage!")
    attack_landed.emit(dmg)
    if current_target:
        current_target.take_damage(dmg, "enemy")

