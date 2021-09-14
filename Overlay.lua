--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame
    local parent = self:GetParent()
    self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
end

function LiteButtonAurasOverlayMixin:Hook(frame, method)
    if not self.isHooked then
        hooksecurefunc(frame, method, function () self:Update() end)
        self.isHooked = true
    end
end

-- This could be optimized (?) slightly be checking if type, id, subType
-- are all the same as before and doing nothing

function LiteButtonAurasOverlayMixin:SetUpAction()
    self.action = self:GetParent().action

    local type, id, subType = GetActionInfo(self.action)
    if type == 'spell' then
        self.name = GetSpellInfo(id)
        self.spellID = id
        return
    end

    if type == 'item' then
        self.name, self.spellID = GetItemSpell(id)
        return
    end

    if type == 'macro' then
        local itemName = GetMacroItem(id)
        if itemName then
            local name, spellID = GetItemSpell(itemName)
            self.spellID = spellID
            self.name = name or itemName
            return
        else
            self.spellID = GetMacroSpell(id)
            self.name = GetSpellInfo(self.spellID)
            return
        end
    end

    self.name = nil
end

function LiteButtonAurasOverlayMixin:TryShowDispel()
    if not self.spellID then
        return
    end

    local dispels
    if UnitIsFriend('player', 'target') then
        dispels = LBA.FriendlyDispels[self.spellID]
    elseif UnitIsEnemy('player', 'target') then
        dispels = LBA.HostileDispels[self.spellID]
    end
    if not dispels then
        return
    end

    for k in pairs(dispels) do
        for _, info in pairs(LBA.state.targetBuffs) do
            if info[4] == k then
                self:ShowDispel(info)
                return true
            end
        end
    end
end

function LiteButtonAurasOverlayMixin:CanInterrupt()
    if self.spellID and LBA.Interrupts[self.spellID] then
        return LBA.state.targetInterrupt
    end
end

function LiteButtonAurasOverlayMixin:CanSoothe()
    if self.spellID and LBA.Soothes[self.spellID] then
        for _, info in pairs(LBA.state.targetBuffs) do
            if info[8] and info[4] == "" then
                return true
            end
        end
    end
end

function LiteButtonAurasOverlayMixin:Update(stateOnly)
    -- Even though the action might be the same what we do could have
    -- changed due to the dynamic nature of macros and some spells.
    if not stateOnly then
        self:SetUpAction()
    end

    local show = false
    local state = LBA.state

    if self.name and not LBA.Options:IsDenied(self.spellID) then
        if self:CanInterrupt() or self:CanSoothe() then
            self:ShowSuggestion()
            show = true
        else
            self:HideSuggestion()
        end
        if state.playerBuffs[self.name] then
            self:ShowBuff(state.playerBuffs[self.name])
            show = true
        elseif state.playerTotems[self.name] then
            self:ShowTotem(state.playerTotems[self.name])
            show = true
        elseif state.targetDebuffs[self.name] then
            self:ShowDebuff(state.targetDebuffs[self.name])
            show = true
        elseif self:TryShowDispel(self) then
            show = true
        else
            self:HideAura()
        end
    end
    self:SetShown(show)
end

local function DurationAbbrev(duration)
    if duration >= 86400 then
        return "%dd", math.ceil(duration/86400)
    elseif duration >= 3600 then
        return "%dh", math.ceil(duration/3600)
    elseif duration >= 60 then
        return "%dm", math.ceil(duration/60)
    elseif duration >= 3 then
        return "%d", math.ceil(duration)
    else
        return "%.1f", duration
    end
end

-- BuffFrame does it this way, SetFormattedText on every frame. If its
-- good enough for them it's good enough for me.

function LiteButtonAurasOverlayMixin:UpdateDuration()
    if self.expireTime then
        local duration = self.expireTime - GetTime()
        if self.timeMod and self.timeMod > 0 then
            duration = duration / self.timeMod
        end
        self.Duration:SetFormattedText(DurationAbbrev(duration))
        self.Duration:SetTextColor(LBA.DurationRGB(duration))
        self.Duration:Show()
    else
        self.Duration:Hide()
    end
end

function LiteButtonAurasOverlayMixin:ShowTotem(expireTime)
    self.expireTime = expireTime
    self.Glow:SetVertexColor(0.0, 1.0, 0.0, 0.7)
    self.Glow:Show()
    self:SetScript('OnUpdate', self.UpdateDuration)
end

-- name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ...

function LiteButtonAurasOverlayMixin:ShowAura(info)
    if info[6] and info[6] ~= 0 then
        self.expireTime = info[6]
        self.timeMod = info[15]
        self:SetScript('OnUpdate', self.UpdateDuration)
    else
        self.expireTime = nil
        self.timeMod = nil
    end
    self.Glow:Show()
end

function LiteButtonAurasOverlayMixin:HideAura()
    self.expireTime = nil
    self.timeMod = nil
    self.Glow:Hide()
    self:SetScript('OnUpdate', nil)
end

function LiteButtonAurasOverlayMixin:ShowBuff(info)
    self.Glow:SetVertexColor(0.0, 1.0, 0.0, 0.7)
    self:ShowAura(info)
end

function LiteButtonAurasOverlayMixin:ShowDebuff(info)
    self.Glow:SetVertexColor(1.0, 0.0, 0.0, 0.7)
    self:ShowAura(info)
end

function LiteButtonAurasOverlayMixin:ShowDispel(info)
    local color = DebuffTypeColor[info[4] or "none"]
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self:ShowAura(info)
end

function LiteButtonAurasOverlayMixin:ShowSuggestion()
    ActionButton_ShowOverlayGlow(self)
end

function LiteButtonAurasOverlayMixin:HideSuggestion()
    ActionButton_HideOverlayGlow(self)
end
