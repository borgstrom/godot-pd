extends SceneTree
## Regression test for Pd message and MIDI round-trips through the
## receive_* signals, using pd/test-echo.pd (r fromgd -> s togd, plus
## ctlin/ctlout, notein/noteout, and pgmin/pgmout echoes).
##
## Run headless from the demo folder:
##   godot --headless --path . --script tests/messaging.gd
##
## Exits with the number of failed checks (0 = success).

var failures := 0
var got := {}


func check(cond: bool, what: String) -> void:
	if cond:
		print("ok - ", what)
	else:
		failures += 1
		printerr("FAIL - ", what)


func _initialize() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = AudioStreamPD.new()
	root.add_child(player)
	for i in 3:
		await physics_frame

	player.play()
	var pd := player.get_stream_playback() as AudioStreamPlaybackPD
	check(pd != null, "playback available")
	check(pd.open_patch("./pd/test-echo.pd") > 0, "test-echo.pd opens")

	pd.subscribe("togd")
	pd.receive_bang.connect(func(dest: String): got["bang"] = dest)
	pd.receive_float.connect(func(_dest: String, num: float): got["float"] = num)
	pd.receive_symbol.connect(func(_dest: String, symbol: String): got["symbol"] = symbol)
	pd.receive_list.connect(func(_dest: String, list: Array): got["list"] = list)
	pd.receive_control_change.connect(
			func(channel: int, controller: int, value: int): got["cc"] = [channel, controller, value])
	pd.receive_note_on.connect(
			func(channel: int, pitch: int, velocity: int): got["note"] = [channel, pitch, velocity])
	pd.receive_program_change.connect(
			func(channel: int, value: int): got["pgm"] = [channel, value])

	pd.send_bang("fromgd")
	pd.send_float("fromgd", 13.37)
	pd.send_symbol("fromgd", "hello")
	pd.send_list("fromgd", ["a", 1, 2.5])
	pd.send_control_change(0, 7, 99)
	pd.send_note_on(0, 60, 101)
	pd.send_program_change(0, 42)

	# give the mixer time to run and the queued messages time to arrive
	for i in 30:
		await physics_frame

	check(got.get("bang") == "togd", "bang round-trips")
	check(absf(got.get("float", 0.0) - 13.37) < 0.001, "float round-trips")
	check(got.get("symbol") == "hello", "symbol round-trips")
	check(got.get("list", []) == ["a", 1.0, 2.5], "list round-trips")
	check(got.get("cc") == [0, 7, 99],
			"control change round-trips with channel, controller, and value (%s)" % [got.get("cc")])
	check(got.get("note") == [0, 60, 101], "note on round-trips (%s)" % [got.get("note")])
	check(got.get("pgm") == [0, 42], "program change round-trips (%s)" % [got.get("pgm")])

	player.stop()
	print("done: %d failure(s)" % failures)
	quit(failures)
