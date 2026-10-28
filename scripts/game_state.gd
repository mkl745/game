extends Node
signal changed
var chapter := 0
var day := 1
var energy := 6
var staff_trust := 12
var student_standing := 55
var credibility := 70
var heat := 0
var conscience := 60
var favor := {"principal": 8, "deputy": 5, "painting": 10, "ceramics": 5, "math": 0, "guard": 0, "canteen": 0}
var flags: Dictionary = {}
var fatigue: Dictionary = {}
var player_position := Vector2(640, 390)
var ending := ""
var current_event := ""

func apply(effects: Dictionary) -> void:
	for key in effects:
		match key:
			"staff": staff_trust = clampi(staff_trust + int(effects[key]), 0, 100)
			"students": student_standing = clampi(student_standing + int(effects[key]), 0, 100)
			"credibility": credibility = clampi(credibility + int(effects[key]), 0, 100)
			"heat": heat = clampi(heat + int(effects[key]), 0, 100)
			"conscience": conscience = clampi(conscience + int(effects[key]), 0, 100)
			"energy": energy = clampi(energy + int(effects[key]), 0, 8)
			"favor":
				var who: String = str(effects[key].get("who", "principal"))
				favor[who] = clampi(int(favor.get(who, 0)) + int(effects[key].get("amount", 0)), 0, 100)
			"flag": flags[str(effects[key].get("id", "event"))] = effects[key].get("value", true)
	changed.emit()

func next_day() -> void:
	flags.erase("event_done_%d_%d" % [chapter, day])
	day += 1
	energy = 6
	fatigue.clear()
	TimeManager.slot = 0
	if day > 5:
		day = 1
		chapter += 1
	if chapter >= 6:
		ending = EventManager.choose_ending()
	SaveManager.save_game()
	changed.emit()
