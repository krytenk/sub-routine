extends SceneTree

# Headless GDUnit4 CLI Test Runner for Godot 4 Engine
# Automatically discovers and executes all test suites in res://tests/

const TEST_FILES = [
	"test_roxy_damage_rules.gd",
	"test_environmental_hazards.gd",
	"test_difficulty_slider.gd",
	"test_overseer_fourth_wall.gd",
	"test_audio_manager.gd",
	"test_non_euclidean.gd",
	"test_levels.gd",
	"test_asset_models.gd",
	"test_subroutine_terminal.gd",
	"test_sector_04_concourse.gd",
	"test_sector_3_transition.gd",
	"test_audio_jumpscare_flow.gd",
	"test_generator_and_casualties.gd",
	"test_sector_05_and_elevator.gd",
	"test_sector_06_and_emp_upgrade.gd",
	"test_sector_07_ducts_and_boss.gd",
	"test_sector_08_and_09_stalking.gd",
	"test_maps_saves_and_credits.gd"
]

func _init() -> void:
	print("=================================================================")
	print(" SUB-ROUTINE IN-ENGINE GDUNIT4 CLI TEST RUNNER (GODOT 4)")
	print("=================================================================")

	var total_passed = 0
	var total_failed = 0
	var failed_tests: Array[String] = []

	for file_name in TEST_FILES:
		var candidate_paths = [
			"res://tests/" + file_name,
			"res://godot_project/tests/" + file_name
		]
		var resolved_path = ""
		for p in candidate_paths:
			if ResourceLoader.exists(p) or FileAccess.file_exists(p):
				resolved_path = p
				break

		if resolved_path == "":
			push_error("[GDUnit4] Test file not found: " + file_name)
			failed_tests.append(file_name + " (File not found)")
			total_failed += 1
			continue

		var script_res = ResourceLoader.load(resolved_path) as GDScript
		if not script_res:
			push_error("[GDUnit4] Failed to load script: " + resolved_path)
			failed_tests.append(file_name + " (Script load failed)")
			total_failed += 1
			continue

		if not script_res.can_instantiate():
			push_error("[GDUnit4] Script compilation failed: " + resolved_path)
			failed_tests.append(file_name + " (Compilation failed)")
			total_failed += 1
			continue

		var suite_name = file_name.get_basename()
		print("\n--- Running Suite: ", suite_name, " ---")

		var suite_instance = script_res.new()
		if not suite_instance:
			push_error("[GDUnit4] Failed to instantiate suite: " + suite_name)
			failed_tests.append(suite_name + " (Instantiation failed)")
			total_failed += 1
			continue

		var methods = suite_instance.get_method_list()
		for m in methods:
			var m_name: String = m["name"]
			if m_name.begins_with("test_"):
				print("  Executing: ", m_name, "...")
				# Execute test method
				var test_result = suite_instance.call(m_name)
				if test_result == true:
					total_passed += 1
				else:
					push_error("[GDUnit4] FAIL: " + suite_name + "." + m_name + " failed!")
					failed_tests.append(suite_name + "." + m_name)
					total_failed += 1

	print("\n=================================================================")
	print(" RESULTS: ", total_passed, " PASSED, ", total_failed, " FAILED")
	print("=================================================================")

	if total_failed > 0:
		print("[GDUnit4] FAILED TEST SUITES/METHODS:")
		for ft in failed_tests:
			print("  ❌ ", ft)
		print("[GDUnit4] Test suite finished with ERRORS (Exit code 1)")
		quit(1)
	else:
		print("[GDUnit4] All ", total_passed, " in-engine tests PASSED successfully (Exit code 0)")
		quit(0)
