extends Node3D
class_name Level14Sector

# Sector 14: Instruction Pipeline Trench
# Features:
# - 4-stage CPU instruction pipeline (Fetch -> Decode -> Execute -> Writeback)
# - East Overhead Ventilation Duct Bypass [C] above a patrolling Dredge Titan
# - Forward-then-Backtrack Puzzle: Roxy advances to the West Branch Predictor Alcove & South Writeback Bay
#   to recover the Branch Predictor Module & latch the Decode/Execute stages, then backtracks to the
#   North Fetch Dispatcher Terminal to flush the pipeline and open the South Writeback Bulkhead to Sector 15!

var latched_stages: Dictionary = {
	"latch_decode": false,
	"latch_execute": false
}
var has_branch_predictor: bool = false
var is_pipeline_flushed: bool = false

@onready var fetch_terminal: Node3D = find_child("FetchDispatcherTerminal", true, false)
@onready var writeback_terminal: Node3D = find_child("WritebackGateTerminal", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector15ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_14] Instruction Pipeline Trench initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Use East Overhead Ducts [C] to bypass the Dredge Titan. Latch Decode/Execute stages (0/2) & find Branch Predictor.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec14")

	var latches = [
		find_child("PipelineLatch_Decode", true, false),
		find_child("PipelineLatch_Execute", true, false)
	]
	for l in latches:
		if l:
			if l.has_signal("relay_cycled") and not l.is_connected("relay_cycled", _on_stage_latched):
				l.connect("relay_cycled", _on_stage_latched)
			elif l.has_signal("relay_synchronized") and not l.is_connected("relay_synchronized", _on_stage_latched):
				l.connect("relay_synchronized", _on_stage_latched)

	var predictor = find_child("BranchPredictorCipher", true, false)
	if predictor and predictor.has_signal("cipher_collected"):
		if not predictor.is_connected("cipher_collected", _on_predictor_collected):
			predictor.connect("cipher_collected", _on_predictor_collected)

	if fetch_terminal:
		if fetch_terminal.has_signal("terminal_accessed"):
			if not fetch_terminal.is_connected("terminal_accessed", _on_pipeline_terminal_accessed):
				fetch_terminal.connect("terminal_accessed", _on_pipeline_terminal_accessed)
		elif fetch_terminal.has_signal("interacted"):
			if not fetch_terminal.is_connected("interacted", _on_pipeline_terminal_accessed):
				fetch_terminal.connect("interacted", _on_pipeline_terminal_accessed)

	if writeback_terminal:
		if writeback_terminal.has_signal("terminal_accessed"):
			if not writeback_terminal.is_connected("terminal_accessed", _on_pipeline_terminal_accessed):
				writeback_terminal.connect("terminal_accessed", _on_pipeline_terminal_accessed)
		elif writeback_terminal.has_signal("interacted"):
			if not writeback_terminal.is_connected("interacted", _on_pipeline_terminal_accessed):
				writeback_terminal.connect("interacted", _on_pipeline_terminal_accessed)

func _on_stage_latched(l_id: String) -> void:
	latched_stages[l_id] = true
	var count = get_latched_count()
	print("[Level_14] Pipeline Stage latched: ", l_id, " (", count, "/2)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 2:
			hud.update_objective("Pipeline Stages Latched (%d/2). Latch remaining stage." % count)
		elif not has_branch_predictor:
			hud.update_objective("Both Stages Latched! Recover Branch Predictor Module in West Predictor Alcove.")
		else:
			hud.update_objective("Backtrack to North Fetch Dispatcher Terminal (or Writeback Console) [E] to flush pipeline!")

func _on_predictor_collected(_p_id: String = "") -> void:
	has_branch_predictor = true
	print("[Level_14] Branch Predictor Module recovered!")

	var count = get_latched_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 2:
			hud.update_objective("Branch Predictor acquired! Latch remaining Pipeline Stages (%d/2)." % count)
		else:
			hud.update_objective("Backtrack to North Fetch Dispatcher Terminal (or Writeback Console) [E] to flush pipeline!")

func get_latched_count() -> int:
	var c = 0
	for k in latched_stages.keys():
		if latched_stages[k]:
			c += 1
	return c

func _on_pipeline_terminal_accessed(_user_data = null) -> void:
	if is_pipeline_flushed:
		return

	var count = get_latched_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 2 or not has_branch_predictor:
		print("[Level_14] Pipeline flush rejected: Latches (", count, "/2), Predictor: ", has_branch_predictor)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ PIPELINE STALL HAZARD ]\nLatch both Decode/Execute Stages (%d/2) and recover Branch Predictor Module (%s) before flushing." % [count, "READY" if has_branch_predictor else "MISSING"],
				""
			)
		return

	unlock_sector_15_bulkhead()

func unlock_sector_15_bulkhead() -> void:
	if is_pipeline_flushed:
		return
	is_pipeline_flushed = true
	print("[Level_14] Instruction Pipeline flushed! Sector 15 Interrupt Vector Bulkhead UNLOCKED.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ INSTRUCTION PIPELINE FLUSHED ]\nSouth Writeback Bulkhead disengaged. Proceed to Sector 15: Interrupt Vector Cell.",
			"overseer_pipeline_flushed"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through South Writeback Bulkhead into Sector 15: Interrupt Vector Cell.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("pipeline_flushed")
