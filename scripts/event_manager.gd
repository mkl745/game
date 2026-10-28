extends Node
var events: Array = []
var selected: Dictionary = {}
func _ready() -> void:
	var f := FileAccess.open("res://data/events.json", FileAccess.READ)
	if f: events = JSON.parse_string(f.get_as_text())
func daily_event() -> Dictionary:
	var day_key := "event_done_%d_%d" % [GameState.chapter, GameState.day]
	if GameState.flags.get(day_key, false): return {"title":"امروز برایت کافی بود", "body":"یک اتفاق در روز کافی است؛ بقیهٔ شایعه‌ها فردا هم سر جایشان هستند.", "choices":[]}
	var pool: Array = events.filter(func(e): return int(e.get("chapter", 0)) <= GameState.chapter)
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
