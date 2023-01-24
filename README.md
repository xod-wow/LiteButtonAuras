# LiteButtonAuras WoW AddOn

LiteButtonAuras shows your buffs on you and your debuffs on your target inside your action buttons with a
colored border and timer. It is like AdiButtonAuras, and Inline Aura before it, just much dumber and much
easier to maintain.

A buff you cast on yourself shows a green highlight in ability button:

![](https://i.imgur.com/vsf97X0.png)

A debuff you cast on your target shows red highlight in ability button:

![](https://i.imgur.com/HmN2WR5.png)

For all of your action buttons:

- Suggest button (border glow/ants) with timer if:
    - your target is casting a spell you can interrupt and the button action is an interrupt, or
    - your target is enraged and the button action is a soothe
- Show a green highlight and timer if:
    - the action name matches a buff on you that you cast, or
    - the action is a totem or guardian and it is summoned
- Show a red highlight and timer if:
    - the action name matches a debuff that you cast on your target
- Show a debuff-colored border (curse/disease/magic/poison) if:
    * your target is an enemy, and
    - you can purge the buff, and
    - the button action is a purge/spellsteal

LiteButtonAuras works with the default Blizzard action bars, Dominos, Bartender and anything that
uses LibActionButton (including ElvUI).

Supports WoW retail, classic (Vanilla) and classic (WotLK).

## WoW Classic (Vanilla) Timers

For WoW Classic (Vanilla) to get debuff timers you will need to also install LibClassicDurations or
have WeakAuras installed which bundles it.

## Comparison with AdiButtonAuras

Compared to AdiButtonAuras (which this addon is modeled on), LiteButtonAuras:

1. matches buffs/debuffs by name, so it doesn't require manually maintaining spells every expansion.
1. has less code and hopefully uses less CPU (probably not though).
1. has limited support for custom rules (only "show aura on ability").
1. doesn't show buffs/debuffs on abilities that have a different name unless manualy configured.
1. limited support for customizing (timer appearance, show stacks or not).
1. doesn't show hints for using abilities, except for interrupt, purge and soothe.
1. doesn't show holy power/chi/combo points/soul shards.
1. doesn't handle macros that change the unit (always assumes target).

As of Dragonflight it appears that AdiButtonAuras is no longer being maintained, but I hope
it returns for all the people who want the extra features it provides.

## Appearance Options

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

## Show Highlights for Other Auras

By default LiteButtonAuras only shows highlights when the name of the buff/debuff and the name of
the action match. (Plus a special case for totems and guardians like monk statues.)

Using the `/lba aura` command you can add extra auras that will highlight your abilities (for
example, to show a debuff on the ability that triggers it).

```
/lba aura list - list current extra aura mappings
/lba aura show <auraSpellID> on <ability>
/lba aura hide <auraSpellID> on <ability>
```

If an ability is in your spell book you can use it by name otherwise by spell ID.

You can only add auras using this, or remove ones you previously added. You can't use "hide" to
change the default behaviour of showing buffs/debuffs that match the ability name.

The `hide` option is only to remove extra mappings you have added, it does not affect the default
display when the names match.

## Never Highlight An Ability

You can stop an ability from ever getting highlighted due to the default name matching.

```
/lba deny list - list abilities never to highlight
/lba deny add <ability>
/lba deny remove <ability>
```

If ability is in your spell book you can use it by name otherwise spell ID.

## How to find spell IDs

Every ability and every buff/debuff has an associated Spell ID, which you need to know to
configure custom highlights (above).

LiteButtonAuras doesn't include any helpers for finding spell IDs, you'll need to do it
yourself. Here are three ways to do this:

1. Look up wowhead.com. The spell ID is the number after spell= in the URL.
1. Get an addon that adds Spell IDs to the tooltip.
1. If you have the _Details!_ addon, it keeps a list of spells you can view with `/details spells`

## Features I can't or won't support, and why

1. __Weapon Enchants__. There's no way to get the name from the enchant ID that I can see.
1. __Macro @units__. There's no simple way to figure out what unit an action will target.
   It can be done with a lot of complex processing, maybe. If Blizzard ever added a
   GetActionUnit() I would do it in a heartbeat so I can have focus interrupt suggesting.
1. __Non-Auras__. E.g. channeling time, combo/chi/holy power/etc points. A lot of these
   could be done, but LBA's focus is on auras only and I personally feel those are better
   done in other ways or by other addons.

In general a lot of not supporting things involves keeping LiteButtonAuras small and
simple enough that when a major WoW release comes out I can update it without causing
myself so much stress I give up.

##  If This AddOn Seems Abandoned

If more than two weeks go by after a major patch and this addon isn't updated, I've probably been
hit by a bus. In that case I encourage anyone with the necessary ability to take over maintenance of
the addon. It is released under the terms of the GNU General Public License, which means anyone can
take it and do whatever they want with it, as long as they don't claim they wrote it and they too
release their code under the same terms.
