extends Node2D
var player := Vector2(640, 410)
var speed := 245.0
var message := "به هنرستان خوش آمدی؛ اینجا استعداد مهم است، مخصوصاً در تعریف‌کردن."
var panel: PanelContainer
var body_label: Label
var hud: Label
var joy_vec := Vector2.ZERO
var interaction_index := 0
var current_person := "principal"
var places := [{"name":"مدیر", "id":"principal", "pos":Vector2(940,220)}, {"name":"معاون", "id":"deputy", "pos":Vector2(855,310)}, {"name":"استاد کیانی", "id":"painting", "pos":Vector2(385,250)}, {"name":"استاد حمیدی", "id":"ceramics", "pos":Vector2(210,420)}, {"name":"خانم نوری", "id":"math", "pos":Vector2(600,235)}, {"name":"آقا رحیم", "id":"guard", "pos":Vector2(1060,500)}, {"name":"خاله ملیحه", "id":"canteen", "pos":Vector2(800,500)}, {"name":"آرمان", "id":"arman", "pos":Vector2(520,440)}, {"name":"سارا", "id":"sara", "pos":Vector2(350,500)}, {"name":"نیلوفر", "id":"niloufar", "pos":Vector2(440,330)}, {"name":"مهرداد", "id":"mehrdad", "pos":Vector2(700,400)}, {"name":"کامیار", "id":"kamyar", "pos":Vector2(150,540)}, {"name":"پارسا", "id":"parsa", "pos":Vector2(610,520)}, {"name":"ملیکا", "id":"malika", "pos":Vector2(730,340)}]
var room_names := ["حیاط", "کلاس‌ها", "آتلیه", "کارگاه سفال", "کتابخانه", "بوفه", "دفتر مدیر", "نمازخانه", "پشت کارگاه", "پارکینگ", "انبار", "بام"]
func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_build_ui()
	SaveManager.load_game()
	GameState.changed.connect(_refresh)
	_refresh()
func _build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(root)
	hud = Label.new(); hud.position = Vector2(18,15); hud.add_theme_font_size_override("font_size", 21); hud.add_theme_color_override("font_color", Color.WHITE); hud.add_theme_color_override("font_shadow_color", Color.BLACK); hud.add_theme_constant_override("shadow_offset_x",2); hud.add_theme_constant_override("shadow_offset_y",2); root.add_child(hud)
	panel = PanelContainer.new(); panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); panel.offset_left=15; panel.offset_right=-15; panel.offset_top=-160; panel.offset_bottom=-12; root.add_child(panel)
	var vb := VBoxContainer.new(); panel.add_child(vb)
	body_label=Label.new(); body_label.custom_minimum_size.y=46; body_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; body_label.add_theme_font_size_override("font_size",20); vb.add_child(body_label)
	var row := HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_CENTER; vb.add_child(row)
	_add_button(row,"تعامل",_interact); _add_button(row,"تعریف زیرکانه",func(): _flatter("subtle")); _add_button(row,"تعریف معمولی",func(): _flatter("normal")); _add_button(row,"اغراق!",func(): _flatter("grand")); _add_button(row,"شنود / مدرک",_gather); _add_button(row,"گزارش",_report); _add_button(row,"رویداد امروز",_event); _add_button(row,"دفترچه",_journal)
	var pad := HBoxContainer.new(); pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); pad.position=Vector2(20,-230); pad.add_theme_constant_override("separation",8); root.add_child(pad)
	_add_button(pad,"◀",func(): joy_vec.x=-1); _add_button(pad,"▲",func(): joy_vec.y=-1); _add_button(pad,"▼",func(): joy_vec.y=1); _add_button(pad,"▶",func(): joy_vec.x=1); _add_button(pad,"■",func(): joy_vec=Vector2.ZERO)
	_add_button(row,"ذخیره",func(): SaveManager.save_game(); _say("ذخیره شد. فردا هم همین مدرسه است."))
func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(100,48); b.add_theme_font_size_override("font_size",17); b.pressed.connect(callback); parent.add_child(b)
func _layout() -> void: queue_redraw()
func _process(delta: float) -> void:
	var axis:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if joy_vec != Vector2.ZERO: axis=joy_vec.normalized()
	player += axis*speed*delta; player.x=clampf(player.x,45,1235); player.y=clampf(player.y,105,575); GameState.player_position=player
	if axis != Vector2.ZERO: queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)),Color("243b37"))
	draw_rect(Rect2(35,100,1210,500),Color("567d67"))
	# school wings and courtyard paths
	draw_rect(Rect2(80,125,405,150),Color("d0a77d")); draw_rect(Rect2(520,125,300,115),Color("c9a47e")); draw_rect(Rect2(850,125,340,250),Color("b88e70"))
	draw_rect(Rect2(65,290,1120,14),Color("d7c69b")); draw_rect(Rect2(485,125,20,400),Color("d7c69b")); draw_rect(Rect2(820,125,18,410),Color("d7c69b"))
	for i in range(5): draw_circle(Vector2(150+i*220,350),18,Color("365d45")); draw_circle(Vector2(150+i*220,340),27,Color("648c5b"))
	for i in range(room_names.size()):
		var x:=90+float(i%4)*290; var y:=110+float(i/4)*35
		draw_string(ThemeDB.fallback_font,Vector2(x,y),room_names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff1ca"))
	for p in places:
		var pos:Vector2=p.pos; draw_circle(pos,16,Color("d66a50") if p.id in ["arman","kamyar"] else Color("e4d4a3")); draw_circle(pos,8,Color("31434d")); draw_string(ThemeDB.fallback_font,pos+Vector2(-35,32),p.name,HORIZONTAL_ALIGNMENT_LEFT,120,15,Color.WHITE)
	draw_circle(player,14,Color("46d7e7")); draw_circle(player+Vector2(-4,-3),4,Color("ffffff"))
func _nearest() -> Dictionary:
	var target:Dictionary={"id":"principal","name":"دکتر صادقی"}; var distance:=180.0
	for p in places:
		var d:float=player.distance_to(p.pos)
		if d<distance: distance=d; target=p
	return target
func _interact() -> void:
	var p:=_nearest(); current_person=str(p.id); _say(DialogueManager.speak(current_person))
	TimeManager.spend(); _refresh()
func _flatter(style:String) -> void:
	current_person=str(_nearest().get("id","principal")); _say(DialogueManager.compliment(current_person,style)); _refresh()
func _gather() -> void:
	var p:=_nearest(); var clue:=IntelManager.gather(str(p.get("name","همکلاسی")),"رفتار مشکوک نزدیک "+str(p.get("name","")),2,68)
	GameState.apply({"energy":-1}); _say("مدرک ثبت شد: %s. کیفیت %d؛ گزارش علنی یا بی‌نام؟" % [clue.subject,clue.quality]); _refresh()
func _report() -> void:
	if IntelManager.evidence.is_empty(): _say("دفترچه خالی است. اول چیزی ببین یا بشنو."); return
	var result:=IntelManager.report(0,"خانم رضوی",false,false); TimeManager.spend(); _say(result+" گرما %d؛ اعتبار %d." % [GameState.heat,GameState.credibility]); _refresh()
func _event() -> void:
	var e:=EventManager.daily_event();
	if e.is_empty(): return
	current_event=str(e.title); _show_choices(e)
func _show_choices(e:Dictionary) -> void:
	var choices:Array=e.get("choices",[]); var text:=str(e.get("title",""))+"\n"+str(e.get("body",""))+"\n\n"
	for i in range(choices.size()): text += str(i+1)+") "+str(choices[i].text)+"   "
	text += "\nبرای انتخاب از کلیدهای 1، 2 یا 3 استفاده کن."; _say(text)
func _unhandled_key_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and current_event!="":
		var n:=int(event.keycode)-KEY_1
		if n>=0 and n<3:
			var result:=EventManager.choose(n); TimeManager.spend(); current_event=""; _say(result); _refresh()
func _journal() -> void:
	var intel:="مدرکی نداری."
	for item in IntelManager.evidence: intel += "\n• "+str(item.subject)+": "+str(item.clue)+" (شدت "+str(item.severity)+")"
	_say("دفترچهٔ محرمانه\nاعتبار: %d | وجدان: %d | اعتماد: %d | محبوبیت: %d | گرما: %d\nفصل %d، روز %d؛ انرژی %d\nپایان احتمالی: %s\n%s" % [GameState.credibility,GameState.conscience,GameState.staff_trust,GameState.student_standing,GameState.heat,GameState.chapter+1,GameState.day,GameState.energy,EventManager.choose_ending(),intel])
func _say(text:String) -> void: message=text; body_label.text=message
func _refresh() -> void:
	if not is_instance_valid(hud): return
	hud.text="شاگرد نمونه  |  روز %d  %s  | انرژی %d  | اعتماد کارکنان %d  | جایگاه دانش‌آموزان %d  | گرما %d" % [GameState.day,TimeManager.daypart,GameState.energy,GameState.staff_trust,GameState.student_standing,GameState.heat]
func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_tree().paused=not get_tree().paused; _say("بازی مکث شد. دوباره Escape برای ادامه.")
