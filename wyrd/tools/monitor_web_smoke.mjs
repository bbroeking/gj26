#!/usr/bin/env node

import {writeFileSync} from "node:fs";

// Monitor a Wayfinder Web smoke route through Chrome DevTools Protocol.
// Chrome should already be running with --remote-debugging-port=<port> and an
// about:blank tab. This script navigates only after the Runtime/Log domains are
// active so startup diagnostics cannot be missed.

const url = process.argv[2];
const timeoutMs = Number(process.argv[3] ?? 900000);
const port = Number(process.argv[4] ?? 9223);
const options = process.argv.slice(5);
const autoBegin = options.includes("--begin");
const screenshotOption = options.find((value) => value.startsWith("--screenshot="));
const screenshotPath = screenshotOption?.slice("--screenshot=".length) ?? "";
if (!url || !Number.isFinite(timeoutMs) || !Number.isFinite(port)) {
  console.error("usage: monitor_web_smoke.mjs URL [timeout_ms] [debug_port] [--begin] [--screenshot=PATH]");
  process.exit(2);
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
let target;
for (let attempt = 0; attempt < 100; attempt += 1) {
  try {
    const response = await fetch(`http://127.0.0.1:${port}/json/list`);
    const targets = await response.json();
    target = targets.find((entry) => entry.type === "page");
    // Chrome 150 can start a remote-debugging browser without exposing the
    // command-line about:blank tab as a page target. Create the QA tab through
    // CDP rather than treating that browser-version detail as a game failure.
    if (!target && attempt === 5) {
      const created = await fetch(
        `http://127.0.0.1:${port}/json/new?about:blank`,
        {method: "PUT"},
      );
      if (created.ok) target = await created.json();
    }
    if (target?.webSocketDebuggerUrl) break;
  } catch (_) {
    // Chrome may still be starting.
  }
  await delay(100);
}
if (!target?.webSocketDebuggerUrl) {
  console.error(`Chrome debugging target did not appear on port ${port}`);
  process.exit(2);
}

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, {once: true});
  socket.addEventListener("error", reject, {once: true});
});

let nextId = 1;
const pending = new Map();
const diagnostics = [];
const diagnosticKeys = new Set();
const recordDiagnostic = (kind, detail) => {
  const diagnostic = `${kind}: ${detail}`;
  if (diagnosticKeys.has(diagnostic)) return;
  diagnosticKeys.add(diagnostic);
  diagnostics.push(diagnostic);
  console.error(`[browser-${kind}] ${detail}`);
};
const send = (method, params = {}) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, {resolve, reject});
  socket.send(JSON.stringify({id, method, params}));
});

socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.id) {
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    if (message.error) waiter.reject(new Error(JSON.stringify(message.error)));
    else waiter.resolve(message.result ?? {});
    return;
  }
  if (message.method === "Runtime.exceptionThrown") {
    const detail = message.params?.exceptionDetails ?? {};
    const text = detail.exception?.description ?? detail.text ?? "runtime exception";
    recordDiagnostic("exception", text);
  }
  if (message.method === "Log.entryAdded") {
    const entry = message.params?.entry ?? {};
    if (["warning", "error"].includes(entry.level)) {
      recordDiagnostic(entry.level, entry.text);
    }
  }
  if (message.method === "Runtime.consoleAPICalled") {
    const type = message.params?.type ?? "log";
    const text = (message.params?.args ?? [])
      .map((arg) => arg.value ?? arg.description ?? "")
      .join(" ");
    if (["warning", "error", "assert"].includes(type)) {
      recordDiagnostic(type, text);
    } else if (text.includes("[web-smoke]")) {
      console.log(text);
    }
  }
});

await send("Runtime.enable");
await send("Log.enable");
await send("Page.enable");
// Godot deliberately suspends its Web main loop when the page is occluded.
// A headed release gate can otherwise spend most of its wall-clock timeout
// paused behind the desktop app even with Chrome's background throttles off.
// Keep this exact QA target foregrounded so the acceptance clock measures
// active gameplay rather than macOS window occlusion.
await send("Page.bringToFront");
const startedAt = performance.now();
await send("Page.navigate", {url});
// Match the manual release procedure's initial canvas gesture. In particular,
// this unlocks WebAudio before the query-gated driver begins pressing Godot UI
// controls, avoiding a false flood of Chrome autoplay-policy warnings.
await delay(250);
await send("Input.dispatchMouseEvent", {
  type: "mousePressed", x: 640, y: 360, button: "left", clickCount: 1,
});
await send("Input.dispatchMouseEvent", {
  type: "mouseReleased", x: 640, y: 360, button: "left", clickCount: 1,
});
if (autoBegin) {
  // The compact Snug route deliberately begins at the real title and waits for
  // a player to choose New Game. Use the rendered button's stable lower-centre
  // location rather than calling a Godot seam, preserving the release path.
  await delay(2500);
  const viewport = await send("Runtime.evaluate", {
    expression: "({width: innerWidth, height: innerHeight})",
    returnByValue: true,
  });
  const size = viewport.result?.value ?? {width: 1280, height: 720};
  const x = Math.round(size.width * 0.5);
  const y = Math.round(size.height * 0.78);
  await send("Input.dispatchMouseEvent", {
    type: "mousePressed", x, y, button: "left", clickCount: 1,
  });
  await send("Input.dispatchMouseEvent", {
    type: "mouseReleased", x, y, button: "left", clickCount: 1,
  });
}

// Release duration is an elapsed-time contract. Wall time can jump when the
// host synchronizes its clock (or wakes from sleep), which previously expired
// a 900-second route after only a few minutes of active gameplay. Node's
// performance clock is monotonic and is the correct source for this gate.
let lastPhase = "";
let finalState = null;
let pollCount = 0;
let screenshotCaptured = false;
while (performance.now() - startedAt < timeoutMs) {
  if (pollCount % 5 === 0) await send("Page.bringToFront");
  pollCount += 1;
  const evaluated = await send("Runtime.evaluate", {
    expression: `JSON.stringify({
      harness: globalThis.__wyrdSmokeHarness ?? null,
      report: globalThis.__wyrdSmoke ?? null
    })`,
    returnByValue: true,
  });
  const raw = evaluated.result?.value;
  if (raw) {
    finalState = JSON.parse(raw);
    const phase = finalState.report?.phase ?? finalState.harness?.status ?? "loading";
    if (phase !== lastPhase) {
      lastPhase = phase;
      const elapsedSec = ((performance.now() - startedAt) / 1000).toFixed(1);
      console.log(`[web-smoke-monitor +${elapsedSec}s] ${phase}`);
    }
    if (!screenshotCaptured && screenshotPath && phase === "world") {
      const shot = await send("Page.captureScreenshot", {format: "png", fromSurface: true});
      writeFileSync(screenshotPath, Buffer.from(shot.data, "base64"));
      screenshotCaptured = true;
    }
    if (finalState.harness?.status === "passed") break;
    if (finalState.harness?.status === "failed") break;
  }
  await delay(1000);
}

socket.close();
const elapsedMs = Math.round(performance.now() - startedAt);
console.log(JSON.stringify({elapsedMs, diagnostics, finalState}, null, 2));
if (diagnostics.length > 0) process.exit(1);
if (finalState?.harness?.status !== "passed") process.exit(1);
