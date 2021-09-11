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

    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
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

function LiteButtonAurasControllerMixin:UpdateOverlays()
    for actionButton, overlay in pairs(self.frames) do
        if overlay.name then
            if self.playerBuffs[overlay.name] then
                overlay:ShowBuff(self.playerBuffs[overlay.name])
            elseif self.targetDebuffs[overlay.name] then
                overlay:ShowDebuff(self.targetDebuffs[overlay.name])
            else
                overlay:Hide()
            end
        end
    end
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_TARGET_CHANGED' then
        self:UpdateTargetDebuffs()
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
    end
end

