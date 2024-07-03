local _, LBA = ...

local AceGUI = LibStub("AceGUI-3.0")

local C_Spell = LBA.C_Spell or C_Spell

local Type = "LBAInputValidSpell"
local Version = 1

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

function SpellCache:IsValidSpell(v)
    if C_Spell.GetSpellName(v) then
        return true
    elseif type(v) == 'string' then
        v = v:lower()
        return self.spells[v] ~= nil
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
    self:SetScript("OnShow", self.OnShow)
    self:SetScript("OnHide", self.OnHide)
    self:Hide()
end

function OkayButtonMixin:OnClick()
    local editBox = self.obj.editBox
    editBox:OnEnterPressed()
end

function OkayButtonMixin:OnShow()
    self.obj.editBox:SetTextInsets(0, 20, 3, 3)
end

function OkayButtonMixin:OnHide()
    self.obj.editBox:SetTextInsets(0, 0, 3, 3)
end

-- [[ EditBox ]] ---------------------------------------------------------------

local EditBoxMixin = {}

function EditBoxMixin:OnTextChanged()
    local value = self:GetText()
    if value ~= self.lastText then
        self.lastText = value
        if SpellCache:IsValidSpell(value) then
            self.obj.okayButton:Show()
        end
        self.obj:Fire("OnTextChanged", value)
    end
end

function EditBoxMixin:OnEditFocusGained()
    AceGUI:SetFocus(self.obj)
end

function EditBoxMixin:OnEscapePressed()
    self:ClearFocus()
end

function EditBoxMixin:OnEnterPressed()
    local value = self:GetText()
    if SpellCache:IsValidSpell(value) then
        local isInvalid = self.obj:Fire("OnEnterPressed", value)
        if isInvalid then
            self:SetFocus()
        else
            self.obj.okayButton:Hide()
        end
    end
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
            self:SetDisabled(false)
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

    self.label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)
    self.label:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -2)
    self.label:SetJustifyH("LEFT")
    self.label:SetHeight(18)

    self.okayButton = CreateFrame("Button", nil, self.editBox, "UIPanelButtonTemplate")
    Mixin(self.okayButton, OkayButtonMixin)
    self.okayButton:Initialize(self)
    self.okayButton:SetPoint("RIGHT", self.editBox, "RIGHT", -2, 0)

    self.alignoffset = 30

    AceGUI:RegisterAsWidget(self)
    return self
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
