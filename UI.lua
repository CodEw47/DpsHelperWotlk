-- UI.lua
-- Manages the Guitar Hero-style UI.

DpsHelper.UI = {}
local mainFrame, actionFrames = nil, {}
local isLocked = false
local FRAME_WIDTH, FRAME_HEIGHT, ICON_SIZE, ICON_SPACING = 260, 100, 50, 4

function DpsHelper.UI:Initialize()
    if mainFrame then
        DpsHelper.Utils:Print("Main frame already initialized, skipping.")
        return
    end
    mainFrame = CreateFrame("Frame", "DpsHelperMainFrame", UIParent)
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\AddOns\\DpsHelper\\Textures\\GradientBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.7)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) if not isLocked then self:StartMoving() end end)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -5)
    title:SetText("DPS Helper")
    title:SetTextColor(1, 0.8, 0, 1)

    actionFrames = {} -- Reset actionFrames to ensure clean initialization
    for i = 1, 4 do
        local actionFrame = CreateFrame("Frame", "DpsHelperAction" .. i, mainFrame)
        actionFrame:SetSize(ICON_SIZE, ICON_SIZE + 20)
        local totalIconsWidth = (4 * ICON_SIZE) + (3 * ICON_SPACING)
        local startX = -(totalIconsWidth / 2) + (ICON_SIZE / 2)
        actionFrame:SetPoint("CENTER", mainFrame, "CENTER", startX + (i - 1) * (ICON_SIZE + ICON_SPACING), 0)

        local highlight = actionFrame:CreateTexture(nil, "BACKGROUND")
        highlight:SetSize(ICON_SIZE + 8, ICON_SIZE + 8)
        highlight:SetPoint("CENTER", actionFrame, "CENTER", 0, 5)
        highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        highlight:SetVertexColor(1, 0.8, 0, 1)
        highlight:Hide()
        actionFrame.highlight = highlight

        local icon = actionFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE - 8, ICON_SIZE - 8)
        icon:SetPoint("TOP", actionFrame, "TOP", 0, -5)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        actionFrame.icon = icon

        local durationBar = CreateFrame("StatusBar", nil, actionFrame)
        durationBar:SetSize(ICON_SIZE - 10, 8)
        durationBar:SetPoint("BOTTOM", actionFrame, "BOTTOM", 0, 2)
        durationBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        durationBar:SetStatusBarColor(0, 1, 0, 0.8)
        durationBar:SetMinMaxValues(0, 1)
        durationBar:Hide()
        actionFrame.durationBar = durationBar

        local spellText = actionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        spellText:SetPoint("BOTTOM", durationBar, "TOP", 0, 2)
        spellText:SetTextColor(1, 1, 1, 1)
        spellText:Hide()
        actionFrame.spellText = spellText

        actionFrame:SetScript("OnEnter", function(self)
            if self.spellName then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self.spellID)
                if self.duration > 0 then
                    GameTooltip:AddLine("Duration: " .. string.format("%.1f", self.duration) .. "s")
                end
                GameTooltip:Show()
            end
        end)
        actionFrame:SetScript("OnLeave", GameTooltip_Hide)

        actionFrames[i] = actionFrame
        DpsHelper.Utils:Print("Initialized actionFrame " .. i)
    end
end

function DpsHelper.UI:Update()
    DpsHelper.Utils:Print("UI:Update chamado, showRecommendations=" .. tostring(DpsHelper.Config:Get("showRecommendations")))
    if not DpsHelper.Config:Get("showRecommendations") then
        self:Hide()
        DpsHelper.Utils:Print("UI escondida porque showRecommendations está desativado")
        return
    end
    if not mainFrame then
        DpsHelper.Utils:Print("Main frame not initialized, calling Initialize")
        self:Initialize()
    end
    if not actionFrames[1] then
        DpsHelper.Utils:Print("actionFrames not initialized, reinitializing")
        self:Initialize()
    end

    local class, spec = DpsHelper.Config:Get("currentClass"), DpsHelper.Config:Get("currentSpec")
    if class == "unknown" or spec == "unknown" then
        DpsHelper.Utils:Print("Class or spec unknown, attempting to detect spec")
        DpsHelper.TalentManager:DetectSpec()
        class, spec = DpsHelper.Config:Get("currentClass"), DpsHelper.Config:Get("currentSpec")
    end

    local rotation = DpsHelper.Rotations[class] and DpsHelper.Rotations[class][spec]
    local queue = rotation and rotation.GetRotationQueue() or {}
    if not rotation then
        DpsHelper.Utils:Print("Rotation not found for class=" .. class .. ", spec=" .. spec)
    end

    for i = 1, 4 do
        local actionFrame = actionFrames[i]
        if not actionFrame then
            DpsHelper.Utils:Print("actionFrame " .. i .. " is nil, reinitializing UI")
            self:Initialize()
            actionFrame = actionFrames[i]
            if not actionFrame then
                DpsHelper.Utils:Print("Failed to initialize actionFrame " .. i)
                return
            end
        end

        local queueItem = queue[i]
        if queueItem then
            local spellName = queueItem.name
            local spellID, _, spellIcon = GetSpellInfo(spellName)
            if spellName and spellIcon then
                actionFrame:Show()
                actionFrame.icon:SetTexture(spellIcon)
                actionFrame.spellID = queueItem.spellID
                actionFrame.spellName = spellName

                local duration = DpsHelper.Utils:GetDebuffRemainingTime("target", spellName)
                if duration > 0 then
                    actionFrame.durationBar:SetMinMaxValues(0, duration)
                    actionFrame.durationBar:SetValue(duration)
                    actionFrame.durationBar:Show()
                    actionFrame.duration = duration
                else
                    actionFrame.durationBar:Hide()
                    actionFrame.duration = 0
                end

                actionFrame.spellText:SetText(i == 1 and spellName or "")
                if i == 1 then
                    actionFrame.spellText:Show()
                    actionFrame.highlight:Show()
                else
                    actionFrame.spellText:Hide()
                    actionFrame.highlight:Hide()
                end
                actionFrame:SetAlpha(1.0 - (i - 1) * 0.2)
            else
                actionFrame:Hide()
            end
        else
            actionFrame:Hide()
        end
    end
end

function DpsHelper.UI:Show()
    if not mainFrame then
        DpsHelper.Utils:Print("Main frame not initialized, calling Initialize")
        self:Initialize()
    end
    mainFrame:Show()
    self:Update()
end

function DpsHelper.UI:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

function DpsHelper.UI:SetScale(scale)
    if not mainFrame then
        DpsHelper.Utils:Print("Main frame not initialized, calling Initialize")
        self:Initialize()
    end
    scale = math.max(0.5, math.min(tonumber(scale) or 1.0, 2.0))
    mainFrame:SetScale(scale)
    DpsHelper.Config:Set("uiScale", scale)
end

function DpsHelper.UI:Lock(lock)
    isLocked = lock
    DpsHelper.Utils:Print("UI " .. (lock and "locked" or "unlocked"))
end

function DpsHelper.UI:ResetPosition()
    if mainFrame then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        DpsHelper.Utils:Print("UI position reset")
    end
end