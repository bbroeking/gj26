#!/usr/bin/env node
"use strict";

const fs = require("node:fs");

function fail(message) {
  console.error(`capture manifest invalid: ${message}`);
  process.exit(1);
}

const [kind, path, expectedRoute] = process.argv.slice(2);
if (!kind || !path || !expectedRoute) {
  fail("usage: validate_capture_manifest.js <codex|source> <path> <route>");
}
if (!fs.existsSync(path)) fail(`missing ${path}`);

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(path, "utf8"));
} catch (error) {
  fail(`unreadable JSON: ${error.message}`);
}
if (manifest.route !== expectedRoute) {
  fail(`route ${JSON.stringify(manifest.route)} != ${JSON.stringify(expectedRoute)}`);
}

const capabilities = manifest.capabilities || {};
if (kind === "codex") {
  if (capabilities.codex_pages !== true || capabilities.open_codex_page !== true) {
    fail("real Codex controller methods were not present");
  }
  const states = capabilities.codex_states || {};
  if (Object.keys(states).length !== 6) fail("Codex did not expose six canonical pages");

  const expectedRecipe = {
    codex_deep_rumoured_kit: "deep_hollow",
    codex_sallow_rumoured_kit: "sallow_mire",
  }[expectedRoute];
  if (expectedRecipe) {
    if (capabilities.source_error) fail(capabilities.source_error);
    if (capabilities.source_id !== ({
      deep_hollow: "atlas_deep_hollow",
      sallow_mire: "mara_sallow_reed",
    })[expectedRecipe]) fail("wrong C2 source transaction");
    if (capabilities.source_read_result?.ok !== true ||
        capabilities.source_read_result?.changed !== true) {
      fail("C2 source transaction did not make a fresh atomic change");
    }
    if (capabilities.source_status_after?.heard !== true) {
      fail("C2 source was not heard after its transaction");
    }
    if (states[expectedRecipe] !== "rumoured") {
      fail(`${expectedRecipe} rendered ${states[expectedRecipe]}, expected rumoured`);
    }
    if (capabilities.open_recipe_result !== true) fail("C2 detail page did not open");
  }
  if (expectedRoute === "codex_stage_all_sufficient" &&
      capabilities.stage_all_result !== true) fail("Stage All success route failed");
  if (expectedRoute === "codex_stage_all_insufficient" &&
      capabilities.stage_all_result !== false) fail("Stage All failure route mutated");
  if (expectedRoute === "codex_guest" &&
      capabilities.guest_session_started !== true) fail("guest fixture did not start");
} else if (kind === "source") {
  if (manifest.status !== "passed" || manifest.error) {
    fail(manifest.error || `source status was ${manifest.status}`);
  }
  const before = capabilities.status_before || {};
  if (before.valid !== true || before.unlocked !== true || before.heard === true) {
    fail("source did not begin eligible and unread");
  }
  if (!capabilities.source_node) fail("real source node was not discovered");
  if (!capabilities.prompt) fail("real source prompt was not exposed");
  if (capabilities.prompt_visible !== true) fail("real source prompt was not visible");
  if (expectedRoute.endsWith("_read")) {
    if (!capabilities.dialog) fail("real source dialog was not discovered");
    if (capabilities.status_after?.heard !== true) fail("source read did not commit");
    if (!(manifest.actions || []).includes("completed source read through source control")) {
      fail("source completion bypassed its Control seam");
    }
  }
} else {
  fail(`unknown manifest kind ${kind}`);
}

console.log(`manifest ✓ ${expectedRoute}`);
