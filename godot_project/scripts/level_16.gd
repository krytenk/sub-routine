extends Node3D
class_name Level16Sector

# Sector 16: Thermal Throttling Spire (Act II Boss Encounter)
# Climactic multi-phase Act II boss arena where Roxy Vance confronts the Thermal Overlord.
# Features:
# - Central Reactor Spire flanked by West, East, and South-Central Cryogenic Heat-Sink Alcoves
# - Multi-Phase Boss Fight: Open 3 Cryogenic Heat-Sink Valves [E] to flash-freeze the Overlord's
#   1,800C molten slag armor into brittle glass, then discharge MK V EMP Pulses [F] to shatter it!
# - Automatic purge of remaining arena escort threads upon Thermal Overlord collapse
# - South Deep Core Elevator unlocking Act II completion & Roll Credits

var opened_valves: Dictionary = {
	"valve_west": false,
	"valve_east": false,
	"valve_south": false
}
var is_boss_defeated: bool = false
var is_deep_core_unlocked: bool = false

@onready var thermal_overlord: CharacterBody3D = find_child("ThermalOverlordBoss", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector16DeepCoreExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_16] Thermal Throttling Spire (Act II Boss Arena) initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("BOSS: Open 3 Cryogenic Heat-Sink Valves [E] (0/3) to flash-freeze the Thermal Overlord's molten armor!")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec16")

	var valves = [
		find_child("CryoValve_West", true, false),
		find_child("CryoValve_East", true, false),
		find_child("CryoValve_South", true, false)
	]
	for v in valves:
		if v:
			if v.has_signal("relay_cycled") and not v.is_connected("relay_cycled", _on_cryo_valve_opened):
				v.connect("relay_cycled", _on_cryo_valve_opened)
			elif v.has_signal("relay_synchronized") and not v.is_connected("relay_synchronized", _on_cryo_valve_opened):
				v.connect("relay_synchronized", _on_cryo_valve_opened)

	if thermal_overlord:
		if thermal_overlord.has_signal("boss_defeated") and not thermal_overlord.is_connected("boss_defeated", _on_boss_defeated):
			thermal_overlord.connect("boss_defeated", _on_boss_defeated)
		if thermal_overlord.has_signal("slag_armor_frozen") and not thermal_overlord.is_connected("slag_armor_frozen", _on_slag_armor_frozen):
			thermal_overlord.connect("slag_armor_frozen", _on_slag_armor_frozen)

func _on_cryo_valve_opened(valve_id: String) -> void:
	if opened_valves.get(valve_id, false):
		return
	opened_valves[valve_id] = true
	var count = get_opened_valve_count()
	print("[Level_16] Cryogenic Heat-Sink Valve OPENED: ", valve_id, " (", count, "/3)")

	if thermal_overlord and is_instance_valid(thermal_overlord) and thermal_overlord.has_method("apply_cryo_valve_quench"):
		thermal_overlord.apply_cryo_valve_quench()

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 3:
		if hud and hud.has_method("update_objective"):
			hud.update_objective("Cryogenic Heat-Sink Valves Opened (%d/3)! Open remaining valves to freeze Molten Slag Armor." % count)
	else:
		_on_slag_armor_frozen()

func get_opened_valve_count() -> int:
	var c = 0
	for k in opened_valves.keys():
		if opened_valves[k]:
			c += 1
	return c

func _on_slag_armor_frozen() -> void:
	print("[Level_16] Thermal Overlord Molten Slag Armor flash-frozen! Boss vulnerable to MK V EMP shatter!")
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ MOLTEN SLAG ARMOR FLASH-FROZEN! ]\nThermal Overlord chassis is brittle! Discharge MK V EMP Pulses [F] near the boss to shatter it!",
			""
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("CHASSIS FROZEN! Discharge MK V EMP Pulses [F] into the Thermal Overlord to shatter it!")

func _on_boss_defeated() -> void:
	if is_boss_defeated:
		return
	is_boss_defeated = true
	is_deep_core_unlocked = true
	print("[Level_16] THERMAL OVERLORD SHATTERED! Unlocking South Deep Core Elevator.")

	# Purge remaining security minions in the Spire from the cryo-thermal shockwave
	var enemies_node = find_child("Enemies", true, false)
	if enemies_node:
		for child in enemies_node.get_children():
			if child != thermal_overlord and is_instance_valid(child):
				if child.has_method("take_damage"):
					child.take_damage(999, "superweapon")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.4, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ THERMAL OVERLORD SHATTERED ]\nAct II Deep Memory Partitions cleared! South Deep Core Elevator unlocked.",
			"overseer_overlord_defeated"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter the South Deep Core Elevator to complete Act II!")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("overlord_defeated")
