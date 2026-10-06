extends Node

# Unit Tests for Sector 07 (Stack Overflow Vault), Duct Crawling, Dredge Titan, and Superweapon Boss Fight

const RoxyVanceScene = preload("res://scenes/player/roxy_vance.tscn")
const VentDuctScene = preload("res://scenes/props/vent_duct_shaft.tscn")
const DredgeTitanScene = preload("res://scenes/enemies/dredge_titan.tscn")
const ArchCompilerGoliathScene = preload("res://scenes/enemies/arch_compiler_goliath.tscn")
const WeaponsTestBenchScene = preload("res://scenes/props/weapons_test_bench_prop.tscn")
const Level07Scene = preload("res://scenes/levels/level_07.tscn")

func test_roxy_crouch_and_duct_crawling() -> bool:
	var roxy = RoxyVanceScene.instantiate()
	assert(roxy != null, "FAILED: RoxyVance scene could not be instantiated")

	# Standing defaults
	assert(roxy.is_crouching == false, "FAILED: Roxy should initially be standing")
	assert(roxy.is_in_duct == false, "FAILED: Roxy should not be in duct initially")

	# Engage crouch
	roxy.set_crouch(true)
	assert(roxy.is_crouching == true, "FAILED: is_crouching should be true after set_crouch(true)")
	var col = roxy.get_node_or_null("CollisionShape3D")
	assert(col != null and col.shape is CapsuleShape3D, "FAILED: CollisionShape3D missing or not Capsule")
	var cap = col.shape as CapsuleShape3D
	assert(cap.height < 1.0, "FAILED: Crouch collision height should be < 1.0m (actual: " + str(cap.height) + ")")

	# Engage duct crawl
	roxy.set_in_duct(true)
	assert(roxy.is_in_duct == true, "FAILED: is_in_duct should be true")
	assert(roxy.is_crouching == true, "FAILED: Duct entry must force crouch")
	assert(roxy.jump() == false, "FAILED: Jumping inside ventilation duct must be disallowed")

	# Exit duct
	roxy.set_in_duct(false)
	assert(roxy.is_in_duct == false, "FAILED: is_in_duct should be false after exit")

	roxy.queue_free()
	print("[PASS] test_roxy_crouch_and_duct_crawling: Roxy crouching, low collision height, and duct crawl mode validated.")
	return true

func test_vent_duct_prop_and_trigger() -> bool:
	var duct = VentDuctScene.instantiate()
	assert(duct != null, "FAILED: VentDuctScene could not be instantiated")
	assert(duct.is_in_group("vent_ducts"), "FAILED: Vent duct must be in 'vent_ducts' group")

	var interior_area = duct.find_child("DuctInteriorArea", true, false)
	assert(interior_area != null, "FAILED: DuctInteriorArea trigger missing on vent duct")

	duct.queue_free()
	print("[PASS] test_vent_duct_prop_and_trigger: Ventilation duct prop and interior trigger validated.")
	return true

func test_dredge_titan_and_lethal_ground_patrol() -> bool:
	var titan = DredgeTitanScene.instantiate()
	assert(titan != null, "FAILED: DredgeTitanScene could not be instantiated")
	assert(titan.is_in_group("titans"), "FAILED: Dredge Titan must be in 'titans' group")
	assert(titan.slam_damage >= 70, "FAILED: Titan ground slam must be heavy/lethal (>= 70 damage)")

	# Test EMP micro-stagger
	titan.take_damage(60, "emp")
	assert(titan.is_stunned == true, "FAILED: Titan should be micro-staggered by EMP")
	assert(titan.stun_timer <= 2.5, "FAILED: Titan EMP stagger should be brief (< 2.5s)")

	titan.queue_free()
	print("[PASS] test_dredge_titan_and_lethal_ground_patrol: Dredge Titan dimensions, slam damage, and armor deflection validated.")
	return true

func test_superweapon_assembly_and_burnout() -> bool:
	var bench = WeaponsTestBenchScene.instantiate()
	assert(bench != null, "FAILED: WeaponsTestBenchScene could not be instantiated")
	assert(bench.is_in_group("test_benches"), "FAILED: Bench must be in 'test_benches' group")

	var roxy = RoxyVanceScene.instantiate()
	assert(roxy.has_superweapon == false, "FAILED: Roxy should not start with superweapon")

	# Mock inventory parts
	bench.installed_parts = ["singularity_magnetron", "singularity_cryo", "singularity_key"]
	bench.interact(roxy)
	assert(bench.is_weapon_armed == true, "FAILED: Test-bench should be armed after 3/3 parts installed")
	assert(roxy.has_superweapon == true, "FAILED: Roxy should have superweapon equipped after assembly")

	# Test discharge and catastrophic meltdown
	var res = roxy.discharge_superweapon()
	assert(res == true, "FAILED: Superweapon discharge should succeed")
	assert(roxy.has_superweapon == false, "FAILED: Superweapon must be permanently consumed/melted after single use")

	bench.queue_free()
	roxy.queue_free()
	print("[PASS] test_superweapon_assembly_and_burnout: Singularity cannon assembly, discharge, and permanent thermal meltdown validated.")
	return true

func test_arch_compiler_goliath_boss_mechanics() -> bool:
	var boss = ArchCompilerGoliathScene.instantiate()
	assert(boss != null, "FAILED: ArchCompilerGoliathScene could not be instantiated")
	assert(boss.is_in_group("bosses"), "FAILED: Boss must be in 'bosses' group")

	# EMP hit only staggers
	boss.take_damage(60, "emp")
	assert(boss.is_stunned == true, "FAILED: Standard EMP should micro-stagger Goliath")
	assert(boss.is_dead == false, "FAILED: Goliath must not die to regular EMP")

	# Superweapon lethal breach
	boss.take_superweapon_hit()
	assert(boss.is_dead == true, "FAILED: Goliath must be neutralized by Singularity Cannon")

	boss.queue_free()
	print("[PASS] test_arch_compiler_goliath_boss_mechanics: Arch-Compiler Goliath boss armor, stagger, and superweapon breach validated.")
	return true

func test_level_07_scene_architecture() -> bool:
	var level = Level07Scene.instantiate()
	assert(level != null, "FAILED: Level 07 scene could not be instantiated")

	# Navigation markers
	var spawn = level.find_child("SpawnPoint", true, false)
	var backtrack = level.find_child("BacktrackPortal", true, false)
	assert(spawn != null, "FAILED: Level 07 SpawnPoint missing")
	assert(backtrack != null, "FAILED: Level 07 BacktrackPortal missing")

	# Ventilation Ducts
	var ducts = level.find_child("VentilationDucts", true, false)
	assert(ducts != null and ducts.get_child_count() >= 3, "FAILED: At least 3 duct shaft sections required in Sector 07")

	# Enemies & Boss
	var titan = level.find_child("DredgeTitan_Trench", true, false)
	var boss = level.find_child("ArchCompilerGoliath", true, false)
	assert(titan != null, "FAILED: Dredge Titan missing in Sector 07 trench")
	assert(boss != null, "FAILED: Arch-Compiler Goliath missing in Sector 07 Blast Core")

	# Scavenge Parts (Magnetron, Cryo, Key)
	var part_mag = level.find_child("Part_Magnetron", true, false)
	var part_cryo = level.find_child("Part_Cryo", true, false)
	var part_key = level.find_child("Part_Key", true, false)
	assert(part_mag != null, "FAILED: Magnetron part missing in Sector 07")
	assert(part_cryo != null, "FAILED: Cryo capsule missing in Sector 07")
	assert(part_key != null, "FAILED: Matrix key missing in Sector 07")

	# Test bench & Exit gate
	var bench = level.find_child("WeaponsTestBench", true, false)
	var exit_trig = level.find_child("Sector08ExitTrigger", true, false)
	assert(bench != null, "FAILED: WeaponsTestBench missing in Sector 07")
	assert(exit_trig != null, "FAILED: Sector08ExitTrigger missing in Sector 07")

	level.queue_free()
	print("[PASS] test_level_07_scene_architecture: Sector 07 Stack Overflow Vault architecture, ducts, titan, parts, and boss validated.")
	return true
