--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...


--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.frames = {}
    self.playerBuffs = {}
    self.targetDebuffs = {}

    self:InitBlizzard()

    if Dominos then
        Dominos.RegisterCallback(self, 'LAYOUT_LOADED', 'InitDominos')
    end

    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('UNIT_SPELLCAST_START')
    self:RegisterEvent('UNIT_SPELLCAST_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
end

function LiteButtonAurasControllerMixin:InitBlizzard()
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        local overlay = self:CreateOverlay(actionButton)
        overlay:ScanAction()
    end
end

function LiteButtonAurasControllerMixin:InitDominos()
    for _, actionButton in pairs(Dominos.ActionButtons) do
        local overlay = self:CreateOverlay(actionButton)
        overlay:ScanAction()
    end
end

function LiteButtonAurasControllerMixin:CreateOverlay(actionButton)
    if not self.frames[actionButton] then
        local name = actionButton:GetName() .. "LiteButtonAurasOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "LiteButtonAurasOverlayTemplate")
        self.frames[actionButton] = overlay
    end
    return self.frames[actionButton]
end

-- name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ... = UnitAura(unit, index, filter)


function LiteButtonAurasControllerMixin:UpdatePlayerBuffs()
    table.wipe(self.playerBuffs)
    AuraUtil.ForEachAura('player', 'HELPFUL PLAYER', nil,
        function (name, ...)
            self.playerBuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetDebuffs()
    table.wipe(self.targetDebuffs)
    AuraUtil.ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (name, ...)
            self.targetDebuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetCast()
    local name, endTime, cantInterrupt, _

    name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo('target')
    if name and not cantInterrupt then
        self.targetInterrupt = endTime / 1000
        return
    end

    name, _, _, endTime, _, cantInterrupt = UnitChannelInfo('target')
    if name and not cantInterrupt then
        self.targetInterrupt = endTime / 1000
        return
    end

    self.targetInterrupt = nil
end

function LiteButtonAurasControllerMixin:UpdateOverlays()
    for actionButton, overlay in pairs(self.frames) do
        local show = false
        if overlay.name then
            if overlay.isInterrupt and self.targetInterrupt then
                overlay:ShowInterrupt()
                show = true
            else
                overlay:HideInterrupt()
            end
            if self.playerBuffs[overlay.name] then
                overlay:ShowBuff(self.playerBuffs[overlay.name])
                show = true
            elseif self.targetDebuffs[overlay.name] then
                overlay:ShowDebuff(self.targetDebuffs[overlay.name])
                show = true
            else
                overlay:HideAura()
            end
            overlay:SetShown(show)
        end
    end
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_TARGET_CHANGED' then
        self:UpdateTargetDebuffs()
        self:UpdateTargetCast()
        self:UpdateOverlays()
    elseif event == 'UNIT_AURA' then
        local unit = ...
        if unit == 'player' then
            self:UpdatePlayerBuffs()
            self:UpdateOverlays()
        elseif unit == 'target' then
            self:UpdateTargetDebuffs()
            self:UpdateOverlays()
        end
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        local unit = ...
        if unit == 'target' then
            self:UpdateTargetCast()
            self:UpdateOverlays()
        end
    end
end
