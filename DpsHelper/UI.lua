DpsHelper = DpsHelper or {}
DpsHelper.UI = {}
local mainFrame, actionFrames, buffReminderFrame = nil, {}, nil
local isLocked = false
local FRAME_WIDTH, FRAME_HEIGHT = 250, 150
local ICON_SIZE, ICON_SPACING = 30, 8
local lastRotationError = nil
local currentScale = 0.8

function DpsHelper.UI:Initialize()
    if mainFrame then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Main frame already initialized, skipping.")
        end
        return
    end

    -- Main frame setup
    mainFrame = CreateFrame("Frame", "DpsHelperMainFrame", UIParent)
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 8,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.9)
    mainFrame:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not isLocked then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -12)
    title:SetTextColor(1, 0.9, 0.1, 1)
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 0.9)
    mainFrame.title = title

    local rotationHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rotationHeader:SetPoint("TOP", mainFrame, "TOP", 0, -35)
    rotationHeader:SetText("Rotation")
    rotationHeader:SetTextColor(1, 1, 1, 1)
    rotationHeader:SetShadowOffset(1, -1)
    mainFrame.rotationHeader = rotationHeader

    -- Action frames for rotation
    actionFrames = {}
    for i = 1, 3 do
        local actionFrame = CreateFrame("Frame", "DpsHelperAction" .. i, mainFrame)
        actionFrame:SetSize(ICON_SIZE + 4, ICON_SIZE + 20)
        local totalIconsWidth = (3 * ICON_SIZE) + (2 * ICON_SPACING)
        local startX = -(totalIconsWidth / 2) + (ICON_SIZE / 2)
        actionFrame:SetPoint("CENTER", mainFrame, "CENTER", startX + (i - 1) * (ICON_SIZE + ICON_SPACING), -15)

        local icon = actionFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("TOP", actionFrame, "TOP", 0, -4)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        actionFrame.icon = icon

        local border = actionFrame:CreateTexture(nil, "BORDER")
        border:SetSize(ICON_SIZE + 6, ICON_SIZE + 6)
        border:SetPoint("CENTER", icon, "CENTER")
        border:SetTexture("Interface\\Buttons\\UI-Quickslot")
        border:SetVertexColor(0.8, 0.8, 0.8, 1)
        actionFrame.border = border

        local highlight = actionFrame:CreateTexture(nil, "OVERLAY")
        highlight:SetSize(ICON_SIZE + 8, ICON_SIZE + 8)
        highlight:SetPoint("CENTER", icon, "CENTER")
        highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        highlight:SetVertexColor(1, 0.3, 0.3, 0.8)
        highlight:SetBlendMode("ADD")
        highlight:Hide()
        actionFrame.highlight = highlight

        local durationBar = CreateFrame("StatusBar", nil, actionFrame)
        durationBar:SetSize(ICON_SIZE, 5)
        durationBar:SetPoint("BOTTOM", icon, "BOTTOM", 0, -4)
        durationBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        durationBar:SetStatusBarColor(0, 1, 0, 0.9)
        durationBar:Hide()
        actionFrame.durationBar = durationBar

        actionFrame:SetScript("OnEnter", function(self)
            if self.spellName and self.spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.type == "item" then
                    GameTooltip:SetItemByID(self.spellID)
                else
                    GameTooltip:SetSpellByID(self.spellID)
                end
                local manaCost = select(4, GetSpellInfo(self.spellName)) or 0
                local cooldown = GetSpellCooldown(self.spellName)
                local cdRemaining = cooldown and (cooldown.start + cooldown.duration - GetTime()) or 0
                if manaCost > 0 then
                    GameTooltip:AddLine("Mana Cost: " .. manaCost, 1, 1, 1)
                end
                if cdRemaining > 0 then
                    GameTooltip:AddLine("Cooldown: " .. string.format("%.1f", cdRemaining) .. "s", 1, 1, 1)
                end
                if self.type == "spell" then
                    local debuffDuration = DpsHelper.Utils:GetDebuffRemainingTime("target", self.spellName)
                    if debuffDuration > 0 then
                        GameTooltip:AddLine("Debuff Duration: " .. string.format("%.1f", debuffDuration) .. "s", 1, 0.8,
                            0.2)
                    end
                end
                GameTooltip:Show()
            end
        end)
        actionFrame:SetScript("OnLeave", GameTooltip_Hide)

        actionFrame:SetScript("OnUpdate", function(self, elapsed)
            if self.spellName and DpsHelper.SpellManager:IsSpellUsable(self.spellName) then
                if not self.highlight:IsShown() then
                    self.highlight:Show()
                end
            else
                self.highlight:Hide()
            end
            if self.duration and self.duration > 0 then
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", self.spellName) or 0
                if remaining > 0 then
                    self.durationBar:SetValue(remaining)
                    local maxDuration = self.duration
                    local percent = remaining / maxDuration
                    if percent > 0.5 then
                        self.durationBar:SetStatusBarColor(0, 1, 0, 0.9)
                    elseif percent > 0.2 then
                        self.durationBar:SetStatusBarColor(1, 1, 0, 0.9)
                    else
                        self.durationBar:SetStatusBarColor(1, 0, 0, 0.9)
                    end
                else
                    self.durationBar:Hide()
                    self.duration = 0
                end
            end
        end)
        actionFrames[i] = actionFrame
    end

    -- Buff reminder frame
    buffReminderFrame = CreateFrame("Frame", "DpsHelperBuffReminderFrame", mainFrame)
    buffReminderFrame:SetSize(FRAME_WIDTH, 100)
    buffReminderFrame:SetPoint("TOP", mainFrame, "BOTTOM", 0, -10)
    buffReminderFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 8,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    buffReminderFrame:SetBackdropColor(0, 0, 0, 0.7)
    buffReminderFrame:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
    buffReminderFrame:Hide()

    local buffReminderHeader = buffReminderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    buffReminderHeader:SetPoint("TOP", buffReminderFrame, "TOP", 0, -8)
    buffReminderHeader:SetText("Buffs/Items")
    buffReminderHeader:SetTextColor(1, 1, 1, 1)
    buffReminderHeader:SetShadowOffset(1, -1)
    buffReminderFrame.buffReminderHeader = buffReminderHeader

    local reminderIcons = {}
    for i = 1, 4 do
        local icon = buffReminderFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("LEFT", buffReminderFrame, "LEFT", (i - 1) * (ICON_SIZE + ICON_SPACING) + 10, -25)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon:Hide()
        local border = icon:GetParent():CreateTexture(nil, "BORDER")
        border:SetSize(ICON_SIZE + 6, ICON_SIZE + 6)
        border:SetPoint("CENTER", icon, "CENTER")
        border:SetTexture("Interface\\Buttons\\UI-Quickslot")
        border:SetVertexColor(0.7, 0.7, 0.7, 1)
        icon.border = border
        icon.border:Hide()

        local frame = CreateFrame("Frame", nil, buffReminderFrame)
        frame:SetSize(ICON_SIZE, ICON_SIZE)
        frame:SetPoint("CENTER", icon, "CENTER")
        frame:SetScript("OnEnter", function(self)
            if self.spellName and self.spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.type == "item" then
                    GameTooltip:SetItemByID(self.spellID)
                elseif self.type == "pet" then
                    GameTooltip:SetSpellByID(self.spellID)
                    GameTooltip:AddLine("Summons a pet for combat.", 1, 1, 1)
                else
                    GameTooltip:SetSpellByID(self.spellID)
                    local manaCost = select(4, GetSpellInfo(self.spellName)) or 0
                    if manaCost > 0 then
                        GameTooltip:AddLine("Mana Cost: " .. manaCost, 1, 1, 1)
                    end
                end
                GameTooltip:Show()
            end
        end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
        icon.frame = frame
        reminderIcons[i] = icon
    end
    buffReminderFrame.icons = reminderIcons

    local savedScale = DpsHelper.Config:Get("uiScale")
    if savedScale then
        DpsHelper.UI:SetScale(savedScale)
    end
end

function DpsHelper.UI:UpdateTitle()
    local class = DpsHelper.Config:Get("currentClass") or "unknown"
    local spec = DpsHelper.Config:Get("currentSpec") or "unknown"
    mainFrame.title:SetText(
        "DpsHelper: " .. class:gsub("^%l", string.upper) .. " (" .. spec:gsub("^%l", string.upper) .. ")")
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "UI: Updated title to class=" .. class .. ", spec=" .. spec)
    end
end

function DpsHelper.UI:UpdateRotation()
    local class = select(2, UnitClass("player")):upper()
    local spec = (DpsHelper.Config:Get("currentSpec") or "unknown"):gsub("^%l", string.upper)
    local debug = DpsHelper.Config:Get("enableDebug")

    if debug then
        DpsHelper.Utils:DebugPrint(1, "UI: Updating rotation for class=%s, spec=%s", class, spec)
    end

    if not actionFrames or #actionFrames < 3 then
        if debug then
            DpsHelper.Utils:DebugPrint(1, "UI: actionFrames not properly initialized")
        end
        return
    end

    if not DpsHelper.Rotations[class] or not DpsHelper.Rotations[class][spec] or
        not DpsHelper.Rotations[class][spec].GetRotationQueue then
        if lastRotationError ~= (class .. "_" .. spec) then
            if debug then
                DpsHelper.Utils:DebugPrint(1, "UI: Rotation not found for class=%s, spec=%s", class, spec)
            end
            lastRotationError = class .. "_" .. spec
        end
        for i = 1, 3 do
            actionFrames[i]:Hide()
        end
        return
    end

    local rotation = DpsHelper.Rotations[class][spec]
    local queue = rotation.GetRotationQueue() or {}

    if type(queue) ~= "table" then
        if debug then
            DpsHelper.Utils:DebugPrint(1, "UI: Invalid rotation queue")
        end
        for i = 1, 3 do
            actionFrames[i]:Hide()
        end
        return
    end

    if debug then
        DpsHelper.Utils:DebugPrint(1, "UI: Rotation queue retrieved with %d items", #queue)
    end

    if #queue == 0 then
        if debug then
            DpsHelper.Utils:DebugPrint(1, "UI: Empty rotation queue for class=%s, spec=%s", class, spec)
        end
        for i = 1, 3 do
            actionFrames[i]:Hide()
        end
        return
    end

    lastRotationError = nil
    for i = 1, 3 do
        local actionFrame = actionFrames[i]
        local queueItem = queue[i]

        if queueItem and queueItem.spellID and queueItem.name and queueItem.type then
            local spellName = queueItem.name
            local spellID, spellIcon
            if queueItem.type == "item" then
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(queueItem.spellID)
                spellID, spellIcon = queueItem.spellID, icon
            else
                local id, _, icon = GetSpellInfo(queueItem.spellID)
                spellID, spellIcon = id, icon
            end

            if spellName and spellID and spellIcon then
                actionFrame:Show()
                actionFrame.icon:SetTexture(spellIcon)
                actionFrame.spellID = spellID
                actionFrame.spellName = spellName
                actionFrame.type = queueItem.type
                actionFrame.border:Show()

                local duration = queueItem.type == "spell" and
                                     DpsHelper.Utils:GetDebuffRemainingTime("target", spellName) or 0
                if duration > 0 then
                    actionFrame.durationBar:SetMinMaxValues(0, duration)
                    actionFrame.durationBar:SetValue(duration)
                    actionFrame.durationBar:Show()
                    actionFrame.duration = duration
                else
                    actionFrame.durationBar:Hide()
                    actionFrame.duration = 0
                end
                actionFrame:SetAlpha(1.0 - (i - 1) * 0.1)

                if debug then
                    DpsHelper.Utils:DebugPrint(1, "UI: Showing actionFrame %d with spell=%s, ID=%d", i, spellName,
                        spellID)
                end
            else
                actionFrame:Hide()
                actionFrame.border:Hide()
                if debug then
                    DpsHelper.Utils:DebugPrint(1,
                        "UI: Invalid spell/item data for queue item %s, hiding actionFrame %d", spellName or "nil", i)
                end
            end
        else
            actionFrame:Hide()
            actionFrame.border:Hide()
            if debug then
                DpsHelper.Utils:DebugPrint(1, "UI: No queue item for actionFrame %d, hiding", i)
            end
        end
    end
end

function DpsHelper.UI:UpdateBuffReminder()
    if not buffReminderFrame then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "BuffReminder frame not initialized, calling Initialize")
        end
        self:Initialize()
    end

    local missing = DpsHelper.BuffReminder:GetMissingBuffs()
    local index = 1
    local reminderIcons = buffReminderFrame and buffReminderFrame.icons or {}

    if not reminderIcons or #reminderIcons < 4 then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "UI: reminderIcons not properly initialized")
        end
        return
    end

    for _, buff in ipairs(missing.buffs) do
        if index <= 4 then
            local _, _, icon = GetSpellInfo(buff.id)
            if icon then
                reminderIcons[index]:SetTexture(icon)
                reminderIcons[index].frame.spellName = buff.name
                reminderIcons[index].frame.spellID = buff.id
                reminderIcons[index].frame.type = "buff"
                reminderIcons[index]:Show()
                reminderIcons[index].border:Show()
                index = index + 1
            end
        end
    end

    for _, item in ipairs(missing.items) do
        if index <= 4 then
            local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(item.id)
            if icon then
                reminderIcons[index]:SetTexture(icon)
                reminderIcons[index].frame.spellName = item.name
                reminderIcons[index].frame.spellID = item.id
                reminderIcons[index].frame.type = "item"
                reminderIcons[index]:Show()
                reminderIcons[index].border:Show()
                index = index + 1
            end
        end
    end

    if missing.pet and index <= 4 then
        local _, _, icon = GetSpellInfo(missing.pet.id)
        if icon then
            reminderIcons[index]:SetTexture(icon)
            reminderIcons[index].frame.spellName = missing.pet.action
            reminderIcons[index].frame.spellID = missing.pet.id
            reminderIcons[index].frame.type = "pet"
            reminderIcons[index]:Show()
            reminderIcons[index].border:Show()
            index = index + 1
        end
    end

    for i = index, 4 do
        reminderIcons[i]:Hide()
        reminderIcons[i].border:Hide()
    end

    if index > 1 then
        buffReminderFrame:Show()
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "UI: Showing buff reminder frame with " .. (index - 1) .. " items")
        end
    else
        buffReminderFrame:Hide()
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "UI: Hiding buff reminder frame, no missing items")
        end
    end
end

function DpsHelper.UI:Update()
    if not mainFrame then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Main frame not initialized, calling Initialize")
        end
        self:Initialize()
    end
    if not DpsHelper.Config:Get("showRecommendations") then
        mainFrame:Hide()
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "UI: Recommendations disabled, hiding UI")
        end
        return
    end
    mainFrame:Show()
    self:UpdateTitle()
    self:UpdateRotation()
    self:UpdateBuffReminder()
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "UI: Full update completed")
    end
end

function DpsHelper.UI:Show()
    if not mainFrame then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Main frame not initialized, calling Initialize")
        end
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
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Main frame not initialized, calling Initialize")
        end
        self:Initialize()
    end
    scale = math.max(0.5, math.min(tonumber(scale) or 1.0, 2.0))
    mainFrame:SetScale(scale)
    DpsHelper.Config:Set("uiScale", scale)
    currentScale = scale
    self:UpdateLayout()
end

function DpsHelper.UI:UpdateLayout()
    if not mainFrame then
        return
    end
    local scale = currentScale

    -- Redimensiona o frame principal
    mainFrame:SetSize(FRAME_WIDTH * scale, FRAME_HEIGHT * scale)

    -- Redimensiona os frames de ação e seus conteúdos
    local scaledIconSize = ICON_SIZE * scale
    local scaledIconSpacing = ICON_SPACING * scale
    local totalIconsWidth = (3 * scaledIconSize) + (2 * scaledIconSpacing)
    local startX = -(totalIconsWidth / 2) + (scaledIconSize / 2)

    for i = 1, 3 do
        local actionFrame = actionFrames[i]
        if actionFrame then
            actionFrame:SetSize(scaledIconSize + 4 * scale, scaledIconSize + 20 * scale)
            actionFrame:SetPoint("CENTER", mainFrame, "CENTER", startX + (i - 1) * (scaledIconSize + scaledIconSpacing),
                -15 * scale)

            actionFrame.icon:SetSize(scaledIconSize, scaledIconSize)
            actionFrame.icon:SetPoint("TOP", actionFrame, "TOP", 0, -4 * scale)

            actionFrame.border:SetSize(scaledIconSize + 6 * scale, scaledIconSize + 6 * scale)
            actionFrame.highlight:SetSize(scaledIconSize + 8 * scale, scaledIconSize + 8 * scale)

            actionFrame.durationBar:SetSize(scaledIconSize, 5 * scale)
            actionFrame.durationBar:SetPoint("BOTTOM", actionFrame.icon, "BOTTOM", 0, -4 * scale)
        end
    end

    -- Redimensiona o buff reminder frame e seus conteúdos
    if buffReminderFrame then
        buffReminderFrame:SetSize(FRAME_WIDTH * scale, 100 * scale)
        buffReminderFrame:SetPoint("TOP", mainFrame, "BOTTOM", 0, -10 * scale)

        local reminderIcons = buffReminderFrame.icons
        if reminderIcons then
            for i = 1, 4 do
                local icon = reminderIcons[i]
                if icon then
                    icon:SetSize(scaledIconSize, scaledIconSize)
                    icon:SetPoint("LEFT", buffReminderFrame, "LEFT",
                        (i - 1) * (scaledIconSize + scaledIconSpacing) + 10 * scale, -10 * scale)
                    icon.border:SetSize(scaledIconSize + 6 * scale, scaledIconSize + 6 * scale)
                    icon.frame:SetSize(scaledIconSize, scaledIconSize)
                end
            end
        end
    end

    -- Redimensiona textos
    mainFrame.title:SetFont(mainFrame.title:GetFont(), 18 * scale, "OUTLINE")
    mainFrame.title:SetShadowOffset(1 * scale, -1 * scale)

    if mainFrame.rotationHeader then
        mainFrame.rotationHeader:SetFont(mainFrame.rotationHeader:GetFont(), 16 * scale, "OUTLINE")
        mainFrame.rotationHeader:SetShadowOffset(1 * scale, -1 * scale)
    end

    if buffReminderFrame.buffReminderHeader then
        buffReminderFrame.buffReminderHeader:SetFont(buffReminderFrame.buffReminderHeader:GetFont(), 16 * scale,
            "OUTLINE")
        buffReminderFrame.buffReminderHeader:SetShadowOffset(1 * scale, -1 * scale)
    end
end

function DpsHelper.UI:Lock(lock)
    isLocked = lock
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "UI " .. (lock and "locked" or "unlocked"))
    end
end

function DpsHelper.UI:ResetPosition()
    if mainFrame then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "UI position reset")
        end
    end
end
