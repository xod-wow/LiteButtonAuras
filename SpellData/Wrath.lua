--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Interrupts = {
    [ 47528] = true,                -- Mind Freeze (Death Knight)
    [ 34490] = true,                -- Silencing Shot (Hunter)
    [  2139] = true,                -- Counterspell (Mage)
    [ 15487] = true,                -- Silence (Priest)
    [  1766] = true,                -- Kick (Rogue)
    [ 57994] = true,                -- Wind Shear (Shaman)
    [ 19647] = true,                -- Spell Lock (Warlock Felhunter Pet)
    [  6552] = true,                -- Pummel (Warrior)
    [ 25046] = true,                -- Arcane Torrent (Blood Elf Rogue)
}

LBA.Soothes = {
}

LBA.HostileDispels = {
    [ 19801] = { Magic = true },    -- Tranquilizing Shot (Hunter)
    [ 30449] = { Magic = true },    -- Spellsteal (Mage)
    [   527] = { Magic = true },    -- Dispel Magic (Priest)
    [ 32375] = { Magic = true },    -- Mass Dispel (Priest)
    [   370] = { Magic = true },    -- Purge (Shaman)
    [ 19505] = { Magic = true },    -- Devour Magic (Warlock)
}

LBA.Taunts = {
    [   355] = true,                -- Taunt (Warrior)
    [ 49576] = true,                -- Death Grip (Death Knight)
    [ 56222] = true,                -- Dark Command (Death Knight)
    [ 62124] = true,                -- Hand of Reckoning (Paladin)
    [ 31789] = true,                -- Righteous Defense (Paladin)
    [  6795] = true,                -- Growl (Druid)
    [ 17735] = true,                -- Suffering (Warlock Voidwalker Pet)
    [  2649] = true,                -- Growl (Hunter Pet)
    [  1161] = true,                -- Challenging Shout (Warrior)
}

LBA.TotemOrGuardianModels = {
}

LBA.WeaponEnchantSpellID = {
}
