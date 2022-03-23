--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.state = {
    playerBuffs = {},
    playerTotems = {},
    targetDebuffs = {},
    targetBuffs = {},
}

LBA.auraMapByName = {}

function LBA.UpdateAuraMap()
    LBA.auraMapByName = table.wipe(LBA.auraMapByName)

    for fromID, fromTable in pairs(LBA.db.profile.auraMap) do
        local fromName = GetSpellInfo(fromID)
        LBA.auraMapByName[fromName] = {}
        for i, toID in ipairs(fromTable) do
            LBA.auraMapByName[fromName][i] = GetSpellInfo(toID)
        end
    end
end

--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.overlayFrames = {}
    self:RegisterEvent('ADDON_LOADED')
end

function LiteButtonAurasControllerMixin:Initialize()
    LBA.InitializeOptions()
    LBA.SetupSlashCommand()
    LBA.BarIntegrations:Initialize()
    LBA.UpdateAuraMap()


    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('PLAYER_TOTEM_UPDATE')

    -- All of these are for the interrupt detection
    self:RegisterEvent('UNIT_SPELLCAST_START')
    self:RegisterEvent('UNIT_SPELLCAST_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')

    LBA.db.RegisterCallback(self, 'OnModified', 'StyleAllOverlays')
end

function LiteButtonAurasControllerMixin:CreateOverlay(actionButton)
    if not self.overlayFrames[actionButton] then
        local name = actionButton:GetName() .. "LiteButtonAurasOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "LiteButtonAurasOverlayTemplate")
        self.overlayFrames[actionButton] = overlay
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

-- name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ... = UnitAura(unit, index, filter)

local function UpdateTableAura(t, name, ...)
    t[name] = { name, ... }
    if LBA.auraMapByName[name] then
        for _, toName in ipairs(LBA.auraMapByName[name]) do
            t[toName] = { name, ... }
        end
    end
end

function LiteButtonAurasControllerMixin:UpdatePlayerBuffs()
    table.wipe(LBA.state.playerBuffs)
    AuraUtil.ForEachAura('player', 'HELPFUL PLAYER', nil,
        function (name, ...)
            UpdateTableAura(LBA.state.playerBuffs, name, ...)
        end)
    AuraUtil.ForEachAura('player', 'HELPFUL RAID', nil,
        function (name, ...)
            UpdateTableAura(LBA.state.playerBuffs, name, ...)
        end)
end

function LiteButtonAurasControllerMixin:UpdatePlayerTotems()
    table.wipe(LBA.state.playerTotems)
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

function LiteButtonAurasControllerMixin:UpdateTargetDebuffs()
    table.wipe(LBA.state.targetDebuffs)
    AuraUtil.ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (name, ...)
            UpdateTableAura(LBA.state.targetDebuffs, name, ...)
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetBuffs()
    table.wipe(LBA.state.targetBuffs)
    if UnitCanAttack('player', 'target') then
        -- Hostile target buffs are only for dispels
        AuraUtil.ForEachAura('target', 'HELPFUL', nil,
            function (name, ...)
                LBA.state.targetBuffs[name] = { name, ... }
            end)
    else
        AuraUtil.ForEachAura('target', 'HELPFUL PLAYER', nil,
            function (name, ...)
                LBA.state.targetBuffs[name] = { name, ... }
            end)
    end
end

function LiteButtonAurasControllerMixin:UpdateTargetCast()
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

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'ADDON_LOADED' then
        self:Initialize()
        self:UnregisterEvent('ADDON_LOADED')
    elseif event == 'PLAYER_ENTERING_WORLD' then
        self:UpdateTargetBuffs()
        self:UpdateTargetDebuffs()
        self:UpdateTargetCast()
        self:UpdatePlayerBuffs()
        self:UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        self:UpdateTargetBuffs()
        self:UpdateTargetDebuffs()
        self:UpdateTargetCast()
        self:UpdateAllOverlays()
    elseif event == 'UNIT_AURA' then
        local unit = ...
        if unit == 'player' then
            self:UpdatePlayerBuffs()
            self:UpdateAllOverlays()
        elseif unit == 'target' then
            self:UpdateTargetBuffs()
            self:UpdateTargetDebuffs()
            self:UpdateAllOverlays()
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        self:UpdatePlayerTotems()
        self:UpdateAllOverlays()
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        local unit = ...
        if unit == 'target' then
            self:UpdateTargetCast()
            self:UpdateAllOverlays()
        end
    end
end
