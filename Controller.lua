--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    This is the event handler and state updater. Watches for the buffs and
    updates LBA.state, then calls overlay:Update() on all actionbutton overlays
    when required.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

local L = LBA.L

local AlwaysTrackedUnits = {
    focus = true,
    mouseover = true,
    pet = true,
    player = true,
    target = true,
}

LBA.state = {}


--[[------------------------------------------------------------------------]]--

-- Cache some things to be faster. This is annoying but it's really a lot
-- faster. Only do this for things that are called in the event loop otherwise
-- it's just a pain to maintain.

local UnitIsUnit = UnitIsUnit
local WOW_PROJECT_ID = WOW_PROJECT_ID

--[[------------------------------------------------------------------------]]--

-- Load and set up dependencies for Masque support. Because we make our own
-- frame and don't touch the ActionButton itself (avoids a LOT of taint issues)
-- we have to make our own masque group. It's a bit weird because it lets  you
-- style LBA differently from the ActionButton, but it's the simplest way.

-- local Masque = LibStub('Masque', true)


--[[------------------------------------------------------------------------]]--

LiteButtonAurasControllerMixin = {}

function LiteButtonAurasControllerMixin:OnLoad()
    self.overlayFrames = {}
    self:RegisterEvent('PLAYER_LOGIN')
end

function LiteButtonAurasControllerMixin:Initialize()

    LBA.InitializeOptions()
    LBA.InitializeGUIOptions()
    LBA.SetupSlashCommand()
    LBA.UpdateAuraMap()

    LBA.BarIntegrations:Initialize()
    self:UpdateTrackedUnitList()

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('PLAYER_TOTEM_UPDATE')
    if WOW_PROJECT_ID == 1 then
        self:RegisterEvent('WEAPON_ENCHANT_CHANGED')
        self:RegisterEvent('WEAPON_SLOT_CHANGED')
    end

    -- These are for noticing that the unit changed
    self:RegisterEvent('INSTANCE_ENCOUNTER_ENGAGE_UNIT')    -- @bossN
    self:RegisterEvent('ARENA_OPPONENT_UPDATE')             -- @arenaN
    self:RegisterEvent('GROUP_ROSTER_UPDATE')               -- @partyN
    self:RegisterEvent('PLAYER_TARGET_CHANGED')             -- @target
    self:RegisterEvent('PLAYER_FOCUS_CHANGED')              -- @focus
    self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')             -- @mouseover

    -- All of these are for the interrupt and player channel detection
    self:RegisterEvent('UNIT_SPELLCAST_START')
    self:RegisterEvent('UNIT_SPELLCAST_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_FAILED')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE')
    self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE')

    -- At init time C_Item.GetItemSpell might not work because they are not
    -- in the cache. I think the actionbar will keep them in the cache the rest
    -- of the time. Mark overlays as dirty when item results come in (overkill
    -- but easier than tracking our itemIDs and rare enough).
    self:RegisterEvent('ITEM_DATA_LOAD_RESULT')

    -- These are for tracking that we need to rescan the current overlays to
    -- find what extra units we are tracking.
    self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
    self:RegisterEvent('UPDATE_MACROS')

    -- Need to track modifier key state for mouseover/focus/self cast modifiers
    self:RegisterEvent('MODIFIER_STATE_CHANGED')

    LBA.db.RegisterCallback(self, 'OnModified', 'StyleAllOverlays')
end

function LiteButtonAurasControllerMixin:CreateOverlay(actionButton)
    if not self.overlayFrames[actionButton] then
        local name = actionButton:GetName() .. "LiteButtonAurasOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "LiteButtonAurasOverlayTemplate")
        self.overlayFrames[actionButton] = overlay
    end
    return self.overlayFrames[actionButton]
end

function LiteButtonAurasControllerMixin:GetOverlay(actionButton)
    return self.overlayFrames[actionButton]
end

function LiteButtonAurasControllerMixin:UpdateAllOverlays(stateOnly)
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Update(stateOnly)
    end
end

-- Triggered when the style options change in the DB
function LiteButtonAurasControllerMixin:StyleAllOverlays()
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Style()
        overlay:Update()
    end
end

function LiteButtonAurasControllerMixin:DumpAllOverlays()
    self:UpdateAllOverlays()
    local sortedOverlays = GetValuesArray(self.overlayFrames)
    table.sort(sortedOverlays, function (a, b) return a:GetActionID() < b:GetActionID() end)
    for _, overlay in pairs(sortedOverlays) do
        overlay:Dump()
    end
end

function LiteButtonAurasControllerMixin:UpdateTrackedUnitList()
    self.trackedUnitList = CopyTable(AlwaysTrackedUnits)
    for _, overlay in pairs(self.overlayFrames) do
        Mixin(self.trackedUnitList, overlay:GetTrackedUnits())
    end
    local newState = {}
    for unit in pairs(self.trackedUnitList) do
        newState[unit] = LBA.state[unit] or LBA.UnitState:Create(unit)
    end
    LBA.state = newState
end


--[[------------------------------------------------------------------------]]--

function LiteButtonAurasControllerMixin:MarkOverlaysDirty(stateOnly)
    -- Tri-state encodes stateOnly : nil / true / false
    self.isOverlayDirty = ( stateOnly == true and self.isOverlayDirty ~= false )
end

-- Limit UNIT_AURA and UNIT_SPELLCAST overlay updates to one per frame
function LiteButtonAurasControllerMixin:OnUpdate()
    if self.isOverlayDirty ~= nil then
        self:UpdateAllOverlays(self.isOverlayDirty)
        self.isOverlayDirty = nil
    end
end

function LiteButtonAurasControllerMixin:IsTrackedUnit(unit)
    return self.trackedUnitList[unit] == true
end

function LiteButtonAurasControllerMixin:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
        self:UnregisterEvent('PLAYER_LOGIN')
        self:MarkOverlaysDirty()
    elseif event == 'PLAYER_ENTERING_WORLD' then
        self:UpdateTrackedUnitList()
        for unit in pairs(self.trackedUnitList) do
            LBA.state[unit]:UpdateAuras()
            LBA.state[unit]:UpdateInterrupt()
        end
        LBA.state.player:UpdateWeaponEnchants()
        LBA.state.player:UpdateChannel()
        LBA.state.player:UpdateTotems()
        self:MarkOverlaysDirty()
    elseif event == 'PLAYER_TARGET_CHANGED' then
        LBA.state.target:UpdateAuras()
        LBA.state.target:UpdateInterrupt()
        self:MarkOverlaysDirty(true)
    elseif event == 'PLAYER_FOCUS_CHANGED' then
        if self:IsTrackedUnit('focus') then
            LBA.state.focus:UpdateAuras()
            LBA.state.focus:UpdateInterrupt()
            self:MarkOverlaysDirty(true)
        end
    elseif event == 'UPDATE_MOUSEOVER_UNIT' then
        if self:IsTrackedUnit('mouseover') then
            LBA.state.mouseover:UpdateAuras()
            LBA.state.mouseover:UpdateInterrupt()
            self:MarkOverlaysDirty(true)
        end
    elseif event == 'GROUP_ROSTER_UPDATE' then
        for i = 1, GetNumGroupMembers() do
            local unit = "party"..i
            if self:IsTrackedUnit(unit) then
                LBA.state[unit]:UpdateAuras()
                LBA.state[unit]:UpdateInterrupt()
                self:MarkOverlaysDirty(true)
            end
        end
    elseif event == 'INSTANCE_ENCOUNTER_ENGAGE_UNIT' then
        for i = 1, MAX_BOSS_FRAMES do
            local unit = "boss"..i
            if self:IsTrackedUnit(unit) then
                LBA.state[unit]:UpdateAuras()
                LBA.state[unit]:UpdateInterrupt()
                self:MarkOverlaysDirty(true)
            end
        end
    elseif event == 'ARENA_OPPONENT_UPDATE' then
        for i = 1, GetNumArenaOpponents() do
            local unit = "arena"..i
            if self:IsTrackedUnit(unit) then
                LBA.state[unit]:UpdateAuras()
                LBA.state[unit]:UpdateInterrupt()
                self:MarkOverlaysDirty(true)
            end
        end
    elseif event == 'UNIT_AURA' then
        -- This fires a lot. Be careful. In DF, UNIT_AURA seems to tick every
        -- second for 'player' with no updates
        local unit, unitAuraUpdateInfo = ...
        if self:IsTrackedUnit(unit) then
            LBA.state[unit]:UpdateAuras(unitAuraUpdateInfo)
            -- Shouldn't be needed but weapon enchant duration is returned
            -- wrongly as 0 at PLAYER_LOGIN. This is how Blizzard works around
            -- it too. Their server code must be a nightmare.
            if unit == 'player' then
                LBA.state.player:UpdateWeaponEnchants()
            end
            self:MarkOverlaysDirty(true)
        end
        -- There are no separate UNIT_AURA events for mouseover (there are for
        -- focus though).
        if UnitIsUnit(unit, 'mouseover') and self:IsTrackedUnit('mouseover') then
            LBA.state.mouseover:UpdateAuras(unitAuraUpdateInfo)
            self:MarkOverlaysDirty(true)
        end
    elseif event == 'PLAYER_TOTEM_UPDATE' then
        LBA.state.player:UpdateTotems()
        self:MarkOverlaysDirty(true)
    elseif event == 'WEAPON_ENCHANT_CHANGED' or event == 'WEAPON_SLOT_CHANGED' then
        LBA.state.player:UpdateWeaponEnchants()
        self:MarkOverlaysDirty(true)
    elseif event:sub(1, 14) == 'UNIT_SPELLCAST' then
        -- This fires a lot too, same applies as UNIT_AURA.
        local unit = ...
        if unit == 'player' then
            LBA.state.player:UpdateChannel()
            self:MarkOverlaysDirty(true)
        else
            if self:IsTrackedUnit(unit) then
                LBA.state[unit]:UpdateInterrupt()
                self:MarkOverlaysDirty(true)
            end
            if UnitIsUnit(unit, 'mouseover') and self:IsTrackedUnit('mouseover') then
                LBA.state.mouseover:UpdateInterrupt()
                self:MarkOverlaysDirty(true)
            end
        end
    elseif event == 'ITEM_DATA_LOAD_RESULT' then
        self:MarkOverlaysDirty()
    elseif event == 'ACTIONBAR_SLOT_CHANGED' or event == 'UPDATE_MACROS' then
        self:UpdateTrackedUnitList()
        for unit in pairs(self.trackedUnitList) do
            LBA.state[unit]:UpdateAuras()
            LBA.state[unit]:UpdateInterrupt()
            self:MarkOverlaysDirty()
        end
    elseif event == 'MODIFIER_STATE_CHANGED' then
        local key = select(1, ...):sub(2)
        if key == GetModifiedClick('MOUSEOVERCAST') then
            LBA.state.mouseover:UpdateAuras()
            LBA.state.mouseover:UpdateInterrupt()
            self:MarkOverlaysDirty(true)
        elseif key == GetModifiedClick('FOCUSCAST') then
            LBA.state.focus:UpdateAuras()
            LBA.state.focus:UpdateInterrupt()
            self:MarkOverlaysDirty(true)
        end
    end
end
