// NPC interaction dispatch — currently just Cook.
import { NPC_DEFS } from '../data/npcs.js';
import { talkToCook } from './quest.js';

export function talkToNpc(role, player, log) {
  if (role === 'cook') {
    const lines = NPC_DEFS.cook.dialog(player.quest);
    for (const l of lines) log('quest', l);
    talkToCook(player, log);
  }
}
