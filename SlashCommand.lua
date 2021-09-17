--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local function IsTrue(x)
    if x == nil or x == false or x == "0" or x == "off" or x == "false" then
        return false
    else
        return true
    end
end

local function TrueStr(x)
    if x then
        return "on"
    else
        return "off"
    end
end

local header = ORANGE_FONT_COLOR:WrapTextInColorCode(addonName ..': ')

local function printf(...)
    local msg = string.format(...)
    SELECTED_CHAT_FRAME:AddMessage(header .. msg)
end

local function PrintUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba colortimers on|off")
    printf("  /lba decimaltimers on|off")
end

local function PrintOptions()
    printf(SETTINGS .. ':')
    printf("  colortimers = " .. TrueStr(LBA.db.profile.colorTimers))
    printf("  decimaltimers = " .. TrueStr(LBA.db.profile.decimalTimers))
end

local function SlashCommand(argstr)
    local args = { strsplit(" ", argstr) }
    local cmd = table.remove(args, 1)

    if cmd == '' then
        PrintOptions()
    elseif cmd:lower() == 'colortimers' and #args == 1 then
        LBA.db.profile.colorTimers = IsTrue(args[1])
    elseif cmd:lower() == 'decimaltimers' and #args == 1 then
        LBA.db.profile.decimalTimers = IsTrue(args[1])
    else
        PrintUsage()
    end
    return true
end

function LBA.SetupSlashCommand()
    SlashCmdList['LiteButtonAuras'] = SlashCommand
    _G.SLASH_LiteButtonAuras1 = "/litebuttonauras"
    _G.SLASH_LiteButtonAuras1 = "/lba"
end

