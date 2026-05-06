// Orchestrator — runs all code-based evals, optionally LLM evals with --full.
// Exits 1 on any blocking failure.
import { evalItemSchema } from './schema.eval.js';
import { evalTierBudget } from './tier-budget.eval.js';
import { evalCrossRefs } from './cross-refs.eval.js';

const FULL = process.argv.includes('--full');

async function main() {
  let exitCode = 0;
  let totalErrors = 0;

  function section(name, errors, blocking = true) {
    console.log(`\n=== ${name} ===`);
    if (errors.length === 0) {
      console.log(`  ✓ pass`);
    } else {
      console.error(`  ✗ ${errors.length} errors:`);
      errors.forEach(e => console.error(`    - ${e}`));
      totalErrors += errors.length;
      if (blocking) exitCode = 1;
    }
  }

  // ---- Layer 1: schema ----
  section('Layer 1 — schema', evalItemSchema());

  // ---- Layer 2: tier budgets ----
  section('Layer 2 — tier budgets', evalTierBudget());

  // ---- Layer 3: cross-refs ----
  section('Layer 3 — cross-refs', evalCrossRefs());

  // ---- Layer 6: balance sim (when implemented) ----
  // section('Layer 6 — balance sim', evalBalance(), false);  // warn, don't fail

  if (FULL) {
    console.log('\n--- Full mode: running LLM graders (slow, costs API tokens) ---');
    // Stubs — uncomment as you implement these:
    //
    // const { evalAllVoices } = await import('./voice.eval.js');
    // section('Layer 4 — voice (LLM)', await evalAllVoices(), false);
    //
    // const { evalAllLore } = await import('./lore.eval.js');
    // section('Layer 5 — lore (LLM)', await evalAllLore(), false);
    console.log('  (LLM evals are stubbed — uncomment in run-all.js when ready)');
  } else {
    console.log('\n(Skipping LLM evals — pass --full to include them)');
  }

  console.log('\n========================================');
  if (exitCode === 0) {
    console.log(`✓ all blocking evals passed${totalErrors > 0 ? ` (${totalErrors} non-blocking warnings)` : ''}`);
  } else {
    console.error(`✗ ${totalErrors} errors total — blocking shipment`);
  }

  process.exit(exitCode);
}

main();
