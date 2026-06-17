# Wayfinder Co-op — Host & Play with Friends

Light a fire, share your address, and delve the same dungeons together. This is
everything you need to host, join, and understand how the multiplayer works.

---

## TL;DR

- **Host:** `Esc` → **The Lantern** → **"Light a fire"** → **"Copy address"** →
  send it to your friend.
- **Join:** `Esc` → **The Lantern** → paste the address → **"Join"**.
- Works on the **same network** or over **Tailscale** (recommended). Port **7777**.
- Friends can join **any time** — in town or mid-delve.

---

## Hosting (step by step)

1. **Run the game** (`godot --path wyrd`, or your build).
2. Press **`Esc`** to open **The Lantern** (the co-op menu).
3. Click **"Light a fire — host (port 7777)"**. You're now the **fire-keeper**
   (the host) — the world keeps running while the Lantern is open.
4. Click **"Copy address"** and send it to your friend (chat/DM). Press `Esc`
   to close the Lantern and keep playing.
5. When a friend joins, they appear beside you. If you're **already in a
   dungeon**, you'll also see the toast *"&lt;name&gt; joins the delve."* (In
   town there's no toast yet — check the party frame / the Lantern's roster to
   confirm they're in.)

> You can keep playing — even start a delve — before anyone joins. A friend who
> connects while you're already in a dungeon is pulled straight into your run.

## Joining a friend

1. **Run the game**, press **`Esc`** → **The Lantern**.
2. Paste your friend's address into the **"friend's address (IP or IP:port)"**
   field and click **"Join"**.
3. You drop into their town. If they're mid-dungeon, you're pulled into the same
   run (same layout, same enemies) automatically.

To leave: `Esc` → **"Leave the party"** (or just close the game).

---

## Getting connected — three paths

### 1. Tailscale (recommended — works anywhere, no router setup)
Both of you install [Tailscale](https://tailscale.com) (free) and sign in. The
host's Tailscale address starts with **`100.`** and appears in the Lantern's
address list (it's the primary one unless your router's UPnP also found a public
IP — the Lantern shows "Other addresses" too, so grab the `100.x`). Send it; your
friend joins with it from anywhere on the internet. No port-forwarding, no
firewall fiddling. This is the most reliable path.

### 2. Same network / LAN (no setup)
If you're on the same Wi-Fi/router, the host's address is a **`192.168.x`** or
**`10.x`** — share it and your friend joins directly.

### 3. Over the open internet (advanced)
- **UPnP (automatic, opportunistic):** if your router supports UPnP, the host
  auto-maps port 7777 and its **public IP** appears first in the Lantern. Many
  home routers have UPnP disabled — if no public IP shows, use Tailscale instead.
- **Manual port-forward:** forward port **7777** (TCP+UDP) to the host machine
  in your router, then your friend uses your public IP. Tailscale is easier.

> On the **first host**, macOS/Windows may pop a firewall prompt to allow
> incoming connections — **allow it**, or friends can't reach you.

---

## Quick local test (two windows on one machine)

```bash
WYRD_NET=host godot --path wyrd            # window 1 — hosts on 7777
WYRD_NET=join:127.0.0.1 godot --path wyrd  # window 2 — joins it
```

Dev/CLI hooks (handy for testing):

| Env var | Effect |
|---|---|
| `WYRD_NET=host` | Light a fire on boot (port 7777) |
| `WYRD_NET=join:<ip[:port]>` | Join a fire on boot |
| `WYRD_DISPLAY_NAME=<name>` | Set your party name |
| `WYRD_NET_RUN=<sec>` | (host) auto-socket a Tier-1 chart after N seconds |
| `WYRD_NET_RUN_BOSS=<trophy>` | (host) force a boss den, e.g. `thorn_essence` → Hedgemother |

---

## How it works

**Host-authoritative over ENet.** The host (peer `1`, the *fire-keeper*) is the
single source of truth; everyone else is a guest. There's no dedicated server —
one player's machine *is* the server, and it keeps simulating while the Lantern
is open.

**Deterministic shared runs — the trick that makes it cheap.** When the host
sockets a chart, only the **chart + its seed** go to each peer. Every machine
then rebuilds the *same* dungeon locally from that seed: identical geometry,
enemies, boss, and loot positions. No level data is streamed — same seed → same
world. (You'll see the identical seed in each player's logs.)

**Players.** Each peer owns its own body (has *authority* over it); your input
drives yours. Other players' bodies mirror via small ~12/sec snapshots carrying
position, facing, moving/dead, and **HP** (so the party frame can show everyone's
health).

**Enemies & the boss — host-driven.** The host runs *all* enemy and boss AI.
Guests show "puppet" copies driven by the host's snapshots (position + HP +
active **status flags** like burn/bleed/snare). The **boss** is the same: guests
replay its **aggro, phase changes, telegraphs, and health bar** from host
broadcasts — so its attacks are visible and **dodgeable** on every screen, and
the arena gates close for everyone.

**Authoritative vs. cosmetic.** The host owns what *matters for fairness* —
damage resolution, enemy/boss AI, loot rolls, kill credit. Guests *replay*
visuals — arrows, damage numbers, boss telegraphs, status effects — so everyone
sees the same fight without the guest's machine getting a vote on the outcome.

**Mid-run join.** A friend who connects while you're delving is dropped into the
active chart and rebuilds it from the seed — no waiting in town.

**Reconnect (wi-fi blips).** If a guest's connection drops, they auto-retry a few
times and rejoin the same run; their own progress (satchel, gold, trades) is kept
locally, so a brief blip doesn't lose anything. The Lantern/HUD shows a
"reconnecting…" banner.

**The party HUD.** Top-left shows every peer's **name + HP bar**. Center banners
announce reconnects and the exit countdown.

**Leaving together.** Stepping through the **exit waystone** gives the rest of the
party a **5-second grace** (grab that last pickup) before everyone returns to
town together. **Abandoning** (tearing the chart) ends the run immediately.

**Loot & progress.** Each player rolls their **own** loot and keeps their **own**
satchel, gold, and trade levels — a shared adventure with individual spoils.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| *"No answer at that door."* | Wrong address/port, the host isn't hosting, or a firewall is blocking. Re-copy the address; allow the firewall prompt on the host. |
| Can't connect over the internet | Use **Tailscale** (simplest), or forward port **7777** on the host's router. |
| Host address is `100.x` | That's **Tailscale** — perfect, share it. |
| Host address is `192.168.x` / `10.x` | **LAN only** — friend must be on the same network (or use Tailscale). |
| No public IP in the Lantern | Your router's UPnP is off — use Tailscale or manual port-forward. |
| Guest sees the dungeon but enemies look frozen | Enemies are host-driven snapshots; a brief freeze means the host hitched. It catches up. |

---

## Limits & notes

- **LAN and Tailscale are proven.** Internet-via-UPnP is opportunistic and
  depends on your router.
- **The host carries the run.** If the host quits, the run ends for everyone
  (guests get the grace and return to town). There's no host migration.
- Co-op is **drop-in**: friends can join, leave, and rejoin freely.

*Architecture and remaining polish are tracked in
[`docs/system-plans/COOP-GOAL.md`](system-plans/COOP-GOAL.md).*
