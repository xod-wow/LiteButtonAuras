--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Create overlays for actionbuttons and hook update when they change. Note
    that hooksecurefunc() is kinda slow and should be avoided in cases where
    the actionbutton provides its own hook.

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.BarIntegrations = {}

local C_Item = LBA.C_Item or C_Item
local C_Spell = LBA.C_Spell or C_Spell

local GetActionInfo = GetActionInfo
local HasAction = HasAction

-- Generic ---------------------------------------------------------------------

local function GenericGetActionID(overlay)
    return overlay:GetParent().action
end

local function GenericGetActionInfo(overlay)
    return GetActionInfo(overlay:GetParent().action)
end

local function GenericHasAction(overlay)
    return HasAction(overlay:GetParent().action)
end

local function GenericInitButton(actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay.GetActionID = GenericGetActionID
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
    overlay.GetActionID = GenericGetActionID
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
-- we don't want to handle them.

function LBA.BarIntegrations:RetailInit()
    if WOW_PROJECT_ID ~= 1 then return end
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            GenericInitButton(actionButton)
        end
    end
end


-- Button Forge ----------------------------------------------------------------

-- These are ActionButton but they don't use the action ID they are set up as per
-- SecureActionButtonTemplate with SetAttribute("type", ...) etc.
--
-- The hook here on widget.icon.SetTexture is not exactly kosher but it does work.
-- Hoping the author will add a BUTTON_UPDATE calback hook or similar.

-- Localize for Minor speedup
local ButtonForge_API1

local function ButtonForgeGetActionID(overlay)
    return 0
end

-- Note that this returns the old-style Blizzard GetActionInfo where macro
-- never returns a subType and id is always the macro ID. So it doesn't have the
-- bugs that the new style does with item macros.
-- See LiteButtonAurasOverlayMixin:SetUpAction() where type == "macro"

local function ButtonForgeGetActionInfo(overlay)
    local widget = overlay:GetParent()
    return ButtonForge_API1.GetButtonActionInfo(widget:GetName())
end

-- The buttons are re-used, but it's ok because CreateOverlay checks for that

local function ButtonForgeInitButton(widget)
    local overlay = LiteButtonAurasController:CreateOverlay(widget)
    overlay.GetActionID = ButtonForgeGetActionID
    overlay.GetActionInfo = ButtonForgeGetActionInfo
    overlay.HasAction = ButtonForgeGetActionInfo
    hooksecurefunc(widget.icon, 'SetTexture', function () overlay:Update() end)
end

local function ButtonForgeCallback(_, event, actionButtonName)
    if event == "BUTTON_ALLOCATED" then
        local widget = _G[actionButtonName]
        ButtonForgeInitButton(widget)
    --[[
    -- This would be nicer than hooking .icon.SetTexture if it got implemented.
    elseif event == "BUTTON_UPDATED" then
        local widget = _G[actionButtonName]
        local overlay = LiteButtonAurasController:GetOverlay(widget)
        if overlay then overlay:Update() end
    ]]
    end
end

function LBA.BarIntegrations:ButtonForgeInit()
    ButtonForge_API1 = _G.ButtonForge_API1
    if ButtonForge_API1 then
        ButtonForge_API1.RegisterCallback(ButtonForgeCallback)
    end
end


-- Dominos ---------------------------------------------------------------------

-- On classic Dominos re-uses the Blizzard action buttons and then adds some
-- more of its own. On retail it uses all its own buttons, but they still use
-- the ActionBarButton API enough for us.

function LBA.BarIntegrations:DominosInit()
    local Init = WOW_PROJECT_ID == 1 and GenericInitButton or ClassicInitButton
    if Dominos and not Dominos.BlizzardActionButtons then
        -- "New" dominos with their own buttons
        for actionButton in pairs(Dominos.ActionButtons.buttons) do
            Init(actionButton)
        end
        hooksecurefunc(Dominos.ActionButton, 'OnCreate',
            function (button, id) Init(button) end)
    end
end


-- ActionBarPlus ---------------------------------------------------------------

-- All SecureActionButton without any actionID

-- I'm not 100% convinced about the wisdom of supporting this. The addon is
-- overengineered and still doesn't support basic things like putting a pet
-- action on a button. The code is inscrutable to me and looks like the kind
-- of thing you get when you believe boolean should be a class and have a
-- BooleanFactory to create one. But this does seem to work.

local function ABPGetActionID(overlay)
    return 0
end

local function ABPGetActionInfo(overlay)
    local button = overlay:GetParent()
    local type = button:GetAttribute("type")
    if type == 'spell' then
        local spell = button:GetAttribute('spell')
        local info = C_Spell.GetSpellInfo(spell)
        if info then return type, info.spellID end
    elseif type == 'macro' then
        local id = button:GetAttribute('macro')
        if id then return type, id end
    elseif type == 'item' then
        local item = button:GetAttribute('item')
        local id = C_Item.GetItemInfoInstant(item)
        if id then return type, id end
    end
end

local function ABPHasAction(overlay)
    local button = overlay:GetParent()
    return not button.widget:IsEmpty()
end

local function ABPInitButton(actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay:SetFrameLevel(actionButton.widget.cooldown():GetFrameLevel() + 1)

    overlay.GetActionID = ABPGetActionID
    overlay.GetActionInfo = ABPGetActionInfo
    overlay.HasAction = ABPHasAction

    if not overlay.isHooked then
        actionButton:HookScript('OnAttributeChanged', function () overlay:Update() end)
        hooksecurefunc(actionButton.widget, 'UpdateMacroState', function () overlay:Update() end)
        overlay.isHooked = true
    end
end

local function ABPInitFrameWidget(actionBar)
    for _, actionButton in ipairs(actionBar.buttonFrames) do
        ABPInitButton(actionButton)
    end
end

function LBA.BarIntegrations:ActionbarPlusInit()
    if ABP_NS then
        for _, actionBar in ipairs(ABP_NS.O.ButtonFactory.FRAMES) do
            ABPInitFrameWidget(actionBar)
        end
        hooksecurefunc(ABP_NS.O.ButtonFactory, 'CreateButtons',
            function (self, fw, rowSize, colSize)
                ABPInitFrameWidget(fw)
            end)
    end
end


-- LibActionButton-1.0 and derivatives -----------------------------------------

-- Covers ElvUI, Bartender. TukUI reuses the Blizzard buttons

local function LABGetActionID(overlay)
    local actionType, action = overlay:GetParent():GetAction()
    if actionType == "action" then
        return action
    end
end

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
    overlay.GetActionID = LABGetActionID
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
    self:ButtonForgeInit()
    self:LABInit()
    self:ActionbarPlusInit()
end
