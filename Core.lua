-- Core.lua
-- Central initialization and event handling for DpsHelper.

DpsHelper = DpsHelper or {}
DpsHelper.isInitialized = false
DpsHelper.Rotations = DpsHelper.Rotations or {}

local function Initialize()
    DpsHelper.Utils:Print("Inicializando addon...")
    DpsHelper.SpellManager:ScanSpellbook()
    DpsHelper.TalentManager:DetectSpec()
    DpsHelper.UI:Initialize()
    DpsHelper.isInitialized = true
    DpsHelper.Utils:Print("Addon inicializado com sucesso.")
end

local eventFrame = CreateFrame("Frame", "DpsHelperEventFrame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_POWER")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    DpsHelper.Utils:Print("Evento disparado: " .. event)
    if event == "PLAYER_ENTERING_WORLD" then
        Initialize()
        DpsHelper.UI:Show()
    elseif event == "LEARNED_SPELL_IN_TAB" then
        DpsHelper.SpellManager:ScanSpellbook()
        DpsHelper.TalentManager:DetectSpec()
    end
    DpsHelper.UI:Update()
end)

SLASH_DPSHELPER1 = "/dpshelper"
SlashCmdList["DPSHELPER"] = function(msg)
    DpsHelper.Options:HandleCommand(msg)
end