# LiteButtonAuras WoW AddOn

LiteButtonAuras shows your buffs on you and your debuffs on your target inside your action buttons with a
colored border and timer. It is like AdiButtonAuras, and Inline Aura before it, just much dumber and much
easier to maintain.

Buff on you shows a green highlight in ability button:

![](https://i.imgur.com/vsf97X0.png)

Debuff on your target shows red highlight in ability button:

![](https://i.imgur.com/HmN2WR5.png)

For all of your action buttons:

- If the action is an interrupt, and your target is casting a spell you can interrupt, suggest the button (border glow/ants) with a timer.
- If the target is enraged and the action is a soothe, suggest the button.
- If the action name matches a buff on you that you cast, show a green highlight and a timer. Includes some totems and guardians.
- If the action name matches a debuff that you cast on your target, show a red highlight and a timer.
- If the action is a purge or dispel, show a highlight colored by the buff or debuff you can purge/dispel.

Works with the default Blizzard action bars, Dominos, and probably ElvUI.

Compared to AdiButtonAuras, LiteButtonAuras:

1. matches buffs/debuffs by name, so it doesn't require manually maintaining spells every expansion.
1. has less code and hopefully uses less CPU (probably not though).
1. doesn't support custom rules.
1. doesn't show buffs/debuffs on different abilities that have a different name.
1. limited support for customizing (only timer appearance).
1. doesn't show hints for using abilities, except for interrupt, purge and soothe.
1. doesn't show holy power/chi/combo points/soul shards.
1. doesn't handle macros that change the unit (always assumes target).

Config Options

```
/lba - print current settings
/lba help - print help
/lba colortimers on | off | default - turn on/off using colors for timers
/lba decimaltimers on | off | default - turn on/off showing 10ths of a second on low timers
/lba stacks on | off | default - turn on/off showing buff/debuff stacks
/lba font default - set font to default
/lba font FontName - set font by name (e.g., NumberFontNormal)
/lba font FontPath - set font by path (e.g., Fonts\ARIALN.TTF)
/lba font Size - set font size (default 14)
/lba font FontPath Size FontFlags - set font by path size and flags
```

Aura Options
```
/lba aura list - list current extra aura mappings
/lba aura show <auraSpellID> on <ability>
/lba aura hide <auraSpellID> on <ability>
```
If ability is in your spell book you can use it by name otherwise spell ID.

This is only for extra mappings, it does not affect the matching name display.
