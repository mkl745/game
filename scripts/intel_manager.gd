extends Node
signal intel_changed
var evidence: Array[Dictionary] = []
func gather(subject: String, clue: String, severity := 2, quality := 65) -> Dictionary:
	var item := {"subject": subject, "clue": clue, "severity": severity, "quality": quality, "truth": "true", "expires": GameState.day + 2, "known_by": ["player"]}
	evidence.append(item)
	intel_changed.emit()
	return item
func report(index: int, recipient: String, public_report: bool, exaggerate := false) -> String:
	if index < 0 or index >= evidence.size(): return "مدرکی برای گزارش نیست."
	var item := evidence[index]
	var truth := str(item.truth)
	if exaggerate: truth = "exaggerated"
	RelationshipManager.react_report(item.severity, item.quality, public_report, truth)
	GameState.flags["reported_" + str(item.subject)] = true
	evidence.remove_at(index)
	intel_changed.emit()
	return "%s گزارش را ثبت کرد؛ حالا %s و بقیه واکنش نشان می‌دهند." % [recipient, str(item.subject)]
func leverage(index: int) -> String:
	if index < 0 or index >= evidence.size(): return "چیزی برای معامله نداری."
	var item: Dictionary = evidence[index]
	GameState.apply({"students": 5, "heat": 4, "conscience": -5})
	return "%s قول داد فعلاً طرفت باشد؛ اما نگاهش عوض شد." % item.subject
