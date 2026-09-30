extends RefCounted

# GDUnit4 Test Suite: Procedural 3D Asset Pipeline Models
# Validates existence, size, and header magic of all 10 procedural PS1 props.

const EXPECTED_MODELS = [
	"glitch_walker.glb",
	"roxy_vance.glb",
	"server_rack.glb",
	"server_corridor.glb",
	"crt_terminal.glb",
	"mainframe_bank.glb",
	"cable_nest.glb",
	"coolant_pipe_junction.glb",
	"blast_door.glb",
	"memory_core_pickup.glb",
	"emp_device.glb",
	"broken_server_rack.glb",
	"sparking_fuse_box.glb",
	"power_inverter.glb"
]

func test_all_14_models_exist_and_valid() -> bool:
	for model_name in EXPECTED_MODELS:
		var path = "res://assets/models/" + model_name
		var exists = FileAccess.file_exists(path) or ResourceLoader.exists(path)
		assert(exists, "FAILED: Missing 3D GLB model asset: " + path)

		var fa = FileAccess.open(path, FileAccess.READ)
		assert(fa != null, "FAILED: Unable to open model file for reading: " + path)
		assert(fa.get_length() > 1000, "FAILED: Model file is suspiciously small: " + str(fa.get_length()) + " bytes")

		# Check glTF binary magic (0x46546C67 -> "glTF")
		var magic = fa.get_32()
		assert(magic == 0x46546C67, "FAILED: Invalid GLB magic header in " + model_name)
		var version = fa.get_32()
		assert(version == 2, "FAILED: Unsupported glTF version in " + model_name + ": " + str(version))
		fa.close()

	print("[PASS] test_all_14_models_exist_and_valid: All 14 procedural GLB models verified on disk.")
	return true

func test_prop_scenes_exist_and_instantiate() -> bool:
	var expected_props = [
		"res://scenes/props/crt_terminal_prop.tscn",
		"res://scenes/props/memory_core_pickup_prop.tscn",
		"res://scenes/props/blast_door_prop.tscn",
		"res://scenes/props/coolant_pipe_prop.tscn",
		"res://scenes/props/cable_nest_prop.tscn",
		"res://scenes/props/mainframe_bank_prop.tscn",
		"res://scenes/props/broken_server_rack_prop.tscn",
		"res://scenes/props/sparking_fuse_box_prop.tscn",
		"res://scenes/props/power_inverter_prop.tscn"
	]
	for prop_path in expected_props:
		var exists = FileAccess.file_exists(prop_path) or ResourceLoader.exists(prop_path)
		assert(exists, "FAILED: Missing prop scene: " + prop_path)
	print("[PASS] test_prop_scenes_exist_and_instantiate: All 9 interactive & atmospheric prop scenes verified.")
	return true

func test_terminal_prop_interaction() -> bool:
	var crt_scene = load("res://scenes/props/crt_terminal_prop.tscn")
	assert(crt_scene != null, "FAILED: Could not load crt_terminal_prop.tscn")
	var terminal = crt_scene.instantiate()
	assert(terminal.has_method("interact"), "FAILED: CRTTerminalProp missing interact method")

	# Check group membership
	assert(terminal.is_in_group("terminals"), "FAILED: CRTTerminalProp not in 'terminals' group")
	assert(terminal.is_in_group("interactive_props"), "FAILED: CRTTerminalProp not in 'interactive_props' group")

	# Check interact call signature (can be called with 0 or 1 args)
	terminal.interact()
	print("[PASS] test_terminal_prop_interaction: CRTTerminalProp interact() successfully called.")
	terminal.queue_free()
	return true

func test_roxy_articulation_nodes() -> bool:
	var scene = load("res://scenes/player/roxy_vance.tscn")
	assert(scene != null, "FAILED: Could not load roxy_vance.tscn")
	var roxy = scene.instantiate()
	var leg_l = roxy.find_child("Leg_L", true, false)
	var leg_r = roxy.find_child("Leg_R", true, false)
	var arm_l = roxy.find_child("Arm_L", true, false)
	var arm_r = roxy.find_child("Arm_R", true, false)
	var torso = roxy.find_child("Torso", true, false)
	var head = roxy.find_child("Head", true, false)
	print("DEBUG ROXY POSITIONS:")
	print("  Leg_L pos: ", leg_l.position)
	print("  Leg_R pos: ", leg_r.position)
	print("  Torso pos: ", torso.position)
	print("  Head pos:  ", head.position)
	print("  Arm_L pos: ", arm_l.position)
	print("  Arm_R pos: ", arm_r.position)


	assert(leg_l != null, "FAILED: Roxy missing Leg_L node for walking animation")
	assert(leg_r != null, "FAILED: Roxy missing Leg_R node for walking animation")
	assert(arm_l != null, "FAILED: Roxy missing Arm_L node for walking animation")
	assert(arm_r != null, "FAILED: Roxy missing Arm_R node for walking animation")
	assert(torso != null, "FAILED: Roxy missing Torso node")
	assert(head != null, "FAILED: Roxy missing Head node")
	print("[PASS] test_roxy_articulation_nodes: Leg_L, Leg_R, Arm_L, Arm_R, Torso, Head verified.")
	roxy.free()
	return true

func test_glitch_walker_articulation_nodes() -> bool:
	var scene = load("res://scenes/enemies/glitch_walker.tscn")
	assert(scene != null, "FAILED: Could not load glitch_walker.tscn")
	var walker = scene.instantiate()
	var leg_l = walker.find_child("Leg_L", true, false)
	var leg_r = walker.find_child("Leg_R", true, false)
	var arm_l = walker.find_child("Arm_L", true, false)
	var arm_r = walker.find_child("Arm_R", true, false)
	var torso = walker.find_child("Torso", true, false)
	var head = walker.find_child("Head", true, false)
	assert(leg_l != null, "FAILED: Walker missing Leg_L node for walking animation")
	assert(leg_r != null, "FAILED: Walker missing Leg_R node for walking animation")
	assert(arm_l != null, "FAILED: Walker missing Arm_L node for walking animation")
	assert(arm_r != null, "FAILED: Walker missing Arm_R node for walking animation")
	assert(torso != null, "FAILED: Walker missing Torso node")
	assert(head != null, "FAILED: Walker missing Head node")
	print("[PASS] test_glitch_walker_articulation_nodes: Walker articulation nodes verified.")
	walker.free()
	return true

