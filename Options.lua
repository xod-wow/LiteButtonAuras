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
            [152175] = true,            -- Whirling Dragon Punch (Monk)
        }
    },
    char = {
    },
}

function LBA.Options:Initialize()
    self.db = LibStub("AceDB-3.0"):New("LiteButtonAurasDB", defaults, true)
end
