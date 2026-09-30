extends Area3D
class_name EnvironmentalHazard

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

# Sub-Routine Environmental Hazard (Toxic Coolant, Electrified Floor, Steam Vent)
# Demonstrates Roxy Vance's 90s gaming trope immunity:
# Roxy takes ZERO damage from environmental hazards, while direct enemy attacks inflict full damage.

signal hazard_triggered(target_name: String, damage_attempted: int)

@export var hazard_type: String = "toxic_coolant" # toxic_coolant, electric_busbar, steam_vent
@export var damage_per_tick: int = 40
@export var tick_interval: float = 1.0

var active_targets: Array[Node3D] = []
var tick_timer: float = 0.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
    if not active_targets.has(body):
        active_targets.append(body)
        _apply_hazard(body)

func _on_body_exited(body: Node3D) -> void:
    active_targets.erase(body)

func _process(delta: float) -> void:
    if active_targets.is_empty():
        return

    tick_timer += delta
    if tick_timer >= tick_interval:
        tick_timer = 0.0
        for target in active_targets:
            _apply_hazard(target)

func _apply_hazard(target: Node3D) -> void:
    hazard_triggered.emit(target.name, damage_per_tick)
    
    if target.has_method("take_damage"):
        # Explicitly specifies source_type as "environmental"
        target.take_damage(damage_per_tick, "environmental")
        if target is RoxyVance:
            print("[Hazard] Environmental hazard '", hazard_type, "' triggered on Roxy Vance. Damage absorbed: 0 taken.")
    else:
        print("[Hazard] Environmental hazard triggered on non-damageable target: ", target.name)
