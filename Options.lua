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
        auraMap = {
            [191587] = {        -- Virulent Plague
                77575,          --  Outbreak
                115989,         --  Unholy Blight
            },
            [55095] = {         -- Frost Fever
                49184,          --  Howling Blast
            },
            [55078] = {         -- Blood Plague
                50842,          --  Blood Boil
            },
            [228287] = {        -- Mark of the Crane
                100780,         --  Tiger Palm
            },
            [116645] = {        -- Teachings of the Monastery
                -- 100780,         --  Tiger Palm
                100784,         --  Blackout Kick
            },
        },
        color = {
            buff    = { r=0.00, g=0.70, b=0.00 },
            debuff  = { r=1.00, g=0.00, b=0.00 },
            enrage  = { r=1.00, g=0.25, b=0.00 }, -- unused
        },
        minAuraDuration = 1.5,
        showTimers = true,
        showStacks = false,
        showSuggestions = true,
        colorTimers = true,
        decimalTimers = true,
        font = 'NumberFontNormal',
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
end

function LBA.DefaultAuraMap()
    LBA.db.profile.auraMap = CopyTable(defaults.profile.auraMap)
    LBA.UpdateAuraMap()
end

function LBA.WipeAuraMap()
    table.wipe(LBA.db.profile.auraMap)
    for n in pairs(defaults.profile.auraMap) do
        LBA.db.profile.auraMap[n] = { false }
    end
    LBA.UpdateAuraMap()
end

function LBA.AddDenySpell(auraID)
    LBA.db.profile.denySpells[auraID] = true
end

function LBA.RemoveDenySpell(auraID)
    LBA.db.profile.denySpells[auraID] = nil
end

function LBA.DefaultDenySpells()
    LBA.db.profile.denySpells = CopyTable(defaults.profile.denySpells)
end

function LBA.WipeDenySpells()
    table.wipe(LBA.db.profile.denySpells)
end
