-- UI.lua
-- Manages the unified, compact, and professional UI for DpsHelper.

DpsHelper.UI = {}
local mainFrame, actionFrames, buffFrames = nil, {}, {}
local isLocked = false
local FRAME_WIDTH, FRAME_HEIGHT = 240, 260
local ICON_SIZE, ICON_SPACING = 32, 3
local lastRotationError = nil

function DpsHelper.UI:Initialize()
    if mainFrame then
        DpsHelper.Utils:Print("Main frame already initialized, skipping.")
        return
    end

    -- Frame principal
    mainFrame = CreateFrame("Frame", "DpsHelperMainFrame", UIParent)
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 12,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.85)
    mainFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) if not isLocked then self:StartMoving() end end)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    -- Título com classe e especialização
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    title:SetTextColor(1, 0.9, 0.1, 1)
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 0.8)
    mainFrame.title = title

    -- Título da seção de buffs
    local buffHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buffHeader:SetPoint("TOP", mainFrame, "TOP", 0, -30)
    buffHeader:SetText("Buff/Item Check")
    buffHeader:SetTextColor(0.9, 0.9, 0.9, 1)
    buffHeader:SetShadowOffset(1, -1)

    -- Frames de buffs/itens/pets
    buffFrames = {}
    for i = 1, 3 do
        local buffFrame = CreateFrame("Frame", "DpsHelperBuff" .. i, mainFrame)
        buffFrame:SetSize(ICON_SIZE, ICON_SIZE + 16)
        local totalIconsWidth = (3 * ICON_SIZE) + (2 * ICON_SPACING)
        local startX = -(totalIconsWidth / 2) + (ICON_SIZE / 2)
        buffFrame:SetPoint("CENTER", mainFrame, "CENTER", startX + (i - 1) * (ICON_SIZE + ICON_SPACING), 20)

        local icon = buffFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("TOP", buffFrame, "TOP", 0, -2)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        buffFrame.icon = icon

        local highlight = buffFrame:CreateTexture(nil, "BORDER")
        highlight:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
        highlight:SetPoint("CENTER", icon, "CENTER")
        highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        highlight:SetVertexColor(1, 0.8, 0.2, 0.9)
        highlight:SetBlendMode("ADD")
        highlight:Hide()
        buffFrame.highlight = highlight

        local nameText = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("BOTTOM", buffFrame, "BOTTOM", 0, 2)
        nameText:SetTextColor(1, 1, 1, 1)
        nameText:SetShadowOffset(1, -1)
        buffFrame.nameText = nameText

        buffFrame:SetScript("OnEnter", function(self)
            if self.name then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.type == "item" then
                    GameTooltip:SetItemByID(self.id)
                else
                    GameTooltip:SetSpellByID(self.id)
                end
                GameTooltip:Show()
            end
        end)
        buffFrame:SetScript("OnLeave", GameTooltip_Hide)

        buffFrame:SetScript("OnUpdate", function(self)
            if self.name and DpsHelper.SpellManager:IsSpellUsable(self.name) then
                self.highlight:Show()
            else
                self.highlight:Hide()
            end
        end)

        buffFrames[i] = buffFrame
    end

    -- Título da seção de rotação
    local rotationHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rotationHeader:SetPoint("TOP", mainFrame, "TOP", 0, -70)
    rotationHeader:SetText("Primary Rotation")
    rotationHeader:SetTextColor(0.9, 0.9, 0.9, 1)
    rotationHeader:SetShadowOffset(1, -1)

    -- Frames de rotação
    actionFrames = {}
    for i = 1, 4 do
        local actionFrame = CreateFrame("Frame", "DpsHelperAction" .. i, mainFrame)
        actionFrame:SetSize(ICON_SIZE, ICON_SIZE + 16)
        local totalIconsWidth = (4 * ICON_SIZE) + (3 * ICON_SPACING)
        local startX = -(totalIconsWidth / 2) + (ICON_SIZE / 2)
        actionFrame:SetPoint("CENTER", mainFrame, "CENTER", startX + (i - 1) * (ICON_SIZE + ICON_SPACING), -80)

        local icon = actionFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("TOP", actionFrame, "TOP", 0, -2)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        actionFrame.icon = icon

        local highlight = actionFrame:CreateTexture(nil, "BORDER")
        highlight:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
        highlight:SetPoint("CENTER", icon, "CENTER")
        highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        highlight:SetVertexColor(1, 0.2, 0.2, 0.9)
        highlight:SetBlendMode("ADD")
        highlight:Hide()
        actionFrame.highlight = highlight

        local durationBar = CreateFrame("StatusBar", nil, actionFrame)
        durationBar:SetSize(ICON_SIZE, 4)
        durationBar:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        durationBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        durationBar:SetStatusBarColor(0, 1, 0, 0.8)
        durationBar:Hide()
        actionFrame.durationBar = durationBar

        local spellText = actionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        spellText:SetPoint("BOTTOM", actionFrame, "BOTTOM", 0, 2)
        spellText:SetTextColor(1, 1, 1, 1)
        spellText:SetShadowOffset(1, -1)
        actionFrame.spellText = spellText

        actionFrame:SetScript("OnEnter", function(self)
            if self.spellName then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self.spellID)
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
                else
                    self.durationBar:Hide()
                    self.duration = 0
                end
            end
        end)

        actionFrames[i] = actionFrame
    end

    mainFrame:SetScale(DpsHelper.Config:Get("uiScale") or 0.8)
    DpsHelper.Utils:Print("UI initialized with scale: " .. (DpsHelper.Config:Get("uiScale") or 0.8))
end

function DpsHelper.UI:Update()
    if not mainFrame then
        DpsHelper.Utils:Print("Main frame not initialized, calling Initialize")
        self:Initialize()
    end
    if not DpsHelper.Config:Get("showRecommendations") then
        mainFrame:Hide()
        DpsHelper.Utils:Print("Recommendations disabled, hiding UI")
        return
    end
    mainFrame:Show()

    local class = (DpsHelper.Config:Get("currentClass") or "unknown"):upper()
    local spec = (DpsHelper.Config:Get("currentSpec") or "unknown"):gsub("^%l", string.upper)
    local className = select(1, UnitClass("player")) or "Unknown"
    local specName = spec ~= "unknown" and spec or "Unknown"
    mainFrame.title:SetText(className .. " - " .. specName)

    -- Atualizar buffs/itens/pets
    local missing = DpsHelper.BuffReminder:GetMissingBuffs()
    local buffQueue = {}
    for _, buff in ipairs(missing.buffs) do
        table.insert(buffQueue, { name = buff.name, id = buff.id, type = "buff" })
    end
    for _, item in ipairs(missing.items) do
        table.insert(buffQueue, { name = item.name, id = item.id, type = "item" })
    end
    if missing.pet then
        table.insert(buffQueue, { name = missing.pet, id = 688, type = "pet" })
    end

    for i = 1, 3 do
        local buffFrame = buffFrames[i]
        local buffItem = buffQueue[i]
        if buffItem then
            local icon
            if buffItem.type == "item" then
                _, _, _, _, _, _, _, _, _, icon = GetItemInfo(buffItem.id)
            else
                _, _, icon = GetSpellInfo(buffItem.id)
            end
            if buffItem.name and buffItem.id and icon then
                buffFrame:Show()
                buffFrame.icon:SetTexture(icon)
                buffFrame.name = buffItem.name
                buffFrame.id = buffItem.id
                buffFrame.type = buffItem.type
                buffFrame.nameText:SetText(i == 1 and buffItem.name or "")
                if i == 1 then
                    buffFrame.nameText:Show()
                else
                    buffFrame.nameText:Hide()
                end
                buffFrame:SetAlpha(1.0 - (i - 1) * 0.15)
            else
                buffFrame:Hide()
                DpsHelper.Utils:Print("Invalid buff/item data: " .. (buffItem.name or "nil"))
            end
        else
            buffFrame:Hide()
        end
    end

    -- Atualizar rotação primária
    if class == "UNKNOWN" or spec == "UNKNOWN" then
        if lastRotationError ~= "class_spec_unknown" then
            DpsHelper.Utils:Print("Class or spec unknown, skipping rotation update")
            lastRotationError = "class_spec_unknown"
        end
        for i = 1, 4 do
            actionFrames[i]:Hide()
        end
        return
    end

    local rotation = DpsHelper.Rotations[class] and DpsHelper.Rotations[class][spec]
    if not rotation or not rotation.GetRotationQueue then
        if lastRotationError ~= (class .. "_" .. spec) then
            DpsHelper.Utils:Print("Rotation not found for class=" .. class .. ", spec=" .. spec)
            lastRotationError = class .. "_" .. spec
        end
        for i = 1, 4 do
            actionFrames[i]:Hide()
        end
        return
    end

    lastRotationError = nil
    local queue = rotation.GetRotationQueue() or {}
    if #queue == 0 then
        DpsHelper.Utils:Print("Empty rotation queue for class=" .. class .. ", spec=" .. spec)
        for i = 1, 4 do
            actionFrames[i]:Hide()
        end
        return
    end

    for i = 1, 4 do
        local actionFrame = actionFrames[i]
        local queueItem = queue[i]
        if queueItem then
            local spellName = queueItem.name
            local spellID, _, spellIcon
            if queueItem.type == "item" then
                _, _, _, _, _, _, _, _, _, spellIcon = GetItemInfo(queueItem.spellID)
                spellID = queueItem.spellID
            else
                spellID, _, spellIcon = GetSpellInfo(queueItem.spellID)
            end
            if spellName and spellID and spellIcon then
                actionFrame:Show()
                actionFrame.icon:SetTexture(spellIcon)
                actionFrame.spellID = queueItem.spellID
                actionFrame.spellName = spellName

                local duration = queueItem.type == "spell" and DpsHelper.Utils:GetDebuffRemainingTime("target", spellName) or 0
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
                else
                    actionFrame.spellText:Hide()
                end
                actionFrame:SetAlpha(1.0 - (i - 1) * 0.15)
            else
                actionFrame:Hide()
                DpsHelper.Utils:Print("Invalid spell data for rotation item " .. (spellName or "nil") .. ", hiding actionFrame " .. i)
            end
        else
            actionFrame:Hide()
            DpsHelper.Utils:Print("No queue item for actionFrame " .. i .. ", hiding")
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
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        DpsHelper.Utils:Print("UI position reset")
    end
end