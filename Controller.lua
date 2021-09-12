--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...


--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.frames = {}
    self.framesByAction = {}
    self.playerBuffs = {}
    self.playerTotems = {}
    self.targetDebuffs = {}
    self.targetBuffs = {}

    self:InitBlizzard()

    if Dominos then
        Dominos.RegisterCallback(self, 'LAYOUT_LOADED', 'InitDominos')
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('UNIT_AURA')
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

-- The OverrideActionButtons have the same actionID as the main buttons and
-- mess up framesByAction (as well as we don't want to handle them)

function LiteButtonAurasControllerMixin:InitBlizzard()
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            local overlay = self:CreateOverlay(actionButton)
            overlay:ScanAction()
        end
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
        self.framesByAction[actionButton.action] = overlay
        hooksecurefunc(actionButton, 'UpdateAction', function () overlay:ScanAction() end)
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
    AuraUtil.ForEachAura('player', 'HELPFUL RAID', nil,
        function (name, ...)
            self.playerBuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdatePlayerTotems()
    table.wipe(self.playerTotems)
    for i = 1, MAX_TOTEMS do
        local exists, name, startTime, duration, model = GetTotemInfo(i)
        if exists then
            name = LBA.TotemOrGuardianModels[model] or name
            self.playerTotems[name] = startTime + duration
        end
    end
end

function LiteButtonAurasControllerMixin:UpdateTargetDebuffs()
    table.wipe(self.targetDebuffs)
    AuraUtil.ForEachAura('target', 'HARMFUL PLAYER', nil,
        function (name, ...)
            self.targetDebuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetBuffs()
    table.wipe(self.targetBuffs)
    AuraUtil.ForEachAura('target', 'HELPFUL', nil,
        function (name, ...)
            self.targetBuffs[name] = { name, ... }
        end)
end

function LiteButtonAurasControllerMixin:UpdateTargetCast()
    local name, endTime, cantInterrupt, _

    name, _, _, _, endTime, _, _, cantInterrupt = UnitCastingInfo('target')
    if name and not cantInterrupt then
        self.targetInterrupt = endTime / 1000
        return
    end

    name, _, _, _, endTime, _, cantInterrupt = UnitChannelInfo('target')
    if name and not cantInterrupt then
        self.targetInterrupt = endTime / 1000
        return
    end

    self.targetInterrupt = nil
end

-- The expectation for users of targetBuffs is that there are VERY few
-- of them and that looping over them is OK because it'll be fast.

function LiteButtonAurasControllerMixin:TryShowDispel(overlay)
    local dispels
    if UnitIsFriend('player', 'target') then
        dispels = overlay.friendlyDispels
    elseif UnitIsEnemy('player', 'target') then
        dispels = overlay.hostileDispels
    end
    if not dispels then
        return
    end

    for k in pairs(dispels) do
        for _, info in pairs(self.targetBuffs) do
            if info[4] == k then
                overlay:ShowDispel(info)
                return true
            end
        end
    end
end

function LiteButtonAurasControllerMixin:CanSoothe(overlay)
    for _, info in pairs(self.targetBuffs) do
        if info[8] and info[4] == "" then
            return true
        end
    end
end

function LiteButtonAurasControllerMixin:UpdateOverlays()
    for actionButton, overlay in pairs(self.frames) do
        local show = false
        if overlay.name and not LBA.DenySpells[overlay.name] then
            if overlay.isInterrupt and self.targetInterrupt then
                overlay:ShowSuggestion()
                show = true
            elseif overlay.isSoothe and self:CanSoothe(overlay) then
                overlay:ShowSuggestion()
                show = true
            else
                overlay:HideSuggestion()
            end
            if self.playerBuffs[overlay.name] then
                overlay:ShowBuff(self.playerBuffs[overlay.name])
                show = true
            elseif self.playerTotems[overlay.name] then
                overlay:ShowTotem(self.playerTotems[overlay.name])
                show = true
            elseif self.targetDebuffs[overlay.name] then
                overlay:ShowDebuff(self.targetDebuffs[overlay.name])
                show = true
            elseif self:TryShowDispel(overlay) then
                show = true
            else
                overlay:HideAura()
            end
        end
        overlay:SetShown(show)
    end
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
        self:UpdateTargetBuffs()
        self:UpdateTargetDebuffs()
        self:UpdateTargetCast()
        self:UpdatePlayerBuffs()
        self:UpdatePlayerTotems()
        self:UpdateOverlays()
    elseif event == 'ACTIONBAR_SLOT_CHANGED' then
        local action = ...
        local overlay = self.framesByAction[action]
        if overlay then
            overlay:ScanAction()
            self:UpdateOverlays()
        end
    elseif event == 'PLAYER_TARGET_CHANGED' then
        self:UpdateTargetBuffs()
        self:UpdateTargetDebuffs()
        self:UpdateTargetCast()
        self:UpdateOverlays()
    elseif event == 'UNIT_AURA' then
        local unit = ...
        if unit == 'player' then
            self:UpdatePlayerBuffs()
            self:UpdateOverlays()
        elseif unit == 'target' then
            self:UpdateTargetBuffs()
            self:UpdateTargetDebuffs()
            self:UpdateOverlays()
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        self:UpdatePlayerTotems()
        self:UpdateOverlays()
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        local unit = ...
        if unit == 'target' then
            self:UpdateTargetCast()
            self:UpdateOverlays()
        end
    end
end
