-- Options.lua
-- In-game options panel for DpsHelper.

DpsHelper.Options = {}

local optionsFrame = CreateFrame("Frame", "DpsHelperOptionsFrame", InterfaceOptionsFrame)
optionsFrame.name = "DpsHelper"

local function CreateOptionsPanel()
    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("DpsHelper Options")

    local toggleRecommendations = CreateFrame("CheckButton", "DpsHelperToggleRecommendations", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    toggleRecommendations:SetPoint("TOPLEFT", 32, -50)
    toggleRecommendations.text = _G[toggleRecommendations:GetName() .. "Text"]
    toggleRecommendations.text:SetText("Show Rotation Recommendations")
    toggleRecommendations.tooltipText = "Toggle rotation recommendations and ability highlights."
    toggleRecommendations:SetChecked(DpsHelper.Config and DpsHelper.Config:Get("showRecommendations") or true)
    DpsHelper.Options.ToggleRecommendations = toggleRecommendations

    local toggleDebug = CreateFrame("CheckButton", "DpsHelperToggleDebug", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    toggleDebug:SetPoint("TOPLEFT", 32, -80)
    toggleDebug.text = _G[toggleDebug:GetName() .. "Text"]
    toggleDebug.text:SetText("Enable Debug Messages")
    toggleDebug.tooltipText = "Toggle verbose debug messages in chat."
    toggleDebug:SetChecked(DpsHelper.Config and DpsHelper.Config:Get("enableDebug") or true)
    DpsHelper.Options.ToggleDebug = toggleDebug

    local uiScaleLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    uiScaleLabel:SetPoint("TOPLEFT", 32, -110)
    uiScaleLabel:SetText("UI Scale:")

    local uiScaleSlider = CreateFrame("Slider", "DpsHelperUIScaleSlider", optionsFrame, "OptionsSliderTemplate")
    uiScaleSlider:SetPoint("TOPLEFT", uiScaleLabel, "TOPRIGHT", 10, 0)
    uiScaleSlider:SetWidth(200)
    uiScaleSlider:SetMinMaxValues(0.5, 2.0)
    uiScaleSlider:SetValueStep(0.05)
    local currentScale = DpsHelper.Config and DpsHelper.Config:Get("uiScale") or 1.0
    uiScaleSlider:SetValue(currentScale)
    uiScaleSlider.tooltipText = "Adjust the size of the floating UI."
    uiScaleSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. "Text"]:SetText(string.format("%.2f", value))
    end)
    _G[uiScaleSlider:GetName() .. "Text"]:SetText(string.format("%.2f", currentScale))
    _G[uiScaleSlider:GetName() .. "Low"]:SetText("0.5")
    _G[uiScaleSlider:GetName() .. "High"]:SetText("2.0")
    DpsHelper.Options.UIScaleSlider = uiScaleSlider

    local infoText = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 16, -160)
    infoText:SetWidth(350)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Use /dpshelper [toggle|spec|scan|show|hide|lock|unlock|scale <value>|reset] for quick commands.")
end

-- Create the options panel before registering it
CreateOptionsPanel()
InterfaceOptions_AddCategory(optionsFrame)

function optionsFrame:OnShow()
    if DpsHelper.Options.ToggleRecommendations and DpsHelper.Config then
        DpsHelper.Options.ToggleRecommendations:SetChecked(DpsHelper.Config:Get("showRecommendations"))
    end
    if DpsHelper.Options.ToggleDebug and DpsHelper.Config then
        DpsHelper.Options.ToggleDebug:SetChecked(DpsHelper.Config:Get("enableDebug"))
    end
    if DpsHelper.Options.UIScaleSlider and DpsHelper.Config then
        local currentScale = DpsHelper.Config:Get("uiScale") or 1.0
        DpsHelper.Options.UIScaleSlider:SetValue(currentScale)
        _G[DpsHelper.Options.UIScaleSlider:GetName() .. "Text"]:SetText(string.format("%.2f", currentScale))
    end
end
optionsFrame:SetScript("OnShow", optionsFrame.OnShow)

function optionsFrame.okay()
    if DpsHelper.Options.ToggleRecommendations and DpsHelper.Config then
        DpsHelper.Config:Set("showRecommendations", DpsHelper.Options.ToggleRecommendations:GetChecked())
    end
    if DpsHelper.Options.ToggleDebug and DpsHelper.Config then
        DpsHelper.Config:Set("enableDebug", DpsHelper.Options.ToggleDebug:GetChecked())
    end
    if DpsHelper.Options.UIScaleSlider and DpsHelper.Config then
        DpsHelper.Config:Set("uiScale", DpsHelper.Options.UIScaleSlider:GetValue())
        DpsHelper.UI:SetScale(DpsHelper.Config:Get("uiScale"))
    end
    DpsHelper.UI:Update()
end

function optionsFrame.cancel()
    if DpsHelper.Options.ToggleRecommendations and DpsHelper.Config then
        DpsHelper.Options.ToggleRecommendations:SetChecked(DpsHelper.Config:Get("showRecommendations"))
    end
    if DpsHelper.Options.ToggleDebug and DpsHelper.Config then
        DpsHelper.Options.ToggleDebug:SetChecked(DpsHelper.Config:Get("enableDebug"))
    end
    if DpsHelper.Options.UIScaleSlider and DpsHelper.Config then
        local currentScale = DpsHelper.Config:Get("uiScale") or 1.0
        DpsHelper.Options.UIScaleSlider:SetValue(currentScale)
        _G[DpsHelper.Options.UIScaleSlider:GetName() .. "Text"]:SetText(string.format("%.2f", currentScale))
    end
end

function DpsHelper.Options:HandleCommand(msg)
    local lowerMsg = string.lower(msg or "")
    if lowerMsg == "toggle" then
        if DpsHelper.Config then
            DpsHelper.Config:Set("showRecommendations", not DpsHelper.Config:Get("showRecommendations"))
            DpsHelper.UI:Update()
        end
    elseif lowerMsg == "spec" then
        DpsHelper.TalentManager:DetectSpec()
    elseif lowerMsg == "scan" then
        DpsHelper.SpellManager:ScanSpellbook()
        DpsHelper.UI:Update()
    elseif lowerMsg == "show" then
        DpsHelper.UI:Show()
    elseif lowerMsg == "hide" then
        DpsHelper.UI:Hide()
    elseif lowerMsg == "lock" then
        DpsHelper.UI:Lock(true)
    elseif lowerMsg == "unlock" then
        DpsHelper.UI:Lock(false)
    elseif lowerMsg:match("^scale%s+([0-9.]+)$") then
        DpsHelper.UI:SetScale(lowerMsg:match("^scale%s+([0-9.]+)$"))
    elseif lowerMsg == "reset" then
        DpsHelper.UI:ResetPosition()
    else
        DpsHelper.Utils:DebugPrint(2,"Usage: /dpshelper [toggle|spec|scan|show|hide|lock|unlock|scale <value>|reset]")
    end
end