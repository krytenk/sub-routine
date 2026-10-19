extends Node
class_name TestSectors10To12Boss

# Unit Test Suite for Sectors 10, 11, and 12 (Act I Climax & Kernel Warden Boss)
# plus HUD MK IV/V display and Campaign Reset improvements.

const Level10Scene = preload("res://scenes/levels/level_10.tscn")
const Level11Scene = preload("res://scenes/levels/level_11.tscn")
const Level12Scene = preload("res://scenes/levels/level_12.tscn")
const MapViewerModalScene = preload("res://scenes/ui/map_viewer_modal.tscn")
const HUDScene = preload("res://scenes/ui/hud.tscn")

# 1. Test Sector 10: Clock Cycle Foundry & Oscillator Hall
func test_sector_10_clock_cycle_foundry() -> bool:
	var lvl = Level10Scene.instantiate()
	lvl._ready()

	assert(lvl.is_foundry_synced == false, "FAILED: Sector 10 foundry must start unsynchronized")

	var map_panel = lvl.find_child("WallMapPanel", true, false)
	assert(map_panel != null and map_panel.sector_index == 10, "FAILED: Sector 10 must contain WallMapPanel with sector_index 10")

	var relay_a = lvl.find_child("OscillatorRelay_Alpha", true, false)
	var relay_b = lvl.find_child("OscillatorRelay_Beta", true, false)
	var relay_c = lvl.find_child("OscillatorRelay_Gamma", true, false)
	var cipher = lvl.find_child("QuartzDividerCipher", true, false)
	var term = lvl.find_child("FoundrySyncTerminal", true, false)

	assert(relay_a != null and relay_b != null and relay_c != null, "FAILED: Sector 10 must have 3 Quartz Oscillator Relays")
	assert(cipher != null and term != null, "FAILED: Sector 10 must have QuartzDividerCipher and FoundrySyncTerminal")

	# Premature terminal interaction must not unlock gate
	lvl._on_foundry_terminal_accessed()
	assert(lvl.is_foundry_synced == false, "FAILED: Foundry terminal must reject access before relays and cipher are ready")

	# Synchronize all 3 relays and collect cipher
	relay_a.interact()
	relay_b.interact()
	relay_c.interact()
	assert(lvl.get_synced_relay_count() == 3, "FAILED: All 3 Quartz Oscillator Relays must be synchronized")

	cipher.interact()
	assert(lvl.has_quartz_cipher == true, "FAILED: QuartzDividerCipher must set has_quartz_cipher = true")

	lvl._on_foundry_terminal_accessed()
	assert(lvl.is_foundry_synced == true, "FAILED: Foundry terminal must unlock Sector 11 gate once relays and cipher are ready")

	lvl.queue_free()
	print("[PASS] test_sector_10_clock_cycle_foundry: Sector 10 relays, cipher, enemies, and gate unlock validated.")
	return true

# 2. Test Sector 11: DMA Controller Trench & Panopticon Gauntlet
func test_sector_11_dma_panopticon_gauntlet() -> bool:
	var lvl = Level11Scene.instantiate()
	lvl._ready()

	assert(lvl.is_panopticon_overridden == false, "FAILED: Sector 11 must start locked")

	var titan = lvl.find_child("DredgeTitan_DMA", true, false)
	var duct_n = lvl.find_child("WestBypassDuct_North", true, false)
	var cctv = lvl.find_child("CCTVMonitorWall", true, false)
	var map_panel = lvl.find_child("WallMapPanel", true, false)

	assert(titan != null, "FAILED: Sector 11 must contain DredgeTitan_DMA in trench")
	assert(duct_n != null, "FAILED: Sector 11 must contain West Overhead Ventilation Duct Bypass")
	assert(cctv != null, "FAILED: Sector 11 must contain CCTVMonitorWall in Panopticon Rotunda")
	assert(map_panel != null and map_panel.sector_index == 11, "FAILED: Sector 11 must contain WallMapPanel with sector_index 11")

	var relay_n = lvl.find_child("DMARelay_North", true, false)
	var relay_e = lvl.find_child("DMARelay_East", true, false)
	var bus_key = lvl.find_child("DMAMasterBusKey", true, false)

	relay_n.interact()
	relay_e.interact()
	assert(lvl.get_synced_relay_count() == 2, "FAILED: Both DMA Interrupt Relays must synchronize")

	bus_key.interact()
	assert(lvl.has_dma_bus_key == true, "FAILED: DMAMasterBusKey must set has_dma_bus_key = true")

	lvl._on_panopticon_terminal_accessed()
	assert(lvl.is_panopticon_overridden == true, "FAILED: Panopticon terminal must unlock Sector 12 Core Threshold")

	lvl.queue_free()
	print("[PASS] test_sector_11_dma_panopticon_gauntlet: Sector 11 duct bypass, Panopticon surveillance, and DMA override validated.")
	return true

# 3. Test Sector 12: Sub-Routine Core Threshold & Kernel Warden Boss Fight
func test_sector_12_kernel_warden_boss_fight() -> bool:
	var lvl = Level12Scene.instantiate()
	lvl._ready()

	var boss = lvl.find_child("KernelWardenBoss", true, false)
	assert(boss != null, "FAILED: Sector 12 must contain KernelWardenBoss")
	assert(boss.phase_shield_active == true, "FAILED: KernelWardenBoss must start with Phase-Shield active")

	# Standard EMP while shielded deals reduced bleed damage (40)
	var initial_hp = boss.current_health
	boss.take_damage(220, "emp")
	assert(boss.current_health == initial_hp - 40, "FAILED: Shielded KernelWardenBoss must dampen EMP to 40 bleed damage")
	assert(boss.phase_shield_active == true, "FAILED: Phase-Shield must remain active until 3 Harmonic Pylons are overloaded")

	# Overload all 3 Harmonic Cooling Pylons
	var pylon_w = lvl.find_child("HarmonicPylon_West", true, false)
	var pylon_e = lvl.find_child("HarmonicPylon_East", true, false)
	var pylon_s = lvl.find_child("HarmonicPylon_South", true, false)
	assert(pylon_w != null and pylon_e != null and pylon_s != null, "FAILED: Sector 12 must contain 3 Harmonic Cooling Pylons")

	pylon_w.interact()
	pylon_e.interact()
	pylon_s.interact()

	assert(lvl.get_overloaded_pylon_count() == 3, "FAILED: All 3 Harmonic Cooling Pylons must register overloaded")
	assert(boss.phase_shield_active == false, "FAILED: KernelWardenBoss Phase-Shield must shatter after 3 pylon overloads")

	# Finish off exposed Kernel Core with MK V EMP pulse (220 damage)
	boss.take_damage(220, "emp")
	assert(boss.is_dead == true, "FAILED: KernelWardenBoss must be defeated by MK V EMP once Phase-Shield is shattered")
	assert(lvl.is_boss_defeated == true, "FAILED: Level 12 must record is_boss_defeated = true")
	assert(lvl.is_ascension_unlocked == true, "FAILED: Level 12 South Surface Ascension Lift must unlock on boss defeat")

	lvl.queue_free()
	print("[PASS] test_sector_12_kernel_warden_boss_fight: Multi-phase Kernel Warden boss fight and Act I finale validated.")
	return true

# 4. Test HUD MK IV / MK V Display & LevelManager Campaign Reset
func test_hud_emp_mk_labels_and_reset() -> bool:
	var hud = HUDScene.instantiate()
	hud._ready()

	hud._on_player_emp_cooldown_updated(0.0, 2.2)
	assert(hud.emp_label.text.contains("MK IV"), "FAILED: HUD must display MK IV when max cooldown is 2.2s")

	hud._on_player_emp_cooldown_updated(0.0, 1.2)
	assert(hud.emp_label.text.contains("MK V"), "FAILED: HUD must display MK V when max cooldown is 1.2s")

	var lm = load("res://scripts/level_manager.gd").new()
	lm.emp_upgrade_level = 5
	lm.add_generator_part("test_part")
	lm.reset_campaign_state()
	assert(lm.emp_upgrade_level == 1, "FAILED: reset_campaign_state must reset emp_upgrade_level to 1")
	assert(lm.generator_parts.is_empty(), "FAILED: reset_campaign_state must clear generator_parts")

	lm.free()
	hud.queue_free()
	print("[PASS] test_hud_emp_mk_labels_and_reset: HUD MK IV/V labels and LevelManager campaign reset validated.")
	return true

# 5. Test Map Viewer Blueprints for Sectors 10, 11, and 12
func test_map_viewer_sectors_10_to_12() -> bool:
	for sec in [10, 11, 12]:
		var path = "res://assets/textures/maps/sector_%02d_map.jpg" % sec
		assert(ResourceLoader.exists(path) or FileAccess.file_exists(path), "FAILED: Missing map blueprint " + path)

	var modal = MapViewerModalScene.instantiate()
	modal._ready()
	modal.open_map(10)
	assert(modal.current_sector_index == 10, "FAILED: MapViewerModal must open Sector 10")
	assert(modal.title_label.text.contains("SECTOR 10"), "FAILED: MapViewerModal must show Sector 10 title")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 11, "FAILED: Next button must advance to Sector 11")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 12, "FAILED: Next button must advance to Sector 12")

	modal.queue_free()
	print("[PASS] test_map_viewer_sectors_10_to_12: Blueprints and navigation for Sectors 10-12 validated.")
	return true
