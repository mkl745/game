extends Node
var active_person := "principal"
var lines := {}
func _ready() -> void:
	var f := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	if f: lines = JSON.parse_string(f.get_as_text())
func speak(person: String, context := "greet") -> String:
	var p: Dictionary = lines.get(person, {})
	var options: Array = p.get(context, p.get("greet", ["وقتشه یه کاری بکنی."]))
	return str(options[randi() % options.size()])
func compliment(person: String, style: String) -> String:
	var result := RelationshipManager.compliment(person, style)
	return "%s — %s %d امتیاز گرفت. %s" % [speak(person, "reaction"), result.name, result.gain, "خستگی چاپلوسی پیداست." if result.tired else ""]
