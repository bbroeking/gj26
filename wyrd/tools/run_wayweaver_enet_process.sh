#!/usr/bin/env bash
# Real host/guest loopback acceptance gate for D8 Wayweaver.  It launches two
# independent Godot headless processes and accepts only their explicit PASS
# markers, zero exit codes, and no engine errors in either log.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
GODOT_EXTRA_ARGS=()
if [[ -n "${WYRD_WAYWEAVER_ENET_GODOT_ARGS:-}" ]]; then
  # Intentionally shell-word split only for a local test flag such as
  # `--verbose`; the executable itself remains one quoted path.
  read -r -a GODOT_EXTRA_ARGS <<<"$WYRD_WAYWEAVER_ENET_GODOT_ARGS"
fi
PORT="${WYRD_WAYWEAVER_ENET_PORT:-18777}"
STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wayweaver-enet.XXXXXX")"
HOST_LOG="$STATE_DIR/host.log"
GUEST_LOG="$STATE_DIR/guest.log"
KEEP="${WYRD_WAYWEAVER_ENET_KEEP_LOGS:-0}"

cleanup() {
  local status=$?
  if [[ -n "${HOST_PID:-}" ]] && kill -0 "$HOST_PID" 2>/dev/null; then kill "$HOST_PID" 2>/dev/null || true; fi
  if [[ -n "${GUEST_PID:-}" ]] && kill -0 "$GUEST_PID" 2>/dev/null; then kill "$GUEST_PID" 2>/dev/null || true; fi
  if [[ "$status" -ne 0 || "$KEEP" == "1" ]]; then
    printf 'Wayweaver ENet logs: %s\n' "$STATE_DIR"
  else
    rm -rf "$STATE_DIR"
  fi
}
trap cleanup EXIT INT TERM

run_role() {
  local role=$1
  local log=$2
  if (( ${#GODOT_EXTRA_ARGS[@]} )); then
    env WYRD_NO_SAVE=1 WYRD_NO_UPNP=1 \
      WYRD_WAYWEAVER_ENET_ROLE="$role" \
      WYRD_WAYWEAVER_ENET_PORT="$PORT" \
      WYRD_WAYWEAVER_ENET_STATE_DIR="$STATE_DIR" \
      "$GODOT_BIN" "${GODOT_EXTRA_ARGS[@]}" --headless --path "$ROOT" --script res://test_wayweaver_enet_process.gd \
      >"$log" 2>&1
  else
    env WYRD_NO_SAVE=1 WYRD_NO_UPNP=1 \
      WYRD_WAYWEAVER_ENET_ROLE="$role" \
      WYRD_WAYWEAVER_ENET_PORT="$PORT" \
      WYRD_WAYWEAVER_ENET_STATE_DIR="$STATE_DIR" \
      "$GODOT_BIN" --headless --path "$ROOT" --script res://test_wayweaver_enet_process.gd \
      >"$log" 2>&1
  fi
}

run_role host "$HOST_LOG" & HOST_PID=$!
# The process log line is a useful early failure diagnosis; the harness itself
# still owns the real roster/attestation readiness contract.
for _ in $(seq 1 100); do
  if grep -q 'ENET_D8_HOST_LISTENING' "$HOST_LOG" 2>/dev/null; then break; fi
  if ! kill -0 "$HOST_PID" 2>/dev/null; then
    cat "$HOST_LOG"
    exit 1
  fi
  sleep 0.05
done
if ! grep -q 'ENET_D8_HOST_LISTENING' "$HOST_LOG"; then
  cat "$HOST_LOG"
  exit 1
fi
run_role guest "$GUEST_LOG" & GUEST_PID=$!

deadline=$((SECONDS + 25))
while kill -0 "$HOST_PID" 2>/dev/null || kill -0 "$GUEST_PID" 2>/dev/null; do
  if (( SECONDS >= deadline )); then
    echo 'ENET_D8_FAIL watchdog timeout' >&2
    exit 1
  fi
  sleep 0.05
done
wait "$HOST_PID"
wait "$GUEST_PID"

for log in "$HOST_LOG" "$GUEST_LOG"; do
  if grep -E 'ENET_D8_FAIL|SCRIPT ERROR|Parse Error|ERROR:|ObjectDB instances leaked|No route to host|sendto:' "$log" >/dev/null; then
    cat "$log"
    exit 1
  fi
done
grep -q 'ENET_D8_HOST_PASS' "$HOST_LOG"
grep -q 'ENET_D8_GUEST_PASS' "$GUEST_LOG"
printf 'ENET_D8_PROCESS_GATE_PASS port=%s\n' "$PORT"
