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

--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.overlayFrames = {}

    LBA.Options:Initialize()
    LBA.BarIntegrations:Initialize()
    LBA.SetupSlashCommand()

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
end

function LiteButtonAurasControllerMixin:CreateOverlay(actionButton)
    if not self.overlayFrames[actionButton] then
        local name = actionButton:GetName() .. "LiteButtonAurasOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "LiteButtonAurasOverlayTemplate")
        self.overlayFrames[actionButton] = overlay
    end
    return self.overlayFrames[actionButton]
end


-- name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ... = UnitAura(unit, index, filter)


function LiteButtonAurasControllerMixin:UpdatePlayerBuffs()
    table.wipe(LBA.state.playerBuffs)
    AuraUtil.ForEachAura('player', 'HELPFUL PLAYER', nil,
        function (name, ...)
            LBA.state.playerBuffs[name] = { name, ... }
        end)
    AuraUtil.ForEachAura('player', 'HELPFUL RAID', nil,
        function (name, ...)
            LBA.state.playerBuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdatePlayerTotems()
    table.wipe(LBA.state.playerTotems)
    for i = 1, MAX_TOTEMS do
        local exists, name, startTime, duration, model = GetTotemInfo(i)
        if exists then
            name = LBA.TotemOrGuardianModels[model] or name
            LBA.state.playerTotems[name] = startTime + duration
        end
    end
end

function LiteButtonAurasControllerMixin:UpdateTargetDebuffs()
    table.wipe(LBA.state.targetDebuffs)
    AuraUtil.ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (name, ...)
            LBA.state.targetDebuffs[name] = { name, ... }
        end)
end

-- The expectation for users of targetBuffs is that there are VERY few
-- of them and that looping over them is OK because it'll be fast.

function LiteButtonAurasControllerMixin:UpdateTargetBuffs()
    table.wipe(LBA.state.targetBuffs)
    AuraUtil.ForEachAura('target', 'HELPFUL', nil,
        function (name, ...)
            LBA.state.targetBuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetCast()
    local name, endTime, cantInterrupt, _

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

    LBA.state.targetInterrupt = nil
end

function LiteButtonAurasControllerMixin:UpdateAllOverlays(stateOnly)
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Update(stateOnly)
    end
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
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
