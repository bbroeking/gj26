#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const vm = require("node:vm");

const source = fs.readFileSync("tools/web_smoke_probe.js", "utf8");

function load(search) {
  let scheduled = null;
  const context = {
    location: {search},
    performance: {now: () => 0},
    URLSearchParams,
    console: {error() {}, info() {}},
    setTimeout(callback) { scheduled = callback; },
  };
  vm.createContext(context);
  vm.runInContext(source, context, {filename: "web_smoke_probe.js"});
  context.runScheduled = () => {
    if (typeof scheduled !== "function") throw new Error("probe did not schedule a poll");
    scheduled();
  };
  return context;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const snug = load("?wyrd_smoke=snug").__wyrdSmokeHarness;
assert(snug.mode === "snug", "plain route mode");
assert(snug.required.join(",") === "title,town,world,complete", "plain required order");

const codex = load("?wyrd_smoke=snug&wyrd_ui_smoke=codex").__wyrdSmokeHarness;
assert(codex.mode === "codex", "Codex route mode");
assert(codex.required.includes("chart_table") && codex.required.includes("codex"),
  "Codex requires real UI phases");

const d1Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=d1");
const d1 = d1Context.__wyrdSmokeHarness;
assert(d1.mode === "d1", "D1 route mode");
assert(d1.request === "run_d1_campaign_with_real_table_escrow_world_boss_and_return",
  "D1 request cannot be a fixture-only campaign shortcut");
assert(d1.required.join(",") === [
  "title", "town", "world", "green_world_1", "green_hollow_1",
  "green_world_2", "green_hollow_2", "green_world_3", "green_hollow_3",
  "chart_table", "boss_preview", "boss_world", "boss_cleared",
  "homecoming_hall", "homecoming_atlas", "homecoming_inspected", "complete",
].join(","), "D1 requires three physical Green returns, boss settlement, and Town Homecoming");
assert(d1.requiredFeatures.join(",") === [
  "d1_gameplay_driver", "d1_world_interact_table", "d1_green_table_commit",
  "d1_production_ink_mixing", "d1_boss_preview_contract",
  "d1_try_inscribe_chart_escrow", "d1_world_campaign_boss",
  "d1_boss_death_host_resolver", "d1_terminal_return_idempotence",
  "d1_homecoming_modal_control", "d1_homecoming_hall_projection",
  "d1_homecoming_atlas_handoff", "d1_homecoming_scanner_inspect",
  "d1_homecoming_copy_only",
].join(","), "D1 requires table, escrow, World, boss, terminal return, and read-only Homecoming evidence");

d1Context.__wyrdSmoke = {phase: "complete", history: [...d1.required], features: {}};
d1Context.runScheduled();
assert(d1.status === "failed" && d1.error.includes("feature evidence"),
  "D1 must reject phase-only completion");

const d1PassingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d1");
const d1Passing = d1PassingContext.__wyrdSmokeHarness;
d1PassingContext.__wyrdSmoke = {
  phase: "complete",
  history: [...d1Passing.required],
  features: Object.fromEntries(d1Passing.requiredFeatures.map((name) => [name, true])),
};
d1PassingContext.runScheduled();
assert(d1Passing.status === "passed", "D1 accepts ordered phases plus production feature evidence");

const d1HomecomingSpoofContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d1");
const d1HomecomingSpoof = d1HomecomingSpoofContext.__wyrdSmokeHarness;
const d1AlmostFeatures = Object.fromEntries(
  d1HomecomingSpoof.requiredFeatures.map((name) => [name, true]));
delete d1AlmostFeatures.d1_homecoming_copy_only;
d1HomecomingSpoofContext.__wyrdSmoke = {
  phase: "complete",
  history: [...d1HomecomingSpoof.required],
  features: d1AlmostFeatures,
};
d1HomecomingSpoofContext.runScheduled();
assert(d1HomecomingSpoof.status === "failed"
  && d1HomecomingSpoof.error.includes("d1_homecoming_copy_only"),
  "D1 must reject a Homecoming phase sequence without its copy-only proof");

const d2Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=d2");
const d2 = d2Context.__wyrdSmokeHarness;
assert(d2.mode === "d2", "D2 route mode");
assert(d2.request ===
  "run_d2_reprise_after_explicit_prerequisite_fixture_with_real_table_world_waystone_hearth_boss_and_return",
  "D2 request names its narrow prerequisite fixture and real replay route");
assert(d2.required.join(",") === [
  "title", "town", "d2_prerequisites", "chart_table", "reprise_preview",
  "reprise_committed", "reprise_layer_1", "exit_waystone", "deepen_choice",
  "reprise_layer_2", "terminal_hearth", "reprise_boss_world",
  "reprise_boss_cleared", "reprise_return", "complete",
].join(","), "D2 requires physical table, Waystone, Hearth, boss, and return phases");
assert(d2.requiredFeatures.join(",") === [
  "d2_prerequisite_fixture", "d2_gameplay_driver", "d2_world_interact_table",
  "d2_reprise_table_commit", "d2_reprise_preview_contract",
  "d2_real_exit_waystone", "d2_real_deepen_choice",
  "d2_terminal_hearth_interaction", "d2_layer_two_encounter_contract",
  "d2_exact_one_heirloom", "d2_campaign_inert_return",
].join(","), "D2 requires fixture disclosure and real replay evidence");

d2Context.__wyrdSmoke = {phase: "complete", history: [...d2.required], features: {}};
d2Context.runScheduled();
assert(d2.status === "failed" && d2.error.includes("feature evidence"),
  "D2 must reject phase-only completion");

const d2PassingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d2");
const d2Passing = d2PassingContext.__wyrdSmokeHarness;
d2PassingContext.__wyrdSmoke = {
  phase: "complete",
  history: [...d2Passing.required],
  features: Object.fromEntries(d2Passing.requiredFeatures.map((name) => [name, true])),
};
d2PassingContext.runScheduled();
assert(d2Passing.status === "passed", "D2 accepts ordered phases plus fixture and production evidence");

const d3Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=d3");
const d3 = d3Context.__wyrdSmokeHarness;
assert(d3.mode === "d3", "D3 route mode");
assert(d3.request ===
  "run_golden_wallow_after_first_knot_fixture_with_real_atlas_table_world_boss_and_settlement",
  "D3 request discloses its prerequisite fixture and production Golden route");
assert(d3.required.join(",") === [
  "title", "town", "first_knot_homecoming", "shallows_source",
  "shallows_table_1", "shallows_world_1", "shallows_return_1",
  "shallows_table_2", "shallows_world_2", "shallows_return_2",
  "shallows_table_3", "shallows_world_3", "shallows_return_3",
  "mire_ink", "boar_preview", "boar_world", "boar_cleared",
  "golden_hall", "golden_atlas", "sallow_jetty", "complete",
].join(","), "D3 requires three Shallows returns, Boar, and settlement projections");
assert(d3.requiredFeatures.join(",") === [
  "d3_post_first_knot_fixture", "d3_bounded_makings_fixture",
  "d3_gameplay_driver", "d3_real_atlas_source_read",
  "d3_shallows_real_table", "d3_mire_ink_production_controls",
  "d3_boar_preview_contract", "d3_boar_table_escrow",
  "d3_world_burrow_boar", "d3_boar_death_settlement",
  "d3_golden_hall_projection", "d3_golden_atlas_projection",
  "d3_sallow_jetty_projection",
].join(","), "D3 requires disclosed fixtures and production route evidence");
d3Context.__wyrdSmoke = {phase: "complete", history: [...d3.required], features: {}};
d3Context.runScheduled();
assert(d3.status === "failed" && d3.error.includes("feature evidence"),
  "D3 must reject phase-only completion");
const d3PassingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d3");
const d3Passing = d3PassingContext.__wyrdSmokeHarness;
d3PassingContext.__wyrdSmoke = {
  phase: "complete", history: [...d3Passing.required],
  features: Object.fromEntries(d3Passing.requiredFeatures.map((name) => [name, true])),
};
d3PassingContext.runScheduled();
assert(d3Passing.status === "passed", "D3 accepts ordered phases plus production evidence");

const d4Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=d4");
const d4 = d4Context.__wyrdSmokeHarness;
assert(d4.mode === "d4", "D4 route mode");
assert(d4.request ===
  "run_seventh_road_after_golden_fixture_with_real_atlas_table_world_archive_and_summit_handoff",
  "D4 request discloses its prerequisite fixture and legacy compatibility route");
assert(d4.required.join(",") === [
  "title", "town", "golden_wallow_settlement", "briar_source",
  "briar_table_1", "briar_world_1", "briar_return_1",
  "briar_table_2", "briar_world_2", "briar_return_2",
  "briar_table_3", "briar_world_3", "briar_return_3",
  "briar_table_4", "briar_world_4", "briar_return_4",
  "mothglow_blocked_13", "mothglow_mixed_14", "wolf_preview",
  "wolf_world", "wolf_cleared", "seventh_hall", "seventh_atlas",
  "skald_archive", "summit_lesson", "legacy_case_1",
  "legacy_world_1", "legacy_refunded", "legacy_world_2",
  "legacy_consumed", "complete",
].join(","), "D4 requires four Briar loops, level-gated Ink, Wolf, Archive, and frozen legacy retry");
assert(d4.requiredFeatures.join(",") === [
  "d4_post_golden_fixture", "d4_bounded_makings_fixture",
  "d4_gameplay_driver", "d4_real_atlas_briar_source",
  "d4_four_briar_table_loops", "d4_four_distinct_cold_tracks",
  "d4_mothglow_level_gate", "d4_mothglow_production_controls",
  "d4_wolf_preview_contract", "d4_wolf_table_escrow",
  "d4_world_wolf_alpha", "d4_wolf_death_settlement",
  "d4_seventh_town_projection", "d4_skald_archive_source_control",
  "d4_archive_missing_only_lesson", "d4_frozen_legacy_chart_case",
  "d4_summit_abandon_refund", "d4_legacy_retry_new_escrow",
  "d4_legacy_world_handoff", "d4_legacy_handoff_consumed",
].join(","), "D4 requires disclosed fixture and production route evidence");
d4Context.__wyrdSmoke = {phase: "complete", history: [...d4.required], features: {}};
d4Context.runScheduled();
assert(d4.status === "failed" && d4.error.includes("feature evidence"),
  "D4 must reject phase-only completion");
const d4PassingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d4");
const d4Passing = d4PassingContext.__wyrdSmokeHarness;
d4PassingContext.__wyrdSmoke = {
  phase: "complete", history: [...d4Passing.required],
  features: Object.fromEntries(d4Passing.requiredFeatures.map((name) => [name, true])),
};
d4PassingContext.runScheduled();
assert(d4Passing.status === "passed", "D4 accepts ordered phases plus production evidence");

const d5Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=d5");
const d5 = d5Context.__wyrdSmokeHarness;
assert(d5.mode === "d5", "D5 route mode");
assert(d5.request ===
  "run_queens_summit_after_seventh_fixture_with_real_archive_table_world_queen_stair_and_settlement",
  "D5 request discloses its prior-chapter fixture and real Queen route");
assert(d5.required.join(",") === [
  "title", "town", "post_seventh_settlement", "archive_source",
  "approach_table_1", "approach_world_1", "approach_return_1",
  "approach_table_2", "approach_world_2", "approach_return_2",
  "approach_table_3", "approach_world_3", "approach_return_3",
  "approach_table_4", "approach_world_4", "approach_return_4",
  "queen_preview", "queen_world", "queen_cleared", "pale_stair_twice",
  "queen_hall", "queen_atlas", "queen_archive", "complete",
].join(","), "D5 requires Archive, four physical Crownward loops, canonical Queen, two Stair reads, and Town settlement");
assert(d5.requiredFeatures.join(",") === [
  "d5_post_seventh_fixture", "d5_real_archive_source",
  "d5_bounded_makings_fixture", "d5_real_table_commits",
  "d5_four_approach_table_loops", "d5_four_distinct_crown_thorns",
  "d5_queen_preview_contract", "d5_queen_table_escrow",
  "d5_world_forced_queen", "d5_canonical_queen_settlement",
  "d5_pale_stair_two_reads", "d5_queen_town_projection",
  "d5_gameplay_driver",
].join(","), "D5 requires disclosed fixture plus Archive, Table, Queen, Stair, and projection evidence");
d5Context.__wyrdSmoke = {phase: "complete", history: [...d5.required], features: {}};
d5Context.runScheduled();
assert(d5.status === "failed" && d5.error.includes("feature evidence"),
  "D5 must reject phase-only completion");
const d5PassingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=d5");
const d5Passing = d5PassingContext.__wyrdSmokeHarness;
d5PassingContext.__wyrdSmoke = {
  phase: "complete", history: [...d5Passing.required],
  features: Object.fromEntries(d5Passing.requiredFeatures.map((name) => [name, true])),
};
d5PassingContext.runScheduled();
assert(d5Passing.status === "passed", "D5 accepts ordered phases plus production evidence");

const d6Context = load("?smoke=1&ui=d6");
const d6 = d6Context.__wyrdSmokeHarness;
assert(d6.mode === "d6", "D6 only activates from its strict smoke=1/ui=d6 route");
assert(d6.request ===
  "run_pale_oath_after_canonical_queen_fixture_with_real_stair_archive_table_rootroads_jarl_reliefs_settlement_and_driving_volley",
  "D6 request names the canonical Queen fixture and every real production boundary");
assert(d6.required.join(",") === [
  "title", "town", "queen_complete_fixture", "pale_stair", "archive_source",
  "pale_veins_table_1", "pale_veins_world_1", "pale_veins_return_1",
  "pale_veins_table_2", "pale_veins_world_2", "pale_veins_return_2",
  "pale_veins_table_3", "pale_veins_world_3", "pale_veins_return_3",
  "pale_veins_table_4", "pale_veins_world_4", "pale_veins_return_4",
  "pale_oath_boss_folio", "pale_oath_preview", "pale_oath_world", "jarl_relief_1", "jarl_relief_2",
  "jarl_relief_3", "jarl_cleared", "rootroad_lift", "oathstone",
  "pale_oath_hall", "pale_oath_atlas", "pale_oath_archive", "driving_volley",
  "complete",
].join(","), "D6 requires Stair and both Archive reads, four physical Pale Veins returns, three Jarl reliefs, exact settlement projections, and Driving Volley");
assert(d6.requiredFeatures.join(",") === [
  "d6_canonical_queen_fixture", "d6_real_pale_stair_read",
  "d6_real_archive_source", "d6_real_table_commits",
  "d6_four_pale_veins_loops", "d6_four_distinct_oath_rubbings",
  "d6_boss_preview_contract", "d6_boss_table_escrow", "d6_world_barrow_jarl",
  "d6_three_host_validated_bell_reliefs", "d6_exact_pale_oath_settlement",
  "d6_rootroad_lift_oathstone", "d6_town_settlement_projections",
  "d6_driving_volley_equipped", "d6_driving_volley_real_displacement",
  "d6_gameplay_driver",
].join(","), "D6 rejects phases without canonical fixture, physical route, exact settlement, and real Volley displacement evidence");
d6Context.__wyrdSmoke = {phase: "complete", history: [...d6.required], features: {}};
d6Context.runScheduled();
assert(d6.status === "failed" && d6.error.includes("feature evidence"),
  "D6 must reject a phase-only completion");
const d6MissingReliefContext = load("?smoke=1&ui=d6");
const d6MissingRelief = d6MissingReliefContext.__wyrdSmokeHarness;
const d6AlmostFeatures = Object.fromEntries(
  d6MissingRelief.requiredFeatures.map((name) => [name, true]));
delete d6AlmostFeatures.d6_three_host_validated_bell_reliefs;
d6MissingReliefContext.__wyrdSmoke = {
  phase: "complete", history: [...d6MissingRelief.required], features: d6AlmostFeatures,
};
d6MissingReliefContext.runScheduled();
assert(d6MissingRelief.status === "failed"
  && d6MissingRelief.error.includes("d6_three_host_validated_bell_reliefs"),
  "D6 must reject a claimed Jarl clear without all host-validated reliefs");
const d6PassingContext = load("?smoke=1&ui=d6");
const d6Passing = d6PassingContext.__wyrdSmokeHarness;
d6PassingContext.__wyrdSmoke = {
  phase: "complete", history: [...d6Passing.required],
  features: Object.fromEntries(d6Passing.requiredFeatures.map((name) => [name, true])),
};
d6PassingContext.runScheduled();
assert(d6Passing.status === "passed", "D6 accepts ordered real-route phases plus all required evidence");
const legacyD6 = load("?wyrd_smoke=snug&wyrd_ui_smoke=d6").__wyrdSmokeHarness;
assert(legacyD6.mode === "snug", "the legacy smoke URL cannot activate D6");

const d7Context = load("?smoke=1&ui=d7");
const d7 = d7Context.__wyrdSmokeHarness;
assert(d7.mode === "d7", "D7 only activates from its strict smoke=1/ui=d7 route");
assert(d7.request ===
  "run_fire_in_the_bough_from_a_fresh_title_through_the_prior_saga_with_real_waystones_lift_table_ashen_verses_manifest_giant_chains_settlement_kiln_alloy_and_threadstep",
  "D7 request names its fresh prior-saga journey and every real Fire boundary");
assert(d7.required.join(",") === [
  "title", "title_new_journey", "town", "fresh_campaign",
  "first_knot_complete", "golden_source", "golden_wallow_complete", "seventh_source",
  "seventh_road_complete", "queens_source", "queens_summit_complete",
  "pale_source", "prior_saga_complete", "lift_ordinary_folio",
  "ashen_table_1", "ashen_world_1", "ashen_return_1",
  "ashen_table_2", "ashen_world_2", "ashen_return_2",
  "ashen_table_3", "ashen_world_3", "ashen_return_3",
  "ashen_table_4", "ashen_world_4", "ashen_return_4",
  "ashen_table_5", "ashen_world_5", "ashen_return_5",
  "lift_giant_folio", "emberleaf_mix", "giant_preview", "giant_world",
  "giant_wrong_chain", "giant_chain_1", "giant_chain_2", "giant_chain_3",
  "giant_cleared", "ember_kiln", "starheart_alloy", "threadstep_accepted",
  "threadstep_blocked", "complete",
].join(","), "D7 requires stable player-facing milestones while detailed feature receipts prove progressive training, five Ashen returns, Giant settlement, Kiln craft, and both Threadstep outcomes");
assert(d7.requiredFeatures.join(",") === [
  "d7_real_title_new_journey", "d7_fresh_campaign_boundary",
  "d7_prior_saga_production", "d7_support_trade_receipts",
  "d7_prior_saga_combat_gather_receipts", "d7_training_earthcraft_town_loop",
  "d7_component_purchase_receipts",
  "d7_golden_renewable_ink",
  "d7_seventh_renewable_ink", "d7_wolf_boss_loot_receipt",
  "d7_wolf_hod_sale_receipt", "d7_queen_component_budget",
  "d7_queen_renewable_ink",
  "d7_pale_renewable_ink", "d7_fire_renewable_ink",
  "d7_real_town_waystone", "d7_real_far_waystone",
  "d7_real_lift_ordinary_folio", "d7_real_table_commits",
  "d7_five_ashen_bough_loops", "d7_five_distinct_ember_verses",
  "d7_frozen_elite_manifest", "d7_pack_reader_zero_rng_manifest",
  "d7_real_lift_boss_folio", "d7_real_emberleaf_mix",
  "d7_boss_preview_contract", "d7_boss_table_escrow", "d7_world_hearth_giant",
  "d7_recoverable_wrong_chain", "d7_three_host_validated_chain_banks",
  "d7_exact_fire_settlement", "d7_town_settlement_projections",
  "d7_post_clear_starheart_alloy", "d7_threadstep_accepted",
  "d7_threadstep_blocked", "d7_gameplay_driver",
  "d7_progressive_level_ledger", "d7_exact_wayfinding_checkpoints",
  "d7_cumulative_gather_proof",
  "d7_pack_reader_deferred_reveal", "d7_simulation_clock",
].join(","), "D7 rejects phase-only completion without fresh-save, source, Table, World, chain, settlement, Kiln, and Skill production evidence");
d7Context.__wyrdSmoke = {phase: "complete", history: [...d7.required], features: {}};
d7Context.runScheduled();
assert(d7.status === "failed" && d7.error.includes("feature evidence"),
  "D7 must reject a phase-only completion");
const d7MissingChainContext = load("?smoke=1&ui=d7");
const d7MissingChain = d7MissingChainContext.__wyrdSmokeHarness;
const d7AlmostFeatures = Object.fromEntries(
  d7MissingChain.requiredFeatures.map((name) => [name, true]));
delete d7AlmostFeatures.d7_three_host_validated_chain_banks;
d7MissingChainContext.__wyrdSmoke = {
  phase: "complete", history: [...d7MissingChain.required], features: d7AlmostFeatures,
};
d7MissingChainContext.runScheduled();
assert(d7MissingChain.status === "failed"
  && d7MissingChain.error.includes("d7_three_host_validated_chain_banks"),
  "D7 must reject a claimed Giant clear without all host-validated chain banks");
const d7BooleanClockContext = load("?smoke=1&ui=d7");
const d7BooleanClock = d7BooleanClockContext.__wyrdSmokeHarness;
const d7BooleanClockFeatures = Object.fromEntries(
  d7BooleanClock.requiredFeatures.map((name) => [name, true]));
d7BooleanClockContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BooleanClock.required], features: d7BooleanClockFeatures,
};
d7BooleanClockContext.runScheduled();
assert(d7BooleanClock.status === "failed"
  && d7BooleanClock.error.includes("d7_simulation_clock"),
  "D7 must reject a boolean simulation-clock claim without an owned-clock receipt");

function d7PassingFeatures(harness) {
  const features = Object.fromEntries(
    harness.requiredFeatures.map((name) => [name, true]));
  features.d7_progressive_level_ledger = [
    {label: "first_knot_settlement", trades: {wayfinding: {xp: 768, level: 9}}},
    {label: "golden_wallow_settlement", trades: {wayfinding: {xp: 2016, level: 15}}},
    {label: "seventh_road_settlement", trades: {wayfinding: {xp: 2280, level: 16}}},
    {label: "queens_summit_settlement", trades: {wayfinding: {xp: 2856, level: 18}}},
    {label: "pale_oath_settlement", trades: {wayfinding: {xp: 3496, level: 20}}},
  ];
  features.d7_exact_wayfinding_checkpoints = {
    golden_deep_return: {expected_xp: 1136, actual_xp: 1136, expected_level: 11, actual_level: 11},
    golden_third_shallows_return: {expected_xp: 1320, actual_xp: 1320, expected_level: 12, actual_level: 12},
    fire_entry: {expected_xp: 3496, actual_xp: 3496, expected_level: 20, actual_level: 20},
    five_ember_verses: {expected_xp: 3840, actual_xp: 3840, expected_level: 21, actual_level: 21},
    hearth_giant_return: {expected_xp: 4200, actual_xp: 4200, expected_level: 22, actual_level: 22},
  };
  features.d7_cumulative_gather_proof = {
    complete: true,
    boundary: "before_first_briar",
    first_witness_by_kind: {
      ore_rock: {kind: "ore_rock", provenance: "d7_scanner_harvest", delta: 1},
      forage_node: {kind: "forage_node", provenance: "d7_scanner_harvest", delta: 1},
      log_pile: {kind: "log_pile", provenance: "d7_scanner_harvest", delta: 1},
    },
  };
  features.d7_wolf_boss_loot_receipt = {
    token: "d7-wolf-1-2", kind_id: "shortbow", name: "Wolf Bow",
    rarity: "rare", sell_value: 35, inventory_before: 0,
    inventory_after: 1, wayfinding_xp: 2280, pickup_action: "grab",
  };
  features.d7_wolf_hod_sale_receipt = {
    token: "d7-wolf-1-2", kind_id: "shortbow", name: "Wolf Bow",
    rarity: "rare", expected_value: 35, actual_value: 35,
    gold_before: 136, gold_after: 171, inventory_before: 1,
    inventory_after: 0, persisted_to_town: true,
    second_sale_possible: false, immutable_state_unchanged: true,
  };
  features.d7_queen_component_budget = {
    chapter_start: {purchase_cost: 236, guaranteed_approach_income: 96,
      available_through_boss: 267, affordable: true},
    boss_ready: {purchase_cost: 56, guaranteed_approach_income: 0,
      gold: 87, affordable: true},
    actual_component_spend: 236,
  };
  features.d7_support_trade_receipts = [
    ["golden_wallow", 1, 10, 768], ["golden_wallow_boss", 1, 10, 1320],
    ["seventh_road", 3, 3, 2016], ["seventh_road_boss", 3, 14, 2144],
    ["queens_summit", 3, 1, 2280], ["queens_summit_boss", 3, 1, 2560],
    ["pale_oath", 18, 18, 2856], ["pale_oath_boss", 18, 19, 3168],
    ["fire_in_the_bough", 18, 20, 3496],
  ].map(([label, earthcraft, wildcraft, wayfinding_xp]) => ({
    label, before: {earthcraft: 1, wildcraft: 1},
    after: {earthcraft, wildcraft}, targets: {earthcraft, wildcraft},
    wayfinding_xp, chart_count: 0,
  }));
  features.d7_prior_saga_combat_gather_receipts = [1, 2, 3].map((world) => ({
    world_generation: world, events: ["combat_clear", "gather_scan"],
    settled_before_gather: true, kills: 3, harvested: 1,
  }));
  features.d7_component_purchase_receipts = [{
    component_id: "cold_track", unit_price: 8, gold_before: 20, gold_after: 12,
    owned_before: 0, owned_after: 1,
  }];
  features.d7_pack_reader_deferred_reveal = {
    deferred_worlds: [1, 2, 3],
    revealed_world: 4,
    huntcraft: 21,
    seed_fingerprint: "validated-ashen-manifest",
  };
  features.d7_simulation_clock = {
    owner: "d7_smoke_clock",
    activated_after_fresh_campaign: true,
    requested_scale: 6,
    observed_scale: 6,
    max_observed_scale: 6,
    captured_baseline_scale: 1,
    watchdog_clock: "monotonic_real_time",
    restored_before_terminal_serialization: true,
    restored: true,
    terminal_reason: "complete",
    terminal_scale: 1,
    terminal_watchdog: {
      duration_sec: 840,
      ignore_time_scale: true,
      attempt_token: "d7_fresh_campaign_1",
      generation: 1,
      armed: false,
      fired: false,
      cancelled: true,
      stale: false,
    },
  };
  return features;
}

const d7BadProgressionContext = load("?smoke=1&ui=d7");
const d7BadProgression = d7BadProgressionContext.__wyrdSmokeHarness;
const d7BadProgressionFeatures = d7PassingFeatures(d7BadProgression);
d7BadProgressionFeatures.d7_exact_wayfinding_checkpoints.fire_entry.actual_xp = 3506;
d7BadProgressionContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BadProgression.required], features: d7BadProgressionFeatures,
};
d7BadProgressionContext.runScheduled();
assert(d7BadProgression.status === "failed"
  && d7BadProgression.error.includes("d7_exact_wayfinding_checkpoints"),
  "D7 must reject a completion that overshot the exact Fire entry ledger");

const d7BadGatherContext = load("?smoke=1&ui=d7");
const d7BadGather = d7BadGatherContext.__wyrdSmokeHarness;
const d7BadGatherFeatures = d7PassingFeatures(d7BadGather);
delete d7BadGatherFeatures.d7_cumulative_gather_proof.first_witness_by_kind.log_pile;
d7BadGatherContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BadGather.required], features: d7BadGatherFeatures,
};
d7BadGatherContext.runScheduled();
assert(d7BadGather.status === "failed"
  && d7BadGather.error.includes("d7_cumulative_gather_proof"),
  "D7 must reject pre-Briar gather proof missing one physical node family");

const d7BadReaderContext = load("?smoke=1&ui=d7");
const d7BadReader = d7BadReaderContext.__wyrdSmokeHarness;
const d7BadReaderFeatures = d7PassingFeatures(d7BadReader);
d7BadReaderFeatures.d7_pack_reader_deferred_reveal.seed_fingerprint = "";
d7BadReaderContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BadReader.required], features: d7BadReaderFeatures,
};
d7BadReaderContext.runScheduled();
assert(d7BadReader.status === "failed"
  && d7BadReader.error.includes("d7_pack_reader_deferred_reveal"),
  "D7 must reject Pack Reader evidence without a frozen manifest fingerprint");

const d7UnrestoredClockContext = load("?smoke=1&ui=d7");
const d7UnrestoredClock = d7UnrestoredClockContext.__wyrdSmokeHarness;
const d7UnrestoredClockFeatures = d7PassingFeatures(d7UnrestoredClock);
d7UnrestoredClockFeatures.d7_simulation_clock.terminal_scale = 6;
d7UnrestoredClockContext.__wyrdSmoke = {
  phase: "complete", history: [...d7UnrestoredClock.required], features: d7UnrestoredClockFeatures,
};
d7UnrestoredClockContext.runScheduled();
assert(d7UnrestoredClock.status === "failed"
  && d7UnrestoredClock.error.includes("d7_simulation_clock"),
  "D7 must reject a terminal report emitted before the captured scale is restored");
const d7OverCapClockContext = load("?smoke=1&ui=d7");
const d7OverCapClock = d7OverCapClockContext.__wyrdSmokeHarness;
const d7OverCapClockFeatures = d7PassingFeatures(d7OverCapClock);
d7OverCapClockFeatures.d7_simulation_clock.max_observed_scale = 7;
d7OverCapClockContext.__wyrdSmoke = {
  phase: "complete", history: [...d7OverCapClock.required], features: d7OverCapClockFeatures,
};
d7OverCapClockContext.runScheduled();
assert(d7OverCapClock.status === "failed"
  && d7OverCapClock.error.includes("d7_simulation_clock"),
  "D7 must reject a simulation-clock receipt that ever exceeds the 6x ceiling");
const d7BadSupportContext = load("?smoke=1&ui=d7");
const d7BadSupport = d7BadSupportContext.__wyrdSmokeHarness;
const d7BadSupportFeatures = d7PassingFeatures(d7BadSupport);
d7BadSupportFeatures.d7_support_trade_receipts.pop();
d7BadSupportContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BadSupport.required], features: d7BadSupportFeatures,
};
d7BadSupportContext.runScheduled();
assert(d7BadSupport.status === "failed"
  && d7BadSupport.error.includes("d7_support_trade_receipts"),
  "D7 must reject support training receipts missing the Fire-entry gate");
const d7BadCombatContext = load("?smoke=1&ui=d7");
const d7BadCombat = d7BadCombatContext.__wyrdSmokeHarness;
const d7BadCombatFeatures = d7PassingFeatures(d7BadCombat);
d7BadCombatFeatures.d7_prior_saga_combat_gather_receipts = [1, 2, 3].map((world) => ({
  world_generation: world, events: ["combat_clear"],
  settled_before_gather: true, kills: 3, harvested: 0,
}));
d7BadCombatContext.__wyrdSmoke = {
  phase: "complete", history: [...d7BadCombat.required], features: d7BadCombatFeatures,
};
d7BadCombatContext.runScheduled();
assert(d7BadCombat.status === "failed"
  && d7BadCombat.error.includes("d7_prior_saga_combat_gather_receipts"),
  "D7 must reject combat receipts without several production gather actions");
const d7MissingTerminalWatchdogContext = load("?smoke=1&ui=d7");
const d7MissingTerminalWatchdog = d7MissingTerminalWatchdogContext.__wyrdSmokeHarness;
const d7MissingTerminalWatchdogFeatures = d7PassingFeatures(d7MissingTerminalWatchdog);
delete d7MissingTerminalWatchdogFeatures.d7_simulation_clock.terminal_watchdog;
d7MissingTerminalWatchdogContext.__wyrdSmoke = {
  phase: "complete", history: [...d7MissingTerminalWatchdog.required],
  features: d7MissingTerminalWatchdogFeatures,
};
d7MissingTerminalWatchdogContext.runScheduled();
assert(d7MissingTerminalWatchdog.status === "failed"
  && d7MissingTerminalWatchdog.error.includes("d7_simulation_clock"),
  "D7 must reject completion without an attempt-owned terminal watchdog receipt");
const d7UncancelledWatchdogContext = load("?smoke=1&ui=d7");
const d7UncancelledWatchdog = d7UncancelledWatchdogContext.__wyrdSmokeHarness;
const d7UncancelledWatchdogFeatures = d7PassingFeatures(d7UncancelledWatchdog);
d7UncancelledWatchdogFeatures.d7_simulation_clock.terminal_watchdog.armed = true;
d7UncancelledWatchdogFeatures.d7_simulation_clock.terminal_watchdog.cancelled = false;
d7UncancelledWatchdogContext.__wyrdSmoke = {
  phase: "complete", history: [...d7UncancelledWatchdog.required],
  features: d7UncancelledWatchdogFeatures,
};
d7UncancelledWatchdogContext.runScheduled();
assert(d7UncancelledWatchdog.status === "failed"
  && d7UncancelledWatchdog.error.includes("d7_simulation_clock"),
  "D7 must reject completion while its terminal watchdog is still armed or uncancelled");
const d7PassingContext = load("?smoke=1&ui=d7");
const d7Passing = d7PassingContext.__wyrdSmokeHarness;
d7PassingContext.__wyrdSmoke = {
  phase: "complete", history: [...d7Passing.required],
  features: d7PassingFeatures(d7Passing),
};
d7PassingContext.runScheduled();
assert(d7Passing.status === "passed", "D7 accepts ordered real-route phases plus all required evidence");
const legacyD7 = load("?wyrd_smoke=snug&wyrd_ui_smoke=d7").__wyrdSmokeHarness;
assert(legacyD7.mode === "snug", "the legacy smoke URL cannot activate D7");

const c2Context = load("?wyrd_smoke=snug&wyrd_ui_smoke=c2");
const c2 = c2Context.__wyrdSmokeHarness;
assert(c2.mode === "c2", "C2 route mode");
assert(c2.request === "run_c2_sources_with_real_gameplay_and_controls",
  "C2 request cannot be a fixture-only shortcut");
assert(c2.required.join(",") === [
  "title", "town", "world", "atlas_deep_source", "chart_table",
  "codex_deep_rumoured", "chart_table_closed", "world",
  "mara_sallow_source", "chart_table", "codex_sallow_rumoured",
  "chart_table_closed", "complete",
].join(","), "C2 required source/Codex phase order");
assert(c2.requiredFeatures.join(",") === [
  "c2_gameplay_driver", "atlas_deep_source_control",
  "mara_sallow_source_control", "chart_rumour_source_dialog",
  "controller_source_binding", "world_interact_action",
  "production_town_gathering",
  "chart_table_ink_mixing", "deep_hollow_table_experiment",
  "sallow_mire_table_experiment",
].join(","), "C2 requires real Control feature evidence");

c2Context.__wyrdSmoke = {phase: "complete", history: [...c2.required], features: {}};
c2Context.runScheduled();
assert(c2.status === "failed" && c2.error.includes("feature evidence"),
  "C2 must reject phase-only completion");

const passingContext = load("?wyrd_smoke=snug&wyrd_ui_smoke=c2");
const passing = passingContext.__wyrdSmokeHarness;
passingContext.__wyrdSmoke = {
  phase: "complete",
  history: [...passing.required],
  features: Object.fromEntries(passing.requiredFeatures.map((name) => [name, true])),
};
passingContext.runScheduled();
assert(passing.status === "passed", "C2 accepts ordered phases plus real feature evidence");

console.log("web smoke probe semantics ✓ snug, codex, c2, d1 Homecoming, d2, d3 Golden Wallow, d4 legacy compatibility, d5 Queen's Summit, strict D6 Pale Oath, strict D7 Fire in the Bough");
