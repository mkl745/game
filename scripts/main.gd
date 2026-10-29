extends Node3D

const WORLD_BOUNDS := Vector2(24.0, 15.0)
const MOVE_SPEED := 6.0
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var body_label: Label
var event_pending := false
var current_event := ""
var current_person := "principal"
var joy := Vector2.ZERO
var elapsed := 0.0
var npc_models: Array[Node3D] = []
var player_limbs: Dictionary = {}
var walk_phase := 0.0
var touch_directions := {"left": false, "right": false, "up": false, "down": false}
var people := [
	{"name":"دکتر صادقی", "id":"principal", "pos":Vector3(17,0,7), "color":Color("8f5576")},
	{"name":"خانم رضوی", "id":"deputy", "pos":Vector3(12,0,7), "color":Color("406b8e")},
	{"name":"استاد کیانی", "id":"painting", "pos":Vector3(-5,0,-4.6), "color":Color("a94d4d")}, 
	{"name":"استاد حمیدی", "id":"ceramics", "pos":Vector3(-17,0,1), "color":Color("d1a456")},
	{"name":"خانم نوری", "id":"math", "pos":Vector3(4,0,-9), "color":Color("597e9e")},
	{"name":"آقا رحیم", "id":"guard", "pos":Vector3(21,0,8), "color":Color("866d4b")},
	{"name":"خاله ملیحه", "id":"canteen", "pos":Vector3(10,0,11), "color":Color("b85e50")},
	{"name":"آرمان", "id":"arman", "pos":Vector3(-1,0,5), "color":Color("cc6552")},
	{"name":"سارا", "id":"sara", "pos":Vector3(-8,0,10), "color":Color("628a68")},
	{"name":"نیلوفر", "id":"niloufar", "pos":Vector3(-9,0,-1), "color":Color("936f9c")},
	{"name":"مهرداد", "id":"mehrdad", "pos":Vector3(6,0,4), "color":Color("a48650")},
	{"name":"کامیار", "id":"kamyar", "pos":Vector3(-20,0,12), "color":Color("4c4c58")},
	{"name":"پارسا", "id":"parsa", "pos":Vector3(4,0,11), "color":Color("527f9a")},
	{"name":"ملیکا", "id":"malika", "pos":Vector3(8,0,-1), "color":Color("a35f76")}
]

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	SaveManager.load_game()
	GameState.changed.connect(_refresh)
	_refresh()
	_say("به هنرستان خوش آمدی؛ اینجا استعداد مهم است، مخصوصاً در تعریف‌کردن.")

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8198a2")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7d8c6")
	environment.ambient_light_energy = 0.75
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -28, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	_add_box("محوطهٔ هنرستان", Vector3(0,-0.3,0), Vector3(50,0.6,34), Color("78926f"))
	_add_box("حیاط آجری", Vector3(0,0.02,0), Vector3(20,0.08,12), Color("b59d7e"))
	# Three school wings define a navigable courtyard, rather than a 2D illustration.
	_add_building("کلاس‌های هنر", Vector3(-13,2,-11), Vector3(22,4,10), Color("bd9274"), ["آتلیه", "کلاس نقاشی", "کتابخانه"])
	_add_building("کارگاه‌ها", Vector3(-15,2,11), Vector3(18,4,8), Color("c3a176"), ["سفال و سرامیک", "انبار", "پشت کارگاه"])
	_add_building("دفتر و خدمات", Vector3(15,2,-8), Vector3(18,4,12), Color("ae806c"), ["دفتر مدیر", "دفتر معاون", "بوفه"])
	_add_building("ورودی هنرستان", Vector3(18,2,12), Vector3(11,4,7), Color("b99575"), ["نگهبانی", "نمازخانه"])
	_add_box("دیوار شمالی", Vector3(0,1.4,-16.5), Vector3(50,2.8,0.6), Color("857a6d"))
	_add_box("دیوار جنوبی", Vector3(0,1.4,16.5), Vector3(50,2.8,0.6), Color("857a6d"))
	_add_box("دیوار غربی", Vector3(-24.5,1.4,0), Vector3(0.6,2.8,33), Color("857a6d"))
	_add_box("دیوار شرقی", Vector3(24.5,1.4,0), Vector3(0.6,2.8,33), Color("857a6d"))
	# Planters, benches, a fountain, and school artwork give scale and landmarks.
	for p in [Vector3(-8,0,0), Vector3(-2,0,-2), Vector3(4,0,1), Vector3(10,0,3)]:
		_add_box("نیمکت", p + Vector3(0,0.35,0), Vector3(2.1,0.2,0.55), Color("73563f"))
		_add_box("پایهٔ نیمکت", p + Vector3(0,0.13,0), Vector3(1.7,0.25,0.22), Color("56534b"))
	for p in [Vector3(-7,0,-1), Vector3(2,0,3), Vector3(-17,0,-2), Vector3(20,0,5)]:
		_add_cylinder("درخت حیاط", p + Vector3(0,1.0,0), 0.32, 2.0, Color("6d503a"))
		_add_sphere("تاج درخت", p + Vector3(0,2.35,0), 1.15, Color("547d53"))
	_add_cylinder("حوض وسط حیاط", Vector3(0,0.25,0), 1.4, 0.5, Color("679ca0"))
	_add_box("تابلوی شاگرد نمونه", Vector3(6,1.8,-5), Vector3(3.5,2.2,0.25), Color("73503d"))
	_add_box("تابلوی طلایی", Vector3(6,1.9,-4.84), Vector3(3.1,1.75,0.08), Color("e2c777"))
	_add_label("شاگرد نمونهٔ سال", Vector3(6,3.25,-4.7), 0.5)
	for person in people:
		_add_npc(person)
	_add_label("حیاط مرکزی", Vector3(0,0.15,7), 0.45)

func _add_box(label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_building(label: String, pos: Vector3, size: Vector3, color: Color, rooms: Array) -> void:
	# The wings are open-roof, walk-in shells with genuine doorway gaps, partitions, and furnishings.
	var floor_y := 0.10
	var wall_h := size.y
	var wall_t := 0.32
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	_add_box(label + " floor", Vector3(pos.x,floor_y,pos.z), Vector3(size.x,0.16,size.z), color.lightened(0.13))
	# Every wing has a real courtyard-facing entrance; the workshop/gate face north, other wings south.
	_add_box(label + " west wall", Vector3(pos.x-half_x,wall_h*0.5,pos.z), Vector3(wall_t,wall_h,size.z), color.darkened(0.08))
	_add_box(label + " east wall", Vector3(pos.x+half_x,wall_h*0.5,pos.z), Vector3(wall_t,wall_h,size.z), color.darkened(0.08))
	var door_w := 2.1
	var side_w := (size.x-door_w)*0.5
	var door_north := label.contains("کارگاه") or label.contains("ورودی")
	var front_z := pos.z + half_z if not door_north else pos.z-half_z
	var rear_z := pos.z-half_z if not door_north else pos.z+half_z
	_add_box(label + " rear wall", Vector3(pos.x,wall_h*0.5,rear_z), Vector3(size.x,wall_h,wall_t), color)
	_add_box(label + " facade left", Vector3(pos.x-(door_w+side_w)*0.5,wall_h*0.5,front_z), Vector3(side_w,wall_h,wall_t), color)
	_add_box(label + " facade right", Vector3(pos.x+(door_w+side_w)*0.5,wall_h*0.5,front_z), Vector3(side_w,wall_h,wall_t), color)
	_add_box(label + " lintel", Vector3(pos.x,wall_h-0.22,front_z), Vector3(door_w,0.44,wall_t), color)
	var face_sign := 1.0 if not door_north else -1.0
	# The roofline is a shallow decorative cornice, not a roof; the camera can see the furnished rooms.
	_add_box(label + " cornice", Vector3(pos.x,wall_h+0.08,pos.z), Vector3(size.x+0.25,0.16,size.z+0.25), color.darkened(0.15))
	_add_box(label + " doorway left", Vector3(pos.x-door_w*0.5+0.10,1.0,front_z+face_sign*0.03), Vector3(0.16,2.0,0.10), Color("604334"))
	_add_box(label + " doorway right", Vector3(pos.x+door_w*0.5-0.10,1.0,front_z+face_sign*0.03), Vector3(0.16,2.0,0.10), Color("604334"))
	_add_box(label + " sign backing", Vector3(pos.x,wall_h-0.40,front_z+face_sign*0.22), Vector3(size.x*0.58,0.54,0.10), Color("57483e"))
	_add_label("  •  ".join(rooms), Vector3(pos.x,wall_h-0.22,front_z+face_sign*0.31), 0.20)
	for i in range(3):
		var wx := pos.x-half_x*0.68+float(i)*half_x*0.68
		if absf(wx-pos.x) < door_w*0.6: continue
		_add_box(label+" window",Vector3(wx,1.75,front_z+face_sign*0.05),Vector3(1.35,0.90,0.11),Color("87b5b8"))
		_add_box(label+" window sill",Vector3(wx,1.25,front_z+face_sign*0.10),Vector3(1.52,0.12,0.18),Color("eee1c7"))
	# Two broad interior dividers make separate classrooms/work areas. A gap remains as an internal doorway.
	if rooms.size() > 1:
		for divider in range(1,rooms.size()):
			var dx := pos.x-half_x+(size.x/rooms.size())*divider
			var room_gap := 1.35
			var section := (size.z-room_gap)*0.5
			_add_box(label+" room divider A",Vector3(dx,1.55,pos.z-half_z+section*0.5),Vector3(wall_t,3.1,section),color.darkened(0.04))
			_add_box(label+" room divider B",Vector3(dx,1.55,pos.z+half_z-section*0.5),Vector3(wall_t,3.1,section),color.darkened(0.04))
	# Functional-looking workshop/classroom details are made from meshes, with room to walk between them.
	if label.contains("کلاس"):
		_add_box("تختهٔ گچی",Vector3(pos.x,1.95,pos.z-half_z+0.22),Vector3(5.0,1.35,0.16),Color("345c53"))
		_add_box("تخته قاب",Vector3(pos.x,2.68,pos.z-half_z+0.32),Vector3(5.2,0.09,0.18),Color("865f3e"))
		for row in range(2):
			for col in range(3):
				var desk := Vector3(pos.x-5.0+float(col)*4.3,0,pos.z-1.0+float(row)*2.3)
				_add_box("میز هنرجو",desk+Vector3(0,0.85,0),Vector3(1.45,0.14,0.78),Color("a77b55"))
				_add_box("پایه میز",desk+Vector3(0,0.43,0),Vector3(0.10,0.76,0.10),Color("51473f"))
	elif label.contains("کارگاه"):
		for i in range(3):
			var table := Vector3(pos.x-5.0+float(i)*5.0,0,pos.z)
			_add_box("میز کارگاه",table+Vector3(0,0.95,0),Vector3(2.7,0.18,1.5),Color("936e4c"))
			_add_cylinder("کاسه سفالی",table+Vector3(0,1.28,0),0.48,0.48,Color("bc795a"))
		_add_box("قفسه رنگ",Vector3(pos.x+half_x-0.55,1.45,pos.z),Vector3(0.8,2.7,3.0),Color("79604a"))
	elif label.contains("دفتر"):
		for i in range(2):
			var desk := Vector3(pos.x-3.0+float(i)*6.0,0,pos.z+1.4)
			_add_box("میز اداری",desk+Vector3(0,0.86,0),Vector3(2.4,0.16,1.15),Color("805b43"))
			_add_box("کمد پرونده",desk+Vector3(0,1.55,-2.7),Vector3(1.7,2.9,0.55),Color("8e755e"))
	elif label.contains("ورودی"):
		_add_box("پیشخوان نگهبانی",Vector3(pos.x,0.8,pos.z+1.2),Vector3(3.2,1.4,0.7),Color("87684c"))
		_add_box("جاکفشی",Vector3(pos.x+3.4,0.8,pos.z-1.5),Vector3(1.5,1.4,0.7),Color("705541"))

func _add_label(text: String, pos: Vector3, size: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font = load("res://assets/fonts/Vazirmatn-Regular.ttf")
	label.font_size = 32
	label.pixel_size = size / 32.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff2d1")
	add_child(label)

func _add_npc(person: Dictionary) -> void:
	var root := Node3D.new()
	root.name = str(person.id)
	root.position = person.pos
	add_child(root)
	var look := _character_look(str(person.id), person.color)
	var limbs := _make_character(root, look)
	root.set_meta("limbs", limbs)
	_add_billboard_name(root, str(person.name))
	npc_models.append(root)

func _character_look(id: String, default_coat: Color) -> Dictionary:
	var palette := {
		"principal":{"hair":Color("55463e"),"pants":Color("343e4a"),"accent":Color("d6b45f"),"hair_style":"silver","prop":"portfolio"},
		"deputy":{"hair":Color("26252b"),"pants":Color("343f50"),"accent":Color("e0c88e"),"hair_style":"scarf","prop":"clipboard"},
		"painting":{"hair":Color("453529"),"pants":Color("343038"),"accent":Color("e1aa67"),"hair_style":"artist","prop":"brush"},
		"ceramics":{"hair":Color("847266"),"pants":Color("55574e"),"accent":Color("79a69a"),"hair_style":"soft","prop":"mug"},
		"math":{"hair":Color("332c2a"),"pants":Color("3e4b5a"),"accent":Color("bd8064"),"hair_style":"scarf","prop":"book"},
		"guard":{"hair":Color("77736b"),"pants":Color("51473d"),"accent":Color("d5a74c"),"hair_style":"cap","prop":"keys"},
		"canteen":{"hair":Color("3e2826"),"pants":Color("5d4641"),"accent":Color("f0d79a"),"hair_style":"scarf","prop":"tray"},
		"arman":{"hair":Color("392c27"),"pants":Color("374c5b"),"accent":Color("e1b64a"),"hair_style":"styled","prop":"phone"},
		"sara":{"hair":Color("342c2a"),"pants":Color("41464e"),"accent":Color("d2a4a0"),"hair_style":"scarf","prop":"notebook"},
		"niloufar":{"hair":Color("28272b"),"pants":Color("3a414b"),"accent":Color("b491c1"),"hair_style":"scarf","prop":"sketchbook"},
		"mehrdad":{"hair":Color("352d29"),"pants":Color("3d4851"),"accent":Color("d1ae55"),"hair_style":"neat","prop":"badge"},
		"kamyar":{"hair":Color("262328"),"pants":Color("343238"),"accent":Color("b35349"),"hair_style":"messy","prop":"hands"},
		"parsa":{"hair":Color("46372d"),"pants":Color("394454"),"accent":Color("81a5bd"),"hair_style":"neat","prop":"book"},
		"malika":{"hair":Color("292329"),"pants":Color("4a3d4b"),"accent":Color("e0ba5d"),"hair_style":"scarf","prop":"badge"}
	}
	var result: Dictionary = palette.get(id, {})
	result["coat"] = default_coat
	return result

func _make_character(parent: Node3D, look: Dictionary) -> Dictionary:
	var coat: Color = look.get("coat", Color("477c8d"))
	var pants: Color = look.get("pants", Color("384452"))
	var skin := Color("d9ad8f")
	# Tapered low-poly clothing, separate limbs, and polished shoes make each figure legible at a distance.
	var left_leg := _add_person_capsule(parent, "left trouser", 0.145, 0.72, Vector3(-0.18,0.49,0), pants)
	var right_leg := _add_person_capsule(parent, "right trouser", 0.145, 0.72, Vector3(0.18,0.49,0), pants)
	_add_person_box(parent, "left shoe", Vector3(0.26,0.13,0.34), Vector3(-0.19,0.12,0.07), Color("292b32"))
	_add_person_box(parent, "right shoe", Vector3(0.26,0.13,0.34), Vector3(0.19,0.12,0.07), Color("292b32"))
	_add_person_box(parent, "jacket", Vector3(0.72,0.87,0.42), Vector3(0,1.18,0), coat)
	_add_person_box(parent, "shirt collar", Vector3(0.23,0.28,0.035), Vector3(0,1.58,0.225), Color("f1e6d0"))
	_add_person_box(parent, "tie or scarf", Vector3(0.11,0.48,0.055), Vector3(0,1.30,0.24), look.get("accent",Color("d0a85b")))
	_add_person_capsule(parent, "neck", 0.12, 0.24, Vector3(0,1.68,0), skin)
	var left_arm := _add_person_capsule(parent, "left sleeve", 0.13, 0.72, Vector3(-0.47,1.18,0), coat)
	var right_arm := _add_person_capsule(parent, "right sleeve", 0.13, 0.72, Vector3(0.47,1.18,0), coat)
	_add_person_sphere(parent, "left hand", 0.13, Vector3(-0.48,0.78,0.08), skin)
	_add_person_sphere(parent, "right hand", 0.13, Vector3(0.48,0.78,0.08), skin)
	_add_person_sphere(parent, "face", 0.255, Vector3(0,1.96,0.015), skin)
	# Hair/headwear silhouettes are intentionally distinct and color-coded per named character.
	var hair: Color = look.get("hair",Color("302a29"))
	var style: String = str(look.get("hair_style","neat"))
	_add_person_sphere(parent, "hair cap", 0.265, Vector3(0,2.09,0.005), hair)
	if style == "scarf":
		_add_person_sphere(parent, "head scarf", 0.276, Vector3(0,2.00,-0.18), look.get("accent",coat))
		_add_person_box(parent, "scarf drape", Vector3(0.52,0.48,0.12), Vector3(0,1.79,-0.19), look.get("accent",coat))
	elif style == "cap":
		_add_person_box(parent, "guard cap", Vector3(0.55,0.16,0.50), Vector3(0,2.23,0), coat.darkened(0.18))
		_add_person_box(parent, "cap brim", Vector3(0.58,0.055,0.32), Vector3(0,2.17,0.16), look.get("accent",Color("d0a85b")))
	elif style in ["messy","artist"]:
		for tuft in [Vector3(-0.14,2.26,0.02),Vector3(0.02,2.30,0),Vector3(0.15,2.24,-0.02)]:
			_add_person_sphere(parent, "hair tuft", 0.11, tuft, hair)
	else:
		_add_person_box(parent, "side hair left", Vector3(0.12,0.35,0.18), Vector3(-0.22,1.94,0), hair)
		_add_person_box(parent, "side hair right", Vector3(0.12,0.35,0.18), Vector3(0.22,1.94,0), hair)
	# Eyes, brows, nose and a small smile face the courtyard path and the player.
	_add_person_sphere(parent, "left eye", 0.035, Vector3(-0.09,1.99,0.24), Color("332c2a"))
	_add_person_sphere(parent, "right eye", 0.035, Vector3(0.09,1.99,0.24), Color("332c2a"))
	_add_person_box(parent, "left brow", Vector3(0.10,0.025,0.035), Vector3(-0.09,2.07,0.25), hair.darkened(0.12))
	_add_person_box(parent, "right brow", Vector3(0.10,0.025,0.035), Vector3(0.09,2.07,0.25), hair.darkened(0.12))
	_add_person_sphere(parent, "nose", 0.045, Vector3(0,1.92,0.27), skin.lightened(0.08))
	_add_person_box(parent, "smile", Vector3(0.09,0.018,0.025), Vector3(0,1.85,0.25), Color("8e514c"))
	var prop := str(look.get("prop",""))
	if prop in ["portfolio","clipboard","book","notebook","sketchbook"]:
		_add_person_box(parent, "school folder", Vector3(0.35,0.48,0.12), Vector3(-0.52,1.12,0.20), look.get("accent",Color("d0a85b")))
		_add_person_box(parent, "folder label", Vector3(0.20,0.035,0.02), Vector3(-0.52,1.20,0.27), Color("f0e5cd"))
	elif prop == "mug":
		_add_person_cylinder(parent, "tea glass", 0.085, 0.20, Vector3(0.50,0.91,0.16), Color("cf9b58"))
	elif prop == "tray":
		_add_person_box(parent, "canteen tray", Vector3(0.50,0.08,0.34), Vector3(0.47,0.91,0.19), Color("d3c5a0"))
	elif prop == "brush":
		_add_person_box(parent, "paintbrush", Vector3(0.045,0.58,0.045), Vector3(0.51,1.08,0.18), Color("805c3e"))
		_add_person_sphere(parent, "brush tip", 0.06, Vector3(0.51,1.39,0.18), Color("df7157"))
	elif prop == "keys":
		_add_person_sphere(parent, "key ring", 0.10, Vector3(0.48,0.74,0.16), look.get("accent",Color("d0a85b")))
	elif prop == "badge":
		_add_person_sphere(parent, "council badge", 0.09, Vector3(0.22,1.43,0.23), look.get("accent",Color("d0a85b")))
	elif prop == "phone":
		_add_person_box(parent, "phone", Vector3(0.13,0.25,0.035), Vector3(0.48,1.02,0.22), Color("28333c"))
	# A small backpack gives students another readable silhouette; staff carry their trade tools instead.
	if prop in ["phone","notebook","sketchbook","badge"]:
		_add_person_box(parent, "backpack", Vector3(0.52,0.62,0.20), Vector3(0,1.08,-0.29), look.get("accent",Color("d0a85b")))
	return {"legs":[left_leg,right_leg], "arms":[left_arm,right_arm]}

func _add_person_box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.name = name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color)
	parent.add_child(instance)

func _add_person_sphere(parent: Node3D, name: String, radius: float, pos: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	instance.name = name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color)
	parent.add_child(instance)

func _add_person_capsule(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 4
	instance.name = name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _add_person_cylinder(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	instance.name = name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color)
	parent.add_child(instance)

func _add_billboard_name(parent: Node3D, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.position.y = 2.45
	label.font = load("res://assets/fonts/Vazirmatn-Regular.ttf")
	label.font_size = 36
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	parent.add_child(label)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func _add_cylinder(label: String, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = _material(color)
	mesh.name = label
	add_child(mesh)

func _add_sphere(label: String, pos: Vector3, radius: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = _material(color)
	mesh.name = label
	add_child(mesh)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0,0.1,8)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.65
	collision.shape = capsule
	collision.position.y = 0.85
	player.add_child(collision)
	var outfit := {"coat":Color("367e8b"),"pants":Color("344450"),"hair":Color("302a29"),"accent":Color("e3b94f"),"hair_style":"messy","prop":"sketchbook"}
	player_limbs = _make_character(player, outfit)
	_add_billboard_name(player, "من")
	add_child(player)
	camera = Camera3D.new()
	camera.position = Vector3(0, 11, 13)
	camera.current = true
	player.add_child(camera)
	camera.position = Vector3(0, 11, 13)
	camera.look_at(player.position + Vector3(0,0.5,0), Vector3.UP)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	hud = Label.new()
	hud.position = Vector2(18,12)
	hud.add_theme_font_size_override("font_size",20)
	hud.add_theme_color_override("font_color",Color.WHITE)
	hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	root.add_child(hud)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 12
	panel.offset_right = -12
	panel.offset_top = -142
	panel.offset_bottom = -10
	root.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	body_label = Label.new()
	body_label.custom_minimum_size.y = 42
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body_label.add_theme_font_size_override("font_size",19)
	vb.add_child(body_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",4)
	vb.add_child(row)
	_add_button(row,"تعامل",_interact)
	_add_button(row,"زیرکانه",func(): _flatter("subtle"))
	_add_button(row,"معمولی",func(): _flatter("normal"))
	_add_button(row,"اغراق",func(): _flatter("grand"))
	_add_button(row,"شنود/مدرک",_gather)
	_add_button(row,"گزارش",_report)
	_add_button(row,"رویداد",_event)
	_add_button(row,"دفترچه",_journal)
	_add_button(row,"ذخیره",func(): SaveManager.save_game(); _say("ذخیره شد."))
	var pad := HBoxContainer.new()
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(18,-205)
	pad.add_theme_constant_override("separation",5)
	root.add_child(pad)
	_add_direction(pad,"◀","left")
	_add_direction(pad,"▲","up")
	_add_direction(pad,"▼","down")
	_add_direction(pad,"▶","right")

func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(90,46)
	button.add_theme_font_size_override("font_size",16)
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_direction(parent: Node, text: String, direction: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(56,52)
	button.button_down.connect(func(): touch_directions[direction] = true)
	button.button_up.connect(func(): touch_directions[direction] = false)
	parent.add_child(button)

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(npc_models.size()):
		var model := npc_models[i]
		if is_instance_valid(model):
			model.position.y = sin(elapsed * 1.7 + float(i) * 0.8) * 0.025
			model.rotation.y = sin(elapsed * 0.7 + float(i)) * 0.045
	if not is_instance_valid(player): return
	var direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if touch_directions.left: direction.x -= 1
	if touch_directions.right: direction.x += 1
	if touch_directions.up: direction.y -= 1
	if touch_directions.down: direction.y += 1
	if direction.length() > 1.0: direction = direction.normalized()
	player.velocity.x = direction.x * MOVE_SPEED
	player.velocity.z = direction.y * MOVE_SPEED
	player.velocity.y -= 22.0 * delta
	player.move_and_slide()
	if direction.length() > 0.08:
		walk_phase += delta * 11.5
		player.rotation.y = atan2(direction.x, direction.y)
	var leg_swing := sin(walk_phase) * 0.38 if direction.length() > 0.08 else 0.0
	var legs: Array = player_limbs.get("legs", [])
	var arms: Array = player_limbs.get("arms", [])
	if legs.size() == 2:
		legs[0].rotation.z = move_toward(legs[0].rotation.z, leg_swing, delta * 5.0)
		legs[1].rotation.z = move_toward(legs[1].rotation.z, -leg_swing, delta * 5.0)
	if arms.size() == 2:
		arms[0].rotation.z = move_toward(arms[0].rotation.z, -leg_swing * 0.72, delta * 5.0)
		arms[1].rotation.z = move_toward(arms[1].rotation.z, leg_swing * 0.72, delta * 5.0)
	player.position.x = clampf(player.position.x, -23, 23)
	player.position.z = clampf(player.position.z, -15, 15)
	var target := player.position + Vector3(0,10,12)
	camera.global_position = camera.global_position.lerp(target, minf(1.0, delta * 4.2))
	camera.look_at(player.global_position + Vector3(0,0.8,0), Vector3.UP)
	GameState.player_position = Vector2(player.position.x, player.position.z)

func _nearest() -> Dictionary:
	var best: Dictionary = people[0]
	var best_distance := 3.25
	for person in people:
		var d: float = player.global_position.distance_to(person.pos)
		if d < best_distance:
			best_distance = d
			best = person
	return best

func _interact() -> void:
	var person := _nearest()
	current_person = str(person.id)
	_say(DialogueManager.speak(current_person))
	TimeManager.spend()
	_refresh()

func _flatter(style: String) -> void:
	current_person = str(_nearest().get("id","principal"))
	_say(DialogueManager.compliment(current_person,style))
	_refresh()

func _gather() -> void:
	var person := _nearest()
	var clue := IntelManager.gather(str(person.name),"رفتار مشکوک نزدیک "+str(person.name),2,68)
	GameState.apply({"energy":-1})
	_say("مدرک ثبت شد: %s؛ کیفیت %d." % [clue.subject, clue.quality])
	_refresh()

func _report() -> void:
	if IntelManager.evidence.is_empty():
		_say("مدرکی برای گزارش نداری. اول چیزی ببین یا بشنو.")
		return
	_say(IntelManager.report(0,"خانم رضوی",false,false))
	TimeManager.spend()
	_refresh()

func _event() -> void:
	var e := EventManager.daily_event()
	if e.is_empty(): return
	current_event = str(e.get("title",""))
	var text := str(e.get("title",""))+"\n"+str(e.get("body",""))+"\n\n"
	for i in range(e.get("choices",[]).size()):
		text += "%d) %s   " % [i+1, str(e.choices[i].text)]
	text += "\nانتخاب با کلیدهای 1 تا 3"
	_say(text)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and current_event != "":
		var index := int(event.keycode)-KEY_1
		if index >= 0 and index < 3:
			_say(EventManager.choose(index))
			TimeManager.spend()
			current_event = ""
			_refresh()

func _journal() -> void:
	var notes := ""
	for item in IntelManager.evidence:
		notes += "\n• "+str(item.subject)+": "+str(item.clue)
	if notes == "": notes = "\nدفترچه فعلاً خالی است."
	_say("دفترچهٔ محرمانه\nاعتبار %d | وجدان %d | اعتماد کارکنان %d | جایگاه دانش‌آموزان %d | گرما %d\nفصل %d، روز %d، انرژی %d\nپایان محتمل: %s%s" % [GameState.credibility,GameState.conscience,GameState.staff_trust,GameState.student_standing,GameState.heat,GameState.chapter+1,GameState.day,GameState.energy,EventManager.choose_ending(),notes])

func _say(text: String) -> void:
	if is_instance_valid(body_label): body_label.text = text

func _refresh() -> void:
	if not is_instance_valid(hud): return
	hud.text = "شاگرد نمونه  |  روز %d  %s  | انرژی %d  | اعتماد %d  | جایگاه %d  | گرما %d" % [GameState.day,TimeManager.daypart,GameState.energy,GameState.staff_trust,GameState.student_standing,GameState.heat]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused
		_say("بازی مکث شد. Escape برای ادامه.")
