--[[----------------------------------------------------------------------------

  LiteButtonAuras/Options.lua

  Copyright 2015 Mike Battersby

----------------------------------------------------------------------------]]--

local addonName, LBA = ...

local L = LBA.L

local LSM = LibStub('LibSharedMedia-3.0')
local FONT = LSM.MediaType.FONT
local ALL_FONTS = LSM:HashTable(FONT)

local ANCHOR_SELECT_VALUES = {
    BOTTOMLEFT = L["Bottom left"],
    BOTTOM = L["Bottom"],
    BOTTOMRIGHT = L["Bottom right"],
    RIGHT = L["Right"],
    TOPRIGHT = L["Top right"],
    TOP = L["Top"],
    TOPLEFT = L["Top left"],
    LEFT = L["Left"],
    CENTER = L["Center"]
}

local function Getter(info)
    local k = info[#info]
    return LBA.db.profile[k]
end

local function Setter(info, val ,...)
    local k = info[#info]
    LBA.SetOption(k, val)
end

local function FontPathGetter(info)
    for name, path in pairs(ALL_FONTS) do
        if path == LBA.db.profile.fontPath then
            return name
        end
    end
end

local function FontPathSetter(info, name)
    if ALL_FONTS[name] then
        LBA.SetOption('fontPath', ALL_FONTS[name])
    end
end

local function ValidateSpellValue(_, v)
    if v == "" then
        return true
    elseif v and C_Spell.GetSpellInfo(v) ~= nil then
        return true
    else
        return format(
                L["Error: unknown spell: %s"] ..
                 "\n\n" ..
                 L["For spells that aren't in your spell book use the spell ID number."],
                ORANGE_FONT_COLOR:WrapTextInColorCode(v))
    end
end

local order
do
    local n = 0
    order = function () n = n + 1 return n end
end

local addAuraMap = { }
local addIgnoreAbility

local ValidateTexture = UIParent:CreateTexture()

local options = {
    type = "group",
    childGroups = "tab",
    args = {
        GeneralGroup = {
            type = "group",
            name = GENERAL,
            order = order(),
            get = Getter,
            set = Setter,
            args = {
                topGap = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                defaultNameMatching = {
                    type = "toggle",
                    name = L["Automatically match auras to abilities by name."],
                    desc = L['If you disable this option, only auras explicitly configured under "Extra aura displays" will be shown.'],
                    order = order(),
                    width = "full",
                },
                playerPetBuffs = {
                    type = "toggle",
                    name = L["Display buffs cast by you on your pet."],
                    order = order(),
                    width = "full",
                },
                showTimers = {
                    type = "toggle",
                    name = L["Display aura duration timers."],
                    order = order(),
                    width = "full",
                },
                colorTimers = {
                    type = "toggle",
                    name = L["Color aura duration timers based on remaining time."],
                    order = order(),
                    width = "full",
                },
                decimalTimers = {
                    type = "toggle",
                    name = L["Show fractions of a second on timers."],
                    order = order(),
                    width = "full",
                },
                showStacks = {
                    type = "toggle",
                    name = L["Show aura stacks."],
                    order = order(),
                    width = "full",
                },
                showSuggestions = {
                    type = "toggle",
                    name = L["Highlight buttons for interrupt and soothe."],
                    order = order(),
                    width = "full",
                },
                preFontHeaderGap = {
                    name = "\n",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                FontHeader = {
                    type = "header",
                    name = L["Font"],
                    order = order(),
                },
                postFontHeaderGap = {
                    name = "",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                fontRestoreDefaults = {
                    name = L["Restore font defaults"],
                    type = "execute",
                    width = "full",
                    order = order(),
                    func =
                        function ()
                            LBA.SetOption("fontPath", "default")
                            LBA.SetOption("fontSize", "default")
                        end,
                },
                preFontPathSpacer = {
                    name = "",
                    type = "description",
                    width = 0.05,
                    order = order(),
                },
                fontPath = {
                    type = "select",
                    name = L["Font name"],
                    order = order(),
                    dialogControl = 'LSM30_Font',
                    values = ALL_FONTS,
                    get = FontPathGetter,
                    set = FontPathSetter,
                },
                fontSizePreGap = {
                    type = "description",
                    name = "",
                    width = 0.1,
                    order = order(),
                },
                fontSize = {
                    type = "range",
                    name = L["Font size"],
                    order = order(),
                    min = 6,
                    max = 24,
                    step = 1,
                },
                preAnchorHeaderGap = {
                    name = "\n",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                AnchorHeader = {
                    type = "header",
                    name = L["Text positions"],
                    order = order(),
                },
                postAnchorHeaderGap = {
                    name = "",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                anchorRestoreDefaults = {
                    name = L["Restore text defaults"],
                    type = "execute",
                    width = "full",
                    order = order(),
                    func =
                        function ()
                            LBA.SetOption("timerAnchor", "default")
                            LBA.SetOption("timerAdjust", "default")
                            LBA.SetOption("stacksAnchor", "default")
                            LBA.SetOption("stacksAdjust", "default")
                        end,
                },
                preTimerAnchorGap = {
                    name = "",
                    type = "description",
                    width = 0.1,
                    order = order(),
                },
                timerAnchor = {
                    name = L["Timer text position"],
                    type = "select",
                    control = 'LBAAnchorButtons',
                    values = ANCHOR_SELECT_VALUES,
                    order = order(),
                },
                preStacksAnchorGap = {
                    name = "",
                    type = "description",
                    width = 0.25,
                    order = order(),
                },
                stacksAnchor = {
                    name = L["Stack text position"],
                    type = "select",
                    control = 'LBAAnchorButtons',
                    values = ANCHOR_SELECT_VALUES,
                    order = order(),
                },
                AnchorsGap = {
                    name = "",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                preTimerAdjustGap = {
                    name = "",
                    type = "description",
                    width = 0.1,
                    order = order(),
                },
                timerAdjust = {
                    name = L["Timer text offset"],
                    type = "range",
                    order = order(),
                    min = -16,
                    max = 16,
                    step = 1,
                },
                preStacksAdjustGap = {
                    name = "",
                    type = "description",
                    width = 0.25,
                    order = order(),
                },
                stacksAdjust = {
                    name = L["Stack text offset"],
                    type = "range",
                    order = order(),
                    min = -16,
                    max = 16,
                    step = 1,
                },
                preGlowHeaderGap = {
                    name = "\n",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                GlowHeader = {
                    type = "header",
                    name = L["Glow"],
                    order = order(),
                },
                postGlowHeaderGap = {
                    name = "",
                    type = "description",
                    width = 'full',
                    order = order(),
                },
                glowRestoreDefaults = {
                    name = L["Restore glow defaults"],
                    type = "execute",
                    width = "full",
                    order = order(),
                    func =
                        function ()
                            LBA.SetOption("glowTexture", "default")
                            LBA.SetOption("glowAlpha", "default")
                            LBA.SetOption("glowUseMasque", "default")
                        end,
                },
                glowTexture = {
                    name = L["Glow texture"],
                    type = "input",
                    width = "full",
                    order = order(),
                    validate =
                        function (info, value)
                            ValidateTexture:SetTexture(value)
                            if ValidateTexture:GetTexture() then
                                return true
                            else
                                return L["Texture not found"]
                            end
                        end,
                },
                glowAlpha = {
                    type = "range",
                    name = L["Glow alpha"],
                    order = order(),
                    min = 0,
                    max = 1,
                    step = 0.01,
                },
                preGlowUseMasqueSpacer = {
                    name = "",
                    type = "description",
                    width = 0.5,
                    order = order(),
                },
                glowUseMasque = {
                    name = L["Automatically use Masque textures"],
                    type = "toggle",
                    width = 2,
                    order = order(),
                },
            },
        },
        MappingGroup = {
            type = "group",
            name = L["Extra aura displays"],
            inline = false,
            order = order(),
            args = {
                showAura = {
                    name = L["Show aura"],
                    type = "input",
                    width = 1.4,
                    order = order(),
                    get =
                        function ()
                            if addAuraMap[1] then
                                local info = C_Spell.GetSpellInfo(addAuraMap[1])
                                return ("%s (%s)"):format(info.name, info.spellID) .. "\0" .. addAuraMap[1]
                            end
                        end,
                    set =
                        function (_, v)
                            local info = C_Spell.GetSpellInfo(v)
                            addAuraMap[1] = info and info.spellID or nil
                        end,
                    control = 'LBAInputFocus',
                    validate = ValidateSpellValue,
                },
                preOnAbilityGap = {
                    name = "",
                    type = "description",
                    width = 0.1,
                    order = order(),
                },
                onAbility = {
                    name = L["On ability"],
                    type = "input",
                    width = 1.4,
                    order = order(),
                    get =
                        function ()
                            if addAuraMap[2] then
                                local info = C_Spell.GetSpellInfo(addAuraMap[2])
                                return ("%s (%s)"):format(info.name, info.spellID) .. "\0" .. addAuraMap[2]
                            end
                        end,
                    set =
                        function (_, v)
                            local info = C_Spell.GetSpellInfo(v)
                            addAuraMap[2] = info and info.spellID or nil
                        end,
                    control = 'LBAInputFocus',
                    validate = ValidateSpellValue,
                },
                preAddButtonGap = {
                    name = "",
                    type = "description",
                    width = 0.1,
                    order = order(),
                },
                AddButton = {
                    name = ADD,
                    type = "execute",
                    width = 0.5,
                    order = order(),
                    disabled =
                        function (info, v)
                            local auraName = addAuraMap[1] and C_Spell.GetSpellName(addAuraMap[1])
                            local abilityName = addAuraMap[2] and C_Spell.GetSpellName(addAuraMap[2])
                            if auraName and abilityName and auraName ~= abilityName then
                                return false
                            else
                                return true
                            end
                        end,
                    func =
                        function ()
                            local auraInfo = addAuraMap[1] and C_Spell.GetSpellInfo(addAuraMap[1])
                            local abilityInfo = addAuraMap[2] and C_Spell.GetSpellInfo(addAuraMap[2])
                            if auraInfo and abilityInfo then
                                LBA.AddAuraMap(auraInfo.spellID, abilityInfo.spellID)
                                addAuraMap[1] = nil
                                addAuraMap[2] = nil
                            end
                        end,
                },
                Mappings = {
                    name = L["Extra aura displays"],
                    type = "group",
                    order = order(),
                    inline = true,
                    args = {},
                    plugins = {},
                }
            }
        },
        IgnoreGroup = {
            type = "group",
            name = L["Ignored spell IDs"],
            order = order(),
            inline = false,
            args = {
                ignoreAbility = {
                    name = L["Add spell ID"],
                    type = "input",
                    width = 1,
                    order = order(),
                    get =
                        function ()
                            if addIgnoreAbility then
                                local info = C_Spell.GetSpellInfo(addIgnoreAbility)
                                return ("%s (%s)"):format(info.name, info.spellID) .. "\0" .. addIgnoreAbility
                            end
                        end,
                    set =
                        function (_, v)
                            local info = C_Spell.GetSpellInfo(v)
                            addIgnoreAbility = info and info.spellID or nil
                        end,
                    control = 'LBAInputFocus',
                    validate = ValidateSpellValue,
                },
                AddButton = {
                    name = ADD,
                    type = "execute",
                    width = 1,
                    order = order(),
                    disabled =
                        function ()
                            if addIgnoreAbility then
                                return not C_Spell.GetSpellInfo(addIgnoreAbility)
                            end
                        end,
                    func =
                        function ()
                            local info = addIgnoreAbility and C_Spell.GetSpellInfo(addIgnoreAbility)
                            if info then
                                LBA.SetIgnoreSpell(info.spellID, { ability = true })
                                addIgnoreAbility = nil
                            end
                        end,
                },
                Abilities = {
                    name = L["Ignored abilities"],
                    type = "group",
                    order = order(),
                    inline = true,
                    args = {},
                    plugins = {},
                }
            }
        },
    },
}

local function GenerateOptions()
    local auraMapList = LBA.GetAuraMapList()
    local auraMaps = { }
    for i, entry in ipairs(auraMapList) do
        auraMaps["mapAura"..i] = {
            order = 10*i+1,
            name = LBA.SpellString(entry[1], entry[2]),
            type = "description",
            image = C_Spell.GetSpellTexture(entry[1] or entry[2]),
            imageWidth = 22,
            imageHeight = 22,
            width = 1.4,
        }
        auraMaps["onText"..i] = {
            order = 10*i+2,
            name = GRAY_FONT_COLOR:WrapTextInColorCode(L["on"]),
            type = "description",
            width = 0.15,
        }
        auraMaps["mapAbility"..i] = {
            order = 10*i+3,
            name = LBA.SpellString(entry[3], entry[4]),
            type = "description",
            image = C_Spell.GetSpellTexture(entry[3] or entry[4]),
            imageWidth = 22,
            imageHeight = 22,
            width = 1.4,
        }
        auraMaps["delete"..i] = {
            order = 10*i+4,
            name = DELETE,
            type = "execute",
            func = function () LBA.RemoveAuraMap(entry[1], entry[3]) end,
            width = 0.45,
        }
    end
    options.args.MappingGroup.args.Mappings.plugins.auraMaps = auraMaps

    local ignoreSpellList = {}
    local cc = ContinuableContainer:Create()
    for spellID, spellIgnoreData in pairs(LBA.db.profile.ignoreSpells) do
        local spell = Spell:CreateFromSpellID(spellID)
        if not spell:IsSpellEmpty() then
            if WOW_PROJECT_ID ~= 1 then
                spell.IsDataEvictable = function () return true end
                spell.IsItemDataCached = spell.IsSpellDataCached
                spell.ContinueWithCancelOnItemLoad = spell.ContinueWithCancelOnSpellLoad
            end
            cc:AddContinuable(spell)
            local data = CopyTable(spellIgnoreData)
            data.spell = spell
            table.insert(ignoreSpellList, data)
        end
    end

    local ignoreAbilities = {}
    local function ignoreSort(a, b) return a.spell:GetSpellName() < b.spell:GetSpellName() end

    cc:ContinueOnLoad(
        function ()
            table.sort(ignoreSpellList, ignoreSort)
            for i, data in ipairs(ignoreSpellList) do
                local spellName = data.spell:GetSpellName()
                local spellID = data.spell:GetSpellID()
                local newData = CopyTable(data)
                ignoreAbilities["spell"..i] = {
                    name = format("%s (%d)",
                                NORMAL_FONT_COLOR:WrapTextInColorCode(spellName),
                                spellID),
                    type = "description",
                    image = C_Spell.GetSpellTexture(spellID),
                    imageWidth = 22,
                    imageHeight = 22,
                    width = 1.5,
                    order = 10*i+1,
                }
                ignoreAbilities["ability"..i] = {
                    name = SPELLS,
                    desc = L["Spells and abilities on your action bars"],
                    type = "toggle",
                    order = 10*i+2,
                    width = 0.5,
                    get = function () return data.ability == true end,
                    set =
                        function (info, val)
                            newData.ability = val and true or nil
                            LBA.SetIgnoreSpell(spellID, newData)
                        end
                }
                ignoreAbilities["player"..i] = {
                    name = PLAYER,
                    desc = L["Buffs and debuffs on player unit"],
                    type = "toggle",
                    order = 10*i+3,
                    width = 0.5,
                    get = function () return data.player == true end,
                    set =
                        function (info, val)
                            newData.player = val and true or nil
                            LBA.SetIgnoreSpell(spellID, newData)
                        end
                }
                ignoreAbilities["unit"..i] = {
                    name = TARGET,
                    type = "toggle",
                    desc = L["Buffs and debuffs on target unit"],
                    order = 10*i+4,
                    width = 0.5,
                    get = function () return data.unit == true end,
                    set =
                        function (info, val)
                            newData.unit = val and true or nil
                            LBA.SetIgnoreSpell(spellID, newData)
                        end
                }
                ignoreAbilities["delete"..i] = {
                    name = DELETE,
                    type = "execute",
                    func = function () LBA.RemoveIgnoreSpell(data.spell:GetSpellID()) end,
                    width = 0.5,
                    order = 10*i+6,
                }
            end
            options.args.IgnoreGroup.args.Abilities.plugins.ignoreAbilites = ignoreAbilities
        end)
    return options
end

-- The sheer amount of crap required here is ridiculous. I bloody well hate
-- frameworks, just give me components I can assemble. Dot-com weenies ruined
-- everything, even WoW.

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions =  LibStub("AceDBOptions-3.0")

-- AddOns are listed in the Blizzard panel in the order they are
-- added, not sorted by name. In order to mostly get them to
-- appear in the right order, add the main panel when loaded.

AceConfig:RegisterOptionsTable(addonName, GenerateOptions, { "litebuttonauras", "lba" })
local optionsPanel, category = AceConfigDialog:AddToBlizOptions(addonName)

function LBA.InitializeGUIOptions()
    local profileOptions = AceDBOptions:GetOptionsTable(LBA.db)
    AceConfig:RegisterOptionsTable(addonName.."Profiles", profileOptions)
    AceConfigDialog:AddToBlizOptions(addonName.."Profiles", profileOptions.name, addonName)
end

function LBA.OpenOptions()
    Settings.OpenToCategory(category)
end

LiteButtonAuras_AddonCompartmentFunc = function () LBA.OpenOptions() end
