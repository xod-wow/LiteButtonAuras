--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local L = LBA.L

local C_Spell = LBA.C_Spell or C_Spell

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local fontPath, fontSize, fontFlags = NumberFontNormal:GetFont()

local defaultAdjust = ( WOW_PROJECT_ID == 1 and 5 or 2 )

local defaults = {
    global = {
    },
    profile = {
        defaultNameMatching = true,
        playerPetBuffs = true,
        ignoreSpells = {
            --            { ability = true, player = true, unit = true }
            [59638]     = { unit = true },      -- Frostbolt (Mage Pet)
            [152175]    = { ability = true },   -- Whirling Dragon Punch (Monk)
            [190356]    = { ability = true },   -- Blizzard (Mage)
            [425782]    = { ability = true },   -- Second Wind (Warrior passive / Skyriding)
        },
        appliedAuraSpells = { },
        auraMap = { },
        color = {
            buff        = { r=0.00, g=0.70, b=0.00 },
            petBuff     = { r=0.00, g=0.00, b=0.70 },
            debuff      = { r=1.00, g=0.00, b=0.00 },
            appliedBuff = { r=0.00, g=0.70, b=0.00 },
        },
        glowTexture = [[Interface\Addons\LiteButtonAuras\Textures\Overlay]],
        glowUseMasque = true,
        glowAlpha = 0.5,
        minAuraDuration = 1.5,
        showTimers = true,
        showStacks = true,
        showSuggestions = true,
        colorTimers = true,
        decimalTimers = true,
        timerAnchor = "BOTTOMLEFT",
        timerAdjust = defaultAdjust,
        stacksAnchor = "TOPLEFT",
        stacksAdjust = defaultAdjust,
        fontPath = fontPath,
        fontSize = math.floor(fontSize + 0.5),
        fontFlags = fontFlags,
    },
    char = {
    },
}

LBA.anchorSettings = {
    TOPLEFT     = { "TOPLEFT",       1, -1,     "LEFT" },
    TOP         = { "TOP",           0, -1,     "CENTER" },
    TOPRIGHT    = { "TOPRIGHT",     -1, -1,     "RIGHT" },
    LEFT        = { "LEFT",          1,  0,     "LEFT", },
    CENTER      = { "CENTER",        0,  0,     "CENTER" },
    RIGHT       = { "RIGHT",        -1,  0,     "RIGHT" },
    BOTTOMLEFT  = { "BOTTOMLEFT",    1,  1,     "LEFT" },
    BOTTOM      = { "BOTTOM",        0,  1,     "CENTER" },
    BOTTOMRIGHT = { "BOTTOMRIGHT",  -1,  1,     "RIGHT" },
}

local function IsTrue(x)
    if x == nil or x == false or x == "0" or x == "off" or x == "false" then
        return false
    else
        return true
    end
end

local function MigrateOptions(sv)
    if sv == nil then return end

    for n,p in pairs(sv.profiles) do
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
        if p.denySpells then
            p.ignoreSpells = p.ignoreSpells or {}
            for spellID in pairs(p.denySpells) do
                p.ignoreSpells[spellID] = { ability = true }
            end
            p.denySpells = nil
        end
    end
end

function LBA.InitializeOptions()
    MigrateOptions(LiteButtonAurasDB)
    LBA.db = LibStub("AceDB-3.0"):New("LiteButtonAurasDB", defaults, true)
    -- Profile change hooks, would be needed to change profiles outside gui
    --[[
    local function notify () AceConfigRegistry:NotifyChange(addonName) end
    LBA.db.RegisterCallback(LBA, "OnProfileChanged", notify)
    LBA.db.RegisterCallback(LBA, "OnProfileCopied", notify)
    LBA.db.RegisterCallback(LBA, "OnProfileReset", notify
    ]]
end

local function GetPathOption(t, option)
    local keys = { string.split('.', option) }
    local current = t
    for i, k in ipairs(keys) do
        if i == #keys then
            return current[k]
        elseif type(current[k]) == 'table' then
            current = current[k]
        else
            return
        end
    end
end

local function SetPathOption(t, option, val)
    local keys = { string.split('.', option) }
    for i, k in ipairs(keys) do
        if i == #keys then
            t[k] = val
            return
        else
            t[k] = t[k] or {}
            t = t[k]
        end
    end
end

function LBA.GetOption(option, key)
    key = key or "profile"
    return GetPathOption(LBA.db[key], option)
end

function LBA.SetOption(option, value, key)
    key = key or "profile"
    if not defaults[key] then return end
    local defaultVal = GetPathOption(defaults[key], option)
    if value == "default" or value == DEFAULT:lower() or value == nil then
        value = defaultVal
    end
    if type(defaultVal) == 'boolean' then
        SetPathOption(LBA.db[key], option, IsTrue(value))
    elseif type(defaults[key][option]) == 'number' then
        if tonumber(value) then
            SetPathOption(LBA.db[key], option, tonumber(value))
        end
    elseif LBA.anchorSettings[defaultVal] then
        if LBA.anchorSettings[value] then
            SetPathOption(LBA.db[key], option, value)
        end
    else
        SetPathOption(LBA.db[key], option, value)
    end
    LBA.db.callbacks:Fire('OnModified')
end

function LBA.SetOptionOutsideUI(option, value, key)
    LBA.SetOption(option, value, key)
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.AddAuraMap(auraSpell, abilitySpell)
    auraSpell = tonumber(auraSpell) or auraSpell
    abilitySpell = tonumber(abilitySpell) or abilitySpell

    if LBA.db.profile.auraMap[auraSpell] then
        table.insert(LBA.db.profile.auraMap[auraSpell], abilitySpell)
    else
        LBA.db.profile.auraMap[auraSpell] = { abilitySpell }
    end
    LBA.UpdateAuraMap()
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.RemoveAuraMap(auraSpell, abilitySpell)
    auraSpell = tonumber(auraSpell) or auraSpell
    abilitySpell = tonumber(abilitySpell) or abilitySpell
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
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.DefaultAuraMap()
    LBA.db.profile.auraMap = CopyTable(defaults.profile.auraMap)
    LBA.UpdateAuraMap()
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.WipeAuraMap()
    LBA.db.profile.auraMap = {}
    LBA.UpdateAuraMap()
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.SetIgnoreSpell(spellID, data)
    LBA.db.profile.ignoreSpells[spellID] = data
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.RemoveIgnoreSpell(spellID)
    LBA.db.profile.ignoreSpells[spellID] = nil
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.DefaultIgnoreSpells()
    LBA.db.profile.ignoreSpells = CopyTable(defaults.profile.ignoreSpells)
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.WipeIgnoreSpells()
    table.wipe(LBA.db.profile.ignoreSpells)
    AceConfigRegistry:NotifyChange(addonName)
end

function LBA.SpellString(spellID, spellName)
    spellName = NORMAL_FONT_COLOR:WrapTextInColorCode(spellName)
    if spellID then
        return format("%s (%d)", spellName, spellID)
    else
        return spellName
    end
end

function LBA.AuraMapString(auraID, auraName, abilityID, abilityName)
    return format(
                "%s %s %s",
                LBA.SpellString(auraID, auraName),
                L["on"],
                LBA.SpellString(abilityID, abilityName)
            )
end

function LBA.GetAuraMapList()
    local out = { }
    for showAura, onAbilityTable in pairs(LBA.db.profile.auraMap) do
        for _, onAbility in ipairs(onAbilityTable) do
            local auraName, auraID, abilityName, abilityID
            if type(showAura) == 'number' then
                local info = C_Spell.GetSpellInfo(showAura)
                if info then
                    auraName = info.name
                    auraID = info.spellID
                end
            else
                auraName = showAura
            end
            if type(onAbility) == 'number' then
                local info = C_Spell.GetSpellInfo(onAbility)
                if info then
                    abilityName = info.name
                    abilityID = info.spellID
                end
            else
                abilityName = onAbility
            end
            if auraName and abilityName then
                table.insert(out, { auraID, auraName, abilityID, abilityName })
            end
        end
    end
    sort(out, function (a, b) return a[2]..a[4] < b[2]..b[4] end)
    return out
end

function LBA.ApplyDefaultSettings()
    LBA.db:ResetProfile()
    AceConfigRegistry:NotifyChange(addonName)
end
