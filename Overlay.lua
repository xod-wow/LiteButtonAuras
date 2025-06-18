--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Code for one overlay frame on top of a button. Most of this code is the
    logic for what to display depending on what auras are in LBA.state, see
    LiteButtonAurasOverlayMixin:Update() for the entry point.

----------------------------------------------------------------------------]]--

local _, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell
local C_Item = LBA.C_Item or C_Item

local LibBG = LibStub("LibButtonGlow-1.0")


--[[------------------------------------------------------------------------]]--

-- Cache a some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's a pain to maintain.

local DebuffTypeColor = DebuffTypeColor
local GetMacroItem = GetMacroItem
local GetMacroSpell = GetMacroSpell
local GetTime = GetTime
local IsSpellOverlayed = IsSpellOverlayed
local UnitCanAttack = UnitCanAttack
local WOW_PROJECT_ID = WOW_PROJECT_ID

--[[------------------------------------------------------------------------]]--

-- LBA matches auras by name, but the profile auraMap is by ID so that it works
-- in all locales. Translate it into the names at load time and when the player
-- adds more mappings. Also invert so we don't have to loop in overlay update.

LBA.AuraMap = {}

function LBA.UpdateAuraMap()
    LBA.AuraMap = {}
    for showAura, onAbilityTable in pairs(LBA.db.profile.auraMap) do
        if type(showAura) == 'number' then
            showAura = C_Spell.GetSpellName(showAura)
        end
        for _, onAbility in ipairs(onAbilityTable) do
            if type(onAbility) == 'number' then
                onAbility = C_Spell.GetSpellName(onAbility)
            end
            if showAura and onAbility then
                LBA.AuraMap[onAbility] = LBA.AuraMap[onAbility] or {}
                table.insert(LBA.AuraMap[onAbility], showAura)
            end
        end
    end
end


--[[------------------------------------------------------------------------]]--

LiteButtonAurasOverlayMixin = {}

function LiteButtonAurasOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame, otherwise the individual
    -- bar integration will need to adjust the level accordingly
    local parent = self:GetParent()
    if parent.cooldown then
        self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
    end
    self:Style()
end

function LiteButtonAurasOverlayMixin:Style()
    local p = LBA.db.profile

    local parent = self:GetParent()
    self:SetSize(parent:GetSize())

    local point, x, y, justifyH

    self.Timer:SetFont(p.fontPath, p.fontSize, p.fontFlags)
    point, x, y, justifyH = unpack(LBA.anchorSettings[p.timerAnchor])
    self.Timer:ClearAllPoints()
    self.Timer:SetPoint(point, self, x*p.timerAdjust, y*p.timerAdjust)
    self.Timer:SetJustifyH(justifyH)

    self.Stacks:SetFont(p.fontPath, p.fontSize, p.fontFlags)
    point, x, y, justifyH = unpack(LBA.anchorSettings[p.stacksAnchor])
    self.Stacks:ClearAllPoints()
    self.Stacks:SetPoint(point, self, x*p.stacksAdjust, y*p.stacksAdjust)
    self.Stacks:SetJustifyH(justifyH)
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
        self.name = C_Spell.GetSpellName(id)
        self.spellID = id
        self.type = type
        return
    end

    if type == 'item' then
        LBA.buttonItemIDs[id] = true
        self.name, self.spellID = C_Item.GetItemSpell(id)
        self.type = type
        return
    end

    if type == 'macro' then
        if subType == 'spell' then
            self.spellID = id
            self.name = C_Spell.GetSpellName(self.spellID)
            self.type = subType
            return
        elseif subType == 'item' then
            -- 10.2 GetActionInfo() seems bugged for this case. In an ideal
            -- world id would be the itemID but it seemds to be actionID-1.
            -- This workaround assumes no two macros have the same name. Maybe
            -- there's a better way.
            local actionID = self:GetActionID()
            if actionID then
                local macroName = GetActionText(actionID)
                local macroID = GetMacroIndexByName(macroName or "")
                if macroID then
                    local _, itemLink = GetMacroItem(macroID)
                    if itemLink then
                        self.name, self.spellID = C_Item.GetItemSpell(itemLink)
                    end
                end
                self.type = subType
                return
            end
        elseif not subType then
            local itemName = GetMacroItem(id)
            if itemName then
                local name, spellID = C_Item.GetItemSpell(itemName)
                self.spellID = spellID
                self.name = name or itemName
                self.type = 'item'
                return
            end
            local spellID = GetMacroSpell(id)
            if spellID then
                self.spellID = spellID
                self.name = C_Spell.GetSpellName(spellID)
                self.type = 'spell'
                return
            end
        end
    end

    self.spellID = nil
    self.name = nil
    self.type = nil
end

function LiteButtonAurasOverlayMixin:IsKnown()
    if self.type == 'item' then
        -- Assume if you have an item on your bars you know it. Could check
        -- the owned item count but it would only matter if an item was an
        -- interrupt or soothe, which is always false.
        return true
    elseif not self.spellID then
        return false
    elseif C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell then
        -- This is trying to account for Pet spells as well which don't count
        -- as IsPlayerSpell() or IsSpellKnown(). I am very much hoping this is not
        -- super slow.
        return C_SpellBook.FindSpellBookSlotForSpell(self.spellID) ~= nil
    else
        return true
    end
end

function LiteButtonAurasOverlayMixin:IsIgnoreSpell()
    if self.spellID and LBA.db.profile.denySpells[self.spellID] then
        return true
    else
        return false
    end
end

function LiteButtonAurasOverlayMixin:GetMatchingAura(t)
    if LBA.AuraMap[self.name] then
        for _, extraAuraName in ipairs(LBA.AuraMap[self.name]) do
            if t[extraAuraName] then
                return t[extraAuraName]
            end
        end
    elseif self:IsIgnoreSpell() then
        return
    elseif LBA.db.profile.defaultNameMatching and t[self.name] then
        return t[self.name]
    end
end

function LiteButtonAurasOverlayMixin:AlreadyOverlayed()
    if WOW_PROJECT_ID == 1 then
        return (self.spellID and IsSpellOverlayed(self.spellID))
    else
        local parent = self:GetParent()
        return (parent.overlay and parent.overlay:IsShown())
    end
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

        if self:IsKnown() then
            if self:TrySetAsSoothe('target') then
                show = true
            elseif self:TrySetAsInterrupt('target') then
                show = true
            elseif self:TrySetAsTotem() then
                show = true
            -- elseif self:TrySetAsTaunt('target') then
            --     show = true
            elseif self:TrySetAsBuff('player') then
                show = true
            elseif self:TrySetAsDebuff('target') then
                show = true
            elseif self:TrySetAsPetBuff('pet') then
                show = true
            elseif self:TrySetAsWeaponEnchant() then
                show = true
            elseif self:TrySetAsDispel('target') then
                show = true
            end
        end
    end

    self:ShowGlow(self.displayGlow and not self:AlreadyOverlayed())
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

function LiteButtonAurasOverlayMixin:SetAsAura(auraData)
    -- Anything that's too short is just annoying
    if auraData.duration > 0 and auraData.duration < LBA.db.profile.minAuraDuration then
        return
    end
    self.displayGlow = true
    if auraData.expirationTime and auraData.expirationTime ~= 0 then
        self.expireTime = auraData.expirationTime
        self.timeMod = auraData.timeMod
    end
    if auraData.applications and auraData.applications > 1 then
        self.stackCount = auraData.applications
    end
end

function LiteButtonAurasOverlayMixin:SetAsBuff(auraData)
    local color = LBA.db.profile.color.buff
    local alpha = LBA.db.profile.glowAlpha
    self.Glow:SetVertexColor(color.r, color.g, color.b, alpha)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(auraData)
end

function LiteButtonAurasOverlayMixin:SetAsPetBuff(auraData)
    local color = LBA.db.profile.color.petBuff
    local alpha = LBA.db.profile.glowAlpha
    self.Glow:SetVertexColor(color.r, color.g, color.b, alpha)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(auraData)
end

function LiteButtonAurasOverlayMixin:SetAsDebuff(auraData)
    local color = LBA.db.profile.color.debuff
    local alpha = LBA.db.profile.glowAlpha
    self.Glow:SetVertexColor(color.r, color.g, color.b, alpha)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsBuff(unit)
    local aura = self:GetMatchingAura(LBA.state[unit].buffs)
    if aura then
        self:SetAsBuff(aura)
        return true
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsPetBuff(unit)
    if LBA.db.profile.playerPetBuffs then
        local aura = self:GetMatchingAura(LBA.state[unit].buffs)
        if aura and aura.sourceUnit == 'player' then
            self:SetAsPetBuff(aura)
            return true
        end
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsDebuff(unit)
    local aura = self:GetMatchingAura(LBA.state[unit].debuffs)
    if aura then
        self:SetAsDebuff(aura)
        return true
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsWeaponEnchant()
    if LBA.state.player.weaponEnchants[self.name] then
        self:SetAsBuff(LBA.state.player.weaponEnchants[self.name])
        return true
    end
end

-- Totem Config ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsTotem(expireTime)
    local color = LBA.db.profile.color.buff
    local alpha = LBA.db.profile.glowAlpha
    self.Glow:SetVertexColor(color.r, color.g, color.b, alpha)
    self.expireTime, self.modTime = expireTime, nil
    self.displayGlow = true
end

function LiteButtonAurasOverlayMixin:TrySetAsTotem()
    if self:IsIgnoreSpell() or not LBA.db.profile.defaultNameMatching then
        return
    elseif LBA.state.player.totems[self.name] then
        self:SetAsTotem(LBA.state.player.totems[self.name])
        return true
    end
end


-- Interrupt Config ------------------------------------------------------------

-- Assuming no interrupt spells are of the "enabled" type
-- https://wowpedia.fandom.com/wiki/API_GetSpellCooldown

function LiteButtonAurasOverlayMixin:ReadyBefore(endTime)
    if endTime == 0 then
        -- Indefinite enrage, such as from the Raging M+ affix
        return true
    else
        local info = C_Spell.GetSpellCooldown(self.spellID)
        return info and info.startTime + info.duration < endTime
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsInterrupt(unit)
    if LBA.state[unit].interrupt then
        if self.name and LBA.Interrupts[self.name] then
            local castEnds = LBA.state[unit].interrupt
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
function LiteButtonAurasOverlayMixin:SetAsSoothe(auraData)
    local color = LBA.db.profile.color.enrage
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(auraData)
end
]]

function LiteButtonAurasOverlayMixin:IsSoothe()
    -- Note this is handling self.name == nil case as well
    local v = LBA.Soothes[self.name]
    if type(v) == 'function' then
        return not not v()
    else
        return not not v
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsSoothe(unit)
    if not self:IsSoothe() then return end
    if not UnitCanAttack('player', unit) then return end

    for _, auraData in pairs(LBA.state[unit].buffs) do
        if auraData.isStealable and auraData.dispelName == "" and self:ReadyBefore(auraData.expirationTime) then
            self.expireTime = auraData.expirationTime
            self.displaySuggestion = true
            return true
        end
    end
end

-- Taunt Config ----------------------------------------------------------------

--[[
-- To work this would require capturing other player debuffs, and would need
-- an different storage for the state auras since at the moment they all assume
-- they are unique by name which is not true once you introduce other units.
function LiteButtonAurasOverlayMixin:TrySetAsTaunt(unit)
    if not self.name or not LBA.Taunts[self.name] then return end
    if not UnitCanAttack('player', unit) then return end

    for _, auraData in pairs(LBA.state[unit].debuffs) do
        if LBA.Taunts[auraData.name] then
            if auraData.sourceUnit == 'player' then
                self:SetAsBuff(auraData)
            else
                self:SetAsDebuff(auraData)
            end
            return true
        end
    end
end
]]

-- Dispel Config ---------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsDispel(auraData)
    local color = DebuffTypeColor[auraData.dispelName or ""]
    local alpha = LBA.db.profile.glowAlpha
    self.Glow:SetVertexColor(color.r, color.g, color.b, alpha)
    -- self.Stacks:SetTextColor(color.r, color.g, color.b, 1.0)
    self:SetAsAura(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsDispel(unit)
    if not self.name then
        return
    end

    if not UnitCanAttack('player', unit) then
        return
    end

    local dispels = LBA.HostileDispels[self.name]
    if dispels then
        for dispelName in pairs(dispels) do
            for _, auraData in pairs(LBA.state[unit].buffs) do
                if auraData.dispelName == dispelName then
                    self:SetAsDispel(auraData)
                    self.displaySuggestion = true
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

if ActionButtonSpellAlertManager then
    function LiteButtonAurasOverlayMixin:ShowSuggestion(isShown)
        if isShown then
            ActionButtonSpellAlertManager:ShowAlert(self)
            self.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
            self.SpellActivationAlert.ProcLoop:Play()
            self.SpellActivationAlert:Show()
        else
            ActionButtonSpellAlertManager:HideAlert(self)
        end
    end
elseif ActionButton_SetupOverlayGlow then
    function LiteButtonAurasOverlayMixin:ShowSuggestion(isShown)
        if isShown then
            -- Taken from ActionButton_ShowOverlayGlow(self) but we don't want the
            -- start animation because it takes 0.7s before the button starts to
            -- glow which is awful for time-sensitive things like interrupts (and
            -- in my opinion awful in general).
            ActionButton_SetupOverlayGlow(self)
            self.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
            self.SpellActivationAlert.ProcLoop:Play()
            self.SpellActivationAlert:Show()
        else
            ActionButton_HideOverlayGlow(self)
        end
    end
else
    function LiteButtonAurasOverlayMixin:ShowSuggestion(isShown)
        if isShown then
            LibBG.ShowOverlayGlow(self)
        else
            LibBG.HideOverlayGlow(self)
        end
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

function LiteButtonAurasOverlayMixin:Dump(force)
    if self.name or force then
        print(string.format("%d. %s = %s (%d)",
                            self:GetActionID(),
                            self:GetParent():GetName(),
                            self.name or NONE,
                            self.spellID or 0))
    end
end
