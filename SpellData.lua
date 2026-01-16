--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is a register of spells that match a few criteria for special
    display: interrupts, soothes, dispels. Also a list of model IDs to
    match totem/guardians to spells (5th return value of GetTotemInfo)
    since the names differ a lot.

----------------------------------------------------------------------------]]--

local _, LBA = ...

-- Expects these tables to have been pre-populated by the expansion-specific
-- SpellData\[Game].lua files.
--
-- LBA.Interrupts = { [spellID] = true, ... }
-- LBA.Soothes = { [spellID] = true, ... }
-- LBA.HostileDispels = { [spellID] = { DispelType = true, ... } }
-- LBA.Taunts = { [spellID] = true }
-- LBA.TotemOrGuardianModels = { [totemModelID] = name, ... }
-- LBA.WeaponEnchantSpellID = { [enchantID] = name, ... }
--
-- The names should be locale-independent by getting them from
-- C_Spell.GetSpellName(spellID)

-- Now these are matched by name don't worry about finding all the spell IDs
-- for all the versions. On classic_era this is ranks, but even on live
-- there are multiple Singe Magic (for example).

-- The main reason for this is that Classic Era still has spell ranks,
-- each rank has a different spell ID, and the tables above only have the
-- first rank since that's what retail/wotlk use. It is generally more in
-- keeping with our "match by name" anyway.

-- Note: due to https://github.com/Stanzilla/WoWUIBugs/issues/373 it's not
-- safe to use ContinueOnSpellLoad as it taints the spellbook if we're the
-- first to query the spell. Fingers crossed that C_Spell.GetSpellName always
-- return true for spellbook spells, even at load time. Otherwise I'll have
-- to build my own SpellEventListener.

do
    local function AddSpellNames(t)
        local spellIDs = GetKeysArray(t)
        for _, spellID in ipairs(spellIDs) do
            local name = C_Spell.GetSpellName(spellID)
            if name then
                t[name] = t[spellID]
            end
        end
    end

    AddSpellNames(LBA.Interrupts)
    AddSpellNames(LBA.Soothes)
    AddSpellNames(LBA.HostileDispels)
    AddSpellNames(LBA.Taunts)
end

--@debug@
_G.LBA = LBA
--@end-debug@
