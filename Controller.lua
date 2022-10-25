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
    playerTotems = {},
    targetDebuffs = {},
    targetBuffs = {},
}


--[[------------------------------------------------------------------------]]--

-- Cache a some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's just a pain to maintain.

local wipe = table.wipe
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
-- in all locales. Translate it into the names once at load time.

local AuraMapByName = {}

function LBA.UpdateAuraMap()
    wipe(AuraMapByName)

    for fromID, fromTable in pairs(LBA.db.profile.auraMap) do
        local fromName = GetSpellInfo(fromID)
        if fromName then
            AuraMapByName[fromName] = {}
            for i, toID in ipairs(fromTable) do
                AuraMapByName[fromName][i] = GetSpellInfo(toID)
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
            t[toName] = { name, ... }
        end
    end
end

local function UpdatePlayerBuffs()
    wipe(LBA.state.playerBuffs)
    ForEachAura('player', 'HELPFUL PLAYER', nil,
        function (...)
            UpdateTableAura(LBA.state.playerBuffs, ...)
        end)
    ForEachAura('player', 'HELPFUL RAID', nil,
        function (...)
            UpdateTableAura(LBA.state.playerBuffs, ...)
        end)
end

local function UpdatePlayerTotems()
    wipe(LBA.state.playerTotems)
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

local function UpdateTargetDebuffs()
    wipe(LBA.state.targetDebuffs)
    ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (...)
            UpdateTableAura(LBA.state.targetDebuffs, ...)
        end)
end

local function UpdateTargetBuffs()
    wipe(LBA.state.targetBuffs)
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

local function UpdateTargetCast()
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
    elseif event == 'PLAYER_ENTERING_WORLD' then
        UpdateTargetBuffs()
        UpdateTargetDebuffs()
        UpdateTargetCast()
        UpdatePlayerBuffs()
        UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        UpdateTargetBuffs()
        UpdateTargetDebuffs()
        UpdateTargetCast()
        self:UpdateAllOverlays()
    elseif event == 'UNIT_AURA' then
        local unit = ...
        if unit == 'player' then
            UpdatePlayerBuffs()
            self:UpdateAllOverlays()
        elseif unit == 'target' then
            UpdateTargetBuffs()
            UpdateTargetDebuffs()
            self:UpdateAllOverlays()
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        local unit = ...
        if unit == 'target' then
            UpdateTargetCast()
            self:UpdateAllOverlays()
        end
    end
end
