--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Interrupts = {
    [ 47528] = true,                -- Mind Freeze (Death Knight)
    [183752] = true,                -- Disrupt (Demon Hunter)
    [ 78675] = true,                -- Solar Beam (Druid)
    [106839] = true,                -- Skull Bash (Druid)
    [147362] = true,                -- Counter Shot (Hunter)
    [187707] = true,                -- Muzzle (Hunter)
    [  2139] = true,                -- Counterspell (Mage)
    [116705] = true,                -- Spear Hand Strike (Monk)
    [ 96231] = true,                -- Rebuke (Paladin)
    [ 15487] = true,                -- Silence (Priest)
    [  1766] = true,                -- Kick (Rogue)
    [ 57994] = true,                -- Wind Shear (Shaman)
    [ 19647] = true,                -- Spell Lock (Warlock Felhunter Pet)
    [ 89766] = true,                -- Axe Toss (Warlock Felguard Pet)
    [  6552] = true,                -- Pummel (Warrior)
    [351338] = true,                -- Quell (Evoker)
}

LBA.Soothes = {
    [  2908] = true,                -- Soothe (Druid)
    [ 19801] = true,                -- Tranquilizing Shot (Hunter)
    [  5938] = true,                -- Shiv (Rogue)
    [115078] = function ()          -- Paralysis (Monk) with Pressure Points
        return IsPlayerSpell(450432)
    end,
}

LBA.HostileDispels = {
    [278326] = { Magic = true },    -- Consume Magic (Demon Hunter)
    [ 19801] = { Magic = true },    -- Tranquilizing Shot (Hunter)
    [ 30449] = { Magic = true },    -- Spellsteal (Mage)
    [   528] = { Magic = true },    -- Dispel Magic (Priest)
    [ 32375] = { Magic = true },    -- Mass Dispel (Priest)
    [   370] = { Magic = true },    -- Purge (Shaman)
    [ 19505] = { Magic = true },    -- Devour Magic (Warlock)
    [ 25046] = { Magic = true },    -- Arcane Torrent (Blood Elf Rogue)
}

LBA.Taunts = {
    [   355] = true,                -- Taunt (Warrior)
    [ 49576] = true,                -- Death Grip (Death Knight)
    [ 56222] = true,                -- Dark Command (Death Knight)
    [115546] = true,                -- Provoke (Monk)
    [ 62124] = true,                -- Hand of Reckoning (Paladin)
    [185245] = true,                -- Torment (Demon Hunter)
    [  6795] = true,                -- Growl (Druid)
    [ 17735] = true,                -- Suffering (Warlock Voidwalker Pet)
    [  2649] = true,                -- Growl (Hunter Pet)
    [  1161] = true,                -- Challenging Shout (Warrior)
    [386071] = true,                -- Disrupting Shout (Warrior)
}

-- Where the totem name does not match the spell name. There's few enough
-- of these that I think it's possible to maintain it.
--
-- [model] = Summoning Spell Name
--
--  for i = 1, MAX_TOTEMS do
--      local exists, name, startTime, duration, model = GetTotemInfo(i)

LBA.TotemOrGuardianModels = {
    [ 136119] = C_Spell.GetSpellName(46584),    -- Raise Dead (DK)
    [ 627607] = C_Spell.GetSpellName(115315),   -- Black Ox Statue (Monk)
    [ 620831] = C_Spell.GetSpellName(115313),   -- Jade Serpent Statue (Monk)
    [4667418] = C_Spell.GetSpellName(388686),   -- White Tiger Statue (Monk)
    [ 620832] = C_Spell.GetSpellName(123904),   -- Xuen,the White Tiger (Monk)
    [ 574571] = C_Spell.GetSpellName(322118),   -- Yu'lon, The Jade Serpent (Monk)
--  [ 608951] = C_Spell.GetSpellName(132578),   -- Niuzao, the Black Ox (Monk)
    [ 877514] = C_Spell.GetSpellName(325197),   -- Chi-ji, The Red Crane (Monk)
    [ 136024] = C_Spell.GetSpellName(198103),   -- Earth Elemental (Shaman)
    [ 135790] = C_Spell.GetSpellName(198067),   -- Fire Elemental (Shaman)
    [1020304] = C_Spell.GetSpellName(192249),   -- Storm Elemental (Shaman)
    [ 237577] = C_Spell.GetSpellName(51533),    -- Feral Spirit (Shaman)
    [ 237562] = C_Spell.GetSpellName(111898),   -- Grimoire: Felguard (Warlock)
    [1378282] = C_Spell.GetSpellName(104316),   -- Call Dreadstalkers (Warlock)
    [1616211] = C_Spell.GetSpellName(264119),   -- Summon Vilefiend (Warlock)
    [1709931] = C_Spell.GetSpellName(455476),   -- Summon Charhound (Warlock)
    [1709932] = C_Spell.GetSpellName(455465),   -- Summon Gloomhound (Warlock)
    [ 132129] = C_Spell.GetSpellName(102693),   -- Grove Guardians (Druid)
}

LBA.WeaponEnchantSpellID = {
    [   5400] = C_Spell.GetSpellName(318038),   -- Flametongue Weapon
    [   5401] = C_Spell.GetSpellName(33757),    -- Windfury Weapon
    [   6498] = C_Spell.GetSpellName(382021),   -- Earthliving Weapon
    [   7528] = C_Spell.GetSpellName(457481),   -- Tidecaller's Guard
    [   7587] = C_Spell.GetSpellName(462757),   -- Thunderstrike Ward
}
