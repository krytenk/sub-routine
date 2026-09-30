extends Area3D
class_name JumpscareTrigger

# Sub-Routine Horror Jumpscare Trigger
# Fires sudden acoustic shockwave, camera trauma, glitch apparition flash, and lighting brownout.

signal jumpscare_activated

@export var jumpscare_id: String = ""
@export var dialogue_key: String = "jumpscare"
@export var sound_clip: String = "res://assets/audio/sfx/sfx_jumpscare_sting.wav"
@export var target_light: Light3D = null
@export var trauma_amount: float = 0.9

static var triggered_jumpscares: Dictionary = {}

var triggered: bool = false
var audio_player: AudioStreamPlayer = null

func _ready() -> void:
    collision_layer = 0
    collision_mask = 2 # Player layer
    body_entered.connect(_on_body_entered)
    
    if jumpscare_id.is_empty():
        jumpscare_id = name + "_" + str(int(round(position.x))) + "_" + str(int(round(position.z)))
    if triggered_jumpscares.get(jumpscare_id, false):
        triggered = true
    
    audio_player = AudioStreamPlayer.new()
    audio_player.name = "JumpscareAudio"
    audio_player.bus = "Master"
    add_child(audio_player)
    if ResourceLoader.exists(sound_clip):
        audio_player.stream = ResourceLoader.load(sound_clip)

func _on_body_entered(body: Node3D) -> void:
    if triggered:
        return
    if not (body is CharacterBody3D or body.name == "RoxyVance"):
        return
        
    triggered = true
    triggered_jumpscares[jumpscare_id] = true
    print("[JumpscareTrigger] Jumpscare triggered at: ", global_position, " (id: ", jumpscare_id, ")")
    jumpscare_activated.emit()

    # 1. Play harsh jumpscare sting
    if audio_player and audio_player.stream:
        audio_player.play()

    # 2. Camera violent trauma shake
    if body.has_method("apply_trauma"):
        body.apply_trauma(trauma_amount)

    # 3. Spawn brief flashing glitch apparition in front of player
    _spawn_glitch_apparition(body)

    # 4. Brownout lighting flicker
    _flicker_lighting()

    # 5. Overseer creepy reaction dialogue
    if is_inside_tree() and has_node("/root/TheOverseer"):
        get_tree().create_timer(1.2).timeout.connect(func():
            if has_node("/root/TheOverseer"):
                get_node("/root/TheOverseer").trigger_dialogue(dialogue_key)
        )

func _spawn_glitch_apparition(player: Node3D) -> void:
    var apparition = MeshInstance3D.new()
    var quad = QuadMesh.new()
    quad.size = Vector2(1.6, 2.2)
    apparition.mesh = quad
    
    var mat = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(1.0, 0.1, 0.2, 0.85)
    apparition.material_override = mat
    
    var parent_node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else (get_parent() if is_inside_tree() else null)
    if parent_node:
        parent_node.add_child(apparition)
        if player and player.is_inside_tree():
            var fwd = -player.global_transform.basis.z
            apparition.global_position = player.global_position + fwd * 1.6 + Vector3(0, 0.4, 0)
            apparition.look_at(player.global_position + Vector3(0, 1.2, 0), Vector3.UP)
    
    # Quick twitch flicker and disappear
    var tween = create_tween()
    if tween:
        tween.tween_property(mat, "albedo_color:a", 0.1, 0.08)
        tween.tween_property(mat, "albedo_color:a", 0.9, 0.06)
        tween.tween_property(mat, "albedo_color:a", 0.0, 0.22)
        tween.tween_callback(apparition.queue_free)

func _flicker_lighting() -> void:
    var lights: Array[Light3D] = []
    if target_light:
        lights.append(target_light)
    else:
        # Find closest light in tree
        var all_lights = get_tree().get_nodes_in_group("lights")
        for l in all_lights:
            if l is Light3D and global_position.distance_to(l.global_position) < 18.0:
                lights.append(l)

    for l in lights:
        var orig_energy = l.light_energy
        var tw = create_tween()
        if tw:
            tw.tween_property(l, "light_energy", 0.05, 0.05)
            tw.tween_interval(0.4)
            tw.tween_property(l, "light_energy", orig_energy * 1.5, 0.08)
            tw.tween_property(l, "light_energy", orig_energy, 0.15)
