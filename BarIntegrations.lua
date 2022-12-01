--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Create overlays for actionbuttons and hook update when they change. Note
    that hooksecurefunc() is kinda slow and should be avoided in cases where
    the actionbutton provides its own hook.

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.BarIntegrations = {}

local GetActionInfo = GetActionInfo

-- Generic ---------------------------------------------------------------------

local function GenericGetActionInfo(overlay)
    return GetActionInfo(overlay:GetParent().action)
end

local function GenericHasAction(overlay)
    return HasAction(overlay:GetParent().action)
end

local function GenericInitButton(actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay.GetActionInfo = GenericGetActionInfo
    overlay.HasAction = GenericHasAction

    if not overlay.isHooked then
        hooksecurefunc(actionButton, 'Update', function () overlay:Update() end)
        overlay.isHooked = true
    end
end

-- Blizzard Classic ------------------------------------------------------------

-- Classic doesn't have an 'Update' method on the ActionButtons to hook
-- so we have to hook the global function ActionButton_Update

local function ClassicButtonUpdate(actionButton)
    local overlay = LiteButtonAurasController:GetOverlay(actionButton)
    if overlay then overlay:Update() end
end

local function ClassicInitButton(actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay.GetActionInfo = GenericGetActionInfo
    overlay.HasAction = GenericHasAction
end

function LBA.BarIntegrations:ClassicInit()
    if WOW_PROJECT_ID == 1 then return end
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            ClassicInitButton(actionButton)
        end
    end
    hooksecurefunc('ActionButton_Update', ClassicButtonUpdate)
end

-- Blizzard Retail -------------------------------------------------------------

-- The OverrideActionButtons have the same action (ID) as the main buttons and
-- mess up framesByAction (as well as we don't want to handle them)

function LBA.BarIntegrations:RetailInit()
    if WOW_PROJECT_ID ~= 1 then return end
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            GenericInitButton(actionButton)
        end
    end
end


-- Dominos ---------------------------------------------------------------------

local function DominosInitCallback()
    for _, actionButton in pairs(Dominos.ActionButtons) do
        GenericInitButton(actionButton)
    end
end

function LBA.BarIntegrations:DominosInit()
    if Dominos then
        Dominos.RegisterCallback(self, 'LAYOUT_LOADED', DominosInitCallback)
    end
end


-- LibActionButton-1.0 and derivatives -----------------------------------------

-- Covers ElvUI, Bartender. TukUI reuses the Blizzard buttons

local function LABGetActionInfo(overlay)
    local actionType, action = overlay:GetParent():GetAction()
    if actionType == "action" then
        return GetActionInfo(action)
    else
        return actionType, action
    end
end

local function LABHasAction(overlay)
    local actionType, action = overlay:GetParent():GetAction()
    if actionType == "action" then
        return HasAction(action)
    end
end

local function LABInitButton(event, actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay.GetActionInfo = LABGetActionInfo
    overlay.HasAction = LABHasAction
    overlay:Update()
end

-- LAB doesn't fire OnButtonCreated until the end of CreateButton but
-- fires OnButtonUpdate in the middle, so we get Update before Create,
-- hence the "if".

local function LABButtonUpdate(event, actionButton)
    local overlay = LiteButtonAurasController:GetOverlay(actionButton)
    if overlay then overlay:Update() end
end

-- As far as I can tell there aren't any buttons at load time but just
-- in case.

local function LABInitAllButtons(lib)
    for actionButton in pairs(lib:GetAllButtons()) do
        LABInitButton(nil, actionButton)
    end
end

-- The %- here is a literal - instead of "zero or more repetitions". A
-- few addons (most noteably ElvUI) use their own private version of
-- LibActionButton with a suffix added to the name.

function LBA.BarIntegrations:LABInit()
    for name, lib in LibStub:IterateLibraries() do
        if name:match('^LibActionButton%-1.0') then
            LABInitAllButtons(lib)
            lib.RegisterCallback(self, 'OnButtonCreated', LABInitButton)
            lib.RegisterCallback(self, 'OnButtonUpdate', LABButtonUpdate)
        end
    end
end

-- Init ------------------------------------------------------------------------

function LBA.BarIntegrations:Initialize()
    self:RetailInit()
    self:ClassicInit()
    self:DominosInit()
    self:LABInit()
end
