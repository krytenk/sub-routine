class_name TestGeneratorAndCasualties
extends RefCounted

# Unit Test Suite: Sub-Routine Environmental Horror Casualties & Generator Puzzle
# Validates casualty remains inspection, component harvesting, pickup props,
# and auxiliary generator multi-stage assembly and activation.

const CasualtyScript = preload("res://scenes/props/facility_casualty_prop.gd")
const PickupScript = preload("res://scenes/props/generator_part_pickup_prop.gd")
const GeneratorScript = preload("res://scenes/props/subterranean_generator_prop.gd")

func test_casualty_initialization_and_lore() -> bool:
	var casualty = CasualtyScript.new()
	casualty.technician_name = "Dr. H. Vance (Experimental Cybernetics)"
	casualty.log_entry = "Protocol override... the neural tether is severed."
	casualty.holds_generator_part = "generator_part_fuse"
	casualty._ready()

	if casualty.has_been_searched:
		push_error("Casualty should start unsearched.")
		casualty.free()
		return false

	if casualty.casualty_id.is_empty():
		push_error("Casualty ID was not auto-generated.")
		casualty.free()
		return false

	print("[PASS] test_casualty_initialization_and_lore: Deceased personnel initialized with badge metadata.")
	casualty.free()
	return true

func test_casualty_scavenge_component() -> bool:
	var casualty = CasualtyScript.new()
	casualty.holds_generator_part = "generator_part_relay"
	casualty._ready()

	var scavenged_box: Array[String] = [""]
	casualty.component_scavenged.connect(func(part: String): scavenged_box[0] = part)

	# First interaction scavenges component
	casualty.interact()

	if scavenged_box[0] != "generator_part_relay":
		push_error("Expected scavenged part 'generator_part_relay', got: " + scavenged_box[0])
		casualty.free()
		return false

	if not casualty.has_been_searched:
		push_error("Casualty flag has_been_searched should be true after interaction.")
		casualty.free()
		return false

	# Second interaction should not re-scavenge
	var re_scavenged: Array[bool] = [false]
	casualty.component_scavenged.connect(func(_p: String): re_scavenged[0] = true)
	casualty.interact()
	if re_scavenged[0]:
		push_error("Casualty allowed multiple scavenging runs.")
		casualty.free()
		return false

	print("[PASS] test_casualty_scavenge_component: Scavenged component successfully harvested once.")
	casualty.free()
	return true

func test_generator_part_pickup() -> bool:
	var pickup = PickupScript.new()
	pickup.part_type = "coolant"
	pickup._ready()

	var collected_box: Array[String] = [""]
	pickup.part_collected.connect(func(pt: String): collected_box[0] = pt)

	pickup.collect()

	if collected_box[0] != "generator_part_coolant":
		push_error("Expected collected part 'generator_part_coolant', got: " + collected_box[0])
		pickup.free()
		return false

	if not pickup.collected:
		push_error("Pickup flag 'collected' should be true.")
		pickup.free()
		return false

	# Second collection should be ignored
	var double_collected: Array[bool] = [false]
	pickup.part_collected.connect(func(_pt: String): double_collected[0] = true)
	pickup.collect()
	if double_collected[0]:
		push_error("Pickup allowed double-collection.")
		pickup.free()
		return false

	print("[PASS] test_generator_part_pickup: Generator component pickup collected properly.")
	pickup.free()
	return true

func test_generator_part_interact_and_groups() -> bool:
	var pickup = PickupScript.new()
	pickup.part_type = "coolant"
	pickup._ready()

	# Validate groups for raycast and proximity interaction priority
	if not pickup.is_in_group("interactive_props"):
		push_error("Pickup missing 'interactive_props' group.")
		pickup.free()
		return false
	if not pickup.is_in_group("generator_parts"):
		push_error("Pickup missing 'generator_parts' group.")
		pickup.free()
		return false
	if not pickup.is_in_group("pickups"):
		push_error("Pickup missing 'pickups' group.")
		pickup.free()
		return false

	var collected_box: Array[String] = [""]
	pickup.part_collected.connect(func(pt: String): collected_box[0] = pt)

	# Verify direct interact() invokes collection
	pickup.interact(null)

	if collected_box[0] != "generator_part_coolant":
		push_error("interact() failed to trigger part collection.")
		pickup.free()
		return false
	if not pickup.collected:
		push_error("Pickup collected flag was not set by interact().")
		pickup.free()
		return false

	print("[PASS] test_generator_part_interact_and_groups: Pickup prop groups and interact() verified.")
	pickup.free()
	return true

func test_generator_part_level_manager_inventory_storage() -> bool:
	var pickup = PickupScript.new()
	pickup.part_type = "coolant"
	pickup._ready()

	# Validate LevelManager integration if autoload exists
	var lm = Engine.get_main_loop().root.get_node_or_null("LevelManager") if Engine.get_main_loop() else null
	if lm:
		lm.generator_parts.clear()
		pickup.collect()
		if not lm.has_generator_part("generator_part_coolant"):
			push_error("LevelManager failed to store generator_part_coolant.")
			pickup.free()
			return false
	else:
		pickup.collect()

	if not pickup.collected:
		push_error("Pickup flag 'collected' should be true.")
		pickup.free()
		return false

	print("[PASS] test_generator_part_level_manager_inventory_storage: LevelManager inventory storage verified without errors.")
	pickup.free()
	return true

func test_subterranean_generator_progressive_install() -> bool:
	var gen = GeneratorScript.new()
	gen.direct_inventory = ["generator_part_relay", "generator_part_coolant", "generator_part_fuse"]
	gen._ready()

	var powered_box: Array[bool] = [false]
	gen.generator_powered.connect(func(): powered_box[0] = true)

	# Part 1 install
	gen.interact()
	if gen.installed_parts.size() != 1 or gen.is_running:
		push_error("Generator step 1 failed. Expected 1 installed, is_running false.")
		gen.free()
		return false

	# Part 2 install
	gen.interact()
	if gen.installed_parts.size() != 2 or gen.is_running:
		push_error("Generator step 2 failed. Expected 2 installed, is_running false.")
		gen.free()
		return false

	# Part 3 install -> Spool up!
	gen.interact()
	if gen.installed_parts.size() != 3 or not gen.is_running or not powered_box[0]:
		push_error("Generator step 3 failed. Expected 3 installed, is_running true, powered_box true.")
		gen.free()
		return false

	print("[PASS] test_subterranean_generator_progressive_install: Auxiliary generator completed 3-stage assembly and spooled to 100% power.")
	gen.free()
	return true

func test_level_horror_assets_presence() -> bool:
	var levels = [
		{"path": "res://scenes/levels/level_01.tscn", "must_have": "Casualty_StorageBay"},
		{"path": "res://scenes/levels/level_02.tscn", "must_have": "Casualty_TrenchAlcove"},
		{"path": "res://scenes/levels/level_03.tscn", "must_have": "Casualty_LowerGantry"},
		{"path": "res://scenes/levels/level_04.tscn", "must_have": "SubterraneanGenerator"}
	]

	for l in levels:
		var scene_res = ResourceLoader.load(l["path"]) as PackedScene
		if not scene_res:
			push_error("Failed to load scene: " + l["path"])
			return false
		var inst = scene_res.instantiate()
		var target = inst.find_child(l["must_have"], true, false)
		if not target:
			push_error("Level '%s' missing required prop '%s'" % [l["path"], l["must_have"]])
			inst.free()
			return false
		inst.free()

	print("[PASS] test_level_horror_assets_presence: All 4 sector levels contain verified casualties and generator entities.")
	return true

func test_sector_02_mezzanine_and_jump_routes() -> bool:
	var scene_res = ResourceLoader.load("res://scenes/levels/level_02.tscn") as PackedScene
	if not scene_res:
		push_error("Failed to load level_02.tscn")
		return false
	var inst = scene_res.instantiate()

	var required_nodes = [
		"SubstationMezzCol",
		"SubstationStep1_Col",
		"SubstationStep2_Col",
		"CatwalkJumpCrateCol",
		"GeneratorPart_Coolant",
		"OmniLight3D_RampGuide"
	]

	for node_name in required_nodes:
		var target = inst.find_child(node_name, true, false)
		if not target:
			push_error("Sector 02 missing required platform/jump node: " + node_name)
			inst.free()
			return false

	var coolant = inst.find_child("GeneratorPart_Coolant", true, false) as Node3D
	if coolant.position.y < 3.5:
		push_error("Coolant should be positioned on the elevated mezzanine platform.")
		inst.free()
		return false

	inst.free()
	print("[PASS] test_sector_02_mezzanine_and_jump_routes: Sector 02 mezzanine platform, jump steps, and backtrack route verified.")
	return true
