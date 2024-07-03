--[[-----------------------------------------------------------------------------
From WeakAuras2
Input Widget that allows to show an alternative text when it does not have focus
Uses \0 to separate the without and with focus texts.
-------------------------------------------------------------------------------]]

local Type, Version = "LBAInputFocus", 1
local AceGUI = LibStub("AceGUI-3.0", true)

local OnEditFocusGained = function(self)
    local textWithFocus = self.obj.textWithFocus
    if textWithFocus and self:GetText() == self.obj.textWithoutFocus then
        self:SetText(textWithFocus)
    end
    AceGUI:SetFocus(self.obj)
end

local function Constructor()
    local frame = AceGUI:Create("EditBox")
    frame.type = Type

    frame.editbox:SetScript("OnEditFocusGained", OnEditFocusGained)

    local oldSetText = frame.SetText
    frame.SetText = function(self, text)
        text = text or ""
        local pos = string.find(text, "\0", nil, true)
        if pos then
            self.textWithoutFocus = text:sub(1, pos -1)
            self.textWithFocus = text:sub(pos + 1)
            oldSetText(self, self.textWithoutFocus)
        else
            self.textWithFocus = nil
            self.textWithoutFocus = nil
            oldSetText(self, text)
        end
    end

    return frame
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
