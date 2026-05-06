// NPC registry. Lookup by role; world.js places them at parser-defined coords.
export const NPC_DEFS = {
  cook: {
    sprite: 'cook',
    name: 'Cook',
    // dialog is a state-machine: returns the line for the current quest stage
    dialog(quest) {
      if (!quest.flags.cookTalked) return [
        'Cook: "Adventurer! I am preparing a feast and need 3 cooked beef."',
        'Cook: "Slay 3 cows in the south field, then cook the meat on my fire."',
      ];
      if (quest.cookedBeefDelivered >= 3) return [
        'Cook: "A feast fit for the Duke! Take this Bronze Sword."',
      ];
      const need = 3 - quest.cookedBeefDelivered;
      return [
        `Cook: "Bring me ${need} more cooked beef. Cook them on my fire."`,
      ];
    },
  },
};
