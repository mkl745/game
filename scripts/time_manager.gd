extends Node
signal ticked
var slot := 0
var slots := ["ورود", "کلاس", "زنگ تفریح", "ناهار", "کارگاه", "بعد از مدرسه"]
var daypart: String:
	get: return slots[clampi(slot, 0, slots.size() - 1)]
func spend(amount := 1) -> void:
	GameState.energy -= amount
	if GameState.energy <= 0:
		GameState.next_day()
	else:
		ticked.emit()
