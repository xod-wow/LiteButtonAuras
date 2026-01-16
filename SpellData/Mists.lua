--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Interrupts = {
    [ 47528] = true,                -- Mind Freeze (Death Knight)
    [ 78675] = true,                -- Solar Beam (Druid)
    [106839] = true,                -- Skull Bash (Druid)
    [147362] = true,                -- Counter Shot (Hunter)
    [ 34490] = true,                -- Silencing Shot (Hunter)
    [  2139] = true,                -- Counterspell (Mage)
    [116705] = true,                -- Spear Hand Strike (Monk)
    [ 96231] = true,                -- Rebuke (Paladin)
    [ 15487] = true,                -- Silence (Priest)
    [  1766] = true,                -- Kick (Rogue)
    [ 57994] = true,                -- Wind Shear (Shaman)
    [ 19647] = true,                -- Spell Lock (Warlock Felhunter Pet)
    [  6552] = true,                -- Pummel (Warrior)
    [ 25046] = true,                -- Arcane Torrent (Blood Elf Rogue)
}

LBA.Soothes = {
    [  2908] = true,                -- Soothe (Druid)
    [ 19801] = true,                -- Tranquilizing Shot (Hunter)
    [  5938] = true,                -- Shiv (Rogue)
}

LBA.HostileDispels = {
    [ 19801] = { Magic = true },    -- Tranquilizing Shot (Hunter)
    [ 30449] = { Magic = true },    -- Spellsteal (Mage)
    [   528] = { Magic = true },    -- Dispel Magic (Priest)
    [ 32375] = { Magic = true },    -- Mass Dispel (Priest)
    [   370] = { Magic = true },    -- Purge (Shaman)
    [ 19505] = { Magic = true },    -- Devour Magic (Warlock)
}

LBA.Taunts = {
    [   355] = true,                -- Taunt (Warrior)
    [ 49576] = true,                -- Death Grip (Death Knight)
    [ 56222] = true,                -- Dark Command (Death Knight)
    [115546] = true,                -- Provoke (Monk)
    [ 62124] = true,                -- Hand of Reckoning (Paladin)
    [  6795] = true,                -- Growl (Druid)
    [ 17735] = true,                -- Suffering (Warlock Voidwalker Pet)
    [  2649] = true,                -- Growl (Hunter Pet)
}

LBA.TotemOrGuardianModels = {
    [136119] = C_Spell.GetSpellName(46584),    -- Raise Dead (DK)
}

LBA.WeaponEnchantSpellID = {
}
