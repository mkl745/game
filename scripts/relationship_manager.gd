extends Node
var people := {}
func _ready() -> void:
	var file := FileAccess.open("res://data/characters.json", FileAccess.READ)
	if file: people = JSON.parse_string(file.get_as_text())
func compliment(id: String, style: String) -> Dictionary:
	var p: Dictionary = people.get(id, {})
	var likes: Array = p.get("likes", [])
	var base := {"subtle": 4, "normal": 7, "grand": 9}.get(style, 4)
	var key := id + ":" + style
	var count := int(GameState.fatigue.get(key, 0))
	var factor := maxf(0.2, 1.0 - count * 0.22)
	var topic: String = str(p.get("topic", "نظم"))
	var taste := 1.3 if topic in likes else (0.55 if style == "grand" else 0.85)
	var gain := roundi(base * taste * factor)
	GameState.fatigue[key] = count + 1
	GameState.favor[id] = clampi(int(GameState.favor.get(id, 0)) + gain, 0, 100)
	GameState.staff_trust = clampi(GameState.staff_trust + int(gain / 3), 0, 100)
	if count >= 2:
		GameState.credibility = max(0, GameState.credibility - 1)
	GameState.apply({"energy": -1, "conscience": -1 if style == "grand" and topic not in likes else 0})
	return {"gain": gain, "tired": count >= 2, "name": p.get("name", id)}
func react_report(severity: int, quality: int, public_report: bool, truth: String) -> void:
	var reward := severity * 2 + int(quality / 20.0)
	if public_report: reward = int(reward * 1.4)
	GameState.staff_trust = clampi(GameState.staff_trust + reward, 0, 100)
	GameState.student_standing = clampi(GameState.student_standing - severity * (2 if public_report else 1), 0, 100)
	GameState.heat = clampi(GameState.heat + severity * (3 if public_report else 1), 0, 100)
	if truth == "true": GameState.credibility = clampi(GameState.credibility + 2, 0, 100)
	else: GameState.credibility = max(0, GameState.credibility - 12)
