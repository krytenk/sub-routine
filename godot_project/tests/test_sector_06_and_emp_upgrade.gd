extends Node

# Unit Tests for Sector 06 (Deep Server Vault), CyberHusk Enemy, and EMP Upgrade Mechanics

const CyberHuskScene = preload("res://scenes/enemies/cyber_husk.tscn")
const RoxyVanceScene = preload("res://scenes/player/roxy_vance.tscn")
const EmpUpgradePickupScene = preload("res://scenes/props/emp_upgrade_pickup.tscn")
const Level06Scene = preload("res://scenes/levels/level_06.tscn")

func test_cyber_husk_anatomy_and_mechanics() -> bool:
	var husk = CyberHuskScene.instantiate()
	assert(husk != null, "FAILED: CyberHusk scene could not be instantiated")

	# Verify cybernetic prosthetic and anatomical markers
	var leg_l = husk.find_child("Leg_L", true, false)
	var shin = husk.find_child("ProstheticShin", true, false)
	var leg_r = husk.find_child("Leg_R", true, false)
	var pincer = husk.find_child("PincerBlade_1", true, false)
	var spine = husk.find_child("SpinalExo", true, false)
	var ocular = husk.find_child("OcularLight", true, false)

	assert(leg_l != null and shin != null, "FAILED: Hydraulic prosthetic left leg missing on CyberHusk")
	assert(leg_r != null, "FAILED: Organic dragging right leg missing on CyberHusk")
	assert(pincer != null, "FAILED: Pneumatic pincer claw missing on CyberHusk")
	assert(spine != null, "FAILED: Spinal exo-frame missing on CyberHusk")
	assert(ocular != null, "FAILED: Cybernetic ocular light missing on CyberHusk")

	# Test EMP vulnerability and seizure mechanic
	husk.take_damage(60, "emp")
	assert(husk.is_stunned == true, "FAILED: CyberHusk should enter stunned seizure state upon EMP blast")
	assert(husk.stun_timer >= 5.5, "FAILED: CyberHusk stun timer should be >= 5.5 seconds")

	husk.queue_free()
	print("[PASS] test_cyber_husk_anatomy_and_mechanics: CyberHusk prosthetic anatomy and EMP overload seizure validated.")
	return true

func test_emp_upgrade_progression() -> bool:
	var roxy = RoxyVanceScene.instantiate()
	assert(roxy != null, "FAILED: RoxyVance scene could not be instantiated")

	# Check base MK I stats
	assert(roxy.emp_upgrade_level == 1, "FAILED: Initial EMP level should be MK I (1)")
	assert(roxy.emp_cooldown == 8.0, "FAILED: Initial EMP cooldown should be 8.0s")
	assert(roxy.emp_pulse_radius == 8.0, "FAILED: Initial EMP pulse radius should be 8.0m")
	assert(roxy.emp_pulse_damage == 60, "FAILED: Initial EMP pulse damage should be 60")

	# Upgrade to MK II
	roxy.upgrade_emp(2)
	assert(roxy.emp_upgrade_level == 2, "FAILED: EMP upgrade level should be 2")
	assert(roxy.emp_cooldown == 5.5, "FAILED: MK II EMP cooldown should be 5.5s")
	assert(roxy.emp_pulse_radius == 11.0, "FAILED: MK II EMP pulse radius should be 11.0m")
	assert(roxy.emp_pulse_damage == 85, "FAILED: MK II EMP pulse damage should be 85")

	# Upgrade to MK III
	roxy.upgrade_emp(3)
	assert(roxy.emp_upgrade_level == 3, "FAILED: EMP upgrade level should be 3")
	assert(roxy.emp_cooldown == 3.5, "FAILED: MK III EMP cooldown should be 3.5s")
	assert(roxy.emp_pulse_radius == 14.5, "FAILED: MK III EMP pulse radius should be 14.5m")
	assert(roxy.emp_pulse_damage == 120, "FAILED: MK III EMP pulse damage should be 120")

	roxy.queue_free()
	print("[PASS] test_emp_upgrade_progression: Roxy EMP upgrades (MK I -> MK II -> MK III) validated.")
	return true

func test_emp_upgrade_pickup_prop() -> bool:
	var pickup = EmpUpgradePickupScene.instantiate()
	assert(pickup != null, "FAILED: EmpUpgradePickupScene could not be instantiated")

	assert(pickup.is_in_group("emp_upgrades"), "FAILED: Pickup must be in 'emp_upgrades' group")
	assert(pickup.is_in_group("interactive_props"), "FAILED: Pickup must be in 'interactive_props' group")
	assert(pickup.is_in_group("pickups"), "FAILED: Pickup must be in 'pickups' group")

	var roxy = RoxyVanceScene.instantiate()
	pickup.interact(roxy)
	assert(roxy.emp_upgrade_level == 2, "FAILED: Interacting with pickup should upgrade Roxy to MK II")
	assert(pickup.collected == true, "FAILED: Pickup should be marked as collected")

	roxy.queue_free()
	pickup.queue_free()
	print("[PASS] test_emp_upgrade_pickup_prop: EMP Dielectric Capacitor pickup interaction validated.")
	return true

func test_level_06_deep_server_vault_architecture() -> bool:
	var level = Level06Scene.instantiate()
	assert(level != null, "FAILED: Level 06 scene could not be instantiated")

	# Check navigation markers
	var spawn = level.find_child("SpawnPoint", true, false)
	var backtrack = level.find_child("BacktrackPortal", true, false)
	assert(spawn != null, "FAILED: Level 06 SpawnPoint missing")
	assert(backtrack != null, "FAILED: Level 06 BacktrackPortal missing")

	# Check casualties
	var arch_casualty = level.find_child("Casualty_SystemsArchitect", true, false)
	var cryo_casualty = level.find_child("Casualty_CryoTech", true, false)
	assert(arch_casualty != null, "FAILED: Systems Architect casualty missing in Sector 06")
	assert(cryo_casualty != null, "FAILED: Cryo Tech casualty missing in Sector 06")

	# Check enemies (CyberHusk presence)
	var enemies = level.find_child("Enemies", true, false)
	assert(enemies != null, "FAILED: Enemies container missing in Sector 06")
	var husks = []
	for child in enemies.get_children():
		if child.name.begins_with("CyberHusk"):
			husks.append(child)
	assert(husks.size() >= 2, "FAILED: At least 2 CyberHusks should be deployed in Sector 06")

	# Check scavengeable EMP capacitor
	var emp_pickup = level.find_child("EmpUpgradePickup", true, false)
	assert(emp_pickup != null, "FAILED: EmpUpgradePickup missing in Sector 06 Security Cage")

	# Check Terminal and Exit Trigger
	var terminal = level.find_child("VaultCompilationTerminal", true, false)
	var exit_trigger = level.find_child("Sector07ExitTrigger", true, false)
	assert(terminal != null, "FAILED: VaultCompilationTerminal missing in Sector 06")
	assert(exit_trigger != null, "FAILED: Sector07ExitTrigger missing in Sector 06")

	# Test unlock progression
	level.unlock_sector_07_transit()
	assert(level.is_vault_unlocked == true, "FAILED: is_vault_unlocked should be true after cipher compile")

	level.queue_free()
	print("[PASS] test_level_06_deep_server_vault_architecture: Sector 06 Server Vault architecture, CyberHusks, and puzzle validated.")
	return true
