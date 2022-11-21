--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is the event handler and state updater. Watches for the buffs and
    updates LBA.state, then calls overlay:Update() on all actionbutton overlays
    when required.

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.state = {
    playerBuffs = {},
    playerPetBuffs = {},
    playerTotems = {},
    playerChannel = nil,
    targetDebuffs = {},
    targetBuffs = {},
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
    ForEachAura =
        function (unit, filter, maxCount, func)
            local i = 1
            while true do
                if maxCount and i > maxCount then
                    return
                elseif UnitAura(unit, i, filter) then
                    func(UnitAura(unit, i, filter))
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

local function UpdateTableAura(t, name, ...)
    t[name] = { name, ... }
    if AuraMapByName[name] then
        for _, toName in ipairs(AuraMapByName[name]) do
            t[toName] = t[name]
        end
    end
end

local function UpdatePlayerChannel()
    LBA.state.playerChannel = UnitChannelInfo('player')
end

local function UpdatePlayerBuffs()
    LBA.state.playerBuffs = {}
    ForEachAura('player', 'HELPFUL PLAYER', nil,
        function (...)
            UpdateTableAura(LBA.state.playerBuffs, ...)
        end)
    ForEachAura('player', 'HELPFUL RAID', nil,
        function (...)
            UpdateTableAura(LBA.state.playerBuffs, ...)
        end)
end

local function UpdatePlayerPetBuffs()
    LBA.state.playerPetBuffs = {}
    ForEachAura('pet', 'HELPFUL PLAYER', nil,
        function (...)
            UpdateTableAura(LBA.state.playerPetBuffs, ...)
        end)
end

local function UpdatePlayerTotems()
    LBA.state.playerTotems = {}
    for i = 1, MAX_TOTEMS do
        local exists, name, startTime, duration, model = GetTotemInfo(i)
        if exists and name then
            if model then
                name = LBA.TotemOrGuardianModels[model] or name
            end
            LBA.state.playerTotems[name] = startTime + duration
        end
    end
end

local function UpdateEnemyDebuffs()
    LBA.state.targetDebuffs = {}
    ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (...)
            UpdateTableAura(LBA.state.targetDebuffs, ...)
        end)
end

local function UpdateEnemyBuffs()
    LBA.state.targetBuffs = {}
    if UnitCanAttack('player', 'target') then
        -- Hostile target buffs are only for dispels
        ForEachAura('target', 'HELPFUL', nil,
            function (name, ...)
                LBA.state.targetBuffs[name] = { name, ... }
            end)
    else
        ForEachAura('target', 'HELPFUL PLAYER', nil,
            function (name, ...)
                LBA.state.targetBuffs[name] = { name, ... }
            end)
    end
end

local function UpdateEnemyCast()
    local name, endTime, cantInterrupt, _

    if UnitCanAttack('player', 'target') then
        name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo('target')
        if name and not cantInterrupt then
            LBA.state.targetInterrupt = endTime / 1000
            return
        end

        name, _, _, _, endTime, _, cantInterrupt = UnitChannelInfo('target')
        if name and not cantInterrupt then
            LBA.state.targetInterrupt = endTime / 1000
            return
        end
    end

    LBA.state.targetInterrupt = nil
end


--[[------------------------------------------------------------------------]]--

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
        self:UnregisterEvent('PLAYER_LOGIN')
        self:UpdateAllOverlays()
        return
    elseif event == 'PLAYER_ENTERING_WORLD' then
        UpdateEnemyBuffs()
        UpdateEnemyDebuffs()
        UpdateEnemyCast()
        UpdatePlayerBuffs()
        UpdatePlayerPetBuffs()
        UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        UpdateEnemyBuffs()
        UpdateEnemyDebuffs()
        UpdateEnemyCast()
        self:UpdateAllOverlays()
    elseif event == 'UNIT_AURA' then
        -- Be careful, this fires a lot. It might be better to dirty these
        -- for an OnUpdate handler so at least it can't be more than once a
        -- frame.
        local unit = ...
        if unit == 'player' then
            UpdatePlayerBuffs()
            self:UpdateAllOverlays()
        elseif unit == 'pet' then
            UpdatePlayerPetBuffs()
            self:UpdateAllOverlays()
        elseif unit == 'target' then
            UpdateEnemyBuffs()
            UpdateEnemyDebuffs()
            self:UpdateAllOverlays()
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        -- This fires a lot too, same applies as UNIT_AURA.
        local unit = ...
        if unit == 'target' then
            UpdateEnemyCast()
            self:UpdateAllOverlays()
        elseif unit == 'player' then
            UpdatePlayerChannel()
            self:UpdateAllOverlays()
        end
    end
end
