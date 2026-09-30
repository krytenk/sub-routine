extends Area3D
class_name ShiftingRoom

# Shifting Dimension Room
# Monitors player orientation. When player turns around 180 degrees, the room shifts its geometry.

signal room_dimensions_shifted(state_index: int)

@export var primary_walls: Node3D
@export var expanded_walls: Node3D
@export var server_monoliths_a: Node3D
@export var server_monoliths_b: Node3D

var current_state: int = 0 # 0 = compressed, 1 = expanded
var tracked_player: RoxyVance = null
var initial_facing_dir: Vector3 = Vector3.FORWARD
var can_shift: bool = true

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _apply_geometry_state()

func _on_body_entered(body: Node3D) -> void:
    if body is RoxyVance:
        tracked_player = body as RoxyVance
        initial_facing_dir = -tracked_player.global_transform.basis.z

func _on_body_exited(body: Node3D) -> void:
    if body == tracked_player:
        tracked_player = null

func _process(_delta: float) -> void:
    if not tracked_player or not can_shift:
        return

    var current_facing = -tracked_player.global_transform.basis.z
    var dot = initial_facing_dir.dot(current_facing)

    # Dot product < -0.7 means player has turned roughly 135 to 180 degrees away
    if dot < -0.7:
        can_shift = false
        trigger_dimension_shift()

    # Reset trigger ability when facing forward again
    elif dot > 0.8 and not can_shift:
        can_shift = true

func trigger_dimension_shift() -> void:
    current_state = 1 if current_state == 0 else 0
    _apply_geometry_state()
    room_dimensions_shifted.emit(current_state)
    print("[ShiftingRoom] Player turned around! Room shifted to state: ", current_state)
    
    if has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").report_dimension_shift()

func _apply_geometry_state() -> void:
    if primary_walls:
        primary_walls.visible = (current_state == 0)
    if expanded_walls:
        expanded_walls.visible = (current_state == 1)
    if server_monoliths_a:
        server_monoliths_a.visible = (current_state == 0)
    if server_monoliths_b:
        server_monoliths_b.visible = (current_state == 1)
