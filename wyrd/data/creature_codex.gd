class_name CreatureCodex
extends RefCounted

# The shipped combat roster in one player-facing source of truth. Keys mirror
# layout_loader.ENEMY_KINDS and BOSS_KINDS so the coverage test can catch drift.
const ENTRIES := {
	"skeleton": {"name": "Barrow Skeleton", "group": "Common Creatures",
		"region": "Hollow · Crypt · Summit", "role": "Steady skirmisher",
		"projectile": "Throws a slow bone-white grave spark before closing.",
		"quote": "A barrow skeleton remembers its watch, but not who gave the order. It salutes old doors and resents new hinges."},
	"rat": {"name": "Mossback Rat", "group": "Common Creatures",
		"region": "First Hollow · Crypt", "role": "Fast nuisance",
		"projectile": "Spits a quick clod of root-mud while it scurries in.",
		"quote": "Mossback rats nest where the roots keep a little warmth. They steal buttons first and food only when the buttons run out."},
	"ghost": {"name": "Lantern Ghost", "group": "Common Creatures",
		"region": "Hollow · Crypt · Summit", "role": "Ranged caster",
		"projectile": "Lobs a pale lantern-orb and keeps its distance.",
		"quote": "A lantern ghost is a light that forgot what it was lighting. Stand aside when it passes; courtesy costs less than courage."},
	"bog_wisp": {"name": "Bog Wisp", "group": "Common Creatures",
		"region": "Sallow Mire", "role": "Mobile ranged caster",
		"projectile": "Fires a bright marsh-green wisp shot across wet ground.",
		"quote": "Bog wisps gather over water too shallow to drown in. This has not stopped them from trying."},
	"hedge_sprite": {"name": "Hedge Sprite", "group": "Common Creatures",
		"region": "Briar Maze · Crypt · Mire", "role": "Durable pursuer",
		"projectile": "Snaps off a green thorn-seed before giving chase.",
		"quote": "Hedge sprites are bits of spring with poor manners. They bite gardeners and leave flowers for everyone else."},
	"bramble_imp": {"name": "Bramble-Imp", "group": "Common Creatures",
		"region": "Hollow · Briar Maze · Mire", "role": "Quick attacker",
		"projectile": "Flicks a berry-dark thorn on approach.",
		"quote": "Bramble-imps steal anything shiny or warm. A pie is both, which explains most village history."},
	"skitterling": {"name": "Skitterling", "group": "Common Creatures",
		"region": "Briar Maze · Sallow Mire", "role": "Fragile swarmer",
		"projectile": "Flings a rust-red husk, then races after it.",
		"quote": "A skitterling is all feet until it stops. Then it is mostly eyes, and none of them apologetic."},
	"warden": {"name": "Briar Warden", "group": "Common Creatures",
		"region": "Hollow · Crypt · Summit", "role": "Pack healer",
		"projectile": "Sends a green ward-spark before tending its allies.",
		"quote": "Briar wardens mend the hedge and anything the hedge considers family. Their list is generous. You are not on it."},
	"barrow_brute": {"name": "Barrow Brute", "group": "Common Creatures",
		"region": "Crypt · Summit", "role": "Heavy bruiser",
		"projectile": "Hurls an earth-brown grave ember before its ring strike.",
		"quote": "Barrow brutes were built to move stones that sensible people left alone. They have not improved their judgment."},
	"bough_watcher": {"name": "Bough Watcher", "group": "Common Creatures",
		"region": "Rootroads", "role": "Oathbound elite",
		"projectile": "Casts a copper oath-nail of light across the road.",
		"quote": "A Bough Watcher keeps an oath after the words have worn away. It watches the road because watching is what remains."},
	"hedgemother": {"name": "The Hedgemother", "group": "Named Creatures",
		"region": "Green Hollow", "role": "Bramble matron",
		"projectile": "Commands sweeps, roots, and the waking hedge.",
		"quote": "Some kindnesses are too big to carry. So we plant them, and let the kindness be the place."},
	"burrow_boar": {"name": "The Burrow Boar", "group": "Named Creatures",
		"region": "Sallow Mire", "role": "Charging den-beast",
		"projectile": "Answers at range with a line charge and root-stomp.",
		"quote": "The Burrow Boar digs where old roads sink beneath the mire. Follow the churned water if you must; never follow the silence."},
	"wolf_alpha": {"name": "The Wolf Alpha", "group": "Named Creatures",
		"region": "Seventh Road", "role": "Pack-lunge hunter",
		"projectile": "Crosses distance in a chain of re-aimed lunges.",
		"quote": "The Alpha runs the Seventh Road as though an eighth were chasing it. No chart has found that road. The village prefers this."},
	"hedgemother_queen": {"name": "The Hedgemother Queen", "group": "Named Creatures",
		"region": "Queen's Summit", "role": "Thorn-guard monarch",
		"projectile": "Calls a thorn-guard when cornered.",
		"quote": "The Queen is not a greater Hedgemother. She is the same old promise, heard where the cold makes every word sound sharp."},
	"barrow_jarl": {"name": "The Barrow Jarl", "group": "Named Creatures",
		"region": "Pale Oath", "role": "Oathbound guardian",
		"projectile": "Turns shield, relief, and vow into a measured duel.",
		"quote": "The Jarl kept the bell-road when there were still bells to answer. He has mistaken endurance for duty, as old guards sometimes do."},
	"hearth_giant": {"name": "The Hearth Giant", "group": "Named Creatures",
		"region": "Ashen Bough", "role": "Keeper of heat",
		"projectile": "Builds heat through vents, cinders, and floor-wide tells.",
		"quote": "The Hearth Giant banks every fire it survives. Speak softly near the coals; some of them are listening for their names."},
	"knot_eater": {"name": "The Knot-Eater", "group": "Named Creatures",
		"region": "The road below", "role": "Unbinding creature",
		"projectile": "Reels the road itself until named and quieted.",
		"quote": "The Knot-Eater does not hate a binding. It is simply hungry, and a promise tied tight smells like supper."},
}

const ORDER := [
	"skeleton", "rat", "ghost", "bog_wisp", "hedge_sprite", "bramble_imp",
	"skitterling", "warden", "barrow_brute", "bough_watcher",
	"hedgemother", "burrow_boar", "wolf_alpha", "hedgemother_queen",
	"barrow_jarl", "hearth_giant", "knot_eater",
]

static func entry(id: String) -> Dictionary:
	return (ENTRIES.get(id, {}) as Dictionary).duplicate(true)

static func ordered_entries() -> Array:
	var out: Array = []
	for id in ORDER:
		var row := entry(id)
		row["id"] = id
		out.append(row)
	return out

static func missing_ids(ids: Array) -> Array:
	var missing: Array = []
	for id_v in ids:
		var id := String(id_v)
		if not ENTRIES.has(id):
			missing.append(id)
	return missing
