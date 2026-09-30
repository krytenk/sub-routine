extends Area3D
class_name MemoryCorePickupProp

# Cybernetic Memory Core Collectible Prop
# Emits pickup signal and provides rotating 3D collectible visuals

signal core_collected(core_id: String)

@export var core_id: String = "CORE_ALPHA_01"
@onready var model_node: Node3D = $Model

var hover_phase: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	hover_phase += delta * 2.8
	if model_node:
		model_node.rotate_y(2.2 * delta)
		model_node.position.y = 0.45 + sin(hover_phase) * 0.09

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		print("[MemoryCore] Core collected: ", core_id)
		core_collected.emit(core_id)

		var cipher_str: String = ""
		var root = get_tree().current_scene
		if root:
			var puzzle = root.find_child("PrimaryPuzzle", true, false)
			if puzzle and "generated_code" in puzzle and puzzle.generated_code != "":
				cipher_str = puzzle.generated_code

		if is_inside_tree() and has_node("/root/TheOverseer"):
			if cipher_str != "":
				get_node("/root/TheOverseer").trigger_dialogue(
					"puzzle_solved",
					"Memory Core decoded: Register Cipher is [ " + cipher_str + " ]. Enter it into the CRT terminal to unlock the blast door."
				)
			else:
				get_node("/root/TheOverseer").trigger_dialogue(
					"puzzle_solved",
					"Memory core [" + core_id + "] loaded into thread stack. Address pointer resolved."
				)

		if is_inside_tree():
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("update_objective"):
				if cipher_str != "":
					hud.update_objective("Enter Register Cipher [ " + cipher_str + " ] at CRT Terminal [E]")
				else:
					hud.update_objective("Access Subroutine Terminal [E] to dereference gate pointer")

		queue_free()
