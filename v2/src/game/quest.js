// "Cook's Assistant" quest state-machine.
import { CONFIG } from '../data/config.js';
import { awardXp } from './skills.js';

export function makeQuest() {
  return {
    flags: { cookTalked: false, finished: false },
    cowKilled: 0,
    cookedBeefDelivered: 0,
  };
}

export function questSummary(quest) {
  if (!quest.flags.cookTalked) return [{ text: 'Speak to the Cook', state: 'active' }];
  if (quest.flags.finished) return [{ text: "Cook's Assistant — done", state: 'done' }];
  const lines = [];
  lines.push({ text: `Kill cows (${quest.cowKilled}/3)`, state: quest.cowKilled >= 3 ? 'done' : 'active' });
  lines.push({ text: `Deliver cooked beef (${quest.cookedBeefDelivered}/3)`,
                state: quest.cookedBeefDelivered >= 3 ? 'done' : (quest.cowKilled >= 3 ? 'active' : 'pending') });
  return lines;
}

/** Called when player faces Cook + interacts. Returns dialog lines. */
export function talkToCook(player, log) {
  const q = player.quest;
  // First contact
  if (!q.flags.cookTalked) {
    q.flags.cookTalked = true;
    log('quest', '★ Quest started: Cook\'s Assistant');
  }
  // Hand-in
  const have = player.inventory.count('cooked_beef');
  if (have > 0 && q.cookedBeefDelivered < 3) {
    const want = 3 - q.cookedBeefDelivered;
    const give = Math.min(want, have);
    player.inventory.remove('cooked_beef', give);
    q.cookedBeefDelivered += give;
    log('quest', `→ Delivered ${give} Cooked Beef. (${q.cookedBeefDelivered}/3)`);
    if (q.cookedBeefDelivered >= 3 && !q.flags.finished) {
      q.flags.finished = true;
      // reward
      player.inventory.add('bronze_sword', 1);
      awardXp(player, 'atk', 50, log);
      log('quest', '★ Quest complete! +Bronze Sword, +50 Attack XP');
    }
  }
}
