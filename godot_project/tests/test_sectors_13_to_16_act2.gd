extends Node
class_name TestSectors13To16Act2

# Unit Test Suite for Act II: Deep Memory Partitions (Sectors 13, 14, 15, and 16 + Thermal Overlord Boss)

const Level13Scene = preload("res://scenes/levels/level_13.tscn")
const Level14Scene = preload("res://scenes/levels/level_14.tscn")
const Level15Scene = preload("res://scenes/levels/level_15.tscn")
const Level16Scene = preload("res://scenes/levels/level_16.tscn")
const MapViewerModalScene = preload("res://scenes/ui/map_viewer_modal.tscn")

# 1. Test Sector 13: Floating Point Void & Mantissa Islands
func test_sector_13_floating_point_void() -> bool:
	var lvl = Level13Scene.instantiate()
	lvl._ready()

	assert(lvl.is_void_anchored == false, "FAILED: Sector 13 Mantissa Void must start unanchored")

	var map_panel = lvl.find_child("WallMapPanel", true, false)
	assert(map_panel != null and map_panel.sector_index == 13, "FAILED: Sector 13 must contain WallMapPanel with sector_index 13")

	var relay_w = lvl.find_child("MantissaRelay_West", true, false)
	var relay_c = lvl.find_child("MantissaRelay_Central", true, false)
	var relay_e = lvl.find_child("MantissaRelay_East", true, false)
	var cipher = lvl.find_child("IEEEPrecisionCipher", true, false)
	var term = lvl.find_child("ExponentConsensusTerminal", true, false)

	assert(relay_w != null and relay_c != null and relay_e != null, "FAILED: Sector 13 must have 3 Mantissa Stabilizer Relays")
	assert(cipher != null and term != null, "FAILED: Sector 13 must have IEEEPrecisionCipher and ExponentConsensusTerminal")

	# Premature terminal interaction must not unlock gate
	lvl._on_exponent_terminal_accessed()
	assert(lvl.is_void_anchored == false, "FAILED: Exponent terminal must reject access before stabilizers and cipher are ready")

	relay_w.interact()
	relay_c.interact()
	relay_e.interact()
	assert(lvl.get_stabilized_count() == 3, "FAILED: All 3 Mantissa Stabilizer Relays must calibrate")

	cipher.interact()
	assert(lvl.has_ieee_cipher == true, "FAILED: IEEEPrecisionCipher must set has_ieee_cipher = true")

	lvl._on_exponent_terminal_accessed()
	assert(lvl.is_void_anchored == true, "FAILED: Exponent terminal must unlock Sector 14 gate once stabilizers and cipher are ready")

	lvl.queue_free()
	print("[PASS] test_sector_13_floating_point_void: Sector 13 Mantissa stabilizers, IEEE-754 cipher, and void anchor validated.")
	return true

# 2. Test Sector 14: Instruction Pipeline Trench & Duct Bypass
func test_sector_14_instruction_pipeline_trench() -> bool:
	var lvl = Level14Scene.instantiate()
	lvl._ready()

	assert(lvl.is_pipeline_flushed == false, "FAILED: Sector 14 pipeline must start locked")

	var titan = lvl.find_child("DredgeTitan_Pipeline", true, false)
	var duct_n = lvl.find_child("EastBypassDuct_North", true, false)
	var map_panel = lvl.find_child("WallMapPanel", true, false)

	assert(titan != null, "FAILED: Sector 14 must contain DredgeTitan_Pipeline in Decode/Execute Trench")
	assert(duct_n != null, "FAILED: Sector 14 must contain East Overhead Ventilation Duct Bypass")
	assert(map_panel != null and map_panel.sector_index == 14, "FAILED: Sector 14 must contain WallMapPanel with sector_index 14")

	var latch_d = lvl.find_child("PipelineLatch_Decode", true, false)
	var latch_e = lvl.find_child("PipelineLatch_Execute", true, false)
	var predictor = lvl.find_child("BranchPredictorCipher", true, false)

	assert(latch_d != null and latch_e != null and predictor != null, "FAILED: Sector 14 must contain Decode/Execute latches and BranchPredictorCipher")

	latch_d.interact()
	latch_e.interact()
	assert(lvl.get_latched_count() == 2, "FAILED: Both Pipeline Stage Latches must synchronize")

	predictor.interact()
	assert(lvl.has_branch_predictor == true, "FAILED: BranchPredictorCipher must set has_branch_predictor = true")

	lvl._on_pipeline_terminal_accessed()
	assert(lvl.is_pipeline_flushed == true, "FAILED: Pipeline Terminal must unlock Sector 15 gate")

	lvl.queue_free()
	print("[PASS] test_sector_14_instruction_pipeline_trench: Sector 14 duct bypass, Branch Predictor module, and pipeline flush validated.")
	return true

# 3. Test Sector 15: Interrupt Vector Cell & Containment Ward (Subject 00 Reveal)
func test_sector_15_interrupt_vector_cell() -> bool:
	var lvl = Level15Scene.instantiate()
	lvl._ready()

	assert(lvl.is_ward_unsealed == false, "FAILED: Sector 15 IRQ Ward must start sealed")

	var cctv = lvl.find_child("CCTVMonitorWall", true, false)
	var map_panel = lvl.find_child("WallMapPanel", true, false)
	var casualty_julian = lvl.find_child("Casualty_Subject00", true, false)

	assert(cctv != null, "FAILED: Sector 15 must contain CCTVMonitorWall in Central Interrogation Hub")
	assert(casualty_julian != null, "FAILED: Sector 15 must contain Subject 00 (Julian Vance) origin log")
	assert(map_panel != null and map_panel.sector_index == 15, "FAILED: Sector 15 must contain WallMapPanel with sector_index 15")

	var irq_a = lvl.find_child("IRQLock_Alpha", true, false)
	var irq_b = lvl.find_child("IRQLock_Beta", true, false)
	var irq_g = lvl.find_child("IRQLock_Gamma", true, false)
	var cipher = lvl.find_child("NMIOverrideCipher", true, false)

	assert(irq_a != null and irq_b != null and irq_g != null and cipher != null, "FAILED: Sector 15 must have 3 IRQ Locks and NMIOverrideCipher")

	irq_a.interact()
	irq_b.interact()
	irq_g.interact()
	assert(lvl.get_cleared_irq_count() == 3, "FAILED: All 3 IRQ Vector Locks must clear")

	cipher.interact()
	assert(lvl.has_nmi_cipher == true, "FAILED: NMIOverrideCipher must set has_nmi_cipher = true")

	lvl._on_spire_terminal_accessed()
	assert(lvl.is_ward_unsealed == true, "FAILED: Spire Lift Terminal must unlock Sector 16 Thermal Spire")

	lvl.queue_free()
	print("[PASS] test_sector_15_interrupt_vector_cell: Sector 15 Subject 00 reveal, 3 IRQ Locks, and NMI Override Cipher validated.")
	return true

# 4. Test Sector 16: Thermal Throttling Spire & Thermal Overlord Boss Fight
func test_sector_16_thermal_overlord_boss_fight() -> bool:
	var lvl = Level16Scene.instantiate()
	lvl._ready()

	var boss = lvl.find_child("ThermalOverlordBoss", true, false)
	var map_panel = lvl.find_child("WallMapPanel", true, false)
	assert(boss != null, "FAILED: Sector 16 must contain ThermalOverlordBoss")
	assert(map_panel != null and map_panel.sector_index == 16, "FAILED: Sector 16 must contain WallMapPanel with sector_index 16")
	assert(boss.slag_armor_molten == true, "FAILED: ThermalOverlordBoss must start with Molten Slag Armor active")

	# Standard EMP while molten deals reduced bleed damage (35)
	var initial_hp = boss.current_health
	boss.take_damage(220, "emp")
	assert(boss.current_health == initial_hp - 35, "FAILED: Molten ThermalOverlordBoss must dampen EMP to 35 bleed damage")
	assert(boss.slag_armor_molten == true, "FAILED: Molten Slag Armor must remain active until 3 Cryogenic Valves are opened")

	# Open all 3 Cryogenic Heat-Sink Valves
	var valve_w = lvl.find_child("CryoValve_West", true, false)
	var valve_e = lvl.find_child("CryoValve_East", true, false)
	var valve_s = lvl.find_child("CryoValve_South", true, false)
	assert(valve_w != null and valve_e != null and valve_s != null, "FAILED: Sector 16 must contain 3 Cryogenic Heat-Sink Valves")

	valve_w.interact()
	valve_e.interact()
	valve_s.interact()

	assert(lvl.get_opened_valve_count() == 3, "FAILED: All 3 Cryogenic Heat-Sink Valves must register opened")
	assert(boss.slag_armor_molten == false, "FAILED: ThermalOverlordBoss Molten Slag Armor must freeze after 3 cryo valves")

	# Shatter frozen chassis with MK V EMP pulse (220 damage)
	boss.take_damage(220, "emp")
	assert(boss.is_dead == true, "FAILED: ThermalOverlordBoss must be shattered by MK V EMP once armor is frozen")
	assert(lvl.is_boss_defeated == true, "FAILED: Level 16 must record is_boss_defeated = true")
	assert(lvl.is_deep_core_unlocked == true, "FAILED: Level 16 South Deep Core Elevator must unlock on boss defeat")

	lvl.queue_free()
	print("[PASS] test_sector_16_thermal_overlord_boss_fight: Multi-phase Thermal Overlord boss fight and Act II finale validated.")
	return true

# 5. Test Map Viewer Blueprints for Sectors 13, 14, 15, and 16
func test_map_viewer_sectors_13_to_16() -> bool:
	for sec in [13, 14, 15, 16]:
		var path = "res://assets/textures/maps/sector_%02d_map.jpg" % sec
		assert(ResourceLoader.exists(path) or FileAccess.file_exists(path), "FAILED: Missing map blueprint " + path)

	var modal = MapViewerModalScene.instantiate()
	modal._ready()
	modal.open_map(13)
	assert(modal.current_sector_index == 13, "FAILED: MapViewerModal must open Sector 13")
	assert(modal.title_label.text.contains("SECTOR 13"), "FAILED: MapViewerModal must show Sector 13 title")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 14, "FAILED: Next button must advance to Sector 14")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 15, "FAILED: Next button must advance to Sector 15")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 16, "FAILED: Next button must advance to Sector 16")

	modal.queue_free()
	print("[PASS] test_map_viewer_sectors_13_to_16: Blueprints and navigation for Sectors 13-16 validated.")
	return true
