--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    For better or worse, try to back-port a minimal amount of compatibility
    for the 11.0 rework into classic, on the assumption that it will eventually
    go in there properly and this is the right approach rather than making the
    new way look like the old.

----------------------------------------------------------------------------]]--

local _, LBA = ...

-- AuraUtil --------------------------------------------------------------------

-- Classic doesn't have ForEachAura even though it has AuraUtil.

LBA.AuraUtil = CopyTable(AuraUtil or {})

if not AuraUtil.ForEachAura then

    function LBA.AuraUtil.ForEachAura(unit, filter, maxCount, func, usePackedAura)
        local i = 1
        while true do
            if maxCount and i > maxCount then
                return
            end
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if auraData == nil then
                return
            end
            if usePackedAura then
                func(auraData)
            else
                func(AuraUtil.UnpackAuraData(auraData))
            end
            i = i + 1
        end
    end

end
