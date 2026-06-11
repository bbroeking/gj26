extends RefCounted
class_name Equipment

# Spec 27d — 5-slot equipment data. Slots are keyed by item category
# (weapon/helmet/chest/boots/ring); validation is "the item's category
# matches a slot name." Emits `changed` on every successful equip/unequip
# so the player can re-derive stats (27e).

const SLOT_ORDER := ["weapon", "helmet", "chest", "boots", "ring"]

signal changed

var slots: Dictionary = {}            # slot_name → item dict or null

func _init() -> void:
	for s in SLOT_ORDER:
		slots[s] = null

# True if `item` has a matching slot (its category exists in SLOT_ORDER).
func can_equip(item: Dictionary) -> bool:
	return slots.has(String(item.get("category", "")))

# Equip the item into its category's slot. Returns the previously equipped
# item in that slot (or null if it was empty). Returns null if the item has
# no valid slot — caller should `can_equip` first to distinguish.
func equip(item: Dictionary):
	var cat := String(item.get("category", ""))
	if not slots.has(cat):
		return null
	var prev = slots[cat]
	slots[cat] = item
	changed.emit()
	return prev

# Remove + return the item in the named slot (or null if the slot is empty
# or the name is unknown).
func unequip(slot_name: String):
	if not slots.has(slot_name):
		return null
	var it = slots[slot_name]
	if it == null:
		return null
	slots[slot_name] = null
	changed.emit()
	return it

func get_slot(slot_name: String):
	return slots.get(slot_name, null)
