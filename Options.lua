--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.Options = {}

local defaults = {
    global = {
    },
    profile = {
        denySpells = {
            [152175]    = true, -- Whirling Dragon Punch (Monk)
        },
        color = {
            buff    = { r=0.00, g=1.00, b=0.00 },
            debuff  = { r=1.00, g=0.00, b=0.00 },
            enrage  = { r=1.00, g=0.65, b=0.00 },
        },
        minAuraDuration = 1.5,
        colorTimers = true,
    },
    char = {
    },
}

function LBA.Options:Initialize()
    LBA.db = LibStub("AceDB-3.0"):New("LiteButtonAurasDB", defaults, true)
end

function LBA.Options:IsDenied(spellID)
    return spellID and LBA.db.profile.denySpells[spellID]
end
