(() => {
  "use strict";

  const query = new URLSearchParams(globalThis.location.search);
  // D6/D7 intentionally have separate, narrow URL contracts.  Do not let the
  // older smoke flag accidentally grant a campaign fixture or driver.
  const d6Route = query.get("smoke") === "1" && query.get("ui") === "d6";
  const d7Route = query.get("smoke") === "1" && query.get("ui") === "d7";
  if (!d6Route && !d7Route && query.get("wyrd_smoke") !== "snug") return;

  const uiMode = query.get("wyrd_ui_smoke");
  const mode = d7Route ? "d7" : d6Route ? "d6" : uiMode === "d5" ? "d5" : uiMode === "d4" ? "d4" : uiMode === "d3" ? "d3" : uiMode === "d2" ? "d2" : uiMode === "d1" ? "d1" : uiMode === "c2" ? "c2" : uiMode === "codex" ? "codex" : "snug";
  const required = mode === "c2"
    ? ["title", "town", "world", "atlas_deep_source", "chart_table",
       "codex_deep_rumoured", "chart_table_closed", "world",
       "mara_sallow_source", "chart_table", "codex_sallow_rumoured",
       "chart_table_closed", "complete"]
    : mode === "d7"
      ? ["title", "title_new_journey", "town", "fresh_campaign",
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
         "threadstep_blocked", "complete"]
    : mode === "d6"
      ? ["title", "town", "queen_complete_fixture", "pale_stair", "archive_source",
         "pale_veins_table_1", "pale_veins_world_1", "pale_veins_return_1",
         "pale_veins_table_2", "pale_veins_world_2", "pale_veins_return_2",
         "pale_veins_table_3", "pale_veins_world_3", "pale_veins_return_3",
         "pale_veins_table_4", "pale_veins_world_4", "pale_veins_return_4",
         "pale_oath_boss_folio", "pale_oath_preview", "pale_oath_world", "jarl_relief_1", "jarl_relief_2",
         "jarl_relief_3", "jarl_cleared", "rootroad_lift", "oathstone",
         "pale_oath_hall", "pale_oath_atlas", "pale_oath_archive", "driving_volley",
         "complete"]
    : mode === "d5"
      ? ["title", "town", "post_seventh_settlement", "archive_source",
         "approach_table_1", "approach_world_1", "approach_return_1",
         "approach_table_2", "approach_world_2", "approach_return_2",
         "approach_table_3", "approach_world_3", "approach_return_3",
         "approach_table_4", "approach_world_4", "approach_return_4",
         "queen_preview", "queen_world", "queen_cleared", "pale_stair_twice",
         "queen_hall", "queen_atlas", "queen_archive", "complete"]
    : mode === "d4"
      ? ["title", "town", "golden_wallow_settlement", "briar_source",
         "briar_table_1", "briar_world_1", "briar_return_1",
         "briar_table_2", "briar_world_2", "briar_return_2",
         "briar_table_3", "briar_world_3", "briar_return_3",
         "briar_table_4", "briar_world_4", "briar_return_4",
         "mothglow_blocked_13", "mothglow_mixed_14", "wolf_preview",
         "wolf_world", "wolf_cleared", "seventh_hall", "seventh_atlas",
         "skald_archive", "summit_lesson", "legacy_case_1",
         "legacy_world_1", "legacy_refunded", "legacy_world_2",
         "legacy_consumed", "complete"]
    : mode === "d3"
      ? ["title", "town", "first_knot_homecoming", "shallows_source",
         "shallows_table_1", "shallows_world_1", "shallows_return_1",
         "shallows_table_2", "shallows_world_2", "shallows_return_2",
         "shallows_table_3", "shallows_world_3", "shallows_return_3",
         "mire_ink", "boar_preview", "boar_world", "boar_cleared",
         "golden_hall", "golden_atlas", "sallow_jetty", "complete"]
    : mode === "d2"
      ? ["title", "town", "d2_prerequisites", "chart_table", "reprise_preview",
         "reprise_committed", "reprise_layer_1", "exit_waystone", "deepen_choice",
         "reprise_layer_2", "terminal_hearth", "reprise_boss_world",
         "reprise_boss_cleared", "reprise_return", "complete"]
    : mode === "d1"
      ? ["title", "town", "world", "green_world_1", "green_hollow_1",
         "green_world_2", "green_hollow_2", "green_world_3", "green_hollow_3",
         "chart_table", "boss_preview", "boss_world", "boss_cleared",
         "homecoming_hall", "homecoming_atlas", "homecoming_inspected", "complete"]
    : mode === "codex"
      ? ["title", "town", "chart_table", "codex", "chart_table_closed", "world", "complete"]
      : ["title", "town", "world", "complete"];
  const requiredFeatures = mode === "c2" ? [
    "c2_gameplay_driver",
    "atlas_deep_source_control",
    "mara_sallow_source_control",
    "chart_rumour_source_dialog",
    "controller_source_binding",
    "world_interact_action",
    "production_town_gathering",
    "chart_table_ink_mixing",
    "deep_hollow_table_experiment",
    "sallow_mire_table_experiment",
  ] : mode === "d7" ? [
    "d7_real_title_new_journey",
    "d7_fresh_campaign_boundary",
    "d7_prior_saga_production",
    "d7_support_trade_receipts",
    "d7_prior_saga_combat_gather_receipts",
    "d7_training_earthcraft_town_loop",
    "d7_component_purchase_receipts",
    "d7_golden_renewable_ink",
    "d7_seventh_renewable_ink",
    "d7_wolf_boss_loot_receipt",
    "d7_wolf_hod_sale_receipt",
    "d7_queen_component_budget",
    "d7_queen_renewable_ink",
    "d7_pale_renewable_ink",
    "d7_fire_renewable_ink",
    "d7_real_town_waystone",
    "d7_real_far_waystone",
    "d7_real_lift_ordinary_folio",
    "d7_real_table_commits",
    "d7_five_ashen_bough_loops",
    "d7_five_distinct_ember_verses",
    "d7_frozen_elite_manifest",
    "d7_pack_reader_zero_rng_manifest",
    "d7_real_lift_boss_folio",
    "d7_real_emberleaf_mix",
    "d7_boss_preview_contract",
    "d7_boss_table_escrow",
    "d7_world_hearth_giant",
    "d7_recoverable_wrong_chain",
    "d7_three_host_validated_chain_banks",
    "d7_exact_fire_settlement",
    "d7_town_settlement_projections",
    "d7_post_clear_starheart_alloy",
    "d7_threadstep_accepted",
    "d7_threadstep_blocked",
    "d7_gameplay_driver",
    "d7_progressive_level_ledger",
    "d7_exact_wayfinding_checkpoints",
    "d7_cumulative_gather_proof",
    "d7_pack_reader_deferred_reveal",
    "d7_simulation_clock",
  ] : mode === "d6" ? [
    "d6_canonical_queen_fixture",
    "d6_real_pale_stair_read",
    "d6_real_archive_source",
    "d6_real_table_commits",
    "d6_four_pale_veins_loops",
    "d6_four_distinct_oath_rubbings",
    "d6_boss_preview_contract",
    "d6_boss_table_escrow",
    "d6_world_barrow_jarl",
    "d6_three_host_validated_bell_reliefs",
    "d6_exact_pale_oath_settlement",
    "d6_rootroad_lift_oathstone",
    "d6_town_settlement_projections",
    "d6_driving_volley_equipped",
    "d6_driving_volley_real_displacement",
    "d6_gameplay_driver",
  ] : mode === "d5" ? [
    "d5_post_seventh_fixture",
    "d5_real_archive_source",
    "d5_bounded_makings_fixture",
    "d5_real_table_commits",
    "d5_four_approach_table_loops",
    "d5_four_distinct_crown_thorns",
    "d5_queen_preview_contract",
    "d5_queen_table_escrow",
    "d5_world_forced_queen",
    "d5_canonical_queen_settlement",
    "d5_pale_stair_two_reads",
    "d5_queen_town_projection",
    "d5_gameplay_driver",
  ] : mode === "d4" ? [
    "d4_post_golden_fixture",
    "d4_bounded_makings_fixture",
    "d4_gameplay_driver",
    "d4_real_atlas_briar_source",
    "d4_four_briar_table_loops",
    "d4_four_distinct_cold_tracks",
    "d4_mothglow_level_gate",
    "d4_mothglow_production_controls",
    "d4_wolf_preview_contract",
    "d4_wolf_table_escrow",
    "d4_world_wolf_alpha",
    "d4_wolf_death_settlement",
    "d4_seventh_town_projection",
    "d4_skald_archive_source_control",
    "d4_archive_missing_only_lesson",
    "d4_frozen_legacy_chart_case",
    "d4_summit_abandon_refund",
    "d4_legacy_retry_new_escrow",
    "d4_legacy_world_handoff",
    "d4_legacy_handoff_consumed",
  ] : mode === "d3" ? [
    "d3_post_first_knot_fixture",
    "d3_bounded_makings_fixture",
    "d3_gameplay_driver",
    "d3_real_atlas_source_read",
    "d3_shallows_real_table",
    "d3_mire_ink_production_controls",
    "d3_boar_preview_contract",
    "d3_boar_table_escrow",
    "d3_world_burrow_boar",
    "d3_boar_death_settlement",
    "d3_golden_hall_projection",
    "d3_golden_atlas_projection",
    "d3_sallow_jetty_projection",
  ] : mode === "d2" ? [
    "d2_prerequisite_fixture",
    "d2_gameplay_driver",
    "d2_world_interact_table",
    "d2_reprise_table_commit",
    "d2_reprise_preview_contract",
    "d2_real_exit_waystone",
    "d2_real_deepen_choice",
    "d2_terminal_hearth_interaction",
    "d2_layer_two_encounter_contract",
    "d2_exact_one_heirloom",
    "d2_campaign_inert_return",
  ] : mode === "d1" ? [
    "d1_gameplay_driver",
    "d1_world_interact_table",
    "d1_green_table_commit",
    "d1_production_ink_mixing",
    "d1_boss_preview_contract",
    "d1_try_inscribe_chart_escrow",
    "d1_world_campaign_boss",
    "d1_boss_death_host_resolver",
    "d1_terminal_return_idempotence",
    "d1_homecoming_modal_control",
    "d1_homecoming_hall_projection",
    "d1_homecoming_atlas_handoff",
    "d1_homecoming_scanner_inspect",
    "d1_homecoming_copy_only",
  ] : [];
  const startedAt = performance.now();
  // The compact route still performs real Godot scene construction. A cold
  // Compatibility import on a busy release host can be healthy but exceed the
  // old 30-second watchdog; keep the behavioral contract and allow startup.
  const timeoutMs = mode === "d7" ? 900000 : mode === "d6" ? 360000 : mode === "d4" || mode === "d5" ? 300000 : mode === "d2" || mode === "d3" ? 240000 : mode === "c2" || mode === "d1" ? 180000 : mode === "codex" ? 45000 : 900000;
  let finished = false;

  const state = globalThis.__wyrdSmokeHarness = {
    mode,
    required: [...required],
    observed: [],
    status: "waiting",
    error: "",
    // The Godot-side enhanced driver may feature-detect this request. Merely
    // reaching `complete` cannot pass the Codex route without the UI phases.
    request: mode === "d7"
      ? "run_fire_in_the_bough_from_a_fresh_title_through_the_prior_saga_with_real_waystones_lift_table_ashen_verses_manifest_giant_chains_settlement_kiln_alloy_and_threadstep"
      : mode === "d6"
      ? "run_pale_oath_after_canonical_queen_fixture_with_real_stair_archive_table_rootroads_jarl_reliefs_settlement_and_driving_volley"
      : mode === "d5"
      ? "run_queens_summit_after_seventh_fixture_with_real_archive_table_world_queen_stair_and_settlement"
      : mode === "d4"
      ? "run_seventh_road_after_golden_fixture_with_real_atlas_table_world_archive_and_summit_handoff"
      : mode === "d3"
      ? "run_golden_wallow_after_first_knot_fixture_with_real_atlas_table_world_boss_and_settlement"
      : mode === "d2"
      ? "run_d2_reprise_after_explicit_prerequisite_fixture_with_real_table_world_waystone_hearth_boss_and_return"
      : mode === "d1"
      ? "run_d1_campaign_with_real_table_escrow_world_boss_and_return"
      : mode === "c2"
      ? "run_c2_sources_with_real_gameplay_and_controls"
      : mode === "codex" ? "open_chart_table_codex_then_run_snug" : "run_snug",
    requiredFeatures: [...requiredFeatures],
  };
	// Mirror the otherwise programmatic harness onto a tiny semantic DOM node.
	// This keeps release QA observable in browser surfaces that intentionally do
	// not expose page-world globals, without painting a visible debug overlay.
	let statusNode = null;
	if (globalThis.document && typeof globalThis.document.createElement === "function") {
		statusNode = globalThis.document.createElement("output");
		statusNode.id = "wyrd-smoke-status";
		statusNode.dataset.testid = "wyrd-smoke-status";
		statusNode.setAttribute("aria-live", "polite");
		statusNode.style.cssText = "position:fixed;width:1px;height:1px;overflow:hidden;clip-path:inset(50%);";
		globalThis.document.body.appendChild(statusNode);
	}

	function publishStatus() {
		if (statusNode) statusNode.textContent = JSON.stringify({
			mode: state.mode,
			status: state.status,
			error: state.error,
			observed: state.observed,
		});
	}
	publishStatus();

  function isSubsequence(needle, haystack) {
    let index = 0;
    for (const value of haystack) {
      if (value === needle[index]) index += 1;
      if (index === needle.length) return true;
    }
    return false;
  }

  // D7's clock receipt is deliberately structured.  A boolean only says that
  // the driver claims to have used a clock; it cannot prove the lease started
  // after the fresh boundary, stayed within the approved ceiling, used a real
  // wall watchdog, or restored before the terminal report was serialized.
  function hasD7SimulationClockReceipt(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const baseline = value.captured_baseline_scale;
    const terminalWatchdog = value.terminal_watchdog;
    return value.owner === "d7_smoke_clock"
      && value.activated_after_fresh_campaign === true
      && value.requested_scale === 6
      && value.observed_scale === 6
      && value.max_observed_scale === 6
      && typeof baseline === "number" && Number.isFinite(baseline) && baseline > 0
      && value.watchdog_clock === "monotonic_real_time"
      && value.restored_before_terminal_serialization === true
      && value.restored === true
      && value.terminal_reason === "complete"
      && value.terminal_scale === baseline
      && terminalWatchdog && typeof terminalWatchdog === "object" && !Array.isArray(terminalWatchdog)
      && terminalWatchdog.duration_sec === 840
      && terminalWatchdog.ignore_time_scale === true
      && typeof terminalWatchdog.attempt_token === "string"
      && terminalWatchdog.attempt_token.startsWith("d7_")
      && terminalWatchdog.attempt_token.length > 3
      && Number.isInteger(terminalWatchdog.generation) && terminalWatchdog.generation > 0
      && terminalWatchdog.armed === false
      && terminalWatchdog.fired === false
      && terminalWatchdog.cancelled === true
      && terminalWatchdog.stale === false;
  }

  function hasD7ProgressiveLevelLedger(value) {
    if (!Array.isArray(value)) return false;
    const expected = [
      ["first_knot_settlement", 768, 9],
      ["golden_wallow_settlement", 2016, 15],
      ["seventh_road_settlement", 2280, 16],
      ["queens_summit_settlement", 2856, 18],
      ["pale_oath_settlement", 3496, 20],
    ];
    let cursor = 0;
    for (const entry of value) {
      const wanted = expected[cursor];
      if (!wanted) break;
      const wayfinding = entry && entry.trades && entry.trades.wayfinding;
      if (entry && entry.label === wanted[0]
          && wayfinding && wayfinding.xp === wanted[1]
          && wayfinding.level === wanted[2]) cursor += 1;
    }
    return cursor === expected.length;
  }

  function hasD7ExactWayfindingCheckpoints(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const expected = {
      golden_deep_return: [1136, 11],
      golden_third_shallows_return: [1320, 12],
      fire_entry: [3496, 20],
      five_ember_verses: [3840, 21],
      hearth_giant_return: [4200, 22],
    };
    return Object.entries(expected).every(([label, [xp, level]]) => {
      const receipt = value[label];
      return receipt && receipt.expected_xp === xp && receipt.actual_xp === xp
        && receipt.expected_level === level && receipt.actual_level === level;
    });
  }

  function hasD7PackReaderReceipt(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    return Number.isInteger(value.revealed_world)
      && value.revealed_world >= 1 && value.revealed_world <= 5
      && Number.isInteger(value.huntcraft) && value.huntcraft >= 21
      && typeof value.seed_fingerprint === "string"
      && value.seed_fingerprint.length > 0
      && (!value.deferred_worlds || (Array.isArray(value.deferred_worlds)
        && value.deferred_worlds.every((world) => Number.isInteger(world)
          && world >= 1 && world < value.revealed_world)));
  }

  function hasD7CumulativeGatherProof(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const kinds = ["ore_rock", "forage_node", "log_pile"];
    const witnesses = value.first_witness_by_kind;
    return value.complete === true && value.boundary === "before_first_briar"
      && witnesses && typeof witnesses === "object" && !Array.isArray(witnesses)
      && kinds.every((kind) => {
        const witness = witnesses[kind];
        return witness && witness.kind === kind
          && witness.provenance === "d7_scanner_harvest"
          && Number.isInteger(witness.delta) && witness.delta > 0;
      });
  }

  function hasD7WolfBossLootReceipt(value) {
    return value && typeof value === "object" && !Array.isArray(value)
      && typeof value.token === "string" && value.token.startsWith("d7-wolf-")
      && typeof value.kind_id === "string" && value.kind_id.length > 0
      && ["rare", "unique"].includes(value.rarity)
      && Number.isInteger(value.sell_value) && value.sell_value >= 35
      && Number.isInteger(value.inventory_before)
      && value.inventory_after === value.inventory_before + 1
      && Number.isInteger(value.wayfinding_xp)
      && value.pickup_action === "grab";
  }

  function hasD7WolfHodSaleReceipt(value) {
    return value && typeof value === "object" && !Array.isArray(value)
      && typeof value.token === "string" && value.token.startsWith("d7-wolf-")
      && ["rare", "unique"].includes(value.rarity)
      && Number.isInteger(value.expected_value) && value.expected_value >= 35
      && value.actual_value === value.expected_value
      && value.gold_after === value.gold_before + value.expected_value
      && value.inventory_after === value.inventory_before - 1
      && value.persisted_to_town === true
      && value.second_sale_possible === false
      && value.immutable_state_unchanged === true;
  }

  function hasD7QueenComponentBudget(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const start = value.chapter_start;
    const boss = value.boss_ready;
    return start && boss
      && start.purchase_cost === 236
      && start.guaranteed_approach_income === 96
      && start.available_through_boss >= start.purchase_cost
      && start.affordable === true
      && boss.purchase_cost === 56
      && boss.guaranteed_approach_income === 0
      && boss.gold >= boss.purchase_cost
      && boss.affordable === true
      && value.actual_component_spend === 236;
  }

  function hasD7SupportTradeReceipts(value) {
    if (!Array.isArray(value)) return false;
    const labels = ["golden_wallow", "golden_wallow_boss", "seventh_road",
      "seventh_road_boss", "queens_summit", "queens_summit_boss",
      "pale_oath", "pale_oath_boss", "fire_in_the_bough"];
    return labels.every((label) => value.some((receipt) => receipt
      && receipt.label === label && receipt.chart_count === 0
      && receipt.before && receipt.after && receipt.targets
      && Number.isInteger(receipt.wayfinding_xp)
      && receipt.after.earthcraft >= receipt.targets.earthcraft
      && receipt.after.wildcraft >= receipt.targets.wildcraft));
  }

  function hasD7CombatGatherReceipts(value) {
    if (!Array.isArray(value) || value.length < 3) return false;
    const everyRoadCleared = value.every((receipt) => receipt
      && Array.isArray(receipt.events) && receipt.events[0] === "combat_clear"
      && receipt.settled_before_gather === true
      && Number.isInteger(receipt.kills) && receipt.kills > 0
      && Number.isInteger(receipt.harvested) && receipt.harvested >= 0);
    const gatheredRoads = value.filter((receipt) => receipt.harvested > 0
      && receipt.events.includes("gather_scan"));
    // Empty Briar layouts are authored and separately receipted. Require
    // several real combat→gather roads here; the cumulative proof below still
    // requires scanner yields from all three gather-node families.
    return everyRoadCleared && gatheredRoads.length >= 3;
  }

  function hasD7ComponentPurchaseReceipts(value) {
    return Array.isArray(value) && value.length > 0 && value.every((receipt) => receipt
      && typeof receipt.component_id === "string" && receipt.component_id.length > 0
      && Number.isInteger(receipt.unit_price) && receipt.unit_price > 0
      && Number.isInteger(receipt.gold_before) && Number.isInteger(receipt.gold_after)
      && receipt.gold_before - receipt.gold_after === receipt.unit_price
      && Number.isInteger(receipt.owned_before) && Number.isInteger(receipt.owned_after)
      && receipt.owned_after === receipt.owned_before + 1);
  }

  function featureIsSatisfied(name, value) {
    if (name === "d7_simulation_clock") return hasD7SimulationClockReceipt(value);
    if (name === "d7_progressive_level_ledger") return hasD7ProgressiveLevelLedger(value);
    if (name === "d7_exact_wayfinding_checkpoints") return hasD7ExactWayfindingCheckpoints(value);
    if (name === "d7_cumulative_gather_proof") return hasD7CumulativeGatherProof(value);
    if (name === "d7_pack_reader_deferred_reveal") return hasD7PackReaderReceipt(value);
    if (name === "d7_wolf_boss_loot_receipt") return hasD7WolfBossLootReceipt(value);
    if (name === "d7_wolf_hod_sale_receipt") return hasD7WolfHodSaleReceipt(value);
    if (name === "d7_queen_component_budget") return hasD7QueenComponentBudget(value);
    if (name === "d7_support_trade_receipts") return hasD7SupportTradeReceipts(value);
    if (name === "d7_prior_saga_combat_gather_receipts") return hasD7CombatGatherReceipts(value);
    if (name === "d7_component_purchase_receipts") return hasD7ComponentPurchaseReceipts(value);
    return value === true;
  }

  function fail(message) {
    if (finished) return;
    finished = true;
    state.status = "failed";
    state.error = message;
	publishStatus();
    console.error(`[web-smoke-harness] ${message}`);
  }

  function poll() {
    if (finished) return;
    const report = globalThis.__wyrdSmoke;
    if (report && Array.isArray(report.history)) {
      state.observed = [...report.history];
		publishStatus();
      if (report.phase === "failed") {
        fail(report.error || "Godot reported a failed smoke phase.");
        return;
      }
      if (report.phase === "complete") {
        if (!isSubsequence(required, state.observed)) {
          fail(`completed without required ${mode} phases: ${required.join(" -> ")}`);
          return;
        }
        const features = report.features || {};
        const missingFeatures = requiredFeatures.filter((name) => !featureIsSatisfied(name, features[name]));
        if (missingFeatures.length) {
          fail(`completed without real ${mode.toUpperCase()} feature evidence: ${missingFeatures.join(", ")}`);
          return;
        }
        finished = true;
        state.status = "passed";
		publishStatus();
        console.info(`[web-smoke-harness] PASS ${required.join(" -> ")}`);
        return;
      }
    }
    if (performance.now() - startedAt > timeoutMs) {
      fail(`timed out waiting for ${required.join(" -> ")}`);
      return;
    }
    globalThis.setTimeout(poll, 100);
  }

  poll();
})();
