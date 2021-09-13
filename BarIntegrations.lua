--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.BarIntegrations = {}

-- Generic ---------------------------------------------------------------------

local function InitGenericButton(actionButton)
    local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
    overlay:Hook(actionButton, 'Update')
end


-- Blizzard --------------------------------------------------------------------

-- The OverrideActionButtons have the same action (ID) as the main buttons and
-- mess up framesByAction (as well as we don't want to handle them)

function LBA.BarIntegrations:InitBlizzard()
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            InitGenericButton(actionButton)
        end
    end
end


-- Dominos ---------------------------------------------------------------------

local function InitDominosCallback()
    for _, actionButton in pairs(Dominos.ActionButtons) do
        InitGenericButton(actionButton)
    end
end

function LBA.BarIntegrations:InitDominos()
    if Dominos then
        Dominos.RegisterCallback(self, 'LAYOUT_LOADED', InitDominosCallback)
    end
end


-- LibActionButton-1.0 and derivatives -----------------------------------------

-- Covers ElvUI, Bartender. TukUI reuses the Blizzard buttons

local function InitLABCallback(lib)
    for actionButton in lib:GetAllButtons() do
        InitGenericButton(actionButton)
    end
end

function LBA.BarIntegrations:InitLAB()
    for name, lib in LibStub:IterateLibraries() do
        if name:match('^LibActionButton-1.0') then
            InitLABCallback(lib)
            hooksecurefunc(lib, 'CreateButton',
                function () InitLABCallback(lib) end)
        end
    end
end

-- Init ------------------------------------------------------------------------

function LBA.BarIntegrations:Initialize()
    self:InitBlizzard()
    self:InitDominos()
    self:InitLAB()
end
