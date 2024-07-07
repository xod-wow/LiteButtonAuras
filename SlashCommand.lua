--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    Slash command just allows setting and displaying the options since
    there is no GUI for it.

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

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
    printf("  /lba options")
    printf("  /lba stacks on|off|default")
    printf("  /lba stacksanchor point [offset]")
    printf("  /lba timers on|off|default")
    printf("  /lba colortimers on|off|default")
    printf("  /lba decimaltimers on|off|default")
    printf("  /lba timeranchor point [offset]")
    printf("  /lba font FontName|default")
    printf("  /lba font path [ size [ flags ] ]")
    printf("  /lba aura help")
    printf("  /lba deny help")
end

local function PrintAuraUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba aura list")
    printf("  /lba aura wipe")
    printf("  /lba aura hide <auraSpellID> on <ability>")
    printf("  /lba aura show <auraSpellID> on <ability>")
end

local function PrintDenyUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba deny defaults")
    printf("  /lba deny list")
    printf("  /lba deny wipe")
    printf("  /lba deny add <abilit>")
    printf("  /lba deny remove <abilit>")
end

local function PrintOptions()
    local p = LBA.db.profile
    printf(SETTINGS .. ':')
    printf("  stacks = " .. TrueStr(p.showStacks))
    printf("  stacksAnchor = %s %d", p.stacksAnchor, p.stacksAdjust)
    printf("  timer = " .. TrueStr(p.showTimers))
    printf("  colorTimer = " .. TrueStr(p.colorTimers))
    printf("  decimalTimer = " .. TrueStr(p.decimalTimers))
    printf("  timerAnchor = %s %d", p.timerAnchor, p.timerAdjust)
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
    if not auraInfo or not abilityInfo then
        return
    else
        return
            auraInfo.spellID,
            auraInfo.name or aura,
            abilityInfo.spellID,
            abilityInfo.name or ability
    end
end

local function PrintAuraMapList()
    printf("Aura list:")
    for i, entry in ipairs(LBA.GetAuraMapList()) do
        printf("%3d. %s", i, LBA.AuraMapString(unpack(entry)))
    end
end

local function AuraCommand(argstr)
    local _, cmd, cmdarg = strsplit(" ", argstr, 3)
    if cmd == 'list' then
        PrintAuraMapList()
    elseif cmd == 'show' and cmdarg then
        local aura, auraName, ability, abilityName = ParseAuraMap(cmdarg)
        if not aura then
            printf("Error: unknown aura spell: %s", NORMAL_FONT_COLOR:WrapTextInColorCode(auraName))
        elseif not ability then
            printf("Error: unknown ability spell: %s", NORMAL_FONT_COLOR:WrapTextInColorCode(abilityName))
        else
            printf("show %s", LBA.AuraMapString(aura, auraName, ability, abilityName))
            LBA.AddAuraMap(aura, ability)
        end
    elseif cmd == 'hide' and cmdarg then
        local aura, auraName, ability, abilityName = ParseAuraMap(cmdarg)
        if not aura then
            printf("Error: unknown aura spell.")
        elseif not ability then
            printf("Error: unknown ability spell.")
        else
            printf("hide %s", LBA.AuraMapString(aura, auraName, ability, abilityName))
            LBA.RemoveAuraMap(aura, ability)
        end
    elseif cmd == 'wipe' then
        printf("Wiping aura list.")
        LBA.WipeAuraMap()
    else
        PrintAuraUsage()
    end

    return true
end

local function PrintDenyList()
    local spells = { }
    for spellID in pairs(LBA.db.profile.denySpells) do
        local spell = Spell:CreateFromSpellID(spellID)
        if not spell:IsSpellEmpty() then
            spell:ContinueOnSpellLoad(function () table.insert(spells, spell) end)
        end
    end
    table.sort(spells, function (a, b) return a:GetSpellName() < b:GetSpellName() end)
    printf("Deny list:")
    for i, spell in ipairs(spells) do
        printf("%3d. %s (%d)", i, spell:GetSpellName() or "?", spell:GetSpellID())
    end
end

local function DenyCommand(argstr)
    local _, cmd, spell = strsplit(" ", argstr, 3)
    if cmd == 'list' then
        PrintDenyList()
    elseif cmd == 'default' then
        LBA.DefaultDenySpells()
    elseif cmd == 'wipe' then
        LBA.WipeDenySpells()
    elseif cmd == 'add' and spell then
        local info = C_Spell.GetSpellInfo(spell)
        if info then
            LBA.AddDenySpell(info.spellID)
        else
            printf("Error: unknown spell: " .. spell)
        end
    elseif cmd == 'remove' and spell then
        local info = C_Spell.GetSpellInfo(spell)
        if info then
            LBA.RemoveDenySpell(info.spellID)
        else
            printf("Error: unknown spell: " .. spell)
        end
    else
        PrintDenyUsage()
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
    elseif cmd:lower() == 'stacks' and #args == 1 then
        LBA.SetOption('showStacks', args[1])
    elseif cmd:lower() == 'stacksanchor' and WithinRange(#args, 1, 2) then
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
    elseif cmd:lower() == 'timeranchor' and WithinRange(#args, 1, 2) then
        LBA.SetOption('timerAnchor', args[1])
        if args[2] then LBA.SetOption('timerAdjust', args[2]) end
    elseif cmd:lower() == 'aura' then
        AuraCommand(argstr)
    elseif cmd:lower() == 'deny' then
        DenyCommand(argstr)
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
