extends Node3D

## A dark room, your beam and three other players' beams. `-- --shot out.png` saves a frame and quits.

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.015)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.ambient_light_energy = 0.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_box(Vector3(0, -0.1, -8), Vector3(20, 0.2, 24))
	_box(Vector3(0, 2, -16), Vector3(20, 4, 0.2))
	_box(Vector3(-5, 1, -9), Vector3(1, 2, 1))
	_box(Vector3(2, 0.75, -12), Vector3(1.5, 1.5, 1.5))

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 0)
	add_child(cam)
	var fl := DotFlashlight.new()
	fl.handle_input = false
	fl.config = DotFlashlightConfig.new()
	cam.add_child(fl)
	fl.begin_map("demo", 0.05, "interior_horror")
	cam.look_at(Vector3(-1, 1.0, -12))

	var crowd := DotFlashlightCrowd.new()
	crowd.config = fl.config
	add_child(crowd)
	crowd.set_viewer(cam.global_position)
	for i in 3:
		var at := Vector3(-6.0 + 5.0 * i, 1.5, -3.0 - 2.0 * i)
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.3
		capsule.height = 1.8
		body.mesh = capsule
		body.position = at - Vector3(0, 0.6, 0)
		add_child(body)
		crowd.set_lit(i, true)
		crowd.place(i, at, Vector3(0.6 - i * 0.6, -0.1, -1.0))
	crowd.rank()

	var shot := _arg("--shot")
	if shot != "":
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(shot)
		print("shot ", shot, " ", fl.describe(), " ", crowd.describe())
		get_tree().quit()


func _box(at: Vector3, size: Vector3) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.5, 0.45)
	m.material_override = mat
	add_child(m)


func _arg(name: String) -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find(name)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else ""
