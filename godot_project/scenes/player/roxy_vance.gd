extends CharacterBody3D
class_name RoxyVance

# Roxanne "Roxy" Vance
# 90s Survival Horror Protagonist
# Takes ZERO environmental damage; takes damage ONLY from direct enemy attacks.
# Features Stamina and Fatigue Sprint mechanics.

signal health_changed(current_hp: int, max_hp: int)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal player_died
signal out_of_bounds_triggered
signal player_exhausted(is_exhausted: bool)
signal emp_fired(cooldown: float)
signal emp_cooldown_updated(current: float, max_time: float)
signal emp_upgraded(new_level: int)
signal crouch_state_changed(is_crouching: bool)
signal hiding_state_changed(is_hiding: bool)
signal fall_damage_taken(damage: int)
signal player_jumped

@export var max_health: int = 100
var current_health: int = 100

@export var max_stamina: float = 100.0
var current_stamina: float = 100.0
@export var stamina_drain_rate: float = 24.0
@export var stamina_regen_rate: float = 16.0
var is_exhausted: bool = false

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.2
var is_crouching: bool = false
var is_in_duct: bool = false
var has_superweapon: bool = false
var is_dead: bool = false

@export var emp_cooldown: float = 8.0
var emp_current_timer: float = 0.0
var emp_upgrade_level: int = 1
var emp_pulse_radius: float = 8.0
var emp_pulse_damage: int = 60
@export var rotation_speed: float = 3.5
@export var gravity: float = 9.8
@export var jump_velocity: float = 5.4

var mouse_sensitivity: float = 0.003
var wall_bump_cooldown: float = 0.0
var is_third_person: bool = true
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

var is_hiding: bool = false
var is_on_ladder: bool = false
var ladder_speed: float = 3.5
var current_ladder_node: Node3D = null
var prev_vertical_velocity: float = 0.0
var was_airborne_last_frame: bool = false

# Articulated Limb Nodes & Walk Cycle Animation
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

var walk_cycle_phase: float = 0.0
var idle_breath_phase: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D if has_node("CameraPivot/SpringArm3D") else null
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D if has_node("CameraPivot/SpringArm3D/Camera3D") else ($CameraPivot/Camera3D if has_node("CameraPivot/Camera3D") else null)
@onready var interaction_ray: RayCast3D = $CameraPivot/InteractionRay
@onready var mesh_instance: Node3D = $ModelAnchor

var camera_trauma: float = 0.0
var heartbeat_player: AudioStreamPlayer = null
var heartbeat_cooldown: float = 0.0
var last_safe_position: Vector3 = Vector3.ZERO
var stuck_duration: float = 0.0
var stuck_reference_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
    current_health = max_health
    current_stamina = max_stamina
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(45.0)
    floor_stop_on_slope = true
    health_changed.emit(current_health, max_health)
    stamina_changed.emit(current_stamina, max_stamina)
    _setup_limbs()
    if not _is_terminal_open():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _apply_camera_perspective()
    
    heartbeat_player = AudioStreamPlayer.new()
    heartbeat_player.name = "HeartbeatPlayer"
    heartbeat_player.bus = "Master"
    add_child(heartbeat_player)
    if ResourceLoader.exists("res://assets/audio/sfx/sfx_heartbeat.wav"):
        heartbeat_player.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_heartbeat.wav")

    if is_inside_tree() and has_node("/root/LevelManager"):
        var lm = get_node("/root/LevelManager")
        if "emp_upgrade_level" in lm and lm.emp_upgrade_level > 1:
            set_emp_upgrade_level(lm.emp_upgrade_level)

func apply_trauma(amount: float) -> void:
    camera_trauma = clampf(camera_trauma + amount, 0.0, 1.0)

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



func _input(event: InputEvent) -> void:
    # Click to capture mouse if window lost focus
    if event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _is_terminal_open():
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            get_viewport().set_input_as_handled()
            return

    # Toggle camera view between 3rd-Person and 1st-Person with 'V'
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_V and not _is_terminal_open():
            toggle_camera_perspective()
            get_viewport().set_input_as_handled()
            return
        # Emergency unstuck hotkey with 'U' or 'F1'
        if (event.keycode == KEY_U or event.keycode == KEY_F1) and not _is_terminal_open():
            execute_unstuck()
            get_viewport().set_input_as_handled()
            return

func execute_unstuck() -> void:
    velocity = Vector3.ZERO
    var target_pos = last_safe_position + Vector3(0.0, 0.4, 0.0)

    # If last safe position is uninitialized or too close to current position, search for a level spawn point
    if target_pos.distance_to(global_position) < 0.6 or last_safe_position == Vector3.ZERO:
        var tree = get_tree()
        var found_spawn = false
        if tree and tree.current_scene:
            var spawn = tree.current_scene.find_child("SpawnPoint", true, false)
            if not spawn:
                var container = tree.current_scene.find_child("LevelContainer", true, false)
                if container and container.get_child_count() > 0:
                    spawn = container.get_child(0).find_child("SpawnPoint", true, false)
            if spawn:
                target_pos = spawn.global_position + Vector3(0.0, 0.35, 0.0)
                found_spawn = true
        if not found_spawn:
            # Fallback: leap backward and upward into open air
            target_pos = global_position + Vector3(0.0, 1.2, 0.0) + transform.basis.z * 1.5

    global_position = target_pos
    move_and_slide()
    print("[Roxy Vance] Emergency unstuck protocol executed. Teleported to: ", global_position)

    var hud = null
    if is_inside_tree() and get_tree() and get_tree().root:
        hud = get_tree().root.find_child("HUD", true, false)
    if hud and hud.has_method("display_overseer_message"):
        hud.display_overseer_message("[ UNSTUCK RECOVERY PROTOCOL ]\nThread coordinates corrected. Geometry pinch cleared.", "")
    if is_inside_tree() and has_node("/root/AudioManager"):
        get_node("/root/AudioManager").play_sfx("sfx_jump")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("unstuck_recovered", "Thread deadlock resolved. Resuming runtime traversal.")

func _unhandled_input(event: InputEvent) -> void:
    if _is_terminal_open():
        return
    if event is InputEventMouseMotion:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            rotate_y(-event.relative.x * mouse_sensitivity)
            if camera_pivot:
                camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
                camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -deg_to_rad(70.0), deg_to_rad(60.0))


func _physics_process(delta: float) -> void:
    if invulnerability_timer > 0.0:
        invulnerability_timer -= delta
        is_invulnerable = (invulnerability_timer > 0.0)

    if is_dead:
        velocity.x = 0
        velocity.z = 0
        move_and_slide()
        _update_walk_animation(delta, 0.0)
        return

    if is_hiding:
        velocity = Vector3.ZERO
        move_and_slide()
        _update_walk_animation(delta, 0.0)
        return

    if _is_terminal_open():
        velocity.x = 0
        velocity.z = 0
        move_and_slide()
        _update_walk_animation(delta, 0.0)
        return

    # Ladder movement mode
    if is_on_ladder:
        # Jump off ladder with Spacebar
        if Input.is_action_just_pressed("jump"):
            set_on_ladder(false, null)
            velocity.y = jump_velocity * 0.95
            var jump_away = transform.basis.z
            velocity.x = jump_away.x * 2.8
            velocity.z = jump_away.z * 2.8
            player_jumped.emit()
            if is_inside_tree() and has_node("/root/AudioManager"):
                get_node("/root/AudioManager").play_sfx("sfx_jump")
            move_and_slide()
            return

        var input_y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
        var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

        # Dismount if stepping backwards while on the ground
        if is_on_floor() and input_y < -0.1:
            set_on_ladder(false, null)
            return

        velocity.y = input_y * ladder_speed

        # Allow horizontal strafing and forward step-off when near landings
        var ladder_right = transform.basis.x
        var ladder_fwd = -transform.basis.z
        if abs(input_x) > 0.2:
            velocity.x = ladder_right.x * input_x * walk_speed * 0.6
            velocity.z = ladder_right.z * input_x * walk_speed * 0.6
        elif input_y > 0.5:
            velocity.x = ladder_fwd.x * 1.2
            velocity.z = ladder_fwd.z * 1.2
        else:
            velocity.x = 0.0
            velocity.z = 0.0

        move_and_slide()
        _update_walk_animation(delta, maxf(abs(input_y) * ladder_speed, abs(input_x) * walk_speed))
        return

    if not is_on_floor():
        velocity.y -= gravity * delta

    prev_vertical_velocity = velocity.y
    was_airborne_last_frame = not is_on_floor()

    # Keyboard camera turning & pitching (Arrow keys)
    var turn_axis = 0.0
    if Input.is_key_pressed(KEY_LEFT):
        turn_axis += 1.0
    if Input.is_key_pressed(KEY_RIGHT):
        turn_axis -= 1.0
    if turn_axis != 0.0:
        rotate_y(turn_axis * rotation_speed * delta)

    var pitch_axis = 0.0
    if Input.is_key_pressed(KEY_UP):
        pitch_axis += 1.0
    if Input.is_key_pressed(KEY_DOWN):
        pitch_axis -= 1.0
    if pitch_axis != 0.0 and camera_pivot:
        camera_pivot.rotate_x(pitch_axis * rotation_speed * delta)
        camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -deg_to_rad(70.0), deg_to_rad(60.0))

    var move_dir = Vector3.ZERO

    var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    var is_moving = (input_x != 0.0 or input_z != 0.0)

    # Crouch / Crawl input handling
    if Input.is_action_just_pressed("crouch") and not is_in_duct and not is_on_ladder:
        set_crouch(not is_crouching)

    # Stamina & Sprint logic
    var wants_sprint = Input.is_action_pressed("sprint") and is_moving and not is_crouching and not is_in_duct
    if is_exhausted:
        wants_sprint = false
        if current_stamina >= 25.0:
            is_exhausted = false
            player_exhausted.emit(false)

    var speed = walk_speed
    if is_crouching or is_in_duct:
        speed = crouch_speed
    elif wants_sprint and current_stamina > 0.0:
        speed = sprint_speed
        current_stamina = maxf(0.0, current_stamina - stamina_drain_rate * delta)
        stamina_changed.emit(current_stamina, max_stamina)
        if current_stamina <= 0.0:
            is_exhausted = true
            player_exhausted.emit(true)
            print("[Roxy Vance] Stamina depleted! Roxy is fatigued.")
    elif not wants_sprint and current_stamina < max_stamina:
        current_stamina = minf(max_stamina, current_stamina + stamina_regen_rate * delta)
        stamina_changed.emit(current_stamina, max_stamina)

    var forward = -transform.basis.z
    var right = transform.basis.x
    move_dir = (right * input_x + forward * -input_z).normalized()

    if move_dir != Vector3.ZERO:
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    # Smoothly orient player character model to face movement direction
    if mesh_instance:
        if is_moving and (input_x != 0.0 or input_z != 0.0):
            var target_angle = atan2(-input_x, -input_z)
            mesh_instance.rotation.y = lerp_angle(mesh_instance.rotation.y, target_angle, clampf(delta * 12.0, 0.0, 1.0))
        else:
            mesh_instance.rotation.y = lerp_angle(mesh_instance.rotation.y, 0.0, clampf(delta * 6.0, 0.0, 1.0))

    # Jump handling (Spacebar)
    if Input.is_action_just_pressed("jump"):
        jump()

    move_and_slide()
    _update_walk_animation(delta, speed)

    # Update safe grounded position for recovery
    if is_on_floor() and global_position.y >= -1.5:
        last_safe_position = global_position

    # Auto-unstuck detection: if attempting to move for > 2.0s without displacement and pinched on geometry
    if is_moving:
        stuck_duration += delta
        if stuck_duration >= 2.0:
            var dist_moved = global_position.distance_to(stuck_reference_pos)
            if dist_moved < 0.2 and (is_on_wall() or is_on_ceiling()):
                print("[Roxy Vance] Persistent collision pinch detected. Executing automatic unstuck.")
                stuck_duration = 0.0
                execute_unstuck()
            else:
                stuck_duration = 0.0
                stuck_reference_pos = global_position
    else:
        stuck_duration = 0.0
        stuck_reference_pos = global_position

    # Fall damage detection
    if was_airborne_last_frame and is_on_floor():
        if prev_vertical_velocity < -8.2:
            var fall_speed = abs(prev_vertical_velocity)
            var fall_dmg = int(round((fall_speed - 7.5) * 8.0))
            if fall_dmg > 0:
                print("[Roxy Vance] Hard landing from height! Fall vel: ", prev_vertical_velocity, " -> Damage: ", fall_dmg)
                take_damage(fall_dmg, "fall")
                apply_trauma(clampf(float(fall_dmg) / 25.0, 0.4, 1.0))
                fall_damage_taken.emit(fall_dmg)
                if is_inside_tree() and has_node("/root/AudioManager"):
                    get_node("/root/AudioManager").play_sfx("sfx_fall_impact")
                if is_inside_tree() and has_node("/root/TheOverseer"):
                    get_node("/root/TheOverseer").trigger_dialogue("fall_damage")

    # Out of bounds safety check (void fall)
    if global_position.y < -15.0:
        out_of_bounds_triggered.emit()
        if is_inside_tree() and has_node("/root/TheOverseer"):
            get_node("/root/TheOverseer").report_out_of_bounds(self)

    # Trauma shake decay and application to camera offsets
    if camera_trauma > 0.0:
        camera_trauma = maxf(0.0, camera_trauma - delta * 1.8)
        var shake_amount = camera_trauma * camera_trauma
        if camera:
            camera.h_offset = (randf() * 2.0 - 1.0) * 0.18 * shake_amount
            camera.v_offset = (randf() * 2.0 - 1.0) * 0.18 * shake_amount
    elif camera and (camera.h_offset != 0.0 or camera.v_offset != 0.0):
        camera.h_offset = 0.0
        camera.v_offset = 0.0

    # Proximity heartbeat horror suspense
    heartbeat_cooldown = maxf(0.0, heartbeat_cooldown - delta)
    if heartbeat_cooldown <= 0.0 and heartbeat_player and heartbeat_player.stream and is_inside_tree():
        var min_dist = 999.0
        var enemies = get_tree().get_nodes_in_group("enemies")
        for enemy in enemies:
            if enemy is Node3D and is_instance_valid(enemy):
                if "is_dead" in enemy and enemy.is_dead:
                    continue
                var d = global_position.distance_to(enemy.global_position)
                if d < min_dist:
                    min_dist = d
        if min_dist < 9.0:
            var intensity = clampf(1.0 - (min_dist / 9.0), 0.0, 1.0)
            heartbeat_player.volume_db = lerp(-14.0, 0.0, intensity)
            heartbeat_player.pitch_scale = lerp(0.85, 1.35, intensity)
            heartbeat_player.play()
            heartbeat_cooldown = lerp(1.1, 0.52, intensity)

    # EMP pulse recharge timer
    if emp_current_timer > 0.0:
        emp_current_timer = maxf(0.0, emp_current_timer - delta)
        emp_cooldown_updated.emit(emp_current_timer, emp_cooldown)

    # EMP pulse or Superweapon trigger
    if Input.is_action_just_pressed("emp_pulse"):
        if has_superweapon:
            fire_superweapon_burst()
        else:
            fire_emp_pulse()

    # Interaction handling
    if Input.is_action_just_pressed("interact"):
        _attempt_interaction()

func set_emp_upgrade_level(level: int) -> void:
    emp_upgrade_level = clampi(level, 1, 3)
    match emp_upgrade_level:
        1:
            emp_cooldown = 8.0
            emp_pulse_radius = 8.0
            emp_pulse_damage = 60
        2:
            emp_cooldown = 5.5
            emp_pulse_radius = 11.0
            emp_pulse_damage = 85
        3:
            emp_cooldown = 3.5
            emp_pulse_radius = 14.5
            emp_pulse_damage = 120
    emp_cooldown_updated.emit(emp_current_timer, emp_cooldown)

func upgrade_emp(target_level: int = -1) -> int:
    if target_level > 0:
        set_emp_upgrade_level(target_level)
    else:
        set_emp_upgrade_level(emp_upgrade_level + 1)
    
    if is_inside_tree() and has_node("/root/LevelManager"):
        get_node("/root/LevelManager").emp_upgrade_level = emp_upgrade_level
    
    emp_upgraded.emit(emp_upgrade_level)
    print("[Roxy Vance] EMP Discharger UPGRADED to MK ", emp_upgrade_level, "! Cooldown: ", emp_cooldown, "s, Radius: ", emp_pulse_radius, "m, Dmg: ", emp_pulse_damage)
    
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("emp_upgraded")
    
    return emp_upgrade_level

func fire_emp_pulse() -> void:
    if is_dead or emp_current_timer > 0.0:
        return
    emp_current_timer = emp_cooldown
    emp_fired.emit(emp_cooldown)
    emp_cooldown_updated.emit(emp_current_timer, emp_cooldown)
    print("[Roxy Vance] EMP Pulse Discharged! (MK ", emp_upgrade_level, ") ", emp_pulse_radius, "m radius shockwave radiated.")

    if is_inside_tree():
        var enemies = get_tree().get_nodes_in_group("enemies")
        for enemy in enemies:
            if enemy is Node3D:
                var dist = global_position.distance_to(enemy.global_position)
                if dist <= emp_pulse_radius:
                    if enemy.has_method("take_damage"):
                        enemy.take_damage(emp_pulse_damage, "emp")
                    elif enemy.has_method("stagger"):
                        enemy.stagger(8.5)

        if has_node("/root/TheOverseer"):
            get_node("/root/TheOverseer").trigger_dialogue("emp_success", "Electromagnetic disruption detected in Sector node. Glitch entity stunned.")

func set_crouch(crouch: bool) -> void:
    if is_crouching == crouch and not is_in_duct:
        return
    is_crouching = crouch or is_in_duct
    crouch_state_changed.emit(is_crouching)

    var col = get_node_or_null("CollisionShape3D")
    if col and col.shape is CapsuleShape3D:
        var capsule = col.shape as CapsuleShape3D
        if is_crouching:
            capsule.height = 0.72
            col.position.y = 0.36
            if camera_pivot:
                camera_pivot.position.y = 0.45
            if mesh_instance:
                mesh_instance.scale = Vector3(1.0, 0.45, 1.0)
        else:
            capsule.height = 1.8
            col.position.y = 0.9
            if camera_pivot:
                camera_pivot.position.y = 1.45
            if mesh_instance:
                mesh_instance.scale = Vector3.ONE

func set_in_duct(in_duct_state: bool) -> void:
    is_in_duct = in_duct_state
    set_crouch(in_duct_state)
    if is_in_duct:
        print("[Roxy Vance] Entered ventilation duct network. Crawl mode engaged.")
        if is_inside_tree() and has_node("/root/TheOverseer"):
            get_node("/root/TheOverseer").trigger_dialogue("duct_crawl")
    else:
        print("[Roxy Vance] Exited ventilation duct network.")

func equip_superweapon() -> void:
    has_superweapon = true
    print("[Roxy Vance] Hyper-Flux Singularity Cannon EQUIPPED! Ready for prototype discharge.")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("cannon_assembled")

func discharge_superweapon() -> bool:
    if not has_superweapon or is_dead:
        return false
    has_superweapon = false
    apply_trauma(0.85)
    print("[Roxy Vance] Hyper-Flux Singularity Cannon DISCHARGED! Blinding particle lance erupted.")
    
    # Meltdown: permanent destruction of weapon to maintain balance
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("cannon_burnout")
    
    return true

func fire_superweapon_burst() -> void:
    if not has_superweapon or is_dead:
        return
    discharge_superweapon()
    if is_inside_tree():
        var enemies = get_tree().get_nodes_in_group("enemies")
        for enemy in enemies:
            if enemy is Node3D and is_instance_valid(enemy):
                var dist = global_position.distance_to(enemy.global_position)
                if dist <= 24.0:
                    if enemy.has_method("take_superweapon_hit"):
                        enemy.take_superweapon_hit()
                    elif enemy.has_method("take_damage"):
                        enemy.take_damage(999, "superweapon")

func jump() -> bool:
    if is_in_duct:
        return false
    if is_crouching:
        set_crouch(false)
        return false
    if not is_on_floor() or is_hiding or is_dead or _is_terminal_open():
        return false
    var jump_force = jump_velocity
    if is_exhausted or current_stamina < 6.0:
        jump_force = jump_velocity * 0.72 # Fatigue jump
    else:
        current_stamina = maxf(0.0, current_stamina - 6.0)
        stamina_changed.emit(current_stamina, max_stamina)
    velocity.y = jump_force
    player_jumped.emit()
    print("[Roxy Vance] Jump executed! Vertical velocity: ", velocity.y)
    if is_inside_tree() and has_node("/root/AudioManager"):
        get_node("/root/AudioManager").play_sfx("sfx_jump")
    return true

func _attempt_interaction() -> void:
    print("[Roxy Vance] Interaction triggered (E key pressed).")
    # 1. Check RayCast direct collider and ancestors
    if interaction_ray and interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider:
            if _try_interact_target(collider):
                return
            if collider.get_parent() and _try_interact_target(collider.get_parent()):
                return
            if collider.get_parent() and collider.get_parent().get_parent() and _try_interact_target(collider.get_parent().get_parent()):
                return

    # 2. Priority check for immediate close-range pickups/components (within 3.0m)
    # Prevents distant terminals or puzzles from intercepting nearby item pickups
    if is_inside_tree():
        var pickups = get_tree().get_nodes_in_group("generator_parts") + get_tree().get_nodes_in_group("pickups")
        var best_pickup: Node = null
        var best_pickup_dist: float = 3.6
        for p in pickups:
            if p is Node3D and (p.has_method("interact") or p.has_method("collect")):
                var d = global_position.distance_to(p.global_position)
                if d < best_pickup_dist:
                    best_pickup_dist = d
                    best_pickup = p
        if best_pickup:
            print("[Roxy Vance] Collecting item via proximity: ", best_pickup.name, " (dist: ", best_pickup_dist, "m)")
            if best_pickup.has_method("interact"):
                best_pickup.call("interact", self)
            elif best_pickup.has_method("collect"):
                best_pickup.call("collect")
            return

    # 3. Proximity fallback: check interactive objects within 2.5 meters (reduced from 8.0m)
    if is_inside_tree():
        var candidates = get_tree().get_nodes_in_group("terminals") + get_tree().get_nodes_in_group("interactive_props") + get_tree().get_nodes_in_group("puzzles")
        var closest_dist: float = 2.5
        var closest_node: Node = null
        for node in candidates:
            if node is Node3D and node.has_method("interact"):
                var d = global_position.distance_to(node.global_position)
                if d < closest_dist:
                    closest_dist = d
                    closest_node = node
        if closest_node:
            _try_interact_target(closest_node)
            return

func _try_interact_target(target: Object) -> bool:
    if target and target.has_method("interact"):
        target.call("interact", self)
        print("[Roxy Vance] Successfully interacted with: ", target)
        return true
    return false

# GDD RULE:
# Takes ZERO environmental damage (coolant, toxic leaks, spikes, lasers).
# Takes damage from direct enemy attacks AND high-altitude falls.
func take_damage(amount: int, source_type: String = "environmental") -> void:
    if source_type == "environmental":
        print("[Roxy Vance] Environmental hazard encountered! Impractical 90s outfit absorbs damage: 0 damage taken.")
        return

    if is_dead:
        return

    if is_invulnerable:
        print("[Roxy Vance] Reboot invulnerability active: direct damage ignored.")
        return

    # Direct enemy attack or fall damage
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    print("[Roxy Vance] Damage taken from ", source_type, "! Health: ", current_health, "/", max_health)

    if current_health <= 0:
        _die()

func set_hiding(hiding: bool) -> void:
    is_hiding = hiding
    hiding_state_changed.emit(is_hiding)
    if is_hiding:
        print("[Roxy Vance] Concealed in stealth locker.")
    else:
        print("[Roxy Vance] Stepped out of stealth locker.")

func set_on_ladder(on_ladder: bool, ladder_node: Node3D = null) -> void:
    is_on_ladder = on_ladder
    current_ladder_node = ladder_node if on_ladder else null
    if on_ladder:
        velocity = Vector3.ZERO

func heal(amount: int) -> void:
    if is_dead:
        return
    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
    print("[Roxy Vance] Health replenished +", amount, " (Current: ", current_health, "/", max_health, ")")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("medkit_used", "Nanite medkit consumed. Patching memory corruption won't prevent the inevitable.")

func _die() -> void:
    if is_dead:
        return
    is_dead = true
    player_died.emit()
    print("[Roxy Vance] Critical fault: Roxy was neutralized by Glitch Walker.")
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").trigger_dialogue("save_threat", "Roxy is offline. Restoring initial thread state.")

    if is_inside_tree():
        var timer = get_tree().create_timer(3.0)
        timer.timeout.connect(_respawn)

func _respawn() -> void:
    is_dead = false
    current_health = max_health
    current_stamina = max_stamina
    is_invulnerable = true
    invulnerability_timer = 4.0
    health_changed.emit(current_health, max_health)
    stamina_changed.emit(current_stamina, max_stamina)

    var spawn_pos = Vector3(0, 0.5, -10)
    var spawn_rot = Vector3(0, PI, 0)
    if is_inside_tree() and get_tree() and get_tree().current_scene:
        var root = get_tree().current_scene
        var lvl_container = root.find_child("LevelContainer", true, false)
        var spawn: Marker3D = null
        if lvl_container:
            spawn = lvl_container.find_child("SpawnPoint", true, false) as Marker3D
        if not spawn:
            spawn = root.find_child("SpawnPoint", true, false) as Marker3D
        if spawn:
            spawn_pos = spawn.global_position
            spawn_rot = spawn.global_rotation

    global_position = spawn_pos
    rotation = spawn_rot
    velocity = Vector3.ZERO
    print("[Roxy Vance] Thread state restored. Roxy re-spawned at sector checkpoint with 4s reboot invulnerability.")


func toggle_camera_perspective() -> void:
    is_third_person = not is_third_person
    _apply_camera_perspective()
    print("[Roxy Vance] Camera perspective toggled: ", "Third-Person" if is_third_person else "First-Person")

func _apply_camera_perspective() -> void:
    var spring = get_node_or_null("CameraPivot/SpringArm3D")
    var ray = get_node_or_null("CameraPivot/InteractionRay")
    if is_third_person:
        if spring:
            spring.spring_length = 2.4
        if mesh_instance:
            mesh_instance.visible = true
        if ray:
            ray.target_position = Vector3(0, 0, -4.5)
    else:
        if spring:
            spring.spring_length = 0.0
        if mesh_instance:
            mesh_instance.visible = false
        if ray:
            ray.target_position = Vector3(0, 0, -3.2)

func _is_terminal_open() -> bool:
    if not is_inside_tree():
        return false
    var term = get_tree().root.find_child("SubroutineTerminal", true, false)
    if term != null and term.visible:
        return true
    var intro = get_tree().root.find_child("IntroSequence", true, false)
    if intro != null and intro.visible:
        return true
    return false

func _update_walk_animation(delta: float, target_speed: float) -> void:
    var h_speed = Vector2(velocity.x, velocity.z).length()
    var on_ground = is_on_floor()

    if on_ground and h_speed > 0.15 and not is_dead and not _is_terminal_open():
        # Advance walk cycle rhythm proportional to ground movement speed
        walk_cycle_phase += delta * h_speed * 2.8
        var swing = sin(walk_cycle_phase)

        # Stride amplitude increases dynamically when sprinting
        var leg_swing_angle = deg_to_rad(34.0) if target_speed <= 5.0 else deg_to_rad(42.0)
        var arm_swing_angle = deg_to_rad(26.0) if target_speed <= 5.0 else deg_to_rad(36.0)

        # Alternating left and right leg stride
        if leg_l:
            leg_l.rotation.x = rest_leg_l_rot.x + swing * leg_swing_angle
        if leg_r:
            leg_r.rotation.x = rest_leg_r_rot.x - swing * leg_swing_angle

        # Opposite arm swing (counter-balance human locomotion)
        if arm_l:
            arm_l.rotation.x = rest_arm_l_rot.x - swing * arm_swing_angle
        if arm_r:
            arm_r.rotation.x = rest_arm_r_rot.x + swing * arm_swing_angle

        # Upper body vertical bounce (2x cycle frequency) and subtle hip roll
        var bob = abs(sin(walk_cycle_phase)) * 0.035
        if torso:
            torso.position.y = rest_torso_pos.y - bob
            torso.rotation.z = rest_torso_rot.z + swing * deg_to_rad(2.2)
            var forward_lean = deg_to_rad(4.0) if target_speed > 5.0 else deg_to_rad(1.8)
            torso.rotation.x = rest_torso_rot.x + forward_lean

        if head:
            head.position.y = rest_head_pos.y - bob
            head.rotation.x = rest_head_rot.x - (deg_to_rad(2.0) if target_speed > 5.0 else 0.0)

        if arm_l:
            arm_l.position.y = rest_arm_l_pos.y - bob
        if arm_r:
            arm_r.position.y = rest_arm_r_pos.y - bob
    elif not on_ground and not is_dead and not _is_terminal_open():
        # Airborne jump/falling pose: tuck legs slightly and raise arms
        var air_blend = clampf(delta * 7.0, 0.0, 1.0)
        if leg_l:
            leg_l.rotation.x = lerp_angle(leg_l.rotation.x, rest_leg_l_rot.x + deg_to_rad(20.0), air_blend)
        if leg_r:
            leg_r.rotation.x = lerp_angle(leg_r.rotation.x, rest_leg_r_rot.x - deg_to_rad(12.0), air_blend)
        if arm_l:
            arm_l.rotation.x = lerp_angle(arm_l.rotation.x, rest_arm_l_rot.x - deg_to_rad(18.0), air_blend)
        if arm_r:
            arm_r.rotation.x = lerp_angle(arm_r.rotation.x, rest_arm_r_rot.x - deg_to_rad(18.0), air_blend)
        if torso:
            torso.rotation.x = lerp_angle(torso.rotation.x, rest_torso_rot.x + deg_to_rad(4.0), air_blend)
    else:
        # Smooth interpolation back to rest pose
        var blend_speed = clampf(delta * 9.0, 0.0, 1.0)
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

        idle_breath_phase += delta * 2.2
        var breath_bob = sin(idle_breath_phase) * 0.006 if not is_dead else 0.0

        if torso:
            torso.position.y = lerp(torso.position.y, rest_torso_pos.y + breath_bob, blend_speed)
            torso.position.x = lerp(torso.position.x, rest_torso_pos.x, blend_speed)
            torso.position.z = lerp(torso.position.z, rest_torso_pos.z, blend_speed)
            torso.rotation.x = lerp_angle(torso.rotation.x, rest_torso_rot.x, blend_speed)
            torso.rotation.z = lerp_angle(torso.rotation.z, rest_torso_rot.z, blend_speed)

        if head:
            head.position.y = lerp(head.position.y, rest_head_pos.y + breath_bob, blend_speed)
            head.rotation.x = lerp_angle(head.rotation.x, rest_head_rot.x, blend_speed)




