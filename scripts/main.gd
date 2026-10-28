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
var touch_directions := {"left": false, "right": false, "up": false, "down": false}
var people := [
	{"name":"دکتر صادقی", "id":"principal", "pos":Vector3(17,0,7), "color":Color("8f5576")},
	{"name":"خانم رضوی", "id":"deputy", "pos":Vector3(12,0,7), "color":Color("406b8e")},
	{"name":"استاد کیانی", "id":"painting", "pos":Vector3(-7,0,-7), "color":Color("a94d4d")},
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
	_add_box(label, pos, size, color)
	# Slightly raised, dark window bands and bright door frames read as real façades.
	var sign_pos := Vector3(pos.x, pos.y + size.y * 0.72, pos.z + size.z * 0.51)
	_add_box("سردر", sign_pos, Vector3(size.x * 0.74, 0.42, 0.12), Color("574c47"))
	_add_label("   •   ".join(rooms), sign_pos + Vector3(0,0.28,0.12), 0.22)
	for i in range(3):
		var wx := pos.x - size.x * 0.3 + float(i) * size.x * 0.3
		_add_box("پنجره", Vector3(wx,pos.y + 0.6,pos.z + size.z * 0.51), Vector3(1.4,0.95,0.1), Color("86a8aa"))
	_add_box("در", Vector3(pos.x,pos.y-0.4,pos.z + size.z * 0.51), Vector3(1.4,2.3,0.15), Color("684b3b"))

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
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.36
	capsule.height = 1.55
	body.mesh = capsule
	body.position.y = 0.92
	body.material_override = _material(person.color)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	head.mesh = sphere
	head.position.y = 1.9
	head.material_override = _material(Color("e5bd99"))
	root.add_child(head)
	_add_billboard_name(root, str(person.name))

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
	var mesh := MeshInstance3D.new()
	var model := CapsuleMesh.new()
	model.radius = 0.36
	model.height = 1.65
	mesh.mesh = model
	mesh.position.y = 0.85
	mesh.material_override = _material(Color("4bd0d9"))
	player.add_child(mesh)
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
