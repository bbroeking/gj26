// NPC dispatch — currently just Cook.
import { NPC_DEFS } from '../data/npcs.js';
import { talkToCook, offerMaudTuskerQuest, acceptMaudTuskerQuest } from './quest.js';
import { showDialog } from '../ui/dialog.js';

export function talkToNpc(role, player, log, opts = {}) {
  if (role === 'cook') {
    const def = NPC_DEFS.cook;
    const lines = def.dialog(player.quest);
    if (opts.gossip) lines.unshift(opts.gossip);
    const choices = [];
    // Sunken Hut follow-up: offered after the picnic is done.
    if (offerMaudTuskerQuest(player)) {
      choices.push({
        label: 'Accept: A Sow for the Pot',
        onClick: () => { acceptMaudTuskerQuest(player, log); },
      });
    }
    // The picnic hand-off + tusker turn-in both fire silently in
    // talkToCook on dialog close.
    choices.push({ label: 'Leave' });
    showDialog({
      speaker: def.name,
      lines,
      choices,
      onClose: () => talkToCook(player, log),
    });
  }
}
