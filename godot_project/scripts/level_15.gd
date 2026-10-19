extends Node3D
class_name Level15Sector

# Sector 15: Interrupt Vector Cell & Containment Ward
# High-security detention complex revealing the origin of Subject 00 (The Stalker).
# Features:
# - Central Octagonal Interrogation Hub, West Cell Block A, East Cell Block B, and Subject 00 Observation Chamber
# - 3 Interrupt Vector Locks (IRQ Alpha, Beta, Gamma) + NMI Master Override Cipher recovery
# - 4 Glitch Walkers, 3 Wire Hounds, 3 CyberHusks, CCTV Monitor Wall, 6 Cameras, and 4 Stalker Shadows
# - Wall Map Panel (Sector 15 Blueprint) & Backtrack gate to Sector 14

var cleared_irqs: Dictionary = {
	"irq_alpha": false,
	"irq_beta": false,
	"irq_gamma": false
}
var has_nmi_cipher: bool = false
var is_ward_unsealed: bool = false

@onready var spire_terminal: Node3D = find_child("SpireLiftTerminal", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector16ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_15] Interrupt Vector Cell & Containment Ward initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Clear 3 Interrupt Vector Locks (0/3) across Cell Blocks A & B & recover NMI Override Cipher.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec15")

	var locks = [
		find_child("IRQLock_Alpha", true, false),
		find_child("IRQLock_Beta", true, false),
		find_child("IRQLock_Gamma", true, false)
	]
	for l in locks:
		if l:
			if l.has_signal("relay_cycled") and not l.is_connected("relay_cycled", _on_irq_cleared):
				l.connect("relay_cycled", _on_irq_cleared)
			elif l.has_signal("relay_synchronized") and not l.is_connected("relay_synchronized", _on_irq_cleared):
				l.connect("relay_synchronized", _on_irq_cleared)

	var cipher = find_child("NMIOverrideCipher", true, false)
	if cipher and cipher.has_signal("cipher_collected"):
		if not cipher.is_connected("cipher_collected", _on_nmi_collected):
			cipher.connect("cipher_collected", _on_nmi_collected)

	if spire_terminal:
		if spire_terminal.has_signal("terminal_accessed"):
			if not spire_terminal.is_connected("terminal_accessed", _on_spire_terminal_accessed):
				spire_terminal.connect("terminal_accessed", _on_spire_terminal_accessed)
		elif spire_terminal.has_signal("interacted"):
			if not spire_terminal.is_connected("interacted", _on_spire_terminal_accessed):
				spire_terminal.connect("interacted", _on_spire_terminal_accessed)

func _on_irq_cleared(irq_id: String) -> void:
	cleared_irqs[irq_id] = true
	var count = get_cleared_irq_count()
	print("[Level_15] Interrupt Vector Lock cleared: ", irq_id, " (", count, "/3)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("Interrupt Vector Locks Cleared (%d/3). Search remaining Cell Blocks." % count)
		elif not has_nmi_cipher:
			hud.update_objective("All 3 IRQ Locks Cleared! Recover NMI Override Cipher in Subject 00 Observation Chamber.")
		else:
			hud.update_objective("IRQ Vectors Ready! Access Spire Lift Terminal [E] at South Lift.")

func _on_nmi_collected(_c_id: String = "") -> void:
	has_nmi_cipher = true
	print("[Level_15] NMI Master Override Cipher recovered!")

	var count = get_cleared_irq_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("NMI Cipher acquired! Clear remaining Interrupt Vector Locks (%d/3)." % count)
		else:
			hud.update_objective("IRQ Vectors Ready! Access Spire Lift Terminal [E] at South Lift.")

func get_cleared_irq_count() -> int:
	var c = 0
	for k in cleared_irqs.keys():
		if cleared_irqs[k]:
			c += 1
	return c

func _on_spire_terminal_accessed(_user_data = null) -> void:
	if is_ward_unsealed:
		return

	var count = get_cleared_irq_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 3 or not has_nmi_cipher:
		print("[Level_15] Spire Lift Terminal rejected: IRQs (", count, "/3), Cipher: ", has_nmi_cipher)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ NON-MASKABLE INTERRUPT ACTIVE ]\nClear all 3 IRQ Vector Locks (%d/3) and acquire NMI Override Cipher (%s) to unseal Sector 16." % [count, "READY" if has_nmi_cipher else "MISSING"],
				""
			)
		return

	unlock_sector_16_lift()

func unlock_sector_16_lift() -> void:
	if is_ward_unsealed:
		return
	is_ward_unsealed = true
	print("[Level_15] Interrupt Vectors cleared! Sector 16 Thermal Throttling Spire Lift UNLOCKED.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ INTERRUPT VECTORS CLEARED ]\nSouth Spire Lift unsealed. Enter Sector 16: Thermal Throttling Spire.",
			"overseer_irq_released"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter the South Spire Lift into Sector 16: Thermal Throttling Spire.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("irq_released")
