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
    printf("  /lba aura help")
    printf("  /lba deny help")
end

local function PrintAuraUsage()
    printf(GAMEMENU_HELP .. ":")
    printf("  /lba aura default")
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

local function ParseAuraMap(cmdarg)
    local aura, ability = cmdarg:match('^(.+) on (.+)$')
    local auraName, _, _, _, _, _, auraID = GetSpellInfo(aura)
    local abilityName, _, _, _, _, _, abilityID = GetSpellInfo(ability)
    return auraID, auraName or aura, abilityID, abilityName or ability
end

local function AuraMapString(aura, auraName, ability, abilityName)
    local c = NORMAL_FONT_COLOR
    return format(
                "%s %d on %s %d",
                c:WrapTextInColorCode(auraName),
                aura,
                c:WrapTextInColorCode(abilityName),
                ability
            )
end

local function GetAuraMapList()
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

local function PrintAuraMapList()
    printf("Aura list:")
    for i, entry in ipairs(GetAuraMapList()) do
        printf("%3d. %s", i, AuraMapString(unpack(entry)))
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
            printf("show %s", AuraMapString(aura, auraName, ability, abilityName))
            LBA.AddAuraMap(aura, ability)
        end
    elseif cmd == 'hide' and cmdarg then
        local aura, auraName, ability, abilityName = ParseAuraMap(cmdarg)
        if not aura then
            printf("Error: unknown aura spell.")
        elseif not ability then
            printf("Error: unknown ability spell.")
        else
            printf("hide %s", AuraMapString(aura, auraName, ability, abilityName))
            LBA.RemoveAuraMap(aura, ability)
        end
    elseif cmd == 'wipe' then
        printf("Wiping aura list.")
        LBA.WipeAuraMap()
    elseif cmd == 'default' then
        printf("Setting aura list to defaults.")
        LBA.WipeAuraMap()
        LBA.DefaultAuraMap()
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
        LBA.DefaultDenyList()
    elseif cmd == 'wipe' then
        LBA.WipeDenyList()
    elseif cmd == 'add' and spell then
        local id = select(7, GetSpellInfo(spell))
        if id then
            LBA.AddDenySpell(id)
        else
            printf("Error: unknown spell: " .. spell)
        end
    elseif cmd == 'remove' and spell then
        local id = select(7, GetSpellInfo(spell))
        if id then
            LBA.RemoveDenySpell(id)
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
