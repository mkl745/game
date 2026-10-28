extends Node
const PATH := "user://teachers_pet_save.json"
func save_game() -> void:
	var data := {"chapter": GameState.chapter, "day": GameState.day, "energy": GameState.energy, "staff": GameState.staff_trust, "students": GameState.student_standing, "credibility": GameState.credibility, "heat": GameState.heat, "conscience": GameState.conscience, "favor": GameState.favor, "flags": GameState.flags, "evidence": IntelManager.evidence}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))
func load_game() -> bool:
	if not FileAccess.file_exists(PATH): return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	GameState.chapter = d.get("chapter", 0); GameState.day = d.get("day", 1); GameState.energy = d.get("energy", 6)
	GameState.staff_trust = d.get("staff", 12); GameState.student_standing = d.get("students", 55); GameState.credibility = d.get("credibility", 70)
	GameState.heat = d.get("heat", 0); GameState.conscience = d.get("conscience", 60); GameState.favor = d.get("favor", {}); GameState.flags = d.get("flags", {})
	IntelManager.evidence.assign(d.get("evidence", [])); return true
