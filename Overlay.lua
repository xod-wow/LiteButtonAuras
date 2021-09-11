--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...


--[[------------------------------------------------------------------------]]--

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    self.Glow:SetAlpha(0.6)
end

function LiteButtonAurasOverlayMixin:ScanAction()
    local actionButton = self:GetParent()
    self.actionID = actionButton.action
    
    local type, id, subType = GetActionInfo(actionButton.action)
    if type == 'spell' then
        self.name = GetSpellInfo(id)
    elseif type == 'macro' then
        local itemID = GetMacroItem(id)
        local spellID = GetMacroSpell(id)
        if itemID then
            self.name = GetItemInfo(itemID)
        elseif spellID then
            self.name = GetSpellInfo(spellID)
        end
    else
        self.name = nil
    end
end

function LiteButtonAurasOverlayMixin:OnUpdate()
    self:UpdateDuration()
end

local function DurationAbbrev(duration)
    if duration >= 86400 then
        return "%dd", math.ceil(duration/86400)
    elseif duration >= 3600 then
        return "%dh", math.ceil(duration/3600)
    elseif duration >= 60 then
        return "%dm", math.ceil(duration/60)
    elseif duration >= 5 then
        return "%d", duration
    else
        return "%0.1f", duration
    end
end

function LiteButtonAurasOverlayMixin:UpdateDuration()
    if self.expireTime then
        local duration = self.expireTime - GetTime()
        self.Duration:SetFormattedText(DurationAbbrev(duration))
        self.Duration:Show()
    else
        self.Duration:Hide()
    end
end

-- name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ...

function LiteButtonAurasOverlayMixin:ShowBuff(index)
    self.expireTime = select(6, UnitAura('player', index))
    self.Glow:SetVertexColor(0.7, 1.0, 0.7)
    self:Show()
end

function LiteButtonAurasOverlayMixin:ShowDebuff(index)
    self.expireTime = select(6, UnitAura('target', index))
    self.Glow:SetVertexColor(1.0, 0.7, 0.7)
    self:Show()
end

function LiteButtonAurasOverlayMixin:ShowInterrupt(index)
end

function LiteButtonAurasOverlayMixin:ShowDispel(index)
end

