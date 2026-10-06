extends Node3D
class_name Level07Sector

# Sector 07: Stack Overflow Vault & The Proving Grounds
# High-peril sector featuring overhead duct crawling above the lethal Dredge Titan,
# modular scavenging for the prototype Singularity Cannon, and an apex boss fight
# against the Arch-Compiler Goliath before the weapon disintegrates forever.

var is_boss_beaten: bool = false
var is_exit_unlocked: bool = false

@onready var test_bench: Node3D = find_child("WeaponsTestBench", true, false)
@onready var boss_goliath: CharacterBody3D = find_child("ArchCompilerGoliath", true, false)
@onready var exit_bulkhead_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector08ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_07] Stack Overflow Vault initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Avoid the Dredge Titan. Crawl through overhead ducts [C] to scavenge weapon modules.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec7")

	if boss_goliath:
		if boss_goliath.has_signal("boss_defeated"):
			boss_goliath.connect("boss_defeated", _on_boss_defeated)

	if test_bench:
		if test_bench.has_signal("weapon_assembled"):
			test_bench.connect("weapon_assembled", _on_weapon_assembled)

func _on_weapon_assembled() -> void:
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter Central Blast Core. Destroy Arch-Compiler Goliath with Singularity Cannon [F].")

func _on_boss_defeated() -> void:
	if is_boss_beaten:
		return
	is_boss_beaten = true
	is_exit_unlocked = true
	print("[Level_07] Arch-Compiler Goliath neutralized! Sector 08 Transit Gate UNLOCKED.")

	if exit_bulkhead_mesh:
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_bulkhead_mesh, "position:y", exit_bulkhead_mesh.position.y + 4.2, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ GOLIATH CORE OBLITERATED ]\nSector 08 Blast Bulkhead energized & disengaged.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through Blast Bulkhead to Sector 08.")
