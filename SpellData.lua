--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Interrupts = {
    [ 47528] = true,    -- Mind Freeze (Death Knight)
    [183752] = true,    -- Disrupt (Demon Hunter)
--  [202137] = true,    -- Sigil of Silence (Demon Hunter)
    [ 78675] = true,    -- Solar Beam (Druid)
    [106839] = true,    -- Skull Bash (Druid)
    [147362] = true,    -- Counter Shot (Hunter)
    [187707] = true,    -- Muzzle (Hunter)
    [  2139] = true,    -- Counterspell (Mage)
    [116705] = true,    -- Spear Hand Strike (Monk)
    [ 96231] = true,    -- Rebuke (Paladin)
    [ 31935] = true,    -- Avenger's Shield (Paladin)
    [ 15487] = true,    -- Silence (Priest)
    [  1766] = true,    -- Kick (Rogue)
    [ 57994] = true,    -- Wind Shear (Paladin)
    [ 89808] = true,    -- Singe Magic (Warlock)
    [119905] = true,    -- Command Demon: Singe Magic (Warlock)
    [132411] = true,    -- Command Demon: Singe Magic (Warlock)
    [212623] = true,    -- Command Demon: Singe Magic (Warlock PvP Talent)
    [  6552] = true,    -- Pummel (Warrior)
}

LBA.Soothes = {
    [  2908] = true,                -- Soothe (Druid)
    [ 19801] = true,                -- Tranquilizing Shot (Hunter)
    [  5938] = true,                -- Shiv (Rogue)
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
    [ 28730] = { Magic = true },    -- Arcane Torrent (Blood Elf Mage/Warlock)
    [ 50613] = { Magic = true },    -- Arcane Torrent (Blood Elf Death Knight)
    [ 69179] = { Magic = true },    -- Arcane Torrent (Blood Elf Warrior)
    [ 80483] = { Magic = true },    -- Arcane Torrent (Blood Elf Hunter)
    [129597] = { Magic = true },    -- Arcane Torrent (Blood Elf Monk)
    [155145] = { Magic = true },    -- Arcane Torrent (Blood Elf Paladin)
    [202719] = { Magic = true },    -- Arcane Torrent (Blood Elf Demon Hunter)
    [232633] = { Magic = true },    -- Arcane Torrent (Blood Elf Priest)
}

-- Where the totem name does not match the spell name. There's few enough
-- of these that I think it's possible to maintain it.
-- [Texture ID] = Summoning Spell Name

LBA.TotemOrGuardianModels = {
    [ 627607] = GetSpellInfo(115315),   -- Black Ox Statue (Monk)
    [ 620831] = GetSpellInfo(115313),   -- Jade Serpent Statue (Monk)
    [ 620832] = GetSpellInfo(123904),   -- Xuen,the White Tiger (Monk)
    [ 574571] = GetSpellInfo(322118),   -- Yu'lon, The Jade Serpent (Monk)
--  [ 608951] = GetSpellInfo(132578),   -- Niuzao, the Black Ox (Monk)
    [ 877514] = GetSpellInfo(325197),   -- Chi-ji, The Red Crane (Monk)
    [ 136024] = GetSpellInfo(198103),   -- Earth Elemental (Shaman)
    [ 135790] = GetSpellInfo(198067),   -- Fire Elemental (Shaman)
    [1020304] = GetSpellInfo(192249),   -- Storm Elemental (Shaman)
    [ 237577] = GetSpellInfo(51533),    -- Feral Spirit (Shaman)
}

--@debug
_G.LBA = LBA
--@end-debug
