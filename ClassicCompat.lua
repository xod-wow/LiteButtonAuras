--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    For better or worse, try to back-port a minimal amount of compatibility
    for the 11.0 rework into classic, on the assumption that it will eventually
    go in there properly and this is the right approach rather than making the
    new way look like the old.

----------------------------------------------------------------------------]]--

local _, LBA = ...


-- C_Spell ---------------------------------------------------------------------

LBA.C_Spell = CopyTable(C_Spell or {})

if not LBA.C_Spell.GetSpellInfo then
    local GetSpellInfo = _G.GetSpellInfo

    function LBA.C_Spell.GetSpellInfo(spellIdentifier)
        local name, _, iconID, castTime, minRange, maxRange, spellID, originalIconID = GetSpellInfo(spellIdentifier)
        if name then
            return {
                name = name,
                iconID = iconID,
                originalIconID = originalIconID,
                castTime = castTime,
                minRange = minRange,
                maxRange = maxRange,
                spellID = spellID,
            }
        end
    end
end

if not LBA.C_Spell.GetSpellName then
    local GetSpellInfo = _G.GetSpellInfo

    function LBA.C_Spell.GetSpellName(spellIdentifier)
        local name = GetSpellInfo(spellIdentifier)
        return name
    end
end

if not LBA.C_Spell.GetSpellTexture then
    local GetSpellInfo = _G.GetSpellInfo

    function LBA.C_Spell.GetSpellTexture(spellIdentifier)
        local _, _, iconID = GetSpellInfo(spellIdentifier)
        return iconID
    end
end

if not LBA.C_Spell.GetSpellCooldown then
    local GetSpellCooldown = _G.GetSpellCooldown

    function LBA.C_Spell.GetSpellCooldown(spellIdentifier)
        local startTime, duration, isEnabled, modRate = GetSpellCooldown(spellIdentifier)
        if startTime then
            return {
                startTime = startTime,
                duration = duration,
                isEnabled = isEnabled,
                modRate = modRate,
            }
        end
    end
end


-- C_Item ----------------------------------------------------------------------

LBA.C_Item = CopyTable(C_Item or {})

if not LBA.C_Item.GetItemInfoInstant then
    LBA.C_Item.GetItemInfoInstant = _G.GetItemInfoInstant
end

if not LBA.C_Item.GetItemSpell then
    LBA.C_Item.GetItemSpell = _G.GetItemSpell
end


-- AuraUtil --------------------------------------------------------------------

-- Classic doesn't have ForEachAura even though it has AuraUtil.

LBA.AuraUtil = CopyTable(AuraUtil or {})

if not AuraUtil.ForEachAura then

    local UnitAura = _G.UnitAura

    -- Turn the UnitAura returns into a facsimile of the UnitAuraInfo struct
    -- returned by C_UnitAuras.GetAuraDataBySlot(unit, slot)

    local auraInstanceID = 0

    local function UnitAuraData(unit, i, filter)
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(unit, i, filter)

        local isHarmful = filter:find('HARMFUL') and true or false
        local isHelpful = filter:find('HELPFUL') and true or false

        auraInstanceID = auraInstanceID + 1
        return {
            applications = count,
            auraInstanceID = auraInstanceID,
            canApplyAura = canApplyAura,
            -- charges = ,
            dispelName = dispelType,
            duration = duration,
            expirationTime = expirationTime,
            icon = icon,
            isBossAura = isBossDebuff,
            isFromPlayerOrPlayerPet = castByPlayer, -- player = me vs player = a player?
            isHarmful = isHarmful,
            isHelpful = isHelpful,
            -- isNameplateOnly =
            -- isRaid =
            isStealable = isStealable,
            -- maxCharges =
            name = name,
            nameplateShowAll = nameplateShowAll,
            nameplateShowPersonal = nameplateShowPersonal,
            -- points =
            sourceUnit = source,
            spellId = spellId,
            timeMod = timeMod,
        }
    end

    function LBA.AuraUtil.ForEachAura(unit, filter, maxCount, func, usePackedAura)
        local i = 1
        while true do
            if maxCount and i > maxCount then
                return
            elseif UnitAura(unit, i, filter) then
                if usePackedAura then
                    func(UnitAuraData(unit, i, filter))
                else
                    func(UnitAura(unit, i, filter))
                end
            else
                return
            end
            i = i + 1
        end
    end

end
