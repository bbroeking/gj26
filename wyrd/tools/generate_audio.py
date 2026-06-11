#!/usr/bin/env python3
"""Generate Wayfinder's missing SFX via the ElevenLabs sound-generation API.

Usage:
    1. Put ELEVENLABS_API_KEY=... in wyrd/.env (never committed).
    2. python3 tools/generate_audio.py            # generates missing files
       python3 tools/generate_audio.py --force    # regenerates everything
       python3 tools/generate_audio.py --only quaff,town_theme

Files land in wyrd/audio/<key>.mp3 — the paths the Sfx autoload expects.
Existing files are skipped unless --force. The key is read from .env and
never printed.
"""
import argparse
import json
import pathlib
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO_DIR = ROOT / "audio"
ENV_PATH = ROOT / ".env"
API_URL = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128"

# key -> (prompt, duration_seconds). Voice: cozy storybook, chunky-toon —
# clear and a little cartoonish, never gritty-realistic.
SOUNDS = {
    # ---- gather channels (A4 — the channel must be audible, B8 gate) ----
    "mine": ("Pickaxe striking stone twice, gritty rock chips falling, "
             "short bright game sound effect", 1.4),
    "chop": ("Hatchet chopping into a log, two solid woody thunks, "
             "game sound effect", 1.3),
    "forage": ("Quick rustle of leaves and a soft stem snap, picking herbs, "
               "gentle game sound effect", 1.0),
    # ---- the sustain verb ----
    "quaff": ("Cork pop then two quick cartoonish gulps from a small bottle, "
              "satisfied sigh, game sound effect", 1.4),
    # ---- craft stations ----
    "craft_cook": ("Cheerful bubbling cauldron with a wooden stir and a soft "
                   "chime finish, cozy game sound effect", 2.0),
    "craft_smith": ("Hammer striking an anvil twice with a bright metallic "
                    "ring and ember sizzle, game sound effect", 1.8),
    # ---- progression ----
    "level_up": ("Short cheerful fantasy level-up jingle, plucked strings and "
                 "a bright ascending chime, storybook warm", 2.2),
    # ---- boss fights (B4) ----
    "telegraph": ("Low rising rumble swell, danger building underfoot, "
                  "warning game sound effect", 1.0),
    "charge": ("Heavy boar charge, hooves pounding dirt with an angry snort "
               "and a fast whoosh, game sound effect", 1.4),
    "lunge": ("Quick wolf snarl with a fast darting air whoosh, "
              "game sound effect", 0.9),
    # ---- movement + transitions ----
    "roll": ("Quick soft cloth whoosh of a tumbling dodge roll, "
             "game sound effect", 0.7),
    "waystone": ("Magical stone portal awakening, soft crystalline shimmer "
                 "over a deep stone hum, game sound effect", 2.0),
    # ---- the town theme (looped by the Sfx autoload) ----
    "town_theme": ("Gentle cozy fairytale village ambience, warm acoustic "
                   "guitar and a soft flute melody over distant birdsong, "
                   "peaceful storybook morning, seamless loop", 22.0),
}


def read_key() -> str:
    if not ENV_PATH.exists():
        sys.exit(f"missing {ENV_PATH} — create it with ELEVENLABS_API_KEY=...")
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if line.startswith("ELEVENLABS_API_KEY=") and len(line.split("=", 1)[1]) > 4:
            return line.split("=", 1)[1].strip()
    sys.exit("ELEVENLABS_API_KEY not set in .env yet")


def generate(key: str, prompt: str, seconds: float, api_key: str) -> bool:
    body = json.dumps({
        "text": prompt,
        "duration_seconds": seconds,
        "prompt_influence": 0.35,
    }).encode()
    req = urllib.request.Request(API_URL, data=body, method="POST", headers={
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
    except urllib.error.HTTPError as e:
        print(f"  ✗ {key}: HTTP {e.code} — {e.read()[:200]!r}")
        return False
    out = AUDIO_DIR / f"{key}.mp3"
    out.write_bytes(data)
    print(f"  ✓ {key}.mp3 ({len(data) // 1024} KB)")
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    wanted = set(args.only.split(",")) if args.only else set(SOUNDS)
    api_key = read_key()
    AUDIO_DIR.mkdir(exist_ok=True)
    todo = []
    for key in SOUNDS:
        if key not in wanted:
            continue
        if (AUDIO_DIR / f"{key}.mp3").exists() and not args.force:
            print(f"  - {key}.mp3 exists, skipping (--force to redo)")
            continue
        todo.append(key)
    print(f"generating {len(todo)} sounds...")
    failed = 0
    for key in todo:
        prompt, seconds = SOUNDS[key]
        if not generate(key, prompt, seconds, api_key):
            failed += 1
        time.sleep(0.5)   # be polite to the API
    print(f"done — {len(todo) - failed} generated, {failed} failed")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
