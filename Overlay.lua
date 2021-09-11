--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

local Interrupts = {
    [ 47528] = true,    -- Mind Freeze (Death Knight)
    [183752] = true,    -- Disrupt (Demon Hunter)
    [202137] = true,    -- Sigil of Silence (Demon Hunter)
    [ 78675] = true,    -- Solar Beam (Druid)
    [106839] = true,    -- Skull Bash (Druid)
    [147362] = true,    -- Counter Shot (Hunter)
    [187707] = true,    -- Muzzle (Hunter)
    [  2139] = true,    -- Counterspell (Mage)
    [116705] = true,    -- Spear Hand Strike (Monk)
    [ 96231] = true,    -- Rebuke (Paladin)
    [ 31935] = true,    -- Avenger's Shield (Paladin)
    [ 15487] = true,    -- Silence (Priest)
    [  1766] = true,    -- Kick (Rogue)
    [ 57994] = true,    -- Wind Shear (Paladin)
    [ 89808] = true,    -- Singe Magic (Warlock)
    [119905] = true,    -- Command Demon: Singe Magic (Warlock)
    [132411] = true,    -- Command Demon: Singe Magic (Warlock)
    [212623] = true,    -- Command Demon: Singe Magic (Warlock PvP Talent)
    [  6552] = true,    -- Pummel (Warrior)
}

local Dispels = {
    [205604] = { Magic = true },    -- Reverse Magic (Demon Hunter)
    [278326] = { Magic = true },    -- Consume Magic (Demon Hunter)
    [  2908] = { Enrage = true },   -- Soothe (Druid)
    [ 19801] = { Enrage = true, Magic = true }, -- Tranquilizing Shot (Hunter)
    [ 30449] = { Magic = true },    -- Spellsteal (Mage)
    [   528] = { Magic = true },    -- Dispel Magic (Priest)
    [ 25046] = { Magic = true },    -- Arcane Torrent (Blood Elf Rogue)
    [ 28730] = { Magic = true },    -- Arcane Torrent (Blood Elf Mage/Warlock)
    [ 50613] = { Magic = true },    -- Arcane Torrent (Blood Elf Death Knight)
    [ 69179] = { Magic = true },    -- Arcane Torrent (Blood Elf Warrior)
    [ 80483] = { Magic = true },    -- Arcane Torrent (Blood Elf Hunter)
    [129597] = { Magic = true },    -- Arcane Torrent (Blood Elf Monk)
    [155145] = { Magic = true },    -- Arcane Torrent (Blood Elf Paladin)
    [202719] = { Magic = true },    -- Arcane Torrent (Blood Elf Demon Hunter)
    [232633] = { Magic = true },    -- Arcane Torrent (Blood Elf Priest)
}


--[[------------------------------------------------------------------------]]--

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame
    local parent = self:GetParent()
    self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
end

function LiteButtonAurasOverlayMixin:ScanAction()
    local actionButton = self:GetParent()
    self.actionID = actionButton.action
    self.name = nil
    self.isInterrupt = nil
    
    local type, id, subType = GetActionInfo(actionButton.action)
    if type == 'spell' then
        self.name = GetSpellInfo(id)
        self.isInterrupt = Interrupts[id]
        self.dispels = Dispels[id]
    elseif type == 'macro' then
        local itemID = GetMacroItem(id)
        local spellID = GetMacroSpell(id)
        if itemID then
            self.name = GetItemSpell(itemID) or GetItemInfo(itemID)
        elseif spellID then
            self.name = GetSpellInfo(spellID)
            self.isInterrupt = Interrupts[spellID]
            self.dispels = Dispels[spellID]
        end
    end
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

local function DurationRGB(duration)
    if duration >= 2 then
        return 1, 1, 1
    else
        return RED_FONT_COLOR:GetRGB()
    end
end

function LiteButtonAurasOverlayMixin:UpdateDuration()
    if self.expireTime then
        local duration = self.expireTime - GetTime()
        if self.timeMod > 0 then
            duration = duration / self.timeMod
        end
        self.Duration:SetFormattedText(DurationAbbrev(duration))
        self.Duration:SetTextColor(DurationRGB(duration))
        self.Duration:Show()
    else
        self.Duration:Hide()
    end
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

function LiteButtonAurasOverlayMixin:ShowInterrupt()
    ActionButton_ShowOverlayGlow(self)
end

function LiteButtonAurasOverlayMixin:HideInterrupt()
    ActionButton_HideOverlayGlow(self)
end

function LiteButtonAurasOverlayMixin:ShowDispel(buffTypes)
    for k in pairs(self.dispels) do
        if buffTypes[k] then
            self.Glow:SetVertexColor(0.5, 0.0, 1.0, 0.7)
            self.Glow:Show()
            break
        end
    end
end
