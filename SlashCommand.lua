--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Slash command just allows setting and displaying the options since
    there is no GUI for it.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local function TrueStr(x)
    return x and "on" or "off"
end

local header = ORANGE_FONT_COLOR:WrapTextInColorCode(addonName ..': ')

local function printf(...)
    local msg = string.format(...)
    SELECTED_CHAT_FRAME:AddMessage(header .. msg)
end

local function PrintUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba stacks on|off|default")
    printf("  /lba timers on|off|default")
    printf("  /lba colortimers on|off|default")
    printf("  /lba decimaltimers on|off|default")
    printf("  /lba font FontName|default")
    printf("  /lba font path [ size [ flags ] ]")
end

local function PrintOptions()
    local font = LBA.db.profile.font
    printf(SETTINGS .. ':')
    printf("  stacks = " .. TrueStr(LBA.db.profile.showStacks))
    printf("  timers = " .. TrueStr(LBA.db.profile.showTimers))
    printf("  colortimers = " .. TrueStr(LBA.db.profile.colorTimers))
    printf("  decimaltimers = " .. TrueStr(LBA.db.profile.decimalTimers))
    if type(font) == 'string' then
        printf("  font = " .. font)
    else
        printf("  font = [ '%s', %.1f, '%s' ]", unpack(LBA.db.profile.font))
    end
end

local function SetFont(args)
    local fontName, fontTable
    if type(LBA.db.profile.font) == 'string' then
        fontName = LBA.db.profile.font
        fontTable = { _G[fontName]:GetFont() }
    else
        fontTable = { unpack(LBA.db.profile.font) }
    end
    for _,arg in ipairs(args) do
        if arg == 'default' then
            fontName = 'NumberFontNormal'
            fontTable = { NumberFontNormal:GetFont() }
        elseif _G[arg] and _G[arg].GetFont then
            fontName = arg
            fontTable = { _G[arg]:GetFont() }
        elseif tonumber(arg) then
            fontName = nil
            fontTable[2] = tonumber(arg)
        elseif arg:find("\\") then
            fontName = nil
            fontTable[1] = arg
        else
            fontName = nil
            fontTable[3] = arg
        end
    end
    LBA.SetOption('font', fontName or fontTable)
end

local function SlashCommand(argstr)
    local args = { strsplit(" ", argstr) }
    local cmd = table.remove(args, 1)

    if cmd == '' then
        PrintOptions()
    elseif cmd:lower() == 'stacks' and #args == 1 then
        LBA.SetOption('showStacks', args[1])
    elseif cmd:lower() == 'timers' and #args == 1 then
        LBA.SetOption('showTimers', args[1])
    elseif cmd:lower() == 'colortimers' and #args == 1 then
        LBA.SetOption('colorTimers', args[1])
    elseif cmd:lower() == 'decimaltimers' and #args == 1 then
        LBA.SetOption('decimalTimers', args[1])
    elseif cmd:lower() == 'font' and #args >= 1 then
        SetFont(args)
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

