--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.BarIntegrations = {}

-- Blizzard --------------------------------------------------------------------

-- The OverrideActionButtons have the same action (ID) as the main buttons and
-- mess up framesByAction (as well as we don't want to handle them)

local function InitBlizzard()
    for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
        if actionButton:GetName():sub(1,8) ~= 'Override' then
            local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
            overlay:Hook(actionButton, 'UpdateAction')
            overlay:ScanAction()
        end
    end
end


-- Dominos ---------------------------------------------------------------------

local function InitDominos()
    for _, actionButton in pairs(Dominos.ActionButtons) do
        local overlay = LiteButtonAurasController:CreateOverlay(actionButton)
        overlay:Hook(actionButton, 'UpdateAction')
        overlay:ScanAction()
    end
end

local function InitDominos()
    if Dominos then
        Dominos.RegisterCallback(self, 'LAYOUT_LOADED', InitDominos)
    end
end


-- Init ------------------------------------------------------------------------

function LBA.BarIntegrations:Initialize()
    InitBlizzard()
    InitDominos()
end

