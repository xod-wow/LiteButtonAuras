exclude_files = {
    ".luacheckrc",
    "Tests/",
    "Libs/",
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html

ignore = {
    "11./BINDING_.*", -- Setting an undefined (Keybinding) global variable
    "211", -- Unused local variable
    "212", -- Unused argument
    "213", -- Unused loop variable
    "432/self", -- Shadowing a local variable
    "542", -- empty if branch
    "631", -- line too long
}

globals = {
    "LiteButtonAurasControllerMixin",
    "LiteButtonAurasOverlayMixin",
    "SlashCmdList",
}

read_globals =  {
    "ABP_NS",
    "ADD",
    "ActionBarButtonEventsFrame",
    "ActionButton_HideOverlayGlow",
    "ActionButton_SetupOverlayGlow",
    "AuraUtil",
    "C_Item",
    "C_Spell",
    "ChatFontNormal",
    "ContinuableContainer",
    "CopyTable",
    "CreateFrame",
    "CreateFromMixins",
    "DEFAULT",
    "DELETE",
    "DebuffTypeColor",
    "Dominos",
    "GAMEMENU_HELP",
    "GENERAL",
    "GRAY_FONT_COLOR",
    "GameFontHighlight",
    "GameFontNormal",
    "GameTooltip",
    "GameTooltip_Hide",
    "GetActionInfo",
    "GetActionText",
    "GetKeysArray",
    "GetLocale",
    "GetMacroIndexByName",
    "GetMacroItem",
    "GetMacroSpell",
    "GetTime",
    "GetTotemInfo",
    "GetValuesArray",
    "GetWeaponEnchantInfo",
    "HIGHLIGHT_FONT_COLOR",
    "HasAction",
    "IsMouseButtonDown",
    "IsSpellOverlayed",
    "LibStub",
    "LiteButtonAurasController",
    "MAX_TOTEMS",
    "Mixin",
    "NONE",
    "NORMAL_FONT_COLOR",
    "NumberFontNormal",
    "OKAY",
    "ORANGE_FONT_COLOR",
    "REMOVE",
    "SELECTED_CHAT_FRAME",
    "SETTINGS",
    "Settings",
    "Spell",
    "UIParent",
    "UnitCanAttack",
    "UnitCastingInfo",
    "UnitChannelInfo",
    "UnitIsFriend",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_ID",
    "WithinRange",
    "format",
    "hooksecurefunc",
    "sort",
    "strsplit",
    "tContains",
    "tDeleteItem",
    "table",
}
