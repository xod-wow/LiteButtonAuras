--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2024 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local _, LBA = ...

local L = setmetatable({}, { __index = function (t,k) return k end })

LBA.L = L

local locale = GetLocale()

-- :r! sh fetchlocale.sh -------------------------------------------------------

-- deDE ------------------------------------------------------------------------

if locale == "deDE" then
    L                     = L or {}
    L["Abilities"]        = "Fähigkeiten"
    L["Anchors"]          = "Anker"
    L["Bottom"]           = "Unten"
    L["Bottom Left"]      = "Unten Links"
    L["Bottom Right"]     = "Unten Rechts"
    L["Center"]           = "Mitte"
    L["Color aura duration timers based on remaining time."] = "Timer für die Dauer der Farbaura basierend auf der verbleibenden Zeit."
    L["Display aura duration timers."] = "Zeigt Timer für die Dauer der Aura an."
    L["Extra Aura Displays"] = "Zusätzliche Aura-Displays"
    L["Font name"]        = "Schriftartenname"
    L["Font size"]        = "Schriftgröße"
    L["For spells that aren't in your spell book use the spell ID number."] = "Verwenden Sie für Zaubersprüche, die nicht in Ihrem Zauberbuch enthalten sind, die Zauber-ID-Nummer."
    L["Highlight buttons for interrupt and soothe."] = "Markieren Sie die Schaltflächen zum Tritt und Besänftigen"
    L["Ignore ability"]   = "Fähigkeit ignorieren"
    L["Ignored Abilities"] = "Ignorierte Fähigkeiten"
    L["Invalid spell: %s."] = "Ungültiger Zauber: %s."
    L["Left"]             = "Links"
    L["On ability"]       = "bei Fähigkeit"
    L["Right"]            = "Rechts"
    L["Show aura"]        = "Zeige Aura"
    L["Show aura stacks."] = "Aura-Stapel anzeigen."
    L["Show fractions of a second on timers."] = "Zeigen Sie Sekundenbruchteile auf Timern an."
    L["Stacks Anchor"]    = "Stapelanker"
    L["Stacks Offset"]    = "Stapelversatz"
    L["Timer Anchor"]     = "Timer-Anker"
    L["Timer Offset"]     = "Zeitgeberort Offset"
    L["Top"]              = "Oben"
    L["Top Left"]         = "Oben Links"
    L["Top Right"]        = "Oben Rechts"
end

-- esES / esMX -----------------------------------------------------------------

if locale == "esES" or locale == "esMX" then
    L                     = L or {}
    L["Abilities"]        = "Habilidades"
    L["Bottom"]           = "Abajo"
    L["Bottom Left"]      = "Abajo Izquierda"
    L["Bottom Right"]     = "Abajo Derecha"
    L["Center"]           = "Centro"
    L["Font size"]        = "Tamaño de fuente"
    L["Left"]             = "Izquierda"
    L["Right"]            = "Derecha"
    L["Top"]              = "Superior"
    L["Top Left"]         = "Superior izquierda"
    L["Top Right"]        = "Superior derecha"
end

-- frFR ------------------------------------------------------------------------

if locale == "frFR" then
    L                     = L or {}
    L["Abilities"]        = "Capacités"
    L["Bottom"]           = "Bas"
    L["Bottom Left"]      = "Bas Gauche"
    L["Bottom Right"]     = "Bas Droite"
    L["Center"]           = "Centre"
    L["Font size"]        = "Taille de Police"
    L["Left"]             = "Gauche"
    L["Right"]            = "Droite"
    L["Top"]              = "Haut"
    L["Top Left"]         = "Haut Gauche"
    L["Top Right"]        = "Haut Droite"
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
    L["Abilities"]        = "Abilità"
    L["Bottom"]           = "Basso"
    L["Bottom Left"]      = "Basso a sinistra"
    L["Bottom Right"]     = "Basso a destra"
    L["Center"]           = "Centro"
    L["Left"]             = "Left"
    L["Right"]            = "Right"
    L["Top"]              = "Top"
    L["Top Left"]         = "Top Left"
    L["Top Right"]        = "Top Right"
end

-- koKR ------------------------------------------------------------------------

if locale == "koKR" then
    L                     = L or {}
    L["Abilities"]        = "스킬"
    L["Anchors"]          = "앵커"
    L["Bottom"]           = "아래"
    L["Bottom Left"]      = "왼쪽 아래"
    L["Bottom Right"]     = "오른쪽 아래"
    L["Center"]           = "중앙"
    L["Color aura duration timers based on remaining time."] = "남은 시간을 기준으로 오라 지속 시간 타이머에 색상을 지정합니다."
    L["Display aura duration timers."] = "오라 지속 시간 타이머를 표시합니다."
    L["Font name"]        = "글꼴"
    L["Font size"]        = "글꼴 크기"
    L["Left"]             = "왼쪽"
    L["Right"]            = "오른쪽"
    L["Top"]              = "위"
    L["Top Left"]         = "왼쪽 위"
    L["Top Right"]        = "오른쪽 위"
end

-- ptBR ------------------------------------------------------------------------

if locale == "ptBR" then
    L                     = L or {}
    L["Abilities"]        = "Habilidades"
    L["Bottom"]           = "Embaixo"
    L["Bottom Left"]      = "Embaixo à esquerda"
    L["Bottom Right"]     = "Embaixo à direita"
    L["Center"]           = "Centro"
    L["Left"]             = "Esquerda"
    L["Right"]            = "Direita"
    L["Top"]              = "Topo"
    L["Top Left"]         = "Topo à esquerda"
    L["Top Right"]        = "Topo à direita"
end

-- ruRU ------------------------------------------------------------------------

if locale == "ruRU" then
    L                     = L or {}
    L["Abilities"]        = "Способности"
    L["Bottom"]           = "Снизу"
    L["Bottom Left"]      = "Снизу слева"
    L["Bottom Right"]     = "Снизу справа"
    L["Center"]           = "Центр"
    L["Font name"]        = "Шрифт"
    L["Font size"]        = "Размер шрифта"
    L["Left"]             = "Слева"
    L["Right"]            = "Справа"
    L["Top"]              = "Сверху"
    L["Top Left"]         = "Сверху слева"
    L["Top Right"]        = "Сверху справа"
end

-- zhCN ------------------------------------------------------------------------

if locale == "zhCN" then
    L                     = L or {}
    L["Abilities"]        = "技能"
    L["Bottom"]           = "下"
    L["Bottom Left"]      = "左下"
    L["Bottom Right"]     = "右下"
    L["Center"]           = "中间"
    L["Font name"]        = "字体"
    L["Font size"]        = "字体尺寸"
    L["Left"]             = "左"
    L["Right"]            = "右"
    L["Top"]              = "上"
    L["Top Left"]         = "左上"
    L["Top Right"]        = "右上"
end

-- zhTW ------------------------------------------------------------------------

if locale == "zhTW" then
    L                     = L or {}
    L["Abilities"]        = "技能"
    L["Bottom"]           = "下"
    L["Bottom Left"]      = "左下"
    L["Bottom Right"]     = "右下"
    L["Center"]           = "中間"
    L["Font name"]        = "字體"
    L["Font size"]        = "文字大小"
    L["Left"]             = "左"
    L["Right"]            = "右"
    L["Top"]              = "上"
    L["Top Left"]         = "左上"
    L["Top Right"]        = "右上"
end
