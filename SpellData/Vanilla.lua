--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Interrupts = {
    [  2139] = true,                -- Counterspell (Mage)
    [  1766] = true,                -- Kick (Rogue)
    [  6552] = true,                -- Pummel (Warrior)
    [425609] = true,                -- Rebuke (Paladin)
    [ 15487] = true,                -- Silence (Priest)
    [410176] = true,                -- Skull Bash (Druid)
    [ 19647] = true,                -- Spell Lock (Warlock Felhunter Pet)
}

LBA.Soothes = {
}

LBA.HostileDispels = {
    [ 19505] = { Magic = true },    -- Devour Magic (Warlock)
    [   527] = { Magic = true },    -- Dispel Magic (Priest)
    [   370] = { Magic = true },    -- Purge (Shaman)
}

LBA.Taunts = {
    [  1161] = true,                -- Challenging Shout (Warrior)
    [  6795] = true,                -- Growl (Druid)
    [  2649] = true,                -- Growl (Hunter Pet)
    [407631] = true,                -- Hand of Reckoning (Paladin)
    [ 17735] = true,                -- Suffering (Warlock Voidwalker Pet)
    [   355] = true,                -- Taunt (Warrior)
}

LBA.TotemOrGuardianModels = {
}

LBA.WeaponEnchantSpellID = {
}
