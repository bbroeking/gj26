#!/usr/bin/env node
// Unpacks the custom MJB1 archive produced by the in-browser bulk-loader
// into per-id PNGs in assets/icons/.
//
// Format:
//   "MJB1" (4 bytes)
//   uint32 LE: entry count
//   per entry:
//     uint8: id length
//     id (utf-8 bytes)
//     uint32 LE: data length
//     data (PNG bytes)
//
// Usage:  node scripts/research/unpack_mj_archive.mjs [archive_path]
//   default archive path = ~/Downloads/mj-icons.mjb1
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';

const archivePath = process.argv[2] || `${homedir()}/Downloads/mj-icons.mjb1`;
const ROOT = new URL('../..', import.meta.url).pathname;
const OUT = `${ROOT}/assets/icons`;
mkdirSync(OUT, { recursive: true });

if (!existsSync(archivePath)) {
  console.error(`Archive not found: ${archivePath}`);
  process.exit(1);
}

const buf = readFileSync(archivePath);
const magic = buf.slice(0, 4).toString('ascii');
if (magic !== 'MJB1') {
  console.error(`Bad magic: expected MJB1, got ${JSON.stringify(magic)}`);
  process.exit(1);
}

const count = buf.readUInt32LE(4);
console.log(`Archive: ${archivePath}  entries=${count}  size=${buf.length}`);

let off = 8;
let written = 0, skipped = 0;
for (let i = 0; i < count; i++) {
  const idLen = buf.readUInt8(off); off += 1;
  const id = buf.slice(off, off + idLen).toString('utf8'); off += idLen;
  const dataLen = buf.readUInt32LE(off); off += 4;
  const data = buf.slice(off, off + dataLen); off += dataLen;
  // Strip skill_ prefix → save as e.g. atk.png
  const fileName = id.replace(/^skill_/, '') + '.png';
  const dest = `${OUT}/${fileName}`;
  writeFileSync(dest, data);
  written++;
}
console.log(`Wrote ${written} icons → ${OUT}`);
