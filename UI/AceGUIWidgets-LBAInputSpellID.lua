local _, LBA = ...

local C_Spell = LBA.C_Spell or C_Spell

local AceGUI = LibStub("AceGUI-3.0")

local Type = "LBAInputSpellID"
local Version = 1
local PREDICTION_ROWS = 20

local function GetSpellText(id)
    local info = C_Spell.GetSpellInfo(id or 0)
    if info then
        local idText = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(string.format('(%d)', info.spellID))
        return string.format("%s %s", info.name, idText)
    else
        return ''
    end
end

-- [[ SpellCache ]] ------------------------------------------------------------

local SpellCache = CreateFrame("Frame")

function SpellCache.BuildCoRoutine()
    local id = 0
    local misses = 0
    while misses < 80000 do
        id = id + 1
        local info = C_Spell.GetSpellInfo(id)

        if not info then
            misses = misses + 1
        elseif info.iconID == 136243  then
            -- 136243 is the a gear icon, we can ignore those spells
            misses = 0;
        elseif info.name and info.name ~= "" and info.iconID then
            local name = info.name:lower()
            SpellCache.spells[name] = SpellCache.spells[name] or {}
            table.insert(SpellCache.spells[name], id)
            if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and id == 81748 then
                 -- jump around big hole with classic SoD
                id = 219002
            end
            misses = 0
        else
            misses = misses + 1
        end
        if id % 1000 == 0 then
            coroutine.yield()
        end
    end
    for _, cacheLine in pairs(SpellCache.spells) do
        table.sort(cacheLine)
    end
end

function SpellCache:Build()

    if self.spells then return end

    self.spells = {}

    local co = coroutine.create(self.BuildCoRoutine)
    coroutine.resume(co)

    self:SetScript("OnUpdate",
        function (self, elapsed)
            if coroutine.status(co) == "dead" then
                self:SetScript("OnUpdate", nil)
            else
                coroutine.resume(co)
            end
        end)
end

function SpellCache:Get(name)
    if name then
        name = name:lower()
        return self.spells[name]
    end
end


-- [[ OkayButton ]] ------------------------------------------------------------

local OkayButtonMixin = {}

function OkayButtonMixin:Initialize(obj)
    self.obj = obj
    self:SetWidth(40)
    self:SetHeight(20)
    self:SetText(OKAY)
    self:SetScript("OnClick", self.OnClick)
    self:Hide()
end

function OkayButtonMixin:OnClick()
    local editBox = self.obj.editBox
    editBox:OnEnterPressed()
    editBox:ClearFocus()
end


-- [[ PredictSpellButton ]] ----------------------------------------------------

local PredictSpellButtonMixin = {}

function PredictSpellButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetHyperlink("spell:" .. self.spellID)
end

function PredictSpellButtonMixin:OnClick()
    self.obj:SetValue(self.spellID)
    self.obj:SubmitValue()
    self.obj:Update()
end

function PredictSpellButtonMixin:SetSpell(id)
    self.spellID = id
    local info = C_Spell.GetSpellInfo(id)
    self:SetFormattedText("|T%s:18:18:0:0|t %s", info.iconID, GetSpellText(id))
end

function PredictSpellButtonMixin:Initialize(obj)
    self.obj = obj
    self:SetHeight(22)
    self:SetScript("OnClick", self.OnClick)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", GameTooltip_Hide)

    -- Create the actual text
    self.text = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.text:SetJustifyH("LEFT")
    self.text:SetAllPoints(self)
    self:SetFontString(self.text)

    -- Setup the highlighting
    self.highlightTexture = self:CreateTexture(nil, "ARTWORK")
    self.highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    self.highlightTexture:ClearAllPoints()
    self.highlightTexture:SetPoint("TOPLEFT", self, 0, -2)
    self.highlightTexture:SetPoint("BOTTOMRIGHT", self, 5, 2)
    self.highlightTexture:SetAlpha(0.70)

    self:SetHighlightTexture(self.highlightTexture)
    self:SetHighlightFontObject(GameFontHighlight)
    self:SetNormalFontObject(GameFontNormal)
end


-- [[ PredictFrame ]] ----------------------------------------------------------

local PredictFrameMixin = {}

local backdrop = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tileEdge = true,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

function PredictFrameMixin:Initialize(obj)
    self.obj = obj

    self:SetBackdrop(backdrop)
    self:SetBackdropColor(0, 0, 0, 0.85)
    self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    self:SetFrameStrata("TOOLTIP")

    self.buttons = {}

    for i = 1, PREDICTION_ROWS do
        local button = CreateFrame("Button", self:GetName() .. "Button" .. i, self)
        Mixin(button, PredictSpellButtonMixin)
        button:Initialize(obj)

        if i > 1 then
            button:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT", 0, 0)
            button:SetPoint("TOPRIGHT", self.buttons[i - 1], "BOTTOMRIGHT", 0, 0)
        else
            -- Total vOff here 8+7 = 15 matches the 15 + for SetHeight
            button:SetPoint("TOPLEFT", self, 8, -8)
            button:SetPoint("TOPRIGHT", self, -7, 0)
        end

        self.buttons[i] = button
    end
end

function PredictFrameMixin:UpdateSearch(name)
    for _, button in pairs(self.buttons) do
        button:Hide()
    end

    local spellIDList = SpellCache:Get(name)
    local nShown = 0

    if spellIDList then
        for i, spellID in ipairs(spellIDList) do
            local button = self.buttons[i]
            button:SetSpell(spellID)
            button:Show()

            button:UnlockHighlight()
            if GameTooltip:IsOwned(button) then
                GameTooltip_Hide()
            end

            nShown = i

            if i >= PREDICTION_ROWS then
                break
            end
        end
        self:SetHeight(15 + nShown * self.buttons[1]:GetHeight())
        self:Show()
    else
        self:Hide()
    end
end


-- [[ EditBox ]] ---------------------------------------------------------------

local EditBoxMixin = {}

function EditBoxMixin:OnTextChanged()
    local value = self:GetText()
    self.obj:Fire("OnTextChanged", value)
    self.obj:Update()
end

function EditBoxMixin:OnEditFocusLost()
    self.obj:Update()
end

function EditBoxMixin:OnEditFocusGained()
    self:SetText(self.obj.value or '')
    self.obj:Update()
end

function EditBoxMixin:OnEscapePressed()
    self:ClearFocus()
end

function EditBoxMixin:OnEnterPressed()
    local value = self:GetText()
    self.obj:SetValue(value)
    local isInvalid = self.obj:SubmitValue()
    if isInvalid then self:SetFocus() end
    self.obj:Update()
end

function EditBoxMixin:OnEnter()
    self.obj:Fire("OnEnter")
end

function EditBoxMixin:OnLeave()
    self.obj:Fire("OnLeave")
end

function EditBoxMixin:Initialize(obj)
    self.obj = obj
    self:SetAutoFocus(false)
    self:SetFontObject(ChatFontNormal)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("OnEscapePressed", self.OnEscapePressed)
    self:SetScript("OnEnterPressed", self.OnEnterPressed)
    self:SetScript("OnTextChanged", self.OnTextChanged)
    self:SetScript("OnEditFocusGained", self.OnEditFocusGained)
    self:SetScript("OnEditFocusLost", self.OnEditFocusLost)
    self:SetTextInsets(0, 0, 3, 3)
    self:SetMaxLetters(256)
end


--[[ Main Widget ]] ------------------------------------------------------------

local methods = {

    OnAcquire =
        function (self)
            self:SetHeight(26)
            self:SetWidth(200)
            self:SetDisabled(false)
            self:SetLabel()
        end,

    OnRelease =
        function (self)
            self.frame:ClearAllPoints()
            self.frame:Hide()
            self.predictFrame:Hide()
            self:SetDisabled(false)
        end,

    Update =
        function (self)
            if self.predictFrame:IsMouseOver() and IsMouseButtonDown('LeftButton') then
                -- In the middle of a predict spell click, don't mess it up.
                return
            end
            if self.editBox:HasFocus() then
                self.predictFrame:UpdateSearch(self.editBox:GetText())
                self.okayButton:Show()
            else
                self.predictFrame:Hide()
                self.editBox:SetText(GetSpellText(self.value))
                self.okayButton:Hide()
            end
        end,

    SetDisabled =
        function (self, disabled)
            self.disabled = disabled
            if disabled then
                self.editBox:EnableMouse(false)
                self.editBox:ClearFocus()
                self.editBox:SetTextColor(0.5, 0.5, 0.5)
                self.label:SetTextColor(0.5, 0.5, 0.5)
            else
                self.editBox:EnableMouse(true)
                self.editBox:SetTextColor(1, 1, 1)
                self.label:SetTextColor(1, 0.82, 0)
            end
        end,

    SetText =
        function (self, text, cursor)
            self.editBox:SetText(text)
            self.editBox:SetCursorPosition(cursor or 0)
            self:Update()
        end,

    SetLabel =
        function (self, text)
            if text and text ~= "" then
                self.label:SetText(text)
                self.label:Show()
                self.editBox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, -18)
                self:SetHeight(44)
                self.alignoffset = 30
            else
                self.label:SetText("")
                self.label:Hide()
                self.editBox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, 0)
                self:SetHeight(26)
                self.alignoffset = 12
            end
        end,

    SetValue =
        function (self, value)
            if tonumber(value) then
                self.value = value
            else
                local info = C_Spell.GetSpellInfo(value)
                self.value = info and info.name or ''
            end
        end,

    SubmitValue =
        function (self)
            return self:Fire("OnEnterPressed", self.value or '')
        end,
}


local function Constructor()
    SpellCache:Build()

    local self = CreateFromMixins(methods)
    self.type = Type
    self.num = AceGUI:GetNextWidgetNum(Type)

    self.frame = CreateFrame("Frame", nil, UIParent)
    self.frame:SetHeight(44)
    self.frame:SetWidth(200)
    self.frame.obj = self

    self.editBox = CreateFrame("EditBox", "AceGUI30SpellEditBox" .. self.num, self.frame, "InputBoxTemplate")
    Mixin(self.editBox, EditBoxMixin)
    self.editBox:Initialize(self)
    self.editBox:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 6, 0)
    self.editBox:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
    self.editBox:SetHeight(19)

    self.predictFrame = CreateFrame("Frame", "AceGUI30SpellEditBox" .. self.num .. "PredictFrame", UIParent, "BackdropTemplate")
    Mixin(self.predictFrame, PredictFrameMixin)
    self.predictFrame:Initialize(self)
    self.predictFrame:SetPoint("TOPLEFT", self.editBox, "BOTTOMLEFT", -6, 0)
    self.predictFrame:SetPoint("TOPRIGHT", self.editBox, "BOTTOMRIGHT", 0, 0)

    self.alignoffset = 30

    self.label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)
    self.label:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -2)
    self.label:SetJustifyH("LEFT")
    self.label:SetHeight(18)

    self.okayButton = CreateFrame("Button", nil, self.editBox, "UIPanelButtonTemplate")
    Mixin(self.okayButton, OkayButtonMixin)
    self.okayButton:Initialize(self)
    self.okayButton:SetPoint("RIGHT", self.editBox, "RIGHT", -2, 0)

    AceGUI:RegisterAsWidget(self)
    return self
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
