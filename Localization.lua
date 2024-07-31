--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2024 Mike "Xodiv" Battersby

    您好，請幫忙翻譯一下
    https://legacy.curseforge.com/wow/addons/litebuttonauras/localization

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA.L = setmetatable({}, { __index = function (_,k) return k end })

local L = LBA.L

local locale = GetLocale()

-- :r! sh fetchlocale.sh -------------------------------------------------------

-- deDE ------------------------------------------------------------------------

if locale == "deDE" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Unten"
    L["Bottom left"]      = "Unten Links"
    L["Bottom right"]     = "Unten Rechts"
    L["Center"]           = "Mitte"
    L["Color aura duration timers based on remaining time."] = "Timer für die Dauer der Farbaura basierend auf der verbleibenden Zeit."
    L["Display aura duration timers."] = "Zeigt Timer für die Dauer der Aura an."
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    L["Extra aura displays"] = "Zusätzliche Aura-Displays"
    L["Font name"]        = "Schriftartenname"
    L["Font size"]        = "Schriftgröße"
    L["For spells that aren't in your spell book use the spell ID number."] = "Verwenden Sie für Zaubersprüche, die nicht in Ihrem Zauberbuch enthalten sind, die Zauber-ID-Nummer."
    L["Highlight buttons for interrupt and soothe."] = "Markieren Sie die Schaltflächen zum Tritt und Besänftigen"
    L["Ignored abilities"] = "Ignorierte Fähigkeiten"
    L["Left"]             = "Links"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    L["On ability"]       = "bei Fähigkeit"
    L["Right"]            = "Rechts"
    L["Show aura"]        = "Zeige Aura"
    L["Show aura stacks."] = "Aura-Stapel anzeigen."
    L["Show fractions of a second on timers."] = "Zeigen Sie Sekundenbruchteile auf Timern an."
    L["Stack text offset"] = "Stapelversatz"
    L["Stack text position"] = "Stapelanker"
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    L["Timer text offset"] = "Zeitgeberort Offset"
    L["Timer text position"] = "Timer-Anker"
    L["Top"]              = "Oben"
    L["Top left"]         = "Oben Links"
    L["Top right"]        = "Oben Rechts"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- esES / esMX -----------------------------------------------------------------

if locale == "esES" or locale == "esMX" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Abajo"
    L["Bottom left"]      = "Abajo Izquierda"
    L["Bottom right"]     = "Abajo Derecha"
    L["Center"]           = "Centro"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font name"]   = "Font name"--]] 
    L["Font size"]        = "Tamaño de fuente"
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "Izquierda"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "Derecha"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "Superior"
    L["Top left"]         = "Superior izquierda"
    L["Top right"]        = "Superior derecha"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- frFR ------------------------------------------------------------------------

if locale == "frFR" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Bas"
    L["Bottom left"]      = "Bas Gauche"
    L["Bottom right"]     = "Bas Droite"
    L["Center"]           = "Centre"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font name"]   = "Font name"--]] 
    L["Font size"]        = "Taille de Police"
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "Gauche"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "Droite"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "Haut"
    L["Top left"]         = "Haut Gauche"
    L["Top right"]        = "Haut Droite"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Basso"
    L["Bottom left"]      = "Basso a sinistra"
    L["Bottom right"]     = "Basso a destra"
    L["Center"]           = "Centro"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font name"]   = "Font name"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font size"]   = "Font size"--]] 
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "Left"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "Right"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "Top"
    L["Top left"]         = "Top Left"
    L["Top right"]        = "Top Right"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- koKR ------------------------------------------------------------------------

if locale == "koKR" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "아래"
    L["Bottom left"]      = "왼쪽 아래"
    L["Bottom right"]     = "오른쪽 아래"
    L["Center"]           = "중앙"
    L["Color aura duration timers based on remaining time."] = "남은 시간을 기준으로 오라 지속 시간 타이머에 색상을 지정합니다."
    L["Display aura duration timers."] = "오라 지속 시간 타이머를 표시합니다."
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    L["Font name"]        = "글꼴"
    L["Font size"]        = "글꼴 크기"
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "왼쪽"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "오른쪽"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "위"
    L["Top left"]         = "왼쪽 위"
    L["Top right"]        = "오른쪽 위"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- ptBR ------------------------------------------------------------------------

if locale == "ptBR" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Embaixo"
    L["Bottom left"]      = "Embaixo à esquerda"
    L["Bottom right"]     = "Embaixo à direita"
    L["Center"]           = "Centro"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font name"]   = "Font name"--]] 
    --[[Translation missing --]] = 
    --[[ L["Font size"]   = "Font size"--]] 
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "Esquerda"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "Direita"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "Topo"
    L["Top left"]         = "Topo à esquerda"
    L["Top right"]        = "Topo à direita"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- ruRU ------------------------------------------------------------------------

if locale == "ruRU" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "Снизу"
    L["Bottom left"]      = "Снизу слева"
    L["Bottom right"]     = "Снизу справа"
    L["Center"]           = "Центр"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    L["Font name"]        = "Шрифт"
    L["Font size"]        = "Размер шрифта"
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "Слева"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "Справа"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "Сверху"
    L["Top left"]         = "Сверху слева"
    L["Top right"]        = "Сверху справа"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- zhCN ------------------------------------------------------------------------

if locale == "zhCN" then
    L                     = L or {}
    --[[Translation missing --]] = 
    --[[ L["Aura list"]   = "Aura list"--]] 
    L["Bottom"]           = "下"
    L["Bottom left"]      = "左下"
    L["Bottom right"]     = "右下"
    L["Center"]           = "中间"
    --[[Translation missing --]] = 
    --[[ L["Color aura duration timers based on remaining time."] = "Color aura duration timers based on remaining time."--]] 
    --[[Translation missing --]] = 
    --[[ L["Display aura duration timers."] = "Display aura duration timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown ability spell: %s"] = "Error: unknown ability spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown aura spell: %s"] = "Error: unknown aura spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Error: unknown spell: %s"] = "Error: unknown spell: %s"--]] 
    --[[Translation missing --]] = 
    --[[ L["Extra aura displays"] = "Extra aura displays"--]] 
    L["Font name"]        = "字体"
    L["Font size"]        = "字体尺寸"
    --[[Translation missing --]] = 
    --[[ L["For spells that aren't in your spell book use the spell ID number."] = "For spells that aren't in your spell book use the spell ID number."--]] 
    --[[Translation missing --]] = 
    --[[ L["Highlight buttons for interrupt and soothe."] = "Highlight buttons for interrupt and soothe."--]] 
    --[[Translation missing --]] = 
    --[[ L["Ignored abilities"] = "Ignored abilities"--]] 
    L["Left"]             = "左"
    --[[Translation missing --]] = 
    --[[ L["on"]          = "on"--]] 
    --[[Translation missing --]] = 
    --[[ L["On ability"]  = "On ability"--]] 
    L["Right"]            = "右"
    --[[Translation missing --]] = 
    --[[ L["Show aura"]   = "Show aura"--]] 
    --[[Translation missing --]] = 
    --[[ L["Show aura stacks."] = "Show aura stacks."--]] 
    --[[Translation missing --]] = 
    --[[ L["Show fractions of a second on timers."] = "Show fractions of a second on timers."--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text offset"] = "Stack text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Stack text position"] = "Stack text position"--]] 
    --[[Translation missing --]] = 
    --[[ L["Text positions"] = "Text positions"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text offset"] = "Timer text offset"--]] 
    --[[Translation missing --]] = 
    --[[ L["Timer text position"] = "Timer text position"--]] 
    L["Top"]              = "上"
    L["Top left"]         = "左上"
    L["Top right"]        = "右上"
    --[[Translation missing --]] = 
    --[[ L["Wiping aura list."] = "Wiping aura list."--]] 
end

-- zhTW ------------------------------------------------------------------------

if locale == "zhTW" then
    L                     = L or {}
    L["Aura list"]        = "光環清單"
    L["Bottom"]           = "下"
    L["Bottom left"]      = "左下"
    L["Bottom right"]     = "右下"
    L["Center"]           = "中間"
    L["Color aura duration timers based on remaining time."] = "依據剩餘時間變化文字顏色"
    L["Display aura duration timers."] = "顯示光環持續時間"
    L["Error: unknown ability spell: %s"] = "錯誤: 未知的技能法術: %s"
    L["Error: unknown aura spell: %s"] = "錯誤: 未知的光環法術: %s"
    L["Error: unknown spell: %s"] = "錯誤: 未知的法術: %s"
    L["Extra aura displays"] = "額外顯示光環"
    L["Font name"]        = "字體"
    L["Font size"]        = "文字大小"
    L["For spells that aren't in your spell book use the spell ID number."] = "不在你的法術書裡面的法術請使用法術 ID 數字"
    L["Highlight buttons for interrupt and soothe."] = "斷法和安撫按鈕發光"
    L["Ignored abilities"] = "忽略技能"
    L["Left"]             = "左"
    L["on"]               = "於"
    L["On ability"]       = "於技能"
    L["Right"]            = "右"
    L["Show aura"]        = "顯示光環"
    L["Show aura stacks."] = "顯示光環層數"
    L["Show fractions of a second on timers."] = "時間顯示小數點"
    L["Stack text offset"] = "層數位置偏移"
    L["Stack text position"] = "層數位置"
    L["Text positions"]   = "位置"
    L["Timer text offset"] = "時間位置偏移"
    L["Timer text position"] = "時間位置"
    L["Top"]              = "上"
    L["Top left"]         = "左上"
    L["Top right"]        = "右上"
    L["Wiping aura list."] = "正在清空光環清單。"
end
