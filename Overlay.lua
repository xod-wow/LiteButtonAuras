--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Code for one overlay frame on top of a button. Most of this code is the
    logic for what to display depending on what auras are in LBA.state, see
    LiteButtonAurasOverlayMixin:Update() for the entry point.

----------------------------------------------------------------------------]]--

local _, LBA = ...

local LibBG = LibStub("LibButtonGlow-1.0")


--[[------------------------------------------------------------------------]]--

-- Cache a some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's just a pain to maintain.

local DebuffTypeColor = DebuffTypeColor
local GetItemSpell = GetItemSpell
local GetMacroItem = GetMacroItem
local GetMacroSpell = GetMacroSpell
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local IsSpellOverlayed = IsSpellOverlayed
local UnitIsFriend = UnitIsFriend
local WOW_PROJECT_ID = WOW_PROJECT_ID


--[[------------------------------------------------------------------------]]--

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame
    local parent = self:GetParent()
    self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
    self:SetSize(parent:GetSize())
    self:Style()
end

function LiteButtonAurasOverlayMixin:Style()
    local font = LBA.db.profile.font
    if type(font) == 'string' and _G[font] and _G[font].GetFont then
        self.Timer:SetFont(_G[font]:GetFont())
        self.Stacks:SetFont(_G[font]:GetFont())
    elseif type(font) == 'table' then
        self.Timer:SetFont(unpack(font))
        self.Stacks:SetFont(unpack(font))
    else
        self.Timer:SetFont(NumberFontNormal:GetFont())
        self.Stacks:SetFont(NumberFontNormalYellow:GetFont())
    end
end

-- This could be optimized (?) slightly be checking if type, id, subType
-- are all the same as before and doing nothing
--
-- In an ideal world GetActionInfo would return the unit as well. Or there
-- would be a GetActionUnit function. If we could find the unit then it
-- would make sense to change LBA.state to be unit-indexed and to collect
-- state for all the units we are interested in rather than a hard coded
-- player and target set. Exactly how to do that efficiently would be a
-- bit of a challenge but I think it's still faster than not keeping the
-- state and each overlay doing its own UnitAura calls.
--
-- Realistically speaking we could scan all the macros for @ and target=
-- and add them to a "wanted units" list. I don't think it would be worth
-- trying to handle auto-self-cast or the new blizzard mouseover cast.

function LiteButtonAurasOverlayMixin:SetUpAction()

    local type, id, subType = self:GetActionInfo()
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

    self.spellID = nil
    self.name = nil
end

local function IsDeniedSpell(spellID)
    return spellID and LBA.db.profile.denySpells[spellID]
end

function LiteButtonAurasOverlayMixin:Update(stateOnly)
    local show = false

    self.expireTime = nil
    self.stackCount = nil
    self.displayGlow = nil
    self.displaySuggestion = nil

    if self:HasAction() then

        -- Even though the action might be the same, what it contains could have
        -- changed due to the dynamic nature of macros and some spells.
        if not stateOnly then
            self:SetUpAction()
        end

        local state = LBA.state

        if self.name and not IsDeniedSpell(self.spellID) then
            if self:TrySetAsSoothe() then
                show = true
            elseif self:TrySetAsInterrupt() then
                show = true
            elseif state.playerTotems[self.name] then
                self:SetAsTotem(state.playerTotems[self.name])
                show = true
            elseif state.playerBuffs[self.name] then
                if self.name ~= LBA.state.playerChannel then
                    self:SetAsBuff(state.playerBuffs[self.name])
                    show = true
                end
            elseif state.playerPetBuffs[self.name] then
                if LBA.PlayerPetBuffs[self.spellID] then
                    self:SetAsBuff(state.playerPetBuffs[self.name])
                    show = true
                end
            elseif state.targetDebuffs[self.name] then
                if self.name ~= LBA.state.playerChannel then
                    self:SetAsDebuff(state.targetDebuffs[self.name])
                    show = true
                end
            elseif self:TrySetAsDispel(self) then
                show = true
            end
        end

        -- We want to try to avoid doubling up on buttons Blizzard are already
        -- showing their overlay on, because it looks terrible. Also try to
        -- avoid calling IsSpellOverlayed as it seems to cause issues with the
        -- new WoW 10.0.2 glow.

        if WOW_PROJECT_ID == 1 then
            self.displayGlow = self.displayGlow and not (self.spellID and IsSpellOverlayed(self.spellID))
        else
            local parent = self:GetParent()
            self.displayGlow = self.displayGlow and not (parent.overlay and parent.overlay:IsShown())
        end
    end

    self:ShowGlow(self.displayGlow)
    self:ShowTimer(self.expireTime ~= nil and LBA.db.profile.showTimers)
    self:ShowStacks(self.stackCount ~= nil and LBA.db.profile.showStacks)
    self:ShowSuggestion(self.displaySuggestion and LBA.db.profile.showSuggestions)
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
    end
    if info[3] and info[3] > 1 then
        self.stackCount = info[3]
    end
end

function LiteButtonAurasOverlayMixin:SetAsBuff(info)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end

function LiteButtonAurasOverlayMixin:SetAsDebuff(info)
    local color = LBA.db.profile.color.debuff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end


-- Totem Config ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsTotem(expireTime)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self.expireTime, self.modTime = expireTime, nil
    self.displayGlow = true
end


-- Interrupt Config ------------------------------------------------------------

-- Assuming no interrupt spells are of the "enabled" type
-- https://wowpedia.fandom.com/wiki/API_GetSpellCooldown

function LiteButtonAurasOverlayMixin:ReadyBefore(endTime)
    if endTime == 0 then
        -- Indefinite enrage, such as from the Raging M+ affix
        return true
    else
        local start, duration = GetSpellCooldown(self.spellID)
        return start + duration < endTime
    end
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

--[[
function LiteButtonAurasOverlayMixin:SetAsSoothe(info)
    local color = LBA.db.profile.color.enrage
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(info)
end
]]

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
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
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
        self.Stacks:SetText(self.stackCount)
    end
    self.Stacks:SetShown(isShown)
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
        if LBA.db.profile.colorTimers then
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
