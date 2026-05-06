// Townsfolk questlines for Bramblewood. Each NPC has a small arc tracked
// on player.quest.flags + counters. The tracker is intentionally simple —
// no global registry — because each quest is hand-written.
//
// Lines:
//   maud      — "The Harvest Picnic" (existing)
//   hod       — "First Hammer"
//   quill     — "Withering Bramble"
//   withering — "Pernel's Errand" → optional "Crown of Thorns"
import { awardXp } from './skills.js';

export function makeQuest() {
  return {
    // Per-questline flags. Each is set once, never cleared.
    flags: {
      // Maud
      cookTalked: false,
      finished: false,            // legacy alias for maud's finish flag
      maudFinished: false,
      // Hod
      hodTalked: false,
      hodAccepted: false,
      hodFinished: false,
      // Quill
      quillTalked: false,
      quillAccepted: false,
      quillFinished: false,
      // Withering
      witheringTalked: false,
      witheringAccepted: false,
      witheringFinished: false,
      crownAccepted: false,
      crownFinished: false,
      // Eldra — Lantern Watch (light 5 dim village lanterns by sundown)
      eldraAccepted: false,
      eldraFinished: false,
      // Cricket — Letter Route (deliver 3 letters around the village)
      cricketAccepted: false,
      cricketFinished: false,
      // Pell — Stone Cloister Library (read 3 marked books)
      pellAccepted: false,
      pellFinished: false,
      // Onywyn — Foxglove Trade (bring foxglove sprigs to the herb-witch)
      onywynAccepted: false,
      onywynFinished: false,
    },
    cowKilled: 0,
    cookedBeefDelivered: 0,
    eldraLanternsLit: 0,
    eldraLitIds: [],
    cricketDelivered: 0,
    cricketDeliveredIds: [],
    pellRead: 0,
    pellReadIds: [],
    onywynFoxgloves: 0,
  };
}

export function questSummary(quest) {
  const lines = [];
  // Maud
  if (!quest.flags.cookTalked)        lines.push({ text: 'Speak to Maud Pennycress', state: 'active' });
  else if (quest.flags.finished || quest.flags.maudFinished)
                                       lines.push({ text: 'The Harvest Picnic — done', state: 'done' });
  else {
    lines.push({ text: `Slay dairy cows (${quest.cowKilled}/3)`, state: quest.cowKilled >= 3 ? 'done' : 'active' });
    lines.push({
      text: `Deliver cooked beef to Maud (${quest.cookedBeefDelivered}/3)`,
      state: quest.cookedBeefDelivered >= 3 ? 'done' : (quest.cowKilled >= 3 ? 'active' : 'pending'),
    });
  }
  // Hod
  if (quest.flags.hodAccepted) {
    lines.push({
      text: quest.flags.hodFinished
        ? "Hod's First Hammer — done"
        : "Bring Hod 5 mosswort ore + 2 logs",
      state: quest.flags.hodFinished ? 'done' : 'active',
    });
  }
  // Quill
  if (quest.flags.quillAccepted) {
    lines.push({
      text: quest.flags.quillFinished
        ? "Quill's Withering Bramble — done"
        : "Gather 3 Bramble Resin for Quill",
      state: quest.flags.quillFinished ? 'done' : 'active',
    });
  }
  // Scope-quest triangle — three follow-ups, each pointing at a dungeon scope
  if (quest.flags.quillBriarAccepted) {
    lines.push({
      text: quest.flags.quillBriarFinished
        ? "A Bushel of Thorns — done"
        : "Bring Quill 5 Thorn Essence (try a Briar Maze chart)",
      state: quest.flags.quillBriarFinished ? 'done' : 'active',
    });
  }
  if (quest.flags.hodDelveAccepted) {
    lines.push({
      text: quest.flags.hodDelveFinished
        ? "Pale Veins — done"
        : "Bring Hod 6 Palechalk Ore (try a Delve chart)",
      state: quest.flags.hodDelveFinished ? 'done' : 'active',
    });
  }
  if (quest.flags.maudTuskerAccepted) {
    lines.push({
      text: quest.flags.maudTuskerFinished
        ? "A Sow for the Pot — done"
        : "Bring Maud 4 Raw Tusker (try a Sunken Hut chart)",
      state: quest.flags.maudTuskerFinished ? 'done' : 'active',
    });
  }
  // Withering
  if (quest.flags.witheringAccepted) {
    lines.push({
      text: quest.flags.witheringFinished
        ? "Pernel's Errand — done"
        : "Bring Withering a Whickerhare's Foot Charm",
      state: quest.flags.witheringFinished ? 'done' : 'active',
    });
  }
  if (quest.flags.crownAccepted) {
    lines.push({
      text: quest.flags.crownFinished
        ? 'Crown of Thorns — done'
        : 'Slay the Hedgemother and bring her crown',
      state: quest.flags.crownFinished ? 'done' : 'active',
    });
  }
  // Eldra — Lantern Watch
  if (quest.flags.eldraAccepted) {
    lines.push({
      text: quest.flags.eldraFinished
        ? "Eldra's Lantern Watch — done"
        : `Light dim village lanterns (${quest.eldraLanternsLit}/5)`,
      state: quest.flags.eldraFinished
        ? 'done'
        : (quest.eldraLanternsLit >= 5 ? 'turnin' : 'active'),
    });
  }
  // Cricket — Letter Route
  if (quest.flags.cricketAccepted) {
    lines.push({
      text: quest.flags.cricketFinished
        ? "Cricket's Letter Route — done"
        : `Deliver letters around the village (${quest.cricketDelivered}/3)`,
      state: quest.flags.cricketFinished
        ? 'done'
        : (quest.cricketDelivered >= 3 ? 'turnin' : 'active'),
    });
  }
  // Pell — Stone Cloister Library
  if (quest.flags.pellAccepted) {
    lines.push({
      text: quest.flags.pellFinished
        ? "Pell's Marked Pages — done"
        : `Read marked books at the cloister (${quest.pellRead}/3)`,
      state: quest.flags.pellFinished
        ? 'done'
        : (quest.pellRead >= 3 ? 'turnin' : 'active'),
    });
  }
  // Onywyn — Foxglove Trade
  if (quest.flags.onywynAccepted) {
    lines.push({
      text: quest.flags.onywynFinished
        ? "Onywyn's Foxglove Trade — done"
        : `Bring 5 foxglove sprigs to Mother Onywyn (${quest.onywynFoxgloves}/5)`,
      state: quest.flags.onywynFinished
        ? 'done'
        : (quest.onywynFoxgloves >= 5 ? 'turnin' : 'active'),
    });
  }
  return lines;
}

export function talkToCook(player, log) {
  const q = player.quest;
  if (!q.flags.cookTalked) {
    q.flags.cookTalked = true;
    log('quest', '★ Quest started: The Harvest Picnic');
  }
  const have = player.inventory.count('brindle_roast');
  if (have > 0 && q.cookedBeefDelivered < 3) {
    const want = 3 - q.cookedBeefDelivered;
    const give = Math.min(want, have);
    player.inventory.remove('brindle_roast', give);
    q.cookedBeefDelivered += give;
    log('quest', `→ Delivered ${give} Brindle Roast. (${q.cookedBeefDelivered}/3)`);
    if (q.cookedBeefDelivered >= 3 && !q.flags.finished) {
      q.flags.finished = true;
      q.flags.maudFinished = true;
      player.inventory.add('brindle_sword', 1);
      awardXp(player, 'atk', 50, log);
      log('quest', '★ Picnic ready! Maud gives you her late husband\'s brindle sword.');
      // Unlock pantry stew follow-up: gift one to start the cooking thread
      if (player.inventory.add('pantry_stew', 1)) {
        log('quest', '★ Maud presses a pot of pantry stew into your hands.');
      }
    }
  }
  // Follow-up: Sunken Hut tusker hunt. Auto-trigger turn-in if player
  // walks up with the goods. Plays alongside the picnic-style hand-off.
  if (q.flags.maudFinished && q.flags.maudTuskerAccepted && !q.flags.maudTuskerFinished) {
    const tusker = player.inventory.count('raw_tusker');
    if (tusker >= 4) {
      player.inventory.remove('raw_tusker', 4);
      q.flags.maudTuskerFinished = true;
      if (player.inventory.add('whicker_stew', 3)) {
        log('quest', '★ Maud cooks the tusker meat into three whicker stews. "Gods bless a Tusker Sow."');
      }
      awardXp(player, 'cook', 100, log);
    }
  }
}
/** Maud's follow-up — sunken_hut scope. The Sunken Hut chart's loot
 *  table biases hard toward raw_tusker (4 is enough for a full hand-in). */
export function offerMaudTuskerQuest(player) {
  // Returns true if there's a fresh quest to offer right now (post-picnic,
  // not yet accepted).
  const q = player.quest;
  return q.flags.maudFinished && !q.flags.maudTuskerAccepted;
}
export function acceptMaudTuskerQuest(player, log) {
  player.quest.flags.maudTuskerAccepted = true;
  log('quest', '★ Quest started: A Sow for the Pot.');
  log('quest', '→ Bring 4 Raw Tusker. Maud says a Sunken Hut chart breeds the biggest sows.');
}
export function maudTuskerProgress(player) {
  const q = player.quest;
  if (!q.flags.maudTuskerAccepted) return null;
  if (q.flags.maudTuskerFinished) return 'done';
  return player.inventory.count('raw_tusker');
}

// ---- Hod the smith ----------------------------------------------------
export function talkToHod(player, log) {
  const q = player.quest;
  if (!q.flags.hodTalked) {
    q.flags.hodTalked = true;
    return { kind: 'offer', npc: 'hod' };
  }
  if (!q.flags.hodAccepted) return { kind: 'offer', npc: 'hod' };
  if (!q.flags.hodFinished) {
    // First quest still in progress
    const ore  = player.inventory.count('mosswort_ore');
    const logs = player.inventory.count('logs');
    if (ore >= 5 && logs >= 2) return { kind: 'turnin', npc: 'hod' };
    return { kind: 'progress', npc: 'hod', ore, logs };
  }
  // Follow-up: Hod wants palechalk_ore from a Delve chart
  if (!q.flags.hodDelveAccepted) return { kind: 'offer-delve', npc: 'hod' };
  if (q.flags.hodDelveFinished)  return { kind: 'done', npc: 'hod' };
  const chalk = player.inventory.count('palechalk_ore');
  if (chalk >= 6) return { kind: 'turnin-delve', npc: 'hod' };
  return { kind: 'progress-delve', npc: 'hod', chalk };
}
export function acceptHodQuest(player, log) {
  const q = player.quest;
  q.flags.hodAccepted = true;
  if (player.inventory.add('hods_anvil_token', 1)) {
    log('quest', "★ Quest started: Hod's First Hammer.");
    log('quest', '→ Bring 5 Mosswort Ore + 2 Logs.');
  }
}
export function turnInHodQuest(player, log) {
  const q = player.quest;
  if (player.inventory.count('mosswort_ore') < 5 || player.inventory.count('logs') < 2) return;
  player.inventory.remove('mosswort_ore', 5);
  player.inventory.remove('logs', 2);
  player.inventory.remove('hods_anvil_token', 1);
  q.flags.hodFinished = true;
  if (player.inventory.add('apprentices_hammer', 1)) {
    log('quest', "★ Hod hammers the apprentice's hammer for you. Smithing unlocked in spirit.");
  }
  awardXp(player, 'smith', 60, log);
}
/** Hod's follow-up — wants palechalk ore, which the Delve scope's stone-
 *  themed pool drops from chest loot bonus. */
export function acceptHodDelveQuest(player, log) {
  player.quest.flags.hodDelveAccepted = true;
  log('quest', '★ Quest started: Pale Veins.');
  log('quest', '→ Bring 6 Palechalk Ore. Hod says the Delve charts run pale-veined deepest.');
}
export function turnInHodDelveQuest(player, log) {
  if (player.inventory.count('palechalk_ore') < 6) return;
  player.inventory.remove('palechalk_ore', 6);
  player.quest.flags.hodDelveFinished = true;
  if (player.inventory.add('bogiron_bar', 4)) {
    log('quest', '★ Hod cooks the chalk into four pale-iron bars and slides them across the anvil.');
  }
  awardXp(player, 'smith', 120, log);
  awardXp(player, 'mine', 60, log);
}

// ---- Quill the herbalist ----------------------------------------------
export function talkToQuill(player, log) {
  const q = player.quest;
  if (!q.flags.quillTalked) { q.flags.quillTalked = true; return { kind: 'offer', npc: 'quill' }; }
  if (!q.flags.quillAccepted) return { kind: 'offer', npc: 'quill' };
  // First quest still in progress
  if (!q.flags.quillFinished) {
    const resin = player.inventory.count('bramble_resin');
    if (resin >= 3) return { kind: 'turnin', npc: 'quill' };
    return { kind: 'progress', npc: 'quill', resin };
  }
  // Follow-up: Briar Essence — only after first quest finished
  if (!q.flags.quillBriarAccepted) return { kind: 'offer-briar', npc: 'quill' };
  if (q.flags.quillBriarFinished)  return { kind: 'done', npc: 'quill' };
  const essence = player.inventory.count('thorn_essence');
  if (essence >= 5) return { kind: 'turnin-briar', npc: 'quill' };
  return { kind: 'progress-briar', npc: 'quill', essence };
}
export function acceptQuillQuest(player, log) {
  player.quest.flags.quillAccepted = true;
  log('quest', '★ Quest started: Withering Bramble.');
  log('quest', '→ Gather 3 Bramble Resin from withered bramble vines.');
}
export function turnInQuillQuest(player, log) {
  const q = player.quest;
  if (player.inventory.count('bramble_resin') < 3) return;
  player.inventory.remove('bramble_resin', 3);
  q.flags.quillFinished = true;
  // Reward: 2 healing draughts + foraging XP
  if (player.inventory.add('healing_draught', 2)) {
    log('quest', '★ Quill brews two healing draughts and presses them into your bag.');
  }
  awardXp(player, 'forage', 40, log);
}
/** Follow-up quest unlocked after Withering Bramble — sends the player
 *  into a Briar Maze chart specifically, since that scope's spawn pool
 *  biases hard toward thorn-fae enemies (skitterlings + bramble caps),
 *  the natural source of thorn_essence. */
export function acceptQuillBriarQuest(player, log) {
  player.quest.flags.quillBriarAccepted = true;
  log('quest', '★ Quest started: A Bushel of Thorns.');
  log('quest', '→ Bring 5 Thorn Essence. The bramble cap drops them — try a Briar Maze chart.');
}
export function turnInQuillBriarQuest(player, log) {
  const q = player.quest;
  if (player.inventory.count('thorn_essence') < 5) return;
  player.inventory.remove('thorn_essence', 5);
  q.flags.quillBriarFinished = true;
  // Reward: refined_ink (rare, scope-themed) + foraging + carto XP
  if (player.inventory.add('refined_ink', 2)) {
    log('quest', "★ Quill twists the essences into thread. \"Two pots of refined ink — for your maps.\"");
  }
  awardXp(player, 'forage', 80, log);
  awardXp(player, 'carto', 60, log);
}

// ---- Sir Withering ----------------------------------------------------
export function talkToWithering(player, log) {
  const q = player.quest;
  if (!q.flags.witheringTalked) { q.flags.witheringTalked = true; return { kind: 'offer', npc: 'withering' }; }
  if (!q.flags.witheringAccepted) return { kind: 'offer', npc: 'withering' };
  if (q.flags.witheringFinished) {
    // Optional follow-up: Crown of Thorns
    if (!q.flags.crownAccepted) return { kind: 'offer-crown', npc: 'withering' };
    if (q.flags.crownFinished) return { kind: 'done', npc: 'withering' };
    // Crown turn-in if player has the thorn_crown drop
    if (player.inventory.count('thorn_crown') >= 1) return { kind: 'turnin-crown', npc: 'withering' };
    return { kind: 'progress-crown', npc: 'withering' };
  }
  if (player.inventory.count('whickerhares_foot') >= 1) return { kind: 'turnin', npc: 'withering' };
  return { kind: 'progress', npc: 'withering' };
}
export function acceptWitheringQuest(player, log) {
  player.quest.flags.witheringAccepted = true;
  log('quest', "★ Quest started: Pernel's Errand.");
  log('quest', '→ Find a Whickerhare\'s Foot Charm. Whickerhares roam the open wolds.');
}
export function turnInWitheringQuest(player, log) {
  const q = player.quest;
  if (player.inventory.count('whickerhares_foot') < 1) return;
  player.inventory.remove('whickerhares_foot', 1);
  q.flags.witheringFinished = true;
  if (player.inventory.add('falcons_whistle', 1)) {
    log('quest', "★ Sir Withering presses a bone whistle into your palm. \"For Pernel.\"");
  }
  awardXp(player, 'falconry', 30, log);
}
export function acceptCrownQuest(player, log) {
  player.quest.flags.crownAccepted = true;
  log('quest', "★ Quest started: Crown of Thorns.");
  log('quest', '→ Slay the Hedgemother and bring her thorn-crown.');
}
export function turnInCrownQuest(player, log) {
  const q = player.quest;
  if (player.inventory.count('thorn_crown') < 1) return;
  // Don't consume the crown — it's a wearable / lore item.
  q.flags.crownFinished = true;
  awardXp(player, 'atk', 200, log);
  awardXp(player, 'def', 200, log);
  log('quest', '★ Sir Withering bows. "You wear it well, where I could not."');
}
