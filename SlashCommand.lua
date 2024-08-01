--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Slash command just allows setting and displaying the options since
    there is no GUI for it.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

local L = LBA.L

local function TrueStr(x)
    return x and "on" or "off"
end

local header = ORANGE_FONT_COLOR:WrapTextInColorCode(addonName..': ')

local function printf(...)
    local msg = string.format(...)
    SELECTED_CHAT_FRAME:AddMessage(header .. msg)
end

local function PrintUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba options")
    printf("  /lba stack on|off|default")
    printf("  /lba stackposition point [offset]")
    printf("  /lba timer on|off|default")
    printf("  /lba colortimer on|off|default")
    printf("  /lba decimaltimer on|off|default")
    printf("  /lba timerposition point [offset]")
    printf("  /lba font FontName|default")
    printf("  /lba font path [ size [ flags ] ]")
    printf("  /lba aura help")
    printf("  /lba ignore help")
end

local function PrintAuraUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba aura list")
    printf("  /lba aura add <auraID> on <ability>")
    printf("  /lba aura remove <auraID> on <ability>")
    printf("  /lba aura wipe")
end

local function PrintIgnoreUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba ignore list")
    printf("  /lba ignore add <ability")
    printf("  /lba ignore remove <ability>")
    printf("  /lba ignore default")
    printf("  /lba ignore wipe")
end

local function PrintOptions()
    local p = LBA.db.profile
    printf(SETTINGS .. ':')
    printf("  stack = " .. TrueStr(p.showStacks))
    printf("  stackPosition = %s %d", p.stacksAnchor, p.stacksAdjust)
    printf("  timer = " .. TrueStr(p.showTimers))
    printf("  colorTimer = " .. TrueStr(p.colorTimers))
    printf("  decimalTimer = " .. TrueStr(p.decimalTimers))
    printf("  timerPosition = %s %d", p.timerAnchor, p.timerAdjust)
    printf("  font = [ '%s', %.1f, '%s' ]", p.fontPath, p.fontSize, p.fontFlags)
end

local function SetFont(args)
    local path, size, flags
    for _,arg in ipairs(args) do
        if arg == 'default' then
            path, size, flags = 'default', 'default', 'default'
        elseif _G[arg] and _G[arg].GetFont then
            path, size, flags = _G[arg]:GetFont()
        elseif tonumber(arg) then
            size = math.floor(tonumber(arg) + 0.5)
        elseif arg:find("\\") then
            path = arg
        else
            flags = arg
        end
    end
    if path then LBA.SetOption('fontPath', path) end
    if size then LBA.SetOption('fontSize', size) end
    if flags then LBA.SetOption('fontFlags', flags) end
end

local function ParseAuraMap(cmdarg)
    local aura, ability = cmdarg:match('^(.+) on (.+)$')
    local auraInfo = C_Spell.GetSpellInfo(aura)
    local abilityInfo = C_Spell.GetSpellInfo(ability)
    return
        auraInfo and auraInfo.spellID,
        auraInfo and auraInfo.name or aura,
        abilityInfo and abilityInfo.spellID,
        abilityInfo and abilityInfo.name or ability
end

local function PrintAuraMapList()
    printf(L["Aura list"] .. ":")
    for i, entry in ipairs(LBA.GetAuraMapList()) do
        printf("%3d. %s", i, LBA.AuraMapString(unpack(entry)))
    end
end

local function AuraCommand(argstr)
    local _, cmd, cmdarg = strsplit(" ", argstr, 3)
    if cmd == 'list' then
        PrintAuraMapList()
    elseif cmd == 'add' and cmdarg then
        local aura, auraName, ability, abilityName = ParseAuraMap(cmdarg)
        if not aura then
            printf(L["Error: unknown aura spell: %s"], NORMAL_FONT_COLOR:WrapTextInColorCode(auraName))
        elseif not ability then
            printf(L["Error: unknown ability spell: %s"], NORMAL_FONT_COLOR:WrapTextInColorCode(abilityName))
        else
            printf(ADD.." %s", LBA.AuraMapString(aura, auraName, ability, abilityName))
            LBA.AddAuraMap(aura, ability)
        end
    elseif cmd == 'remove' and cmdarg then
        local aura, auraName, ability, abilityName = ParseAuraMap(cmdarg)
        if not aura then
            printf(L["Error: unknown aura spell: %s"], NORMAL_FONT_COLOR:WrapTextInColorCode(auraName))
        elseif not ability then
            printf(L["Error: unknown ability spell: %s"], NORMAL_FONT_COLOR:WrapTextInColorCode(abilityName))
        else
            printf(REMOVE.." %s", LBA.AuraMapString(aura, auraName, ability, abilityName))
            LBA.RemoveAuraMap(aura, ability)
        end
    elseif cmd == 'wipe' then
        printf(L["Wiping aura list."])
        LBA.WipeAuraMap()
    else
        PrintAuraUsage()
    end

    return true
end

local function PrintIgnoreList()
    local spells = { }
    for spellID in pairs(LBA.db.profile.denySpells) do
        local spell = Spell:CreateFromSpellID(spellID)
        if not spell:IsSpellEmpty() then
            spell:ContinueOnSpellLoad(function () table.insert(spells, spell) end)
        end
    end
    table.sort(spells, function (a, b) return a:GetSpellName() < b:GetSpellName() end)
    printf(L["Ignored abilities"]..":")
    for i, spell in ipairs(spells) do
        printf("%3d. %s (%d)", i, spell:GetSpellName() or "?", spell:GetSpellID())
    end
end

local function IgnoreCommand(argstr)
    local _, cmd, spell = strsplit(" ", argstr, 3)
    if cmd == 'list' then
        PrintIgnoreList()
    elseif cmd == 'default' then
        LBA.DefaultIgnoreSpells()
    elseif cmd == 'wipe' then
        LBA.WipeIgnoreSpells()
    elseif cmd == 'add' and spell then
        local info = C_Spell.GetSpellInfo(spell)
        if info then
            LBA.AddIgnoreSpell(info.spellID)
        else
            printf(L["Error: unknown spell: %s"], spell)
        end
    elseif cmd == 'remove' and spell then
        local info = C_Spell.GetSpellInfo(spell)
        if info then
            LBA.RemoveIgnoreSpell(info.spellID)
        else
            printf(L["Error: unknown spell: %s"], spell)
        end
    else
        PrintIgnoreUsage()
    end
    return true
end

local function SlashCommand(argstr)
    local args = { strsplit(" ", argstr) }
    local cmd = table.remove(args, 1)
    local n = cmd:len()

    if cmd == '' then
        PrintOptions()
    elseif cmd == ('options'):sub(1,n) then
        LBA.OpenOptions()
    elseif cmd:lower() == 'stack' and #args == 1 then
        LBA.SetOption('showStacks', args[1])
    elseif cmd:lower() == 'stackposition' and WithinRange(#args, 1, 2) then
        LBA.SetOption('stacksAnchor', args[1])
        if args[2] then LBA.SetOption('stacksAdjust', args[2]) end
    elseif cmd:lower() == 'timer' and #args == 1 then
        LBA.SetOption('showTimers', args[1])
    elseif cmd:lower() == 'colortimer' and #args == 1 then
        LBA.SetOption('colorTimers', args[1])
    elseif cmd:lower() == 'decimaltimer' and #args == 1 then
        LBA.SetOption('decimalTimers', args[1])
    elseif cmd:lower() == 'font' and WithinRange(#args, 1, 3) then
        SetFont(args)
    elseif cmd:lower() == 'timerposition' and WithinRange(#args, 1, 2) then
        LBA.SetOption('timerAnchor', args[1])
        if args[2] then LBA.SetOption('timerAdjust', args[2]) end
    elseif cmd:lower() == 'aura' then
        AuraCommand(argstr)
    elseif cmd:lower() == 'ignore' then
        IgnoreCommand(argstr)
    elseif cmd:lower() == 'dump' then
        LiteButtonAurasController:DumpAllOverlays()
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
