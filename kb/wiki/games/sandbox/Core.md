---
type: game
tags: [game-study, sandbox, ugc, creation-tools, unreal-engine, creator-economy, pc]
status: draft
updated: 2026-06-14
sources:
  - "https://en.wikipedia.org/wiki/Core_(video_game)"
  - "https://www.gamesround.com/blog/manticore-games-raises-100m-for-ugc-games-platform-core"
  - "https://naavik.co/deep-dives/the-state-of-ugc-games-2025-deep-dive/"
  - "https://techcrunch.com/2021/10/14/core-manticore-metaverse-game-creation-hands-on/"
  - "https://www.hollywoodreporter.com/business/digital/manticore-games-launches-monetization-system-for-core-platform-4100540/"
---

# Core

A free-to-play Windows UGC platform by Manticore Games (2021, Early Access) powered by Unreal Engine 4 that lets anyone publish multiplayer games without writing a standalone build — positioned as "Roblox with AAA graphics" and backed by $100 M in funding, though by 2025 Manticore pivoted toward first-party titles built on its own infrastructure.

## Design

**Creation tools.** Creators use a drag-and-drop editor inside Core's launcher, kitbashing from a large built-in asset library or importing external `.obj` files. Logic is scripted in **Lua** against an extensive built-in API, supporting up to 32-player multiplayer. The authoring environment closely resembles a lightweight Unreal editor: move/rotate/scale gizmos, a content browser, play-in-editor testing. Games cannot be exported as standalone executables — they live exclusively inside the Core client, which enforces discoverability but limits creator ownership.

**Discoverability.** A curated front page and genre browsing surface games within the Core launcher. The platform's early breakout titles (Mining Magnate, Roll 'Em) reached 100,000 plays by December 2020 through platform promotion. By 2025 the most-played title had not been updated since 2023, suggesting the platform's discovery funnel did not sustain long-tail engagement.

**Social.** Multiplayer is native: games spin up shared instances and Core accounts persist inventory and progress across sessions. No console release was shipped; the platform remained Windows-only.

**Standout mechanic.** The 50/50 creator revenue split — announced December 2020 — was among the most generous in the UGC space at the time, undercutting Roblox's effective rate and giving creators subscription, in-app-purchase, and pay-to-play levers to combine freely.

## Implementation

Core runs on **Windows** (Steam/Epic Games Store) as a persistent client. All games are hosted by Manticore's servers; creators publish directly from the editor into the live catalogue. The underlying renderer is Unreal Engine 4, giving PC-quality lighting and PBR materials to user-made content at no licensing cost to creators.

In September 2025, Manticore shipped **Out of Time**, a standalone co-op roguelite on the Epic Games Store built internally on Core's tools — signalling a shift from "platform for others" to "studio that uses its own platform." The UGC creator layer remained technically live but received no major editorial investment after 2023.

## Why it matters

Core's experiment answers a specific question: *does a generous revenue split attract enough quality creators to sustain a UGC ecosystem?* The answer appears to be "not without a mobile audience." Core's PC-only footprint, against Roblox's mobile-first 80 M+ DAU base, meant the creator funnel never generated the player mass needed to make creator earnings compelling. The 2025 strategic pivot toward first-party content — using UGC tooling as internal dev infrastructure rather than a marketplace — is a model worth tracking: the tools are reused, but the economy is abandoned.

## Relevance to Wayfinder

1. **[[Economy]]** — The 50/50 split and flexible monetisation levers (subscription, IAP, pay-to-play) are a reference when designing any future Wayfinder creator or modding economy.
2. **[[UI Workflow]]** — Core's in-editor Lua scripting + kitbash approach mirrors the tradeoffs Wayfinder faces if chart-inscription tools are ever exposed to players; the lesson is that Lua lowers the floor but doesn't raise the ceiling.
3. **[[Design Influences]]** — The pivot to self-publishing on a proprietary engine (Out of Time) parallels Wayfinder's own Godot-as-engine decision.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Economy]]
- [[UI Workflow]]
- [[Roblox]] — dominant competitor; compare PC-only vs. mobile-first scale
- [[Garry's Mod]] — earlier Lua-scripted game-on-game creation model
- [[Dreams PS4]] — console UGC counterpart; compare discoverability approaches

## Sources

- https://en.wikipedia.org/wiki/Core_(video_game)
- https://www.gamesround.com/blog/manticore-games-raises-100m-for-ugc-games-platform-core
- https://naavik.co/deep-dives/the-state-of-ugc-games-2025-deep-dive/
- https://techcrunch.com/2021/10/14/core-manticore-metaverse-game-creation-hands-on/
- https://www.hollywoodreporter.com/business/digital/manticore-games-launches-monetization-system-for-core-platform-4100540/
