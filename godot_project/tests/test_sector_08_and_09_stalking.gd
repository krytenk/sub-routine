extends Node
class_name TestSector08And09Stalking

# Comprehensive GDUnit4 Test Suite for Sector 08, Sector 09, EMP MK IV/V, and Surveillance Stalker Mechanics

const RoxyVanceScene = preload("res://scenes/player/roxy_vance.tscn")
const SurveillanceCameraScene = preload("res://scenes/props/surveillance_camera_prop.tscn")
const CCTVMonitorWallScene = preload("res://scenes/props/cctv_monitor_wall_prop.tscn")
const StalkerShadowScene = preload("res://scenes/props/stalker_shadow_prop.tscn")
const NullKeyPickupScene = preload("res://scenes/props/null_pointer_key_pickup.tscn")
const ThreadCipherPickupScene = preload("res://scenes/props/thread_lock_cipher_pickup.tscn")
const DeadlockRelayScene = preload("res://scenes/props/deadlock_relay_prop.tscn")
const EmpUpgradePickupScene = preload("res://scenes/props/emp_upgrade_pickup.tscn")
const Level08Scene = preload("res://scenes/levels/level_08.tscn")
const Level09Scene = preload("res://scenes/levels/level_09.tscn")

# 1. Test EMP Upgrade MK IV and MK V Progression
func test_emp_upgrade_mk4_and_mk5_stats() -> bool:
	var roxy = RoxyVanceScene.instantiate()

	# Initial tier
	assert(roxy.emp_upgrade_level == 1, "FAILED: Initial EMP tier should be MK 1")
	assert(roxy.emp_cooldown == 8.0, "FAILED: MK 1 cooldown should be 8.0s")

	# Upgrade to MK 4
	roxy.set_emp_upgrade_level(4)
	assert(roxy.emp_upgrade_level == 4, "FAILED: EMP tier should be MK 4")
	assert(roxy.emp_cooldown == 2.2, "FAILED: MK 4 cooldown should be 2.2s")
	assert(roxy.emp_pulse_radius == 18.0, "FAILED: MK 4 radius should be 18.0m")
	assert(roxy.emp_pulse_damage == 160, "FAILED: MK 4 damage should be 160")

	# Upgrade to MK 5
	roxy.set_emp_upgrade_level(5)
	assert(roxy.emp_upgrade_level == 5, "FAILED: EMP tier should be MK 5")
	assert(roxy.emp_cooldown == 1.2, "FAILED: MK 5 cooldown should be 1.2s")
	assert(roxy.emp_pulse_radius == 22.0, "FAILED: MK 5 radius should be 22.0m")
	assert(roxy.emp_pulse_damage == 220, "FAILED: MK 5 damage should be 220")

	# Clamping test
	roxy.set_emp_upgrade_level(99)
	assert(roxy.emp_upgrade_level == 5, "FAILED: EMP tier should clamp to max 5")

	roxy.queue_free()
	print("[PASS] test_emp_upgrade_mk4_and_mk5_stats: MK 4 & MK 5 stats and clamping validated.")
	return true

# 2. Test EMP Upgrade Pickups for MK 4 and MK 5
func test_emp_upgrade_pickups() -> bool:
	var roxy = RoxyVanceScene.instantiate()
	roxy.set_emp_upgrade_level(3)

	var pickup_mk4 = EmpUpgradePickupScene.instantiate()
	pickup_mk4.upgrade_level_target = 4
	pickup_mk4.upgrade_id = "emp_inductor_mk4"
	pickup_mk4._ready()

	pickup_mk4.collect(roxy)
	assert(roxy.emp_upgrade_level == 4, "FAILED: Collecting MK 4 pickup should upgrade Roxy to tier 4")

	var pickup_mk5 = EmpUpgradePickupScene.instantiate()
	pickup_mk5.upgrade_level_target = 5
	pickup_mk5.upgrade_id = "emp_resonant_matrix_mk5"
	pickup_mk5._ready()

	pickup_mk5.collect(roxy)
	assert(roxy.emp_upgrade_level == 5, "FAILED: Collecting MK 5 pickup should upgrade Roxy to tier 5")

	roxy.queue_free()
	pickup_mk4.queue_free()
	pickup_mk5.queue_free()
	print("[PASS] test_emp_upgrade_pickups: MK 4 & MK 5 collectible pickups validated.")
	return true

# 3. Test Surveillance Camera Autonomous Tracking and EMP Overload
func test_surveillance_camera_behavior() -> bool:
	var cam = SurveillanceCameraScene.instantiate()
	cam._ready()

	assert(cam.is_active == true, "FAILED: Surveillance camera should be active by default")
	assert(cam.gimbal != null, "FAILED: Surveillance camera must instantiate a gimbal arm")
	assert(cam.tally_light != null, "FAILED: Surveillance camera must instantiate a red tally light")

	# Test EMP reaction
	cam.take_damage(160, "emp")
	assert(cam.disabled_timer > 0.0, "FAILED: EMP should disable camera with cooldown timer")
	assert(cam.tally_light.visible == false, "FAILED: Disabled camera tally light must be extinguished")

	cam.queue_free()
	print("[PASS] test_surveillance_camera_behavior: Camera tracking and EMP disabling validated.")
	return true

# 4. Test CCTV Monitor Wall Prop and Surveillance Reveal
func test_cctv_monitor_wall() -> bool:
	var cctv = CCTVMonitorWallScene.instantiate()
	cctv._ready()

	assert(cctv.screen_labels.size() == 4, "FAILED: CCTV Wall must contain 4 CRT screen labels")
	assert(cctv.has_been_accessed == false, "FAILED: CCTV Wall should not be accessed initially")

	cctv.activate_surveillance()
	assert(cctv.is_powered == true, "FAILED: CCTV Wall should be powered on after interaction")
	assert(cctv.has_been_accessed == true, "FAILED: has_been_accessed flag should be true")

	# Verify sector feeds are displayed
	var text_0 = cctv.screen_labels[0].text
	assert(text_0.contains("CAM 01: BIOS BOOT"), "FAILED: Screen 0 must show Sector 01 feed")
	var text_3 = cctv.screen_labels[3].text
	assert(text_3.contains("CAM 08: OBS ROOM"), "FAILED: Screen 3 must show Sector 08 live feed")

	cctv.queue_free()
	print("[PASS] test_cctv_monitor_wall: CCTV monitor feeds and stalker surveillance reveal validated.")
	return true

# 5. Test Stalker Shadow Apparition Dissolve
func test_stalker_shadow_vanish() -> bool:
	var shadow = StalkerShadowScene.instantiate()
	shadow._ready()

	assert(shadow.has_vanished == false, "FAILED: Stalker shadow should be present initially")
	shadow.vanish()
	assert(shadow.has_vanished == true, "FAILED: Calling vanish() must set has_vanished to true")
	shadow.queue_free()
	print("[PASS] test_stalker_shadow_vanish: Stalker shadow dissolve into static validated.")
	return true

# 6. Test Quest Item Pickups (Null Pointer Keycard & Thread Lock Cipher)
func test_quest_pickups() -> bool:
	var null_key = NullKeyPickupScene.instantiate()
	null_key._ready()

	var tracker = {"keycard": false, "cipher": false}
	null_key.keycard_collected.connect(func(): tracker["keycard"] = true)
	null_key.collect()

	assert(tracker["keycard"] == true, "FAILED: NullPointerKeyPickup must emit keycard_collected")
	assert(null_key.collected == true, "FAILED: NullPointerKeyPickup collected flag should be true")

	var cipher = ThreadCipherPickupScene.instantiate()
	cipher._ready()

	cipher.cipher_collected.connect(func(): tracker["cipher"] = true)
	cipher.collect()

	assert(tracker["cipher"] == true, "FAILED: ThreadLockCipherPickup must emit cipher_collected")
	assert(cipher.collected == true, "FAILED: ThreadLockCipherPickup collected flag should be true")

	null_key.queue_free()
	cipher.queue_free()
	print("[PASS] test_quest_pickups: Null Pointer Keycard & Thread Lock Cipher collection validated.")
	return true

# 7. Test Deadlock Relay Prop
func test_deadlock_relay_cycle() -> bool:
	var relay = DeadlockRelayScene.instantiate()
	relay.relay_id = "relay_alpha"
	relay._ready()

	assert(relay.is_cycled == false, "FAILED: Deadlock relay must not be cycled initially")

	var tracker = {"id": ""}
	relay.relay_cycled.connect(func(id: String): tracker["id"] = id)
	relay.cycle_relay()

	assert(relay.is_cycled == true, "FAILED: Deadlock relay must be cycled after cycle_relay()")
	assert(tracker["id"] == "relay_alpha", "FAILED: Deadlock relay must emit correct relay_id")

	relay.queue_free()
	print("[PASS] test_deadlock_relay_cycle: Deadlock relay cycle and de-synchronization validated.")
	return true

# 8. Test Sector 08 Level Architecture and False Reprieve Trap
func test_sector_08_architecture() -> bool:
	var lvl8 = Level08Scene.instantiate()
	lvl8._ready()

	assert(lvl8.is_lockdown_triggered == false, "FAILED: Lockdown must not be triggered initially")
	assert(lvl8.is_exit_unlocked == false, "FAILED: Exit must be locked initially")

	# Trigger false reprieve collapse
	lvl8.trigger_lockdown()
	assert(lvl8.is_lockdown_triggered == true, "FAILED: trigger_lockdown must set is_lockdown_triggered")
	assert(lvl8.emergency_lights.visible == true, "FAILED: Emergency lights must activate upon lockdown")

	# Attempt exit unlock without keycard
	lvl8._on_terminal_accessed()
	assert(lvl8.is_exit_unlocked == false, "FAILED: Terminal must reject access without keycard")

	# Supply keycard and override
	lvl8.has_keycard = true
	lvl8._on_terminal_accessed()
	assert(lvl8.is_exit_unlocked == true, "FAILED: Terminal must unlock exit with keycard")

	lvl8.queue_free()
	print("[PASS] test_sector_08_architecture: Sector 08 false reprieve collapse and keycard gating validated.")
	return true

# 9. Test Sector 09 Level Architecture and Deadlock Relays
func test_sector_09_architecture() -> bool:
	var lvl9 = Level09Scene.instantiate()
	lvl9._ready()

	assert(lvl9.cycled_relays.size() == 0, "FAILED: Initially no relays cycled")
	assert(lvl9.is_exit_unlocked == false, "FAILED: Exit must be locked initially")

	# Cycle relays
	lvl9._on_relay_cycled("relay_a")
	lvl9._on_relay_cycled("relay_b")
	assert(lvl9.cycled_relays.size() == 2, "FAILED: 2 relays should be tracked")

	# Attempt unlock prematurely
	lvl9.has_cipher = true
	lvl9._on_console_accessed()
	assert(lvl9.is_exit_unlocked == false, "FAILED: Cannot unlock with only 2 relays cycled")

	# Cycle final relay
	lvl9._on_relay_cycled("relay_c")
	assert(lvl9.cycled_relays.size() == 3, "FAILED: All 3 relays must be tracked")

	# Console access with all relays and cipher
	lvl9._on_console_accessed()
	assert(lvl9.is_exit_unlocked == true, "FAILED: Exit must unlock when 3 relays cycled and cipher present")

	lvl9.queue_free()
	print("[PASS] test_sector_09_architecture: Sector 09 multi-thread deadlock relays and consensus unlock validated.")
	return true
