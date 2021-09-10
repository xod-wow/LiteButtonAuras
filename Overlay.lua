--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...


--[[------------------------------------------------------------------------]]--

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
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
    end
end

function LiteButtonAurasOverlayMixin:ShowBuff(index)
    self.Glow:SetVertexColor(0.7, 1.0, 0.7)
    self:Show()
end

function LiteButtonAurasOverlayMixin:ShowDebuff(index)
end

function LiteButtonAurasOverlayMixin:ShowInterrupt(index)
end

function LiteButtonAurasOverlayMixin:ShowDispel(index)
end

