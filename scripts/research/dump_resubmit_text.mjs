#!/usr/bin/env node
// Emit the resubmit batch as plain text — one prompt per line, with a
// `# id` comment line above each. Easier to chunk-paste into MJ than the
// JSON form. Output: docs/research/icons/_resubmit-batch.txt
import { readFileSync, writeFileSync } from 'node:fs';

const ROOT = new URL('../..', import.meta.url).pathname;
const batch = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/_resubmit-batch.json`, 'utf8'));

const out = batch.prompts
  .map((p, i) => `# [${i + 1}/${batch.count}] ${p.id}\n${p.prompt}`)
  .join('\n\n');

writeFileSync(`${ROOT}/docs/research/icons/_resubmit-batch.txt`, out + '\n');
console.log(`Wrote ${batch.count} prompts → docs/research/icons/_resubmit-batch.txt`);
console.log(`(skip the # id lines when pasting; they're for tracking only)`);
