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

local MasqueTextureFormat = "Interface/AddOns/Masque/Textures/%s/AutoCast-Mask"


--[[------------------------------------------------------------------------]]--

-- Cache a some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's a pain to maintain.

local C_ActionBar = C_ActionBar
local DebuffTypeColor = DebuffTypeColor
local GetActionText = GetActionText
local GetCVarBool = GetCVarBool
local GetMacroBody = GetMacroBody
local GetMacroItem = GetMacroItem
local GetMacroSpell = GetMacroSpell
local GetModifiedClick = GetModifiedClick
local GetTime = GetTime
local IsModifiedClick = IsModifiedClick
local IsSpellOverlayed = IsSpellOverlayed
local PixelUtil = PixelUtil
local SecureCmdOptionParse = SecureCmdOptionParse
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitIsFriend = UnitIsFriend
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

-- This is wrong for any kind of complex macro that contains multiple commands
-- that execute, or one command that executes and has no conditions but then
-- subsequent commands with conditions that don't. But it should be good enough
-- for basic macros that do CC and interrupts, and a full macro parser would be
-- complex. And not significantly better since you can't tell what spell is
-- going to end the macro from the client.

-- I tried caching the gmatch split but it wasn't any faster.

local function GetMacroUnit(macroIdentifier)
    local macroBody = GetMacroBody(macroIdentifier)
    if macroBody == nil then return end

    for cmd, conditionsAndArgs in macroBody:gmatch("/(%w+)%s+([^\n]+)") do
        if cmd == "cast" or cmd == "use" then
            local result, unit = SecureCmdOptionParse(conditionsAndArgs)
            if result then
                return unit
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

function LiteButtonAurasOverlayMixin:StyleMasqueOverrides(parent, useTexture)
    if parent.__MSQ_Enabled then
        if useTexture and parent.__MSQ_Shape and parent.__MSQ_Shape ~= "Blizzard" then
            self.Glow:SetTexture(string.format(MasqueTextureFormat, parent.__MSQ_Shape))
        end
        if parent.__MSQ_Scale then
            self:SetScale(parent.__MSQ_Scale)
        end
    end
end

function LiteButtonAurasOverlayMixin:Style()
    local p = LBA.db.profile

    local parent = self:GetParent()
    PixelUtil.SetSize(self, parent:GetSize())

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

    -- Defaults before Masque gets its dirty mitts on things
    self.Glow:SetTexture(p.glowTexture)
    self.Glow:SetAlpha(p.glowAlpha)
    self:SetScale(1)

    self:StyleMasqueOverrides(parent, p.glowUseMasque)
end

-- From: https://warcraft.wiki.gg/wiki/UnitId
-- Not all units make sense to care about, nobody is going to write [@raid23]
-- The soft targeting isn't really valid either, all of the cases I think we
-- care about are just covered by @target.

local ValidTrackedUnits = {
    "arena1", "arena2", "arena3", "arena4", "arena5",
    "boss1", "boss2", "boss3", "boss4", "boss5", "boss6", "boss7", "boss8",
    "party1", "party2", "party3", "party4",
}

-- Assumes player, pet, mouseover, focus and target are already watched.  This
-- is slow don't call this very often.

function LiteButtonAurasOverlayMixin:GetTrackedUnits()
    local type = self:GetActionInfo()
    local trackedUnits = {}
    if type == 'macro' then
        local macroName = GetActionText(self:GetActionID())
        local macroBody = GetMacroBody(macroName)
        if macroBody then
            for conditionExpr in macroBody:gmatch('%[(.-)%]') do
                for condition in conditionExpr:gmatch('[^,]+') do
                    local unit
                    if condition:sub(1,1) == '@' then
                       unit = condition:sub(2)
                    elseif condition:sub(1,7) == 'target=' then
                        unit = condition:sub(8)
                    end
                    if unit and tContains(ValidTrackedUnits, unit) then
                        trackedUnits[unit] = true
                    end
               end
            end
        end
    end
    return trackedUnits
end

-- In an ideal world GetActionInfo would return the unit as well. Or there
-- would be a GetActionUnit function. This is a hack to try to figure it
-- out in a limited fashion. If this returns something that's not in
-- self:GetTrackedUnits() we could be in trouble.

function LiteButtonAurasOverlayMixin:GetActionUnit(type, id, subType)

    if type == 'macro' then
        local macroName = GetActionText(self:GetActionID())
        local unit = GetMacroUnit(macroName)
        if unit then
            return unit
        end
    end

    -- From SecureButton_GetModifiedUnit

    local useMouseoverCasting = GetCVarBool('enableMouseoverCast') and
                                (GetModifiedClick('MOUSEOVERCAST') == "NONE" or IsModifiedClick('MOUSEOVERCAST'))

    if useMouseoverCasting and UnitExists('mouseover') then
        local actionID = self:GetActionID()
        local isFriend = UnitIsFriend('player', 'mouseover')
        if isFriend and C_ActionBar.IsHelpfulAction(actionID, true) then
            return 'mouseover'
        elseif not isFriend and C_ActionBar.IsHarmfulAction(actionID, true) then
            return 'mouseover'
        end
    end

    if IsModifiedClick('SELFCAST') then
        return 'player'
    end

    if IsModifiedClick('FOCUSCAST') then
        return 'focus'
    end

    return 'target'
end

-- This could be optimized (?) slightly be checking if type, id, subType
-- are all the same as before and doing nothing

function LiteButtonAurasOverlayMixin:SetUpAction()

    local type, id, subType = self:GetActionInfo()

    self.destUnit = self:GetActionUnit(type, id, subType)

    if type == 'spell' then
        self.name = C_Spell.GetSpellName(id)
        self.spellID = id
        self.type = type
        return
    end

    if type == 'item' then
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

function LiteButtonAurasOverlayMixin:IsIgnoreAbility()
    local p = LBA.db.profile
    if p.ignoreSpells[self.spellID] and p.ignoreSpells[self.spellID].ability == true then
        return true
    end
    return false
end

function LiteButtonAurasOverlayMixin:GetMatchingAura(t)
    if LBA.AuraMap[self.name] then
        for _, extraAuraName in ipairs(LBA.AuraMap[self.name]) do
            if t[extraAuraName] then
                return t[extraAuraName]
            end
        end
    end
    if self:IsIgnoreAbility(t) then
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

        -- It's worth keeping in mind that there are two units per spell, source
        -- and dest. Source is nearly always player.

        if self:IsKnown() then
            local destOk = LBA.state[self.destUnit] ~= nil
            -- These are theoretically in priority order but I haven't put a
            -- lot of thought into it because the overlap cases are super rare.
            if destOk and self:TrySetAsSoothe() then
                show = true
            elseif destOk and self:TrySetAsInterrupt() then
                show = true
            elseif destOk and self:TrySetAsHostileDispel() then
                show = true
            elseif destOk and self:TrySetAsTaunt() then
                show = true
            elseif self:TrySetAsPlayerBuff() then
                show = true
            elseif self:TrySetAsPlayerTotem() then
                show = true
            elseif self:TrySetAsWeaponEnchant() then
                show = true
            elseif destOk and self:TrySetAsDebuff() then
                show = true
            elseif self:TrySetAsPetBuff() then
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

--  auraData = {
--    applications = 0,
--    auraInstanceID = 154047,
--    canApplyAura = true,
--    duration = 3600,
--    expirationTime = 9109.109,
--    icon = 136051,
--    isBossAura = false,
--    isFromPlayerOrPlayerPet = true,
--    isHarmful = false,
--    isHelpful = true,
--    isNameplateOnly = false,
--    isRaid = false,
--    isStealable = false
--    name = "Lightning Shield",
--    nameplateShowAll = false,
--    nameplateShowPersonal = false,
--    points = { },
--    sourceUnit = "player",
--    spellId = 192106,
--    timeMod = 1,
--  }

function LiteButtonAurasOverlayMixin:SetAsAuraCommon(auraData)
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

function LiteButtonAurasOverlayMixin:SetAsPlayerBuff(auraData)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b)
    self:SetAsAuraCommon(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsPlayerBuff()
    local aura = self:GetMatchingAura(LBA.state.player.buffs)
    if aura then
        self:SetAsPlayerBuff(aura)
        return true
    end
end

function LiteButtonAurasOverlayMixin:SetAsPetBuff(auraData)
    local color = LBA.db.profile.color.petBuff
    self.Glow:SetVertexColor(color.r, color.g, color.b)
    self:SetAsAuraCommon(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsPetBuff()
    if LBA.db.profile.playerPetBuffs then
        local aura = self:GetMatchingAura(LBA.state.pet.buffs)
        if aura and aura.sourceUnit == 'player' then
            self:SetAsPetBuff(aura)
            return true
        end
    end
end

function LiteButtonAurasOverlayMixin:SetAsDebuff(auraData)
    local color = LBA.db.profile.color.debuff
    self.Glow:SetVertexColor(color.r, color.g, color.b)
    self:SetAsAuraCommon(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsDebuff()
    local aura = self:GetMatchingAura(LBA.state[self.destUnit].debuffs)
    if aura then
        self:SetAsDebuff(aura)
        return true
    end
end

function LiteButtonAurasOverlayMixin:TrySetAsWeaponEnchant()
    if LBA.state.player.weaponEnchants[self.name] then
        self:SetAsPlayerBuff(LBA.state.player.weaponEnchants[self.name])
        return true
    end
end

-- Totem Config ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsPlayerTotem(expireTime)
    local color = LBA.db.profile.color.buff
    self.Glow:SetVertexColor(color.r, color.g, color.b)
    self.expireTime, self.modTime = expireTime, nil
    self.displayGlow = true
end

function LiteButtonAurasOverlayMixin:TrySetAsPlayerTotem()
    if self:IsIgnoreAbility() or not LBA.db.profile.defaultNameMatching then
        return
    elseif LBA.state.player.totems[self.name] then
        self:SetAsPlayerTotem(LBA.state.player.totems[self.name])
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

function LiteButtonAurasOverlayMixin:TrySetAsInterrupt()
    if self.name and LBA.Interrupts[self.name] then
        if LBA.state[self.destUnit].interrupt then
            local castEnds = LBA.state[self.destUnit].interrupt
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
-- Unused, Soothe is suggestion only now
function LiteButtonAurasOverlayMixin:SetAsSoothe(auraData)
    local color = LBA.db.profile.color.enrage
    self.Glow:SetVertexColor(color.r, color.g, color.b, 0.7)
    self:SetAsAuraCommon(auraData)
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

function LiteButtonAurasOverlayMixin:TrySetAsSoothe()
    if not self:IsSoothe() then return end
    if not UnitCanAttack('player', self.destUnit) then return end

    for _, auraData in pairs(LBA.state[self.destUnit].buffs) do
        if auraData.isStealable and auraData.dispelName == "" and self:ReadyBefore(auraData.expirationTime) then
            self.expireTime = auraData.expirationTime
            self.displaySuggestion = true
            return true
        end
    end
end

-- Taunt Config ----------------------------------------------------------------

function LiteButtonAurasOverlayMixin:TrySetAsTaunt()
    if self.name and LBA.Taunts[self.name] and LBA.state[self.destUnit].taunt then
        self:SetAsDebuff(LBA.state[self.destUnit].taunt)
        return true
    end
end

-- Dispel Config ---------------------------------------------------------------

function LiteButtonAurasOverlayMixin:SetAsHostileDispel(auraData)
    local color = DebuffTypeColor[auraData.dispelName or ""]
    self.Glow:SetVertexColor(color.r, color.g, color.b)
    self:SetAsAuraCommon(auraData)
end

function LiteButtonAurasOverlayMixin:TrySetAsHostileDispel()
    if not self.name then
        return
    end

    if not UnitCanAttack('player', self.destUnit) then
        return
    end

    local dispels = LBA.HostileDispels[self.name]
    if dispels then
        for dispelName in pairs(dispels) do
            for _, auraData in pairs(LBA.state[self.destUnit].buffs) do
                if auraData.dispelName == dispelName then
                    self:SetAsHostileDispel(auraData)
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
