--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is the event handler and state updater. Watches for the buffs and
    updates LBA.state, then calls overlay:Update() on all actionbutton overlays
    when required.

----------------------------------------------------------------------------]]--

local _, LBA = ...

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

-- Cache a some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's just a pain to maintain.

local GetSpellInfo = GetSpellInfo
local GetTotemInfo = GetTotemInfo
local MAX_TOTEMS = MAX_TOTEMS
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local WOW_PROJECT_ID = WOW_PROJECT_ID


--[[------------------------------------------------------------------------]]--

-- Classic doesn't have ForEachAura even though it has AuraUtil.

local ForEachAura = AuraUtil.ForEachAura

if not ForEachAura then
    -- Turn the UnitAura returns into a facsimile of the UnitAuraInfo struct
    -- returned by C_UnitAuras.GetAuraDataBySlot(unit, slot)

    local auraInstanceID = 0

    local function UnitAuraData(unit, i, filter)
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(unit, i, filter)

        local isHarmful = filter:find('HARMFUL') and true or false
        local isHelpful = filter:find('HELPFUL') and true or false

        auraInstanceID = auraInstanceID + 1
        return {
            applications = count,
            auraInstanceID = auraInstanceID,
            canApplyAura = canApplyAura,
            -- charges = ,
            dispelName = dispelType,
            duration = duration,
            expirationTime = expirationTime,
            icon = icon,
            isBossAura = isBossDebuff,
            isFromPlayerOrPlayerPet = castByPlayer,
            isHarmful = isHarmful,
            isHelpful = isHelpful,
            -- isNameplateOnly =
            -- isRaid =
            isStealable = isStealable,
            -- maxCharges =
            name = name,
            nameplateShowAll = nameplateShowAll,
            nameplateShowPersonal = nameplateShowPersonal,
            -- points =
            sourceUnit = source,
            spellId = spellId,
            timeMod = timeMod,
        }
    end

    ForEachAura =
        function (unit, filter, maxCount, func, usePackedAura)
            local i = 1
            while true do
                if maxCount and i > maxCount then
                    return
                elseif UnitAura(unit, i, filter) then
                    if usePackedAura then
                        func(UnitAuraData(unit, i, filter))
                    else
                        func(UnitAura(unit, i, filter))
                    end
                else
                    return
                end
                i = i + 1
            end
        end
end


--[[------------------------------------------------------------------------]]--

-- LBA matches auras by name, but the profile auraMap is by ID so that it works
-- in all locales. Translate it into the names at load time and when the player
-- adds more mappings.

local AuraMapByName = {}

function LBA.UpdateAuraMap()
    table.wipe(AuraMapByName)

    for fromID, fromTable in pairs(LBA.db.profile.auraMap) do
        local fromName = GetSpellInfo(fromID)
        if fromName then
            AuraMapByName[fromName] = {}
            for i, toID in ipairs(fromTable) do
                if toID ~= false then
                    AuraMapByName[fromName][i] = GetSpellInfo(toID)
                end
            end
        end
    end
end


--[[------------------------------------------------------------------------]]--

-- Load and set up dependencies for Masque support. Because we make our own
-- frame and don't touch the ActionButton itself (avoids a LOT of taint issues)
-- we have to make our own masque group. It's a bit weird because it lets  you
-- style LBA differently from the ActionButton, but it's the simplest way.

local Masque = LibStub('Masque', true)
local MasqueGroup = Masque and Masque:Group('LiteButtonAuras')


--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.overlayFrames = {}
    self:RegisterEvent('PLAYER_LOGIN')
end

function LiteButtonAurasControllerMixin:Initialize()
    self.LCD = LibStub("LibClassicDurations", true)
    if self.LCD then
        self.LCD:Register("LiteButtonAuras")
        UnitAura = self.LCD.UnitAuraWrapper
    end

    LBA.InitializeOptions()
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

    -- All of these are for the interrupt detection
    self:RegisterEvent('UNIT_SPELLCAST_START')
    self:RegisterEvent('UNIT_SPELLCAST_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
    if WOW_PROJECT_ID == 1 then
        self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE')
        self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE')
    end

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
--  * limit the overlay updates using a dirty/sweep
--  * limit the aura scans by using a dirty/sweep
--  * use the UNIT_AURA push data (as above)
--  * handle AuraMapByName in the overlay instead of here
--  * store only the parts of the UnitAura() return the overlay wants
--  * use C_UnitAuras.GetAuraDataBySlot which has a struct return
--
-- Overall the 10.0 changes are not that helpful for matching by name.
--
-- It's worth noting that the 10.0 BuffFrame still uses the same mechanism
-- as used here, but both the CompactUnitFrame and the TargetFrame have
-- switched to using the new ways.

-- [ 1] name,
-- [ 2] icon,
-- [ 3] count,
-- [ 4] debuffType,
-- [ 5] duration,
-- [ 6] expirationTime,
-- [ 7] source,
-- [ 8] isStealable,
-- [ 9] nameplateShowPersonal,
-- [10] spellId,
-- [11] canApplyAura,
-- [12] isBossDebuff,
-- [13] castByPlayer,
-- [14] nameplateShowAll,
-- [15] timeMod,
-- ...
-- = UnitAura(unit, index, filter)
--
-- https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataBySlot

local function UpdateTableAura(t, auraData)
    t[auraData.name] = auraData
    if AuraMapByName[auraData.name] then
        for _, toName in ipairs(AuraMapByName[auraData.name]) do
            t[toName] = auraData
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
        ForEachAura(unit, 'HELPFUL', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].buffs, auraData)
            end,
            true)
        ForEachAura(unit, 'HARMFUL PLAYER', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].debuffs, auraData)
            end,
            true)
    else
        ForEachAura(unit, 'HELPFUL PLAYER', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].buffs, auraData)
            end,
            true)
        ForEachAura(unit, 'HELPFUL RAID', nil,
            function (auraData)
                UpdateTableAura(LBA.state[unit].buffs, auraData)
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

local function UpdateTargetCast()
    local name, endTime, cantInterrupt, _

    if UnitCanAttack('player', 'target') then
        name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo('target')
        if name and not cantInterrupt then
            LBA.state.target.interrupt = endTime / 1000
            return
        end

        name, _, _, _, endTime, _, cantInterrupt = UnitChannelInfo('target')
        if name and not cantInterrupt then
            LBA.state.target.interrupt = endTime / 1000
            return
        end
    end

    LBA.state.target.interrupt = nil
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

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
        self:UnregisterEvent('PLAYER_LOGIN')
        self:MarkOverlaysDirty()
        return
    elseif event == 'PLAYER_ENTERING_WORLD' then
        UpdateUnitAuras('target')
        UpdateWeaponEnchants()
        UpdateTargetCast()
        UpdateUnitAuras('player')
        UpdateUnitAuras('pet')
        UpdatePlayerChannel()
        UpdatePlayerTotems()
        self:MarkOverlaysDirty()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        UpdateUnitAuras('target')
        UpdateTargetCast()
        self:MarkOverlaysDirty(true)
    elseif event == 'UNIT_AURA' then
        -- This fires a lot. Be careful. In DF, UNIT_AURA seems to tick every
        -- second for 'player' with no updates, but it's not worth optimizing.
        local unit, auraInfo = ...
        if unit == 'player' or unit == 'pet' or unit == 'target' then
            UpdateUnitAuras(unit, auraInfo)
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
        if unit == 'target' then
            UpdateTargetCast()
            self:MarkOverlaysDirty(true)
        elseif unit == 'player' then
            UpdatePlayerChannel()
            self:MarkOverlaysDirty(true)
        end
    end
end
