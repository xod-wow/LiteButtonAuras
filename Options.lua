--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

local defaults = {
    global = {
    },
    profile = {
        denySpells = {
            [116]       = true, -- Frostbolt (Mage)
            [152175]    = true, -- Whirling Dragon Punch (Monk)
            [190356]    = true, -- Blizzard (Mage)
        },
        auraMap = { },
        color = {
            buff    = { r=0.00, g=0.70, b=0.00 },
            debuff  = { r=1.00, g=0.00, b=0.00 },
            enrage  = { r=1.00, g=0.25, b=0.00 }, -- unused
        },
        glowAlpha = 0.5,
        minAuraDuration = 1.5,
        showTimers = true,
        showStacks = false,
        showSuggestions = true,
        colorTimers = true,
        decimalTimers = true,
        fontPath = NumberFontNormal:GetFont(),
        fontSize = math.floor(select(2, NumberFontNormal:GetFont()) + 0.5),
        fontFlags = select(3, NumberFontNormal:GetFont()),
    },
    char = {
    },
}

local function IsTrue(x)
    if x == nil or x == false or x == "0" or x == "off" or x == "false" then
        return false
    else
        return true
    end
end


function LBA.InitializeOptions()
    LBA.db = LibStub("AceDB-3.0"):New("LiteButtonAurasDB", defaults, true)
    -- Migrations
    for _, p in pairs(LBA.db.profiles) do
        if p.font then
            if type(p.font) == 'string' then
                if _G[p.font] and _G[p.font].GetFont then
                    p.fontPath, p.fontSize, p.fontFlags = _G[p.font]:GetFont()
                    p.fontSize = math.floor(p.fontSize + 0.5)
                end
            elseif type(p.font) == 'table' then
                p.fontPath, p.fontSize, p.fontFlags = unpack(p.font)
                p.fontSize = math.floor(p.fontSize + 0.5)
            end
            p.font = nil
        end
    end
end

function LBA.SetOption(option, value, key)
    key = key or "profile"
    if not defaults[key] then return end
    if value == "default" or value == DEFAULT:lower() or value == nil then
        value = defaults[key][option]
    end
    if type(defaults[key][option]) == 'boolean' then
        LBA.db[key][option] = IsTrue(value)
    elseif type(defaults[key][option]) == 'number' then
        LBA.db[key][option] = tonumber(value)
    else
        LBA.db[key][option] = value
    end
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.AddAuraMap(auraSpell, abilitySpell)
    if LBA.db.profile.auraMap[auraSpell] then
        table.insert(LBA.db.profile.auraMap[auraSpell], abilitySpell)
    else
        LBA.db.profile.auraMap[auraSpell] = { abilitySpell }
    end
    tDeleteItem(LBA.db.profile.auraMap, false)
    LBA.UpdateAuraMap()
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.RemoveAuraMap(auraSpell, abilitySpell)
    if not LBA.db.profile.auraMap[auraSpell] then return end

    tDeleteItem(LBA.db.profile.auraMap[auraSpell], abilitySpell)

    if next(LBA.db.profile.auraMap[auraSpell]) == nil then
        if not defaults.profile.auraMap[auraSpell] then
            LBA.db.profile.auraMap[auraSpell] = nil
        else
            LBA.db.profile.auraMap[auraSpell] = { false }
        end
    end
    LBA.UpdateAuraMap()
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.DefaultAuraMap()
    LBA.db.profile.auraMap = CopyTable(defaults.profile.auraMap)
    LBA.UpdateAuraMap()
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.WipeAuraMap()
    table.wipe(LBA.db.profile.auraMap)
    for n in pairs(defaults.profile.auraMap) do
        LBA.db.profile.auraMap[n] = { false }
    end
    LBA.UpdateAuraMap()
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.AddDenySpell(auraID)
    LBA.db.profile.denySpells[auraID] = true
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.RemoveDenySpell(auraID)
    LBA.db.profile.denySpells[auraID] = nil
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.DefaultDenySpells()
    LBA.db.profile.denySpells = CopyTable(defaults.profile.denySpells)
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.WipeDenySpells()
    table.wipe(LBA.db.profile.denySpells)
    LBA.db.callbacks:Fire("OnModified")
end

function LBA.AuraMapString(aura, auraName, ability, abilityName)
    local c = NORMAL_FONT_COLOR
    return format(
                "%s %d on %s %d",
                c:WrapTextInColorCode(auraName),
                aura,
                c:WrapTextInColorCode(abilityName),
                ability
            )
end

function LBA.GetAuraMapList()
    local out = { }
    for aura, abilityTable in pairs(LBA.db.profile.auraMap) do
        for _, ability in ipairs(abilityTable) do
            if ability then -- false indicates default override
                local auraName = GetSpellInfo(aura)
                local abilityName = GetSpellInfo(ability)
                if auraName and abilityName then
                    table.insert(out, { aura, auraName, ability, abilityName })
                end
            end
        end
    end
    sort(out, function (a, b) return a[2] < b[2] end)
    return out
end
