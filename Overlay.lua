--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...


local LibBG = LibStub("LibButtonGlow-1.0")

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame
    local parent = self:GetParent()
    self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
    self:Style()
end

function LiteButtonAurasOverlayMixin:Style()
    local font = LBA.db.profile.font
    if type(font) == 'string' and _G[font] and _G[font].GetFont then
        self.Timer:SetFont(_G[font]:GetFont())
        self.Count:SetFont(_G[font]:GetFont())
    elseif type(font) == 'table' then
        self.Timer:SetFont(unpack(font))
        self.Count:SetFont(unpack(font))
    else
        self.Timer:SetFont(NumberFontNormal:GetFont())
        self.Count:SetFont(NumberFontNormal:GetFont())
    end
end

-- This could be optimized (?) slightly be checking if type, id, subType
-- are all the same as before and doing nothing

function LiteButtonAurasOverlayMixin:SetUpAction()
    local action = self:GetAction()

    local type, id, subType = GetActionInfo(action)
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

local function IsDeniedSpell(spellID)
    return spellID and LBA.db.profile.denySpells[spellID]
end

function LiteButtonAurasOverlayMixin:Update(stateOnly)
    -- Even though the action might be the same, what it contains could have
    -- changed due to the dynamic nature of macros and some spells.
    if not stateOnly then
        self:SetUpAction()
    end

    local show = false
    local state = LBA.state

    self.expireTime = nil
    self.stackCount = nil
    self.displayGlow = nil
    self.displaySuggestion = nil
    self.displayTimerColor = nil

    if self.name and not IsDeniedSpell(self.spellID) then
        if self:TrySetAsSoothe() then
            show = true
        elseif self:TrySetAsInterrupt() then
            show = true
        elseif state.playerTotems[self.name] then
            self:SetAsTotem(state.playerTotems[self.name])
            show = true
        elseif state.playerBuffs[self.name] then
            self:SetAsBuff(state.playerBuffs[self.name])
            show = true
        elseif state.targetDebuffs[self.name] then
            self:SetAsDebuff(state.targetDebuffs[self.name])
            show = true
        elseif self:TrySetAsDispel(self) then
            show = true
        end
    end

    local alreadyOverlayed = self.spellID and IsSpellOverlayed(self.spellID)
    self:ShowGlow(self.displayGlow and not alreadyOverlayed)
    self:ShowTimer(self.expireTime ~= nil)
    self:ShowStacks(self.stackCount ~= nil)
    self:ShowSuggestion(self.displaySuggestion)
    self:SetShown(show)
end


-- Aura Config -----------------------------------------------------------------

-- [ 1] name,
-- [ 2] icon,
-- [ 3] count,
-- [ 4] debuffType,
-- [ 5] duration,
-- [ 6] expirationTime,
-- [ 7] source,
-- [ 8] isStealable,
-- [ 9] nameplateShowPersonal,
-- [10] spellId,
-- [11] canApplyAura,
-- [12] isBossDebuff,
-- [13] castByPlayer,
-- [14] nameplateShowAll,
-- [15] timeMod,
--      ...
--  = UnitAura(unit, index, filter)

function LiteButtonAurasOverlayMixin:SetAsAura(info)
    -- Anything that's too short is just annoying
    local duration = info[5]
    if duration > 0 and duration < LBA.db.profile.minAuraDuration then
        return
    end
    self.displayGlow = true
    if info[6] and info[6] ~= 0 then
        self.expireTime = info[6]
        self.timeMod = info[15]
        self.displayTimerColor = LBA.db.profile.colorTimers
    end
    if info[3] and info[3] > 1 and LBA.db.profile.stacks then
        self.stackCount = info[3]
    end
end

function LiteButtonAurasOverlayMixin:SetAsBuff(info)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.Count:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end

function LiteButtonAurasOverlayMixin:SetAsDebuff(info)
    local color = LBA.db.profile.color.debuff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.Count:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end


-- Totem Config ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsTotem(expireTime)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.expireTime, self.modTime = expireTime, nil
    self.displayGlow = true
    self.displayTimerColor = LBA.db.profile.colorTimers
end


-- Interrupt Config ------------------------------------------------------------

-- Assuming no interrupt spells are of the "enabled" type
-- https://wowpedia.fandom.com/wiki/API_GetSpellCooldown

function LiteButtonAurasOverlayMixin:ReadyBefore(endTime)
    local start, duration = GetSpellCooldown(self.spellID)
    return start + duration < endTime
end

function LiteButtonAurasOverlayMixin:TrySetAsInterrupt()
    if LBA.state.targetInterrupt then
        if self.spellID and LBA.Interrupts[self.spellID] then
            local castEnds = LBA.state.targetInterrupt
            if self:ReadyBefore(castEnds) then
                self.expireTime = castEnds
                self.displaySuggestion = true
                return true
            end
        end
    end
end

-- Soothe Config ---------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsSoothe(info)
    local color = LBA.db.profile.color.enrage
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.Count:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end

function LiteButtonAurasOverlayMixin:TrySetAsSoothe()
    if not self.spellID or not LBA.Soothes[self.spellID] then return end
    if UnitIsFriend('player', 'target') then return end

    for _, info in pairs(LBA.state.targetBuffs) do
        if info[8] and info[4] == "" and self:ReadyBefore(info[6]) then
            self.expireTime = info[6]
            self.displaySuggestion = true
            return true
        end
    end
end

-- Dispel Config ---------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsDispel(info)
    local color = DebuffTypeColor[info[4] or ""]
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.Count:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end

function LiteButtonAurasOverlayMixin:TrySetAsDispel()
    if not self.spellID then
        return
    end

    if UnitIsFriend('player', 'target') then
        return
    end

    local dispels = LBA.HostileDispels[self.spellID]
    if dispels then
        for k in pairs(dispels) do
            for _, info in pairs(LBA.state.targetBuffs) do
                if info[4] == k then
                    self:SetAsDispel(info)
                    return true
                end
            end
        end
    end
end

-- Glow Display ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:ShowGlow(isShown)
    self.Glow:SetShown(isShown)
end

-- Suggestion Display-----------------------------------------------------------

function LiteButtonAurasOverlayMixin:ShowSuggestion(isShown)
    if isShown then
        LibBG.ShowOverlayGlow(self)
    else
        LibBG.HideOverlayGlow(self)
    end
end

-- Count Display ---------------------------------------------------------------

function LiteButtonAurasOverlayMixin:ShowStacks(isShown)
    if isShown then
        self.Count:SetText(self.stackCount)
    end
    self.Count:SetShown(isShown)
end


-- Timer Display ---------------------------------------------------------------

local ceil = math.ceil

local function TimerAbbrev(duration)
    if duration >= 86400 then
        return "%dd", ceil(duration/86400)
    elseif duration >= 3600 then
        return "%dh", ceil(duration/3600)
    elseif duration >= 60 then
        return "%dm", ceil(duration/60)
    elseif duration >= 3 or not LBA.db.profile.decimalTimers then
        return "%d", ceil(duration)
    else
        -- printf uses round (not available in lua) so do our own
        -- ceil and avoid a discontinuity at the break
        duration = ceil(duration*10)/10
        return "%.1f", duration
    end
end

-- BuffFrame does it this way, SetFormattedText on every frame. If its
-- good enough for them it's good enough for me.
--
-- /console scriptprofile 1
-- /reload
--
-- UpdateAddOnCPUUsage()
-- t,n = GetFunctionCPUUsage(LiteButtonAurasOverlayMixin.UpdateTimer, true)
-- print(t*1000/n) -> ~14 ns
--

function LiteButtonAurasOverlayMixin:UpdateTimer()
    local duration = self.expireTime - GetTime()
    if self.timeMod and self.timeMod > 0 then
        duration = duration / self.timeMod
    end
    if duration >= 0 then
        self.Timer:SetFormattedText(TimerAbbrev(duration))
        if self.displayTimerColor then
            self.Timer:SetTextColor(LBA.TimerRGB(duration))
        else
            self.Timer:SetTextColor(1, 1, 1)
        end
    else
        self.Timer:Hide()
        self:SetScript('OnUpdate', nil)
    end
end

function LiteButtonAurasOverlayMixin:ShowTimer(isShown)
    if isShown then
        self:SetScript('OnUpdate', self.UpdateTimer)
        self.Timer:Show()
    else
        self:SetScript('OnUpdate', nil)
        self.Timer:Hide()
    end
end
