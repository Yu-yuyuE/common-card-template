# GdUnit4 test runner — invoked by CI and /smoke-check
# Usage: godot --headless --script tests/gdunit4_runner.gd
extends SceneTree

func _init() -> void:
	OS.execute(OS.get_executable_path(), ["--headless", "-s", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "-a", "res://tests", "--ignoreHeadlessMode"])
	quit(0)
