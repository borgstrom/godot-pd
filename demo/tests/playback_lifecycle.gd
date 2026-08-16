extends SceneTree
## Regression test for the AudioStreamPlayback lifecycle contract
## (_stop / _is_playing / _get_playback_position).
##
## Run headless from the demo folder:
##   godot --headless --path . --script tests/playback_lifecycle.gd
##
## Exits with the number of failed checks (0 = success).

var failures := 0


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
	for i in 12:
		await physics_frame

	check(player.has_stream_playback(), "playback exists after play()")
	check(player.playing, "player.playing is true while audio is active")
	var playback := player.get_stream_playback() as AudioStreamPlaybackPD
	check(playback != null, "playback is an AudioStreamPlaybackPD")
	var position := player.get_playback_position()
	check(position > 0.0, "playback position advances (%f)" % position)

	player.stop()
	for i in 3:
		await physics_frame
	check(not player.playing, "player.playing is false after stop()")

	player.play()
	for i in 3:
		await physics_frame
	check(player.get_stream_playback() != playback,
			"play() after stop() creates a new playback (patches must be re-opened)")
	player.stop()

	print("done: %d failure(s)" % failures)
	quit(failures)
