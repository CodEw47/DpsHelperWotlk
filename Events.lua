-- Events.lua
-- Manages event handling for DpsHelper addon.

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

-- Frame para gerenciar retries com OnUpdate
local retryFrame = CreateFrame("Frame", "DpsHelperRetryFrame")
retryFrame:Hide()

-- Função para tentar detectar a especialização com retry
local function TryDetectSpecWithRetry()
    local attempts, maxAttempts, delay, elapsed = 0, 2, 0.5, 0
    retryFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed < delay then return end
        attempts = attempts + 1
        elapsed = 0
        local tabCount = GetNumTalentTabs() or 0
        DpsHelper.Utils:Print("Attempt " .. attempts .. ": GetNumTalentTabs returned " .. tabCount)
        if tabCount > 0 then
            DpsHelper.SpellManager:ScanSpellbook()
            DpsHelper.TalentManager:DetectSpec()
            DpsHelper.UI:Update()
            DpsHelper.Utils:Print("Specialization detection successful on attempt " .. attempts)
            retryFrame:Hide()
        elseif attempts >= maxAttempts then
            DpsHelper.Utils:Print("Failed to detect specialization after " .. maxAttempts .. " attempts")
            DpsHelper.Config:Set("currentSpec", "unknown")
            DpsHelper.Config:Set("currentClass", select(2, UnitClass("player")):lower())
            retryFrame:Hide()
        end
    end)
    retryFrame:Show()
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "DpsHelper" then
        DpsHelper.Utils:Print("Addon loaded, initializing...")
        DpsHelper:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        DpsHelper.Utils:Print("Player login/entering world, initializing detection...")
        if not DpsHelper.isInitialized then
            DpsHelper:Initialize()
        end
        TryDetectSpecWithRetry()
        DpsHelper.UI:Show()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "LEARNED_SPELL_IN_TAB" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        DpsHelper.Utils:Print("Talent or spell update detected, refreshing...")
        DpsHelper.SpellManager:ScanSpellbook()
        DpsHelper.TalentManager:DetectSpec()
        DpsHelper.UI:Update()
    elseif event == "UNIT_AURA" and (arg1 == "player" or arg1 == "target") then
        DpsHelper.Utils:UpdateAuraCache(arg1)
        DpsHelper.UI:Update()
    elseif event == "UNIT_PET" and arg1 == "player" then
        DpsHelper.Utils:Print("Pet status changed, updating UI")
        DpsHelper.UI:Update()
    elseif event == "UNIT_COMBO_POINTS" and arg1 == "player" or event == "UNIT_POWER_UPDATE" and arg1 == "player" or
           event == "PLAYER_TARGET_CHANGED" or event == "BAG_UPDATE" or event == "SPELL_UPDATE_COOLDOWN" then
        DpsHelper.UI:Update()
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        DpsHelper.SpellManager:UpdateCache()
        DpsHelper.UI:Update()
    elseif event == "PLAYER_REGEN_ENABLED" then
        DpsHelper.Utils:Print("Combat ended, resetting combat timer")
        DpsHelper.Utils.combatStartTime = nil
        DpsHelper.Utils.RecentSpells = {}
        DpsHelper.UI:Update()
    elseif event == "PLAYER_REGEN_DISABLED" then
        DpsHelper.Utils:Print("Combat started, setting combat timer")
        DpsHelper.Utils.combatStartTime = GetTime()
        DpsHelper.UI:Update()
    end
end)