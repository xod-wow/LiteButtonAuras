--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

local InterruptSpellIDs = {
    [ 47528] = true,    -- Mind Freeze (Death Knight)
    [183725] = true,    -- Disrupt (Demon Hunter)
    [204490] = true,    -- Sigil of Silence (Demon Hunter)
    [ 78675] = true,    -- Solar Beam (Druid)
    [106839] = true,    -- Skull Bash (Druid)
    [147362] = true,    -- Counter Shot (Hunter)
    [187707] = true,    -- Muzzle (Hunter)
    [ 96231] = true,    -- Counterspell (Mage)
    [116705] = true,    -- Spear Hand Strike (Monk)
    [ 96231] = true,    -- Rebuke (Paladin)
    [ 31935] = true,    -- Avenger's Shield (Paladin)
    [ 15487] = true,    -- Silence (Priest)
    [  1766] = true,    -- Kick (Rogue)
    [ 57994] = true,    -- Wind Shear (Paladin)
    [ 89808] = true,    -- Singe Magic (Warlock)
    [199905] = true,    -- Command Demon: Singe Magic (Warlock)
    [132411] = true,    -- Command Demon: Singe Magic (Warlock)
    [212623] = true,    -- Command Demon: Singe Magic (Warlock PvP Talent)
    [  6552] = true,    -- Pummel (Warrior)
}

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
        self.isInterrupt = InterruptSpellIDs[id]
    elseif type == 'macro' then
        local itemID = GetMacroItem(id)
        local spellID = GetMacroSpell(id)
        if itemID then
            self.name = GetItemSpell(itemID) or GetItemInfo(itemID)
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
    elseif duration >= 3 then
        return "%d", math.ceil(duration)
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

function LiteButtonAurasOverlayMixin:ShowAura(info)
    self.expireTime = info[6]
    self.timeMod = info[15]
    self:Show()
end

function LiteButtonAurasOverlayMixin:ShowBuff(info)
    self.Glow:SetVertexColor(0.0, 1.0, 0.0, 0.7)
    self:ShowAura(info)
end

function LiteButtonAurasOverlayMixin:ShowDebuff(info)
    self.Glow:SetVertexColor(1.0, 0.0, 0.0, 0.7)
    self:ShowAura(info)
end

function LiteButtonAurasOverlayMixin:ShowInterrupt(endTime)
    self.Glow:SetVertexColor(1.0, 1.0, 0.0, 0.7)
    self.expireTime = endTime
    self:Show()
end

function LiteButtonAurasOverlayMixin:ShowDispel(info)
end

