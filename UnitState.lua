--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    State recording class.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

local L = LBA.L

LBA.state = {}


--[[------------------------------------------------------------------------]]--

-- Cache some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's just a pain to maintain.

local AuraUtil = LBA.AuraUtil or AuraUtil
local GetTotemInfo = GetTotemInfo
local MAX_TOTEMS = MAX_TOTEMS
local UnitCanAttack = UnitCanAttack
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local WOW_PROJECT_ID = WOW_PROJECT_ID


--[[------------------------------------------------------------------------]]--

-- State updating functions

-- This could be made (probably) more efficient by using the 10.0 event
-- argument auraUpdateInfo at the price of losing classic compatibility.
--
-- "Probably" because once you do that you have to do your own "filtering"
-- duplicating the 'HELPFUL PLAYER' etc. and iterate over a bunch of auras
-- that aren't relevant here. It depends on how efficient the filter in
-- UnitAuraSlots is (and by extension AuraUtil.ForEachAura). Would also have
-- to either index them by auraInstanceID + scan for name in overlay, or
-- keep indexing them by name and scan for auraInstanceID when updating.

-- There's no point guessing at what would be better performance, if you're
-- going to try to improve then measure it. Potentials for performance
-- improvement (but measure!):
--
--  * limit the aura scans by using a dirty/sweep
--  * use the UNIT_AURA push data (as above)
--
-- Overall the 10.0 changes are not that helpful for matching by name.
--
-- It's worth noting that the 10.0 BuffFrame still uses the same mechanism
-- as used here, but both the CompactUnitFrame and the TargetFrame have
-- switched to using the new ways.
--
--  {
--    applications = 0,
--    auraInstanceID = 154047,
--    canApplyAura = true,
--    duration = 3600,
--    expirationTime = 9109.109,
--    icon = 136051,
--    isBossAura = false,
--    isFromPlayerOrPlayerPet = true,
--    isHarmful = false,
--    isHelpful = true,
--    isNameplateOnly = false,
--    isRaid = false,
--    isStealable = false
--    name = "Lightning Shield",
--    nameplateShowAll = false,
--    nameplateShowPersonal = false,
--    points = { },
--    sourceUnit = "player",
--    spellId = 192106,
--    timeMod = 1,
--  }
--
-- https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataBySlot

-- Fake AuraData for weapon enchants, see BuffFrame.lua for how WoW does it
local function WeaponEnchantAuraData(duration, charges, id)
    local name = LBA.WeaponEnchantSpellID[id]
    if name then
        return {
            isTempEnchant = true,
            auraType = "TempEnchant",
            applications = charges,
            duration = 0,
            expirationTime = GetTime() + duration/1000,
            name = name,
        }
    end
end

--[[------------------------------------------------------------------------]]--

LBA.UnitState = {}

function LBA.UnitState:Create(unit)
    local unitState = {
        unit = unit,
        buffs = {},
        debuffs = {},
        weaponEnchants = {},
        totems = {},
        channel = nil,
        taunt = nil,
    }
    setmetatable(unitState, { __index=self })
    return unitState
end

-- There is only "player" (which includes pet) and "not player"

function LBA.UnitState:IsIgnoredAura(auraData)
    local ignoreData = LBA.db.profile.ignoreSpells[auraData.spellId]
    if ignoreData then
        if self.unit == 'player' or self.unit == 'pet' then
            return ignoreData.player == true
        else
            return ignoreData.unit == true
        end
    end
    return false
end

-- Also add a duplicate with any override name. This is awkward but there's no
-- inverse of C_Spell.GetOverrideSpell.
--
-- C_Spell.GetOverrideSpell returns the same ID if passed in an ID that's not
-- overridden (seems like no check is done if it's a valid spell or not).
--
-- It will return 0 if given a string that doesn't match to an ID (and not nil
-- like all the other C_Spell.GetX functions).
--
-- We call it with auraData.name because some of our faked up auraData (like
-- for weapon enchants) doesn't have a spellId in it.

function LBA.UnitState:UpdateTableAura(t, auraData)
    if self:IsIgnoredAura(auraData) then
        return
    end
    t[auraData.name] = auraData
    if C_Spell.GetOverrideSpell then
        local overrideID = C_Spell.GetOverrideSpell(auraData.name)
        local overrideName = C_Spell.GetSpellName(overrideID)
        if overrideName and overrideName ~= auraData.name then
            -- Doesn't update the spell name in the auraData only the index name
            t[overrideName] = auraData
        end
    end
end

function LBA.UnitState:UpdateAuras(auraInfo)

    -- XXX TODO handle auraInfo for efficiency

    self.buffs = {}
    self.debuffs = {}
    self.taunt = nil

    if UnitCanAttack('player', self.unit) then
        -- Hostile target buffs are only for dispels
        AuraUtil.ForEachAura(self.unit, 'HELPFUL', nil,
            function (auraData)
                self:UpdateTableAura(self.buffs, auraData)
            end,
            true)
        AuraUtil.ForEachAura(self.unit, 'HARMFUL PLAYER', nil,
            function (auraData)
                self:UpdateTableAura(self.debuffs, auraData)
            end,
            true)
        AuraUtil.ForEachAura(self.unit, 'HARMFUL', nil,
            function (auraData)
                if LBA.Taunts[auraData.spellId] and auraData.expirationTime then
                    if not self.taunt or auraData.expirationTime > self.taunt.expirationTime  then
                        self.taunt = auraData
                    end
                end
            end,
            true)
    else
        AuraUtil.ForEachAura(self.unit, 'HELPFUL PLAYER', nil,
            function (auraData)
                self:UpdateTableAura(self.buffs, auraData)
            end,
            true)
        -- Inclue long-lasting buffs we can cast even if applied
        -- by someone else, since we don't care who cast Battle Shout, etc.
        AuraUtil.ForEachAura(self.unit, 'HELPFUL RAID', nil,
            function (auraData)
                if auraData.duration >= 10*60 then
                    self:UpdateTableAura(self.buffs, auraData)
                end
            end,
            true)
    end
end

function LBA.UnitState:UpdateWeaponEnchants()
    -- Classic doesn't have the events to do this efficiently
    if WOW_PROJECT_ID ~= 1 then return end

    if self.unit == 'player' then
        self.weaponEnchants = {}

        local mhEnchant, mhDuration, mhCharges, mhID,
              ohEnchant, ohDuration, ohCharges, ohID = GetWeaponEnchantInfo()

        if mhEnchant then
            local auraData = WeaponEnchantAuraData(mhDuration, mhCharges, mhID)
            if auraData then
                self:UpdateTableAura(self.weaponEnchants, auraData)
            end
        end
        if ohEnchant then
            local auraData = WeaponEnchantAuraData(ohDuration, ohCharges, ohID)
            if auraData then
                self:UpdateTableAura(self.weaponEnchants, auraData)
            end
        end
    end
end

function LBA.UnitState:UpdateChannel()
    self.channel = UnitChannelInfo(self.unit)
end

function LBA.UnitState:UpdateTotems()
    if self.unit == 'player' then
        self.totems = {}
        for i = 1, MAX_TOTEMS do
            local exists, name, startTime, duration, model = GetTotemInfo(i)
            if exists and name then
                if model then
                    name = LBA.TotemOrGuardianModels[model] or name
                end
                self.totems[name] = startTime + duration
            end
        end
    end
end

function LBA.UnitState:UpdateInterrupt()
    local name, endTime, cantInterrupt, _

    if UnitCanAttack('player', self.unit) then
        name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo(self.unit)
        if name and not cantInterrupt then
            self.interrupt = endTime / 1000
            return
        end

        name, _, _, _, endTime, _, cantInterrupt = UnitChannelInfo(self.unit)
        if name and not cantInterrupt then
            self.interrupt = endTime / 1000
            return
        end
    end

    self.interrupt = nil
end

-- Overlay is reading the states directly but we could add some accessors
-- here and/or move some of the matching logic here as well.

