extends Node3D

## dot-flashlight's headless suite.
##
##     godot --headless --path . res://examples/flashlight_selftest.tscn
##
## Counts sections run to their last line and a total of checks, because a script error aborts a section and not the run.

const EXPECTED_SECTIONS := 7
const EXPECTED_CHECKS := 70

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-flashlight")
	_config()
	_rules()
	_state()
	_battery()
	_replication()
	_crowd()
	_layers()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _config() -> void:
	var c := DotFlashlightConfig.new()
	_check(c.validate().ok, "defaults validate")
	_check(c.config_keys().size() >= 24, "every tunable is a config key", str(c.config_keys().size()))
	for k in ["range_m", "angle", "energy", "colour", "shadows", "shadows_on_web", "shadow_beams", "battery", "battery_seconds", "recharge_seconds", "key", "default_state", "allowed_maps", "remote_beams"]:
		_check(c.has_key(k), "key %s exists" % k)
	c.colour = "red"
	_check(not c.validate().ok, "a bad colour is refused")
	c.colour = "#ff0000"
	_check(c.beam_colour() == Color.html("#ff0000"), "colour parses")
	c.shadows_on_web = false
	_check(c.local_shadows() == (c.shadows and not (DotPlatform.is_web() or DotPlatform.is_mobile())), "shadows follow the platform")
	_sections += 1


func _rules() -> void:
	var c := DotFlashlightConfig.new()
	_check(DotFlashlightRules.start_on(c, "m", 0.05), "dark ambient starts on by default")
	_check(not DotFlashlightRules.start_on(c, "m", 0.8), "a bright map starts off")
	_check(DotFlashlightRules.start_on(c, "m", 0.8, "interior_horror"), "a dark mood starts on though bright")
	c.default_state = DotFlashlightConfig.START_ON
	_check(DotFlashlightRules.start_on(c, "m", 0.9), "default on starts on anywhere")
	c.default_state = DotFlashlightConfig.START_OFF
	_check(not DotFlashlightRules.start_on(c, "m", 0.0), "default off starts off even when dark")
	c.default_state = DotFlashlightConfig.START_ON
	c.allowed_maps = PackedStringArray(["a"])
	_check(DotFlashlightRules.allowed_on(c, "a") and not DotFlashlightRules.allowed_on(c, "b"), "allowed maps filter")
	_check(not DotFlashlightRules.start_on(c, "b", 0.0), "a disallowed map never starts on")
	c.enabled = false
	_check(not DotFlashlightRules.allowed_on(c, "a"), "disabled is allowed nowhere")
	var near := DotFlashlightRules.nearest(PackedFloat32Array([5.0, 1.0, 3.0, 9.0]), 2)
	_check(near.size() == 2 and near[0] == 1 and near[1] == 2, "nearest picks the two smallest", str(near))
	_check(DotFlashlightRules.nearest(PackedFloat32Array([1.0]), 0).is_empty(), "nearest of zero is none")
	_sections += 1


func _node(authoritative := true) -> DotFlashlight:
	var host := Node3D.new()
	add_child(host)
	var fl := DotFlashlight.new()
	fl.config = DotFlashlightConfig.new()
	fl.handle_input = false
	fl.authoritative = authoritative
	host.add_child(fl)
	return fl


func _state() -> void:
	var fl := _node()
	_check(fl.beam != null and fl.beam.get_parent() == fl.get_parent(), "the beam mounts on the host (the parent by default)")
	_check(not fl.on and not fl.beam.visible, "starts off")
	var clicks := []
	fl.clicked.connect(func(v: bool) -> void: clicks.append(v))
	_check(fl.toggle() and fl.on and fl.beam.visible, "toggle lights it")
	_check(clicks == [true], "and clicks once")
	_check(fl.beam.spot_range == fl.config.range_m and is_equal_approx(fl.beam.spot_angle, fl.config.angle), "beam takes the config")
	_check(not fl.request(true), "asking for the state it is in does nothing")
	fl.toggle()
	_check(not fl.on and clicks == [true, false], "toggle off clicks again")
	fl.allowed = false
	_check(not fl.toggle() and not fl.on, "a disallowed light refuses")
	fl.begin_map("m", 0.05)
	_check(fl.allowed and fl.on, "begin_map on a dark map lights it")
	fl.begin_map("m", 0.9)
	_check(not fl.on, "begin_map on a bright map puts it out")
	fl.config.allowed_maps = PackedStringArray(["x"])
	fl.begin_map("m", 0.0)
	_check(not fl.allowed and not fl.on and not fl.toggle(), "a map off the list: no light, no toggle")
	fl.config.allowed_maps = PackedStringArray()
	fl.begin_map("m", 0.0)
	fl.energy_scale = 0.5
	fl._process(0.1)
	_check(is_equal_approx(fl.beam.light_energy, fl.config.energy * 0.5), "a game's energy_scale dims the beam")
	fl.config.range_m = 12.0
	fl.refresh()
	_check(fl.beam.spot_range == 12.0, "refresh restyles the beam from a changed config")
	var h := Node3D.new()
	add_child(h)
	var by_ref := DotFlashlight.new()
	by_ref.handle_input = false
	by_ref.host = DotNodeRef.of_path(NodePath("../Eye"))
	var eye := Node3D.new()
	eye.name = "Eye"
	h.add_child(eye)
	h.add_child(by_ref)
	_check(by_ref.beam != null and by_ref.beam.get_parent() == eye, "the host is a DotNodeRef")
	_sections += 1


func _battery() -> void:
	var fl := _node()
	fl.config.battery = true
	fl.config.battery_seconds = 10.0
	fl.config.recharge_seconds = 20.0
	fl.toggle()
	var dead := []
	fl.depleted.connect(func() -> void: dead.append(1))
	for i in 11:
		fl._process(1.0)
	_check(not fl.on and dead.size() == 1 and fl.charge == 0.0, "a battery runs dry in battery_seconds and the light goes out")
	_check(not fl.toggle(), "a dead battery cannot be lit")
	for i in 2:
		fl._process(1.0)
	_check(is_equal_approx(fl.charge, 0.1) and fl.toggle(), "recharging reaches restart_charge, then it lights")
	_check(DotFlashlightRules.flicker(fl.config, 0.5, 1.0) == 1.0, "a healthy battery does not flicker")
	_check(DotFlashlightRules.flicker(fl.config, 0.05, 1.0) < 1.0, "a weak one does")
	var c := DotFlashlightConfig.new()
	_check(DotFlashlightRules.step_charge(c, 1.0, true, 100.0) == 1.0, "no battery never drains")
	_sections += 1


func _replication() -> void:
	var server := _node(true)
	var client := _node(false)
	var asked := []
	client.switch_requested.connect(func(v: bool) -> void: asked.append(v))
	client.toggle()
	_check(client.on and asked == [true], "a client shows the switch at once and asks the server")
	server.request(asked[0])
	client.apply_state(server.state())
	_check(server.on and client.on, "the server's answer agrees")
	server.config.battery = false
	server.request(false)
	client.apply_state(server.state())
	_check(not client.on and asked == [true], "a server change reaches the client without asking back")
	var clicks := []
	client.clicked.connect(func(v: bool) -> void: clicks.append(v))
	client.apply_state({"on": true, "charge": 0.5})
	_check(client.on and clicks.is_empty() and is_equal_approx(client.charge, 0.5), "applied state is silent and carries the charge")
	_check(client.describe().has("authoritative") and not client.describe()["authoritative"], "describe says it is a client")
	var audio := _FakeAudio.new()
	var fl := _node()
	fl._audio = audio
	fl.toggle()
	_check(audio.played == [&"flashlight_on"], "the click plays through a dot-audio-shaped manager", str(audio.played))
	audio.catalogue.ids.clear()
	fl.toggle()
	_check(audio.played == [&"flashlight_on"], "an id the catalogue lacks is not played", str(audio.played))
	_sections += 1


func _crowd() -> void:
	var c := DotFlashlightConfig.new()
	c.shadows = true
	c.shadows_on_web = true
	c.shadow_beams = 2
	c.remote_beams = 5
	c.remote_range = 50.0
	var crowd := DotFlashlightCrowd.new()
	crowd.config = c
	add_child(crowd)
	for i in 120:
		crowd.set_lit(i, true)
		crowd.place(i, Vector3(float(i) * 0.5, 1.5, 0.0), Vector3.FORWARD)
	crowd.set_lit(500, false)
	crowd.place(500, Vector3(0, 1.5, 0), Vector3.FORWARD)
	crowd.set_viewer(Vector3.ZERO)
	crowd.rank()
	var d := crowd.describe()
	_check(d["tracked"] == 120, "an unlit player costs no light", str(d))
	_check(d["drawn"] == 5, "only remote_beams are drawn of 120", str(d))
	_check(d["shadowed"] == 2, "only shadow_beams cast shadows", str(d))
	var shadow_lights := 0
	var shown := 0
	for child in crowd.get_children():
		var s := child as SpotLight3D
		shown += 1 if s.visible else 0
		shadow_lights += 1 if s.shadow_enabled else 0
	_check(shown == 5 and shadow_lights == 2, "and the lights agree with the count", "%d %d" % [shown, shadow_lights])
	_check(crowd.get_child(0).visible and crowd.get_child(0).shadow_enabled, "the nearest one casts a shadow")
	crowd.set_viewer(Vector3(1000, 0, 0))
	crowd.rank()
	_check(crowd.describe()["drawn"] == 0, "beams past remote_range are not drawn")
	crowd.set_viewer(Vector3.ZERO)
	c.shadows_on_web = false
	if DotPlatform.is_web():
		crowd.rank()
		_check(crowd.describe()["shadowed"] == 0, "no shadows on the web by default")
	else:
		_check(true, "(platform is not web; web rule covered by local_shadows)")
	crowd.retain([1, 2, 3])
	_check(crowd.describe()["tracked"] == 3, "retain keeps only who is still here")
	crowd.set_lit(0, true)
	crowd.remove(0)
	crowd.set_lit(1, true)
	crowd.rank()
	_check(crowd.describe()["tracked"] == 3, "a player removed is forgotten")
	_sections += 1


func _layers() -> void:
	var c := DotFlashlightConfig.new()
	var applied := c.apply_dictionary({"range_m": 33.0, "battery": true, "allowed_maps": ["a", "b"], "shadow_beams": 7})
	_check(applied.size() == 4 and c.range_m == 33.0 and c.battery and c.allowed_maps.size() == 2 and c.shadow_beams == 7, "a dictionary layer sets every type", str(applied))
	c.apply_cli("--flashlight-")
	var r := DotFlashlightConfig.from_files()
	_check(r.ok and r.value is DotFlashlightConfig, "from_files returns a config")
	_check((r.value as DotFlashlightConfig).describe().begins_with("flashlight"), "describe says what it is")
	_check(c.env_prefix() == "DOT_FLASHLIGHT_" and c.cli_prefix() == "--flashlight-", "env and command-line prefixes")
	_sections += 1


class _FakeAudio extends RefCounted:
	var played: Array = []
	var catalogue := _Cat.new()

	func play(id: StringName) -> int:
		played.append(id)
		return 1


class _Cat extends RefCounted:
	var ids: Array = [&"flashlight_on", &"flashlight_off"]

	func has(id: StringName) -> bool:
		return ids.has(id)


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)
