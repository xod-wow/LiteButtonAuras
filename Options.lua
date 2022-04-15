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
        },
        auraMap = {
            [224509] = {        -- Frailty
                73572,          --  Spirit Bomb
            },
            [191587] = {        -- Virulent Plague
                77575,          --  Outbreak
                115989,         --  Unholy Blight
            },
            [55005] = {         -- Frost Fever
                49184,          --  Howling Blast
            },
            [55078] = {         -- Blood Plague
                50842,          --  Blood Boil
            },
            [340459] = {        -- Maraad's Dying Breath
                183998,         --  Light of the Martyr
            },
            [228287] = {        -- Mark of the Crane
                100780,         --  Tiger Palm
            },
            [116645] = {        -- Teachings of the Monastery
                100780,         --  Tiger Palm
                -- 100784,         --  Blackout Kick
            },
            [138279] = {        -- Victorious
                34428,          --  Victory Rush
            },
        },
        color = {
            buff    = { r=0.00, g=1.00, b=0.00 },
            debuff  = { r=1.00, g=0.00, b=0.00 },
            enrage  = { r=1.00, g=0.25, b=0.00 },
        },
        minAuraDuration = 1.5,
        colorTimers = true,
        decimalTimers = true,
        stacks = false,
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
