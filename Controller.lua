--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is the event handler and state updater. Watches for the buffs and
    updates LBA.state, then calls overlay:Update() on all actionbutton overlays
    when required.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

local L = LBA.L

LBA.state = {
    player = {
        buffs = {},
        debuffs = {},
        totems = {},
        weaponEnchants = {},
        channel = nil,
    },
    pet = {
        buffs = {},
        debuffs = {},
    },
    target = {
        buffs = {},
        debuffs = {},
        interrupt = nil,
    },
}


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

-- Load and set up dependencies for Masque support. Because we make our own
-- frame and don't touch the ActionButton itself (avoids a LOT of taint issues)
-- we have to make our own masque group. It's a bit weird because it lets  you
-- style LBA differently from the ActionButton, but it's the simplest way.

local Masque = LibStub('Masque', true)
local MasqueGroup = Masque and Masque:Group(addonName)


--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.overlayFrames = {}
    self:RegisterEvent('PLAYER_LOGIN')
end

function LiteButtonAurasControllerMixin:Initialize()
    LBA.InitializeOptions()
    LBA.InitializeGUIOptions()
    LBA.SetupSlashCommand()
    LBA.UpdateAuraMap()

    -- Now this is be delayed until PLAYER_LOGIN do we still need to list
    -- list all possible LibActionButton derivatives in the TOC dependencies?
    LBA.BarIntegrations:Initialize()

    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('PLAYER_TOTEM_UPDATE')
    if WOW_PROJECT_ID == 1 then
        self:RegisterEvent('WEAPON_ENCHANT_CHANGED')
        self:RegisterEvent('WEAPON_SLOT_CHANGED')
    end

    -- All of these are for the interrupt and player channel detection
    self:RegisterEvent('UNIT_SPELLCAST_START')
    self:RegisterEvent('UNIT_SPELLCAST_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_FAILED')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE')

    LBA.db.RegisterCallback(self, 'OnModified', 'StyleAllOverlays')
end

function LiteButtonAurasControllerMixin:CreateOverlay(actionButton)
    if not self.overlayFrames[actionButton] then
        local name = actionButton:GetName() .. "LiteButtonAurasOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "LiteButtonAurasOverlayTemplate")
        self.overlayFrames[actionButton] = overlay
        if MasqueGroup then
            MasqueGroup:AddButton(overlay, {
                SpellHighlight = overlay.Glow,
                Normal = false,
                -- Duration = overlay.Timer,
                -- Count = overlay.Count,
            })
        end
    end
    return self.overlayFrames[actionButton]
end

function LiteButtonAurasControllerMixin:GetOverlay(actionButton)
    return self.overlayFrames[actionButton]
end

function LiteButtonAurasControllerMixin:UpdateAllOverlays(stateOnly)
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Update(stateOnly)
    end
end

function LiteButtonAurasControllerMixin:StyleAllOverlays()
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Style()
        overlay:Update()
    end
end

function LiteButtonAurasControllerMixin:DumpAllOverlays()
    self:UpdateAllOverlays()
    local sortedOverlays = GetValuesArray(self.overlayFrames)
    table.sort(sortedOverlays, function (a, b) return a:GetActionID() < b:GetActionID() end)
    for _, overlay in pairs(sortedOverlays) do
        overlay:Dump()
    end
end

--[[------------------------------------------------------------------------]]--

-- State updating local functions

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

local function UpdateTableAura(t, auraData)
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

local function UpdateWeaponEnchants()
    -- Classic doesn't have the events to do this efficiently
    if WOW_PROJECT_ID ~= 1 then return end

    LBA.state.player.weaponEnchants = {}

    local mhEnchant, mhDuration, mhCharges, mhID,
          ohEnchant, ohDuration, ohCharges, ohID = GetWeaponEnchantInfo()

    if mhEnchant then
        local auraData = WeaponEnchantAuraData(mhDuration, mhCharges, mhID)
        if auraData then
            UpdateTableAura(LBA.state.player.weaponEnchants, auraData)
        end
    end
    if ohEnchant then
        local auraData = WeaponEnchantAuraData(ohDuration, ohCharges, ohID)
        if auraData then
            UpdateTableAura(LBA.state.player.weaponEnchants, auraData)
        end
    end
end

local function UpdateUnitAuras(unit, auraInfo)

    -- XXX TODO handle auraInfo for efficiency

    LBA.state[unit].buffs = {}
    LBA.state[unit].debuffs = {}

    if UnitCanAttack('player', unit) then
        -- Hostile target buffs are only for dispels
        AuraUtil.ForEachAura(unit, 'HELPFUL', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].buffs, auraData)
            end,
            true)
        AuraUtil.ForEachAura(unit, 'HARMFUL PLAYER', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].debuffs, auraData)
            end,
            true)
    else
        AuraUtil.ForEachAura(unit, 'HELPFUL PLAYER', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].buffs, auraData)
            end,
            true)
        -- Inclue long-lasting buffs we can cast even if applied
        -- by someone else, since we don't care who cast Battle Shout, etc.
        AuraUtil.ForEachAura(unit, 'HELPFUL RAID', nil,
            function (auraData)
                if auraData.duration >= 10*60 then
                    UpdateTableAura(LBA.state[unit].buffs, auraData)
                end
            end,
            true)
    end
end

local function UpdatePlayerChannel()
    LBA.state.player.channel = UnitChannelInfo('player')
end

local function UpdatePlayerTotems()
    LBA.state.player.totems = {}
    for i = 1, MAX_TOTEMS do
        local exists, name, startTime, duration, model = GetTotemInfo(i)
        if exists and name then
            if model then
                name = LBA.TotemOrGuardianModels[model] or name
            end
            LBA.state.player.totems[name] = startTime + duration
        end
    end
end

local function UpdateUnitInterupt(unit)
    local name, endTime, cantInterrupt, _

    if UnitCanAttack('player', unit) then
        name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo(unit)
        if name and not cantInterrupt then
            LBA.state[unit].interrupt = endTime / 1000
            return
        end

        name, _, _, _, endTime, _, cantInterrupt = UnitChannelInfo(unit)
        if name and not cantInterrupt then
            LBA.state[unit].interrupt = endTime / 1000
            return
        end
    end

    LBA.state[unit].interrupt = nil
end


--[[------------------------------------------------------------------------]]--

function LiteButtonAurasControllerMixin:MarkOverlaysDirty(stateOnly)
    -- Tri-state encodes stateOnly : nil / true / false
    self.isOverlayDirty = ( stateOnly == true and self.isOverlayDirty ~= false )
end

-- Limit UNIT_AURA and UNIT_SPELLCAST overlay updates to one per frame
function LiteButtonAurasControllerMixin:OnUpdate()
    if self.isOverlayDirty ~= nil then
        self:UpdateAllOverlays(self.isOverlayDirty)
        self.isOverlayDirty = nil
    end
end

function LiteButtonAurasControllerMixin:IsTrackedUnit(unit)
    if unit == 'player' or unit == 'pet' or unit == 'target' then
        return true
    else
        return false
    end
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
        self:UnregisterEvent('PLAYER_LOGIN')
        self:MarkOverlaysDirty()
        return
    elseif event == 'PLAYER_ENTERING_WORLD' then
        UpdateUnitAuras('target')
        UpdateUnitInterupt('target')
        UpdateWeaponEnchants()
        UpdateUnitAuras('player')
        UpdateUnitAuras('pet')
        UpdatePlayerChannel()
        UpdatePlayerTotems()
        self:MarkOverlaysDirty()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        UpdateUnitAuras('target')
        UpdateUnitInterupt('target')
        self:MarkOverlaysDirty(true)
    elseif event == 'UNIT_AURA' then
        -- This fires a lot. Be careful. In DF, UNIT_AURA seems to tick every
        -- second for 'player' with no updates
        local unit, unitAuraUpdateInfo = ...
        if self:IsTrackedUnit(unit) then
            UpdateUnitAuras(unit, unitAuraUpdateInfo)
            -- Shouldn't be needed but weapon enchant duration is returned
            -- wrongly as 0 at PLAYER_LOGIN. This is how Blizzard works around
            -- it too. Their server code must be a nightmare.
            if unit == 'player' then UpdateWeaponEnchants() end
            self:MarkOverlaysDirty(true)
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        UpdatePlayerTotems()
        self:MarkOverlaysDirty(true)
    elseif event == 'WEAPON_ENCHANT_CHANGED' or event == 'WEAPON_SLOT_CHANGED' then
        UpdateWeaponEnchants()
        self:MarkOverlaysDirty(true)
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        -- This fires a lot too, same applies as UNIT_AURA.
        local unit = ...
        if unit == 'player' then
            UpdatePlayerChannel()
            self:MarkOverlaysDirty(true)
        elseif self:IsTrackedUnit(unit) then
            UpdateUnitInterupt(unit)
            self:MarkOverlaysDirty(true)
        end
    end
end
