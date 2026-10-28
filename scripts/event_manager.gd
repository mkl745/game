extends Node
var events: Array = []
var selected: Dictionary = {}
var chapter_events := {0: [0], 1: [1, 2], 2: [3, 4], 3: [5, 6], 4: [7, 8], 5: [9]}
func _ready() -> void:
	var f := FileAccess.open("res://data/events.json", FileAccess.READ)
	if f: events = JSON.parse_string(f.get_as_text())
func daily_event() -> Dictionary:
	var day_key := "event_done_%d_%d" % [GameState.chapter, GameState.day]
	if GameState.flags.get(day_key, false): return {"title":"امروز برایت کافی بود", "body":"یک اتفاق در روز کافی است؛ بقیهٔ شایعه‌ها فردا هم سر جایشان هستند.", "choices":[]}
	var scripted: Array = chapter_events.get(GameState.chapter, [])
	var story_index := -1
	if not scripted.is_empty():
		if GameState.chapter == 0 and GameState.day == 1: story_index = scripted[0]
		elif GameState.chapter in [1, 2, 3, 4] and GameState.day <= 2: story_index = scripted[GameState.day - 1]
		elif GameState.chapter == 5 and GameState.day == 1: story_index = scripted[0]
	if story_index >= 0 and story_index < events.size():
		selected = events[story_index]
	else:
		var pool: Array = events.filter(func(e): return e.get("side", false))
		if pool.is_empty(): return {}
		selected = pool[randi() % pool.size()]
	GameState.flags[day_key] = true
	return selected
func choose(index: int) -> String:
	var choices: Array = selected.get("choices", [])
	if index < 0 or index >= choices.size(): return ""
	var choice: Dictionary = choices[index]
	GameState.apply(choice.get("effects", {}))
	if choice.has("flag"): GameState.flags[str(choice.flag)] = true
	return str(choice.get("result", "تصمیمت ثبت شد."))
func choose_ending() -> String:
	if GameState.heat >= 75 and GameState.credibility < 35: return "رسواشده"
	if GameState.conscience >= 72 and GameState.student_standing >= 55: return "بازگشت"
	if GameState.heat >= 55 and GameState.staff_trust >= 55: return "مأمور دوجانبه"
	if GameState.staff_trust >= 78 and GameState.student_standing < 30: return "قهرمان محبوب مدیر؛ تنها"
	if GameState.credibility >= 65 and GameState.heat >= 35: return "عروسک‌گردان"
	return "شاگردی که هنوز انتخاب دارد"
