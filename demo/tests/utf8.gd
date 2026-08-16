extends SceneTree
## Regression test for UTF-8 round-trips through Pd: symbols with
## non-ASCII characters must come back intact through the receive
## signals (String(const char *) would decode latin-1 and garble them).
##
## Writes a minimal echo patch ([r fromgd] -> [s togd]) to a temporary
## file so the test is self-contained.
##
## Run headless from the demo folder:
##   godot --headless --path . --script tests/utf8.gd
##
## Exits with the number of failed checks (0 = success).

const ECHO_PATCH := """#N canvas 100 100 450 300 12;
#X obj 20 20 r fromgd;
#X obj 20 50 s togd;
#X connect 0 0 1 0;
"""

var failures := 0
var got := {}


func check(cond: bool, what: String) -> void:
	if cond:
		print("ok - ", what)
	else:
		failures += 1
		printerr("FAIL - ", what)


func _initialize() -> void:
	var patch_path := OS.get_cache_dir().path_join("godot-pd-test-echo.pd")
	var f := FileAccess.open(patch_path, FileAccess.WRITE)
	f.store_string(ECHO_PATCH)
	f.close()

	var player := AudioStreamPlayer.new()
	player.stream = AudioStreamPD.new()
	root.add_child(player)
	for i in 3:
		await physics_frame

	player.play()
	var pd := player.get_stream_playback() as AudioStreamPlaybackPD
	check(pd != null, "playback available")
	check(pd.open_patch(patch_path) > 0, "echo patch opens")

	pd.subscribe("togd")
	pd.receive_symbol.connect(func(_dest: String, symbol: String): got["symbol"] = symbol)
	pd.receive_list.connect(func(_dest: String, list: Array): got["list"] = list)

	var symbol := "héllo→wörld"
	pd.send_symbol("fromgd", symbol)
	pd.send_list("fromgd", ["über", 1.5])

	for i in 30:
		await physics_frame

	check(got.get("symbol") == symbol,
			"UTF-8 symbol round-trips intact (got %s)" % [got.get("symbol")])
	check(got.get("list", []) == ["über", 1.5],
			"UTF-8 list element round-trips intact (got %s)" % [got.get("list")])

	player.stop()
	DirAccess.remove_absolute(patch_path)
	print("done: %d failure(s)" % failures)
	quit(failures)
