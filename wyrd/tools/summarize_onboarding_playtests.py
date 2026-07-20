#!/usr/bin/env python3
"""Summarize Spec 57 cold-playtest JSON reports without external packages."""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path
from typing import Any


GATES: tuple[tuple[str, str, float, str | None], ...] = (
    ("Control", "control_ready", 15.0, None),
    ("First movement", "first_movement", 10.0, "control_ready"),
    ("Mara", "first_mara_conversation", 180.0, None),
    ("Snug entered", "snug_entered", 600.0, None),
    ("Snug completed", "snug_completed", 1080.0, None),
    ("Tier 1 entered", "tier1_entered", 1500.0, None),
    ("Chapter complete", "first_chapter_complete", 2100.0, None),
)


def load_report(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("events"), list):
        raise ValueError("expected an object with an events array")
    return data


def event_times(report: dict[str, Any]) -> dict[str, float]:
    out: dict[str, float] = {}
    for event in report.get("events", []):
        if not isinstance(event, dict):
            continue
        name = event.get("event")
        elapsed = event.get("elapsed_sec")
        if isinstance(name, str) and isinstance(elapsed, (int, float)):
            out.setdefault(name, float(elapsed))
    return out


def gate_value(times: dict[str, float], event: str, relative_to: str | None) -> float | None:
    if event not in times:
        return None
    value = times[event]
    if relative_to is not None:
        if relative_to not in times:
            return None
        value -= times[relative_to]
    return value


def format_seconds(value: float | None) -> str:
    if value is None:
        return "missing"
    minutes, seconds = divmod(max(0.0, value), 60.0)
    return f"{int(minutes)}:{seconds:04.1f}"


def summarize(paths: list[Path]) -> int:
    reports: list[tuple[Path, dict[str, Any], dict[str, float]]] = []
    for path in paths:
        try:
            report = load_report(path)
        except (OSError, json.JSONDecodeError, ValueError) as exc:
            print(f"error: {path}: {exc}", file=sys.stderr)
            return 2
        reports.append((path, report, event_times(report)))

    print(f"Wayfinder onboarding cold-test summary — {len(reports)}/4 sessions")
    print()
    header = f"{'Gate':<20} {'Target':>9}" + "".join(
        f"  {path.stem[:12]:>12}" for path, _, _ in reports
    ) + "  Median"
    print(header)
    print("-" * len(header))
    all_pass = len(reports) >= 4
    for label, event, target, relative_to in GATES:
        values = [gate_value(times, event, relative_to) for _, _, times in reports]
        present = [value for value in values if value is not None]
        median = statistics.median(present) if present else None
        cells = []
        for value in values:
            passed = value is not None and value <= target
            all_pass = all_pass and passed
            cells.append(f"{format_seconds(value)} {'✓' if passed else '✗'}")
        target_label = f"≤{format_seconds(target)}"
        print(f"{label:<20} {target_label:>9}" + "".join(
            f"  {cell:>12}" for cell in cells
        ) + f"  {format_seconds(median)}")

    recovery_totals: dict[str, int] = {}
    for _, report, _ in reports:
        for name, count in report.get("recovery_hints", {}).items():
            if isinstance(name, str) and isinstance(count, (int, float)):
                recovery_totals[name] = recovery_totals.get(name, 0) + int(count)
    print("\nRecovery activations:")
    if recovery_totals:
        for name in sorted(recovery_totals):
            print(f"  {name}: {recovery_totals[name]}")
    else:
        print("  none")

    if len(reports) < 4:
        print("\nNOT READY — four cold sessions are required (three native, one web).")
        return 1
    print(f"\n{'PASS' if all_pass else 'TUNE'} — timing gates "
          f"{'all passed' if all_pass else 'need attention'}.")
    return 0 if all_pass else 1


def self_test() -> int:
    report = {"events": [
        {"event": "control_ready", "elapsed_sec": 8.0},
        {"event": "first_movement", "elapsed_sec": 13.0},
        {"event": "first_chapter_complete", "elapsed_sec": 1800.0},
    ]}
    times = event_times(report)
    assert gate_value(times, "first_movement", "control_ready") == 5.0
    assert gate_value(times, "first_chapter_complete", None) == 1800.0
    assert gate_value(times, "snug_entered", None) is None
    assert format_seconds(65.5) == "1:05.5"
    print("onboarding report analyzer self-test: PASS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="*", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if not args.reports:
        parser.error("provide one or more onboarding_playtest.json reports")
    return summarize(args.reports)


if __name__ == "__main__":
    raise SystemExit(main())
