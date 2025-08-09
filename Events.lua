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
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Attempt " .. attempts .. ": GetNumTalentTabs returned " .. tabCount)
        end
        if tabCount > 0 then
            DpsHelper.TalentManager:DetectSpec()
            DpsHelper.SpellManager.scanned = false  -- Força rescan do spellbook
            DpsHelper.SpellManager:ScanSpellbook()
            DpsHelper.UI:Update()
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Specialization detection successful on attempt " .. attempts)
            end
            retryFrame:Hide()
        elseif attempts >= maxAttempts then
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Failed to detect specialization after " .. maxAttempts .. " attempts")
            end
            DpsHelper.Config:Set("currentSpec", "unknown")
            DpsHelper.Config:Set("currentClass", select(2, UnitClass("player")):lower())
            retryFrame:Hide()
        end
    end)
    retryFrame:Show()
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "DpsHelper" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Addon loaded, initializing...")
        end
        DpsHelper:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Player login/entering world, initializing detection...")
        end
        -- Limpa currentClass e currentSpec do cache
        DpsHelper.Config:Set("currentClass", nil)
        DpsHelper.Config:Set("currentSpec", nil)
        -- Reseta flags de cache para forçar novos scans
        DpsHelper.SpellManager.scanned = false
        DpsHelper.SpellManager.scannedInventory = false
        DpsHelper.SpellManager.PoisonCache = {}
        if not DpsHelper.isInitialized then
            DpsHelper:Initialize()
        end
        TryDetectSpecWithRetry()
        DpsHelper.UI:Show()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "LEARNED_SPELL_IN_TAB" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Talent or spell update detected, refreshing...")
        end
        DpsHelper.SpellManager.scanned = false  -- Força rescan do spellbook
        DpsHelper.TalentManager:DetectSpec()
        DpsHelper.SpellManager:ScanSpellbook()
        DpsHelper.UI:Update()
    elseif event == "UNIT_AURA" and (arg1 == "player" or arg1 == "target") then
        DpsHelper.Utils:UpdateAuraCache(arg1)
        DpsHelper.UI:Update()
    elseif event == "UNIT_PET" and arg1 == "player" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Pet status changed, updating UI")
        end
        DpsHelper.UI:Update()
    elseif event == "UNIT_COMBO_POINTS" and arg1 == "player" or event == "UNIT_POWER_UPDATE" and arg1 == "player" or
           event == "PLAYER_TARGET_CHANGED" or event == "SPELL_UPDATE_COOLDOWN" then
        DpsHelper.UI:Update()
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" or event == "BAG_UPDATE" then
        DpsHelper.SpellManager.scannedInventory = false  -- Força rescan do inventário
        DpsHelper.SpellManager.PoisonCache = {}  -- Invalida cache de poisons
        DpsHelper.SpellManager:ScanInventory()
        DpsHelper.UI:Update()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Combat ended, resetting combat timer")
        end
        DpsHelper.Utils.combatStartTime = nil
        DpsHelper.Utils.RecentSpells = {}
        DpsHelper.UI:Update()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Combat started, setting combat timer")
        end
        DpsHelper.Utils.combatStartTime = GetTime()
        DpsHelper.UI:Update()
    end
end)