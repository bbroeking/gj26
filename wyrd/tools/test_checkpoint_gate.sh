#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
godot_cmd='./tools/godot.sh'

tests='
test_wyrd_loop.gd
test_wyrd_dungeon_scene.gd
test_wyrd_transitions.gd
test_skills.gd
test_boot_smoke.gd
test_first_road_slice.gd
test_movement_feel.gd
test_hollow_readability.gd
test_first_hollow_room_grammar.gd
test_first_hollow_living_edge.gd
test_web_tonal_separation.gd
test_first_hollow_forest_continuity.gd
test_first_road_soft_ground.gd
test_first_road_open_canopy.gd
test_first_hollow_room_composition.gd
test_first_hollow_room_breathing.gd
test_first_hollow_setpiece_breathing.gd
test_first_hollow_readable_passages.gd
test_creature_codex.gd
test_town_tonal_separation.gd
test_town_arrival_framing.gd
test_town_working_edge.gd
test_ui_hud_and_pack_contract.gd
'

passed=0
for test_name in $tests; do
  printf '\n==> %s\n' "$test_name"
  WYRD_NO_SAVE=1 "$godot_cmd" --headless --path . --script "res://$test_name"
  passed=$((passed + 1))
done

printf '\nCheckpoint gate passed: %s/%s entrypoints.\n' "$passed" "$passed"
