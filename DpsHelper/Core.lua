-- Core.lua
-- Central initialization and event handling for DpsHelper.

DpsHelper = DpsHelper or {}
DpsHelper.isInitialized = false
DpsHelper.Rotations = DpsHelper.Rotations or {}

function DpsHelper:Initialize()
    DpsHelper.Utils:DebugPrint(1,"Inicializando addon...")
    DpsHelper.Config:Initialize()
    DpsHelper.SpellManager:ScanSpellbook()
    DpsHelper.TalentManager:DetectSpec()
    DpsHelper.BuffReminder:Initialize()
    DpsHelper.UI:Initialize()

    -- Verificar se as rotações estão carregadas
    for class, specs in pairs(DpsHelper.Rotations) do
        for spec, rotationTable in pairs(specs) do
            if type(rotationTable) == "table" and type(rotationTable.GetRotationQueue) == "function" then
                DpsHelper.Utils:DebugPrint(1,"Rotation loaded for class=" .. class .. ", spec=" .. spec)
            else
                DpsHelper.Utils:DebugPrint(1,"Rotation missing GetRotationQueue for class=" .. class .. ", spec=" .. spec)
            end
        end
    end

    DpsHelper.isInitialized = true
    DpsHelper.Utils:DebugPrint(1,"Addon inicializado com sucesso.")
end

SLASH_DPSHELPER1 = "/dpshelper"
SlashCmdList["DPSHELPER"] = function(msg)
    DpsHelper.Options:HandleCommand(msg)
end