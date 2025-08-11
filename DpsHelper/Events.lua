DpsHelper = DpsHelper or {}
DpsHelper.Utils = DpsHelper.Utils or {}
DpsHelper.Utils.combatStartTime = nil

local eventFrame = CreateFrame("Frame", "DpsHelperEventFrame")
local events = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TALENT_UPDATE",
    "LEARNED_SPELL_IN_TAB",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "UNIT_AURA",
    "UNIT_COMBO_POINTS",
    "UNIT_POWER_UPDATE",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE",
    "SPELL_UPDATE_COOLDOWN",
    "UNIT_PET"
}

for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
end

-- Frame for handling retries with OnUpdate
local retryFrame = CreateFrame("Frame", "DpsHelperRetryFrame")
retryFrame:Hide()

-- Function to attempt specialization detection with retry
local function TryDetectSpecWithRetry()
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "Events: Starting specialization detection retry")
    end
    local attempts, maxAttempts, delay, elapsed = 0, 2, 0.5, 0
    
    retryFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed < delay then return end
        attempts = attempts + 1
        local tabCount = GetNumTalentTabs() or 0
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Attempt " .. attempts .. ": GetNumTalentTabs returned " .. tabCount)
        end
        if tabCount > 0 then
            DpsHelper.TalentManager:DetectSpec()
            DpsHelper.SpellManager.scanned = false
            DpsHelper.SpellManager:ScanSpellbook()
            DpsHelper.UI:Update()
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(1, "Events: Specialization detection successful on attempt " .. attempts)
            end
            retryFrame:Hide()
        elseif attempts >= maxAttempts then
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(1, "Events: Failed to detect specialization after " .. maxAttempts .. " attempts")
            end
            DpsHelper.Config:Set("currentClass", select(2, UnitClass("player")):lower())
            DpsHelper.UI:Update()
            retryFrame:Hide()
        end
    end)
    retryFrame:Show()
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "DpsHelper" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Addon loaded, initializing...")
        end
        DpsHelper:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Player login/entering world, initializing detection...")
        end
        DpsHelper.SpellManager.scanned = false
        DpsHelper.SpellManager.scannedInventory = false
        DpsHelper.SpellManager.PoisonCache = {}
        if not DpsHelper.isInitialized then
            DpsHelper:Initialize()
        end
        TryDetectSpecWithRetry()
        DpsHelper.UI:Show()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "LEARNED_SPELL_IN_TAB" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Talent or spell update detected, refreshing...")
        end
        DpsHelper.SpellManager.scanned = false
        DpsHelper.TalentManager:DetectSpec()
        DpsHelper.SpellManager:ScanSpellbook()
        DpsHelper.UI:Update()
    elseif event == "UNIT_AURA" and (arg1 == "player" or arg1 == "target") then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Aura update for unit=" .. arg1)
        end
        DpsHelper.Utils:UpdateAuraCache(arg1)
        DpsHelper.UI:Update()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "UNIT_PET" and arg1 == "player" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Pet status changed, updating UI")
        end
        DpsHelper.UI:Update()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "UNIT_COMBO_POINTS" and arg1 == "player" or event == "UNIT_POWER_UPDATE" and arg1 == "player" or
           event == "SPELL_UPDATE_COOLDOWN" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Updating UI for event=" .. event)
        end
        DpsHelper.UI:Update()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(1, "Events: Enemy target changed, updating UI")
            end
            DpsHelper.UI:Update()
            DpsHelper.UI:UpdateBuffReminder()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" or event == "BAG_UPDATE" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Inventory or bag update, scanning inventory...")
        end
        DpsHelper.SpellManager.scannedInventory = false
        DpsHelper.SpellManager.PoisonCache = {}
        DpsHelper.SpellManager:ScanInventory()
        DpsHelper.UI:Update()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Combat ended, resetting combat timer")
        end
        DpsHelper.Utils.combatStartTime = nil
        DpsHelper.Utils.RecentSpells = {}
        DpsHelper.UI:Update()
        DpsHelper.UI:UpdateBuffReminder()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "Events: Combat started, setting combat timer")
        end
        DpsHelper.Utils.combatStartTime = GetTime()
        DpsHelper.UI:Update()
    end
end)