// Display strings live here; engine identifiers (e.g. `kind: 'cook'`) stay
// generic. World flavor comes from docs/WORLD_BIBLE.md.
//
// Each entry exposes a `dialog(quest)` returning an array of strings (one
// modal page each), so the calling site can pass it straight to showDialog().
//
// `heightM` is the in-lore height in meters. Used by the codex AND by the
// renderer's `_scaleGLBToHeight` to size character GLBs. Standard adult
// humans are 1.7m; tall imposing characters 1.85+m; children/hunched 1.5–1.6m.
export const NPC_DEFS = {
  cook: {
    name: 'Maud Pennycress',
    heightM: 1.65,
    dialog(quest) {
      if (!quest.flags.cookTalked) return [
        'Newcomer. Good. The harvest picnic is tomorrow and I need three cooked beef before sundown.',
        'The dairy herd is in the south pasture. Bramble-imps have been agitating them, so they\'re cross. Take the meat, cook it on my hearth, bring it back. Off you go.',
      ];
      // Sunken-hut follow-up takes priority once the picnic is finished
      if (quest.flags.maudFinished && quest.flags.maudTuskerFinished) return [
        'Tusker stew\'s set. Three pots, fair trade for four cuts of meat.',
        'You ever taste a sow that\'s been wallowing in the bog her whole life? You will. Bless your spoon.',
      ];
      if (quest.flags.maudFinished && quest.flags.maudTuskerAccepted) {
        const have = (quest.flags.tuskerProgress = 0); // (read at click-time elsewhere)
        return ['Got the meat? Four cuts, no less. Try a Sunken Hut chart — sows there are big as a hay-cart.'];
      }
      if (quest.flags.maudFinished) return [
        'You did right by me. Picnic was the talk of the village.',
        '...there\'s another job, if your boots can stand a bog. I want to brew tusker stew but no boar in our pasture is fat enough.',
        'A Sunken Hut chart breeds the biggest sows. Bring me four raw tusker cuts and I\'ll trade you three pots of whicker stew.',
      ];
      if (quest.cookedBeefDelivered >= 3) return [
        'Three cooked beef. Hot, not burned. Bless your hands.',
        'My late husband\'s sword. He won\'t be needing it. You might.',
      ];
      const need = 3 - quest.cookedBeefDelivered;
      return [
        `Still ${need} short. Cow, fire, plate. Don't dither.`,
      ];
    },
  },

  // -------- Hod Tenter, the smith --------
  // Cozy gruff. Quest: bring 5 Mosswort Ore + 2 Logs → Apprentice's Hammer.
  hod: {
    name: 'Old Hod Tenter',
    heightM: 1.72,
    dialog(quest, state) {
      // state: 'offer' | 'progress' | 'turnin' | 'done' (computed in main.js)
      if (state === 'turnin') return [
        "Ore and wood, as promised. Stand back — sparks like to find sleeves.",
        "There. Apprentice's Hammer. It's not pretty, but it'll teach your wrist what an anvil sounds like.",
      ];
      if (state === 'progress') return [
        "Still short. Five mosswort ore, two logs. The wolds give them up if you ask.",
      ];
      if (state === 'offer-delve') return [
        "Wrist suits you. Want a real one?",
        "I want six palechalk ore. The Delve charts run pale-veined deepest — that's where the chalk runs honest.",
        "Bring them and I'll cook you four bogiron bars from them. Pale-iron — soft, but it takes a polish like nothing else.",
      ];
      if (state === 'progress-delve') return [
        "Got the chalk? Six pieces. The Delve charts breed it thick — try one if you haven't yet.",
      ];
      if (state === 'turnin-delve') return [
        "Six. Look at that vein-line. Pure. Stand back, this'll spit.",
        "Four pale-iron bars. Don't drop them while they're hot or you'll be hopping for a week.",
      ];
      if (state === 'done') return [
        "How's the wrist? Working that hammer is half listening, half being honest.",
        "Come back when you've earned a real bar. I'll teach you a proper steel.",
      ];
      // offer / first-meet
      return [
        "Hammer's hot. State your business or stand back.",
        "You look like trouble that's about to learn a trade. Bring me five mosswort ore and two logs — I'll forge you an apprentice's hammer.",
      ];
    },
  },

  // -------- Quill, the herbalist --------
  // Soft-spoken. Quest: gather 3 Bramble Resin → Healing Draughts.
  quill: {
    name: 'Quill',
    heightM: 1.62,
    dialog(quest, state) {
      if (state === 'turnin') return [
        "Three resins — perfect colour, just on the edge of going dark.",
        "Here. Two healing draughts. They'll keep a week if you don't shake them too hard.",
      ];
      if (state === 'progress') return [
        "Still gathering? Look for vines that have gone yellow at the tips. The resin's where the colour leaves them.",
      ];
      if (state === 'offer-briar') return [
        "There's something else, since you handled the resin so well.",
        "I need five thorn essences — the kind only grows where the bramble fae nest thickest. A 'Briar Maze' chart, that'll be your best bet.",
        "Bring them and I'll trade you refined ink. Two pots, that's a fair price.",
      ];
      if (state === 'progress-briar') return [
        "How many essences? The bramble caps drop them — but only the briar-charts breed enough of them to count.",
      ];
      if (state === 'turnin-briar') return [
        "Five — perfect. Look at that gloss on them.",
        "Here. Two pots of refined ink, and my thanks. May your charts hold.",
      ];
      if (state === 'done') return [
        "How fares the road? Save a draught for when you really need it.",
        "I owe you a tincture next season — the wishrose isn't pressed yet.",
      ];
      // offer
      return [
        "Oh — careful, that pot's hedgecap and it bruises if you knock it.",
        "Listen — the brambles up the hill are withering early. I need three Bramble Resin to test what's wrong. Bring them and I'll brew you healing draughts.",
      ];
    },
  },

  // -------- Sir Withering of Trelliswick --------
  // Quest 1: bring Whickerhare's Foot Charm → Falcon's Whistle.
  // Quest 2 (after #1): bring Hedgemother's Thorn-Crown → big XP + lore.
  withering: {
    name: 'Sir Withering',
    heightM: 1.88,
    dialog(quest, state) {
      if (state === 'turnin') return [
        "A whickerhare's foot — clean cut, fresh. Pernel will track it gladly.",
        "Take this. A bone whistle I cut years ago. Three notes, low to high — she'll find you anywhere on the wolds.",
      ];
      if (state === 'progress') return [
        "Still hunting? Whickerhares break for cover at dusk. Quiet feet, patient eye.",
      ];
      if (state === 'offer-crown') return [
        "Pernel scouts well now. Better. But we have one more matter.",
        "The Hedgemother. Thorn-crowned, deep in the wolds. Slay her and bring me her crown — I'll teach you a trick that's saved my life six times.",
      ];
      if (state === 'progress-crown') return [
        "She's old, slow when alone. Watch her brambles — they tell you when she winds up.",
      ];
      if (state === 'turnin-crown') return [
        "By the road... you wear it well. Better than I would have, were I younger.",
        "Carry it as her warning, not your trophy. There are old knights still alive because of that distinction.",
      ];
      if (state === 'done') return [
        "Pernel sees you and trills. That's high praise.",
        "Walk safe. The wolds will know you now.",
      ];
      // offer
      return [
        "Hold a moment — Pernel is shy of strangers. There. She likes the sound of your voice; that's rare.",
        "I have a small task. Bring me a whickerhare's foot from the open wolds and I'll teach you a falconer's signal that may save your life.",
      ];
    },
  },

  eldra: {
    name: 'Eldra the Lampwright',
    heightM: 1.55,
    dialog(quest) {
      if (quest.flags.eldraFinished) return ['Old hands, old wicks. The lanterns burn easier knowing you\'ve helped tend them.'];
      if (quest.flags.eldraAccepted) return [`The dim ones still need lighting. (${quest.eldraLanternsLit ?? 0}/5)`];
      return ['Old hands, old wicks. The lanterns find their light if you tend them, dear.'];
    },
  },

  cricket: {
    name: 'Cricket the Letter-Carrier',
    heightM: 1.58,
    dialog(quest) {
      if (quest.flags.cricketFinished) return ['Pibbet says hello! Anytime you need a parcel run, you know where to find me.'];
      if (quest.flags.cricketAccepted) return [`Three drops left to make. (${quest.cricketDelivered ?? 0}/3)`];
      return ['Got a letter for someone? I run from valley head to coopers\' gate, three rounds a day.'];
    },
  },

  pell: {
    name: 'Brother Pell of the Stone Cloister',
    heightM: 1.74,
    dialog(quest) {
      if (quest.flags.pellFinished) return ['The cloister thanks you. Come read whenever the dust feels welcoming.'];
      if (quest.flags.pellAccepted) return [`Three marked books still in the reading-nook. (${quest.pellRead ?? 0}/3)`];
      return ['Peace to you, traveler. The cloister keeps a small library — old maps, old ledgers, a few pages of bramble-lore.'];
    },
  },

  onywyn: {
    name: 'Mother Onywyn the Herb-Witch',
    heightM: 1.66,
    dialog(quest) {
      if (quest.flags.onywynFinished) return ['The raven still watches, but kindly now. Bring me herbs whenever the brambles spit them up.'];
      if (quest.flags.onywynAccepted) return [`I need five foxglove sprigs to brew the draught. (${quest.onywynFoxgloves ?? 0}/5)`];
      return ['Hush, hush. The raven knows you\'re here. (She gestures with foxglove.)'];
    },
  },
};
