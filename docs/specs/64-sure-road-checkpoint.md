# 64 — Sure Road checkpoint

> **Outcome:** pressing a critical prompt acts on the physical object named by
> that prompt, including after an encounter has been settled.

## Why this is the checkpoint

The full Fire route was mechanically complete, but hands-on browser play found
that banked chains and relieved bells remained eligible for the nearest-target
scanner. A settled prop could therefore absorb the interaction intended for a
nearby far Waystone. That breaks a basic action-game promise: the same visible
prompt and button should produce the same understandable action.

## Contract

- A banked Hearth chain is still visible and collidable, but no longer enters
  the interaction scanner.
- A relieved Oath bell follows the same settled-prop rule.
- Critical source, chain, and far-Waystone route actions arm one expected
  physical target and record which live Interactable consumed the InputMap
  action.
- If scanner ownership changes between acquisition and input, the action fails
  closed and reports the mismatch; it never falls through to the new target.
- Normal play keeps nearest-prompt interaction behavior unless a release check
  explicitly arms an expectation.
- Do not add encounters, rewards, input verbs, or progression breadth.

## Acceptance

- Intentional wrong-chain play is rejected and each authored chain banks once.
- Used chains and relieved bells cannot steal the far-Waystone prompt.
- Keyboard/controller interaction mapping remains unchanged; controller-A
  transition checks prove the intended source receives the action.
- The canonical eight-suite native gate remains green.
- The audited exported build completes one fresh strict Fire journey with an
  empty browser diagnostic ledger.

Implementation evidence lives in
[`64-sure-road-checkpoint-notes.md`](64-sure-road-checkpoint-notes.md).
