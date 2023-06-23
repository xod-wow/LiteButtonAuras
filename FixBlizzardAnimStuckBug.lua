--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2023 Mike "Xodiv" Battersby

    Fix Blizzard's dumb anim bug in Dragonflight retail where the spell
    alert overlay gets stuck if it reactivates while the animOut is playing
    because they didn't understand what they were doing.

----------------------------------------------------------------------------]]--

if WOW_PROJECT_ID == 1 then

    local function FixBlizzardAnimStuckBug(actionButton)
        local saa = actionButton.SpellActivationAlert
        if not saa.animIn:GetScript('OnStop') then
            saa.animIn:SetScript('OnStop', saa.animIn:GetScript('OnFinished'))
            saa.animOut:SetScript('OnStop', saa.animOut:GetScript('OnFinished'))
        end
    end

    hooksecurefunc('ActionButton_SetupOverlayGlow', FixBlizzardAnimStuckBug)

end
