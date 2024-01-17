--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is a register of spells that match a few criteria for special
    display: interrupts, soothes, dispels. Also a list of model IDs to
    match totem/guardians to spells (5th return value of GetTotemInfo)
    since the names differ a lot.

----------------------------------------------------------------------------]]--

local _, LBA = ...

-- Just to make luacheck shut up a bit
local GetSpellInfo = GetSpellInfo

-- Now these are matched by name don't worry about finding all the spell IDs
-- for all the versions. On classic_era this is ranks, but even on live
-- there are multiple Singe Magic (for example).

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
    [ 57994] = true,    -- Wind Shear (Shaman)
    [ 19647] = true,    -- Spell Lock (Warlock Felhunter Pet)
    [  6552] = true,    -- Pummel (Warrior)
    [351338] = true,    -- Quell (Evoker)
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
--  [ 28730] = { Magic = true },    -- Arcane Torrent (Blood Elf Mage/Warlock)
--  [ 50613] = { Magic = true },    -- Arcane Torrent (Blood Elf Death Knight)
--  [ 69179] = { Magic = true },    -- Arcane Torrent (Blood Elf Warrior)
--  [ 80483] = { Magic = true },    -- Arcane Torrent (Blood Elf Hunter)
--  [129597] = { Magic = true },    -- Arcane Torrent (Blood Elf Monk)
--  [155145] = { Magic = true },    -- Arcane Torrent (Blood Elf Paladin)
--  [202719] = { Magic = true },    -- Arcane Torrent (Blood Elf Demon Hunter)
--  [232633] = { Magic = true },    -- Arcane Torrent (Blood Elf Priest)
}

LBA.PlayerPetBuffs = {
    [   136] = true,                -- Mend Pet
}

LBA.Taunts = {
    [   355] = true,                -- Taunt (Warrior)
    [ 51399] = true,                -- Death Grip (Death Knight)
    [ 56222] = true,                -- Dark Command (Death Knight)
    [116189] = true,                -- Provoke (Monk)
    [ 62124] = true,                -- Hand of Reckoning (Paladin)
    [185245] = true,                -- Torment (Demon Hunter)
    [  6795] = true,                -- Growl (Druid)
    [ 17735] = true,                -- Suffering (Warlock Voidwalker Pet)
    [  2649] = true,                -- Growl (Hunter Pet)
}

-- Where the totem name does not match the spell name. There's few enough
-- of these that I think it's possible to maintain it.
--
-- [model] = Summoning Spell Name
--
--  for i = 1, MAX_TOTEMS do
--      local exists, name, startTime, duration, model = GetTotemInfo(i)

LBA.TotemOrGuardianModels = {
    [ 627607] = GetSpellInfo(115315),   -- Black Ox Statue (Monk)
    [ 620831] = GetSpellInfo(115313),   -- Jade Serpent Statue (Monk)
    [4667418] = GetSpellInfo(388686),   -- White Tiger Statue (Monk)
    [ 620832] = GetSpellInfo(123904),   -- Xuen,the White Tiger (Monk)
    [ 574571] = GetSpellInfo(322118),   -- Yu'lon, The Jade Serpent (Monk)
--  [ 608951] = GetSpellInfo(132578),   -- Niuzao, the Black Ox (Monk)
    [ 877514] = GetSpellInfo(325197),   -- Chi-ji, The Red Crane (Monk)
    [ 136024] = GetSpellInfo(198103),   -- Earth Elemental (Shaman)
    [ 135790] = GetSpellInfo(198067),   -- Fire Elemental (Shaman)
    [1020304] = GetSpellInfo(192249),   -- Storm Elemental (Shaman)
    [ 237577] = GetSpellInfo(51533),    -- Feral Spirit (Shaman)
}

LBA.WeaponEnchantSpellID = {
    [   5400] = GetSpellInfo(318038),   -- Flametongue Weapon
    [   5401] = GetSpellInfo(33757),    -- Windfury Weapon
}

-- The main reason for this is that Classic Era still has spell ranks,
-- each rank has a different spell ID, and the tables above only have the
-- first rank since that's what retail/wotlk use. It is generally more in
-- keeping with our "match by name" anyway.

-- Note: due to https://github.com/Stanzilla/WoWUIBugs/issues/373 it's not
-- safe to use ContinueOnSpellLoad as it taints the spellbook if we're the
-- first to query the spell. Fingers crossed that GetSpellInfo always
-- return true for spellbook spells, even at load time. Otherwise I'll have
-- to build my own SpellEventListener.

do
    local function AddSpellNames(t)
        local spellIDs = GetKeysArray(t)
        for _, spellID in ipairs(spellIDs) do
            local name = GetSpellInfo(spellID)
            if name then
                t[name] = t[spellID]
--@debug@
            else
                print('Missing ' .. tostring(spellID))
--@end-debug@
            end
        end
    end

    AddSpellNames(LBA.Interrupts)
    AddSpellNames(LBA.Soothes)
    AddSpellNames(LBA.HostileDispels)
    AddSpellNames(LBA.PlayerPetBuffs)
    AddSpellNames(LBA.Taunts)
end

--@debug@
_G.LBA = LBA
--@end-debug@
