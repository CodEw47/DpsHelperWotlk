-- TalentManager.lua
-- Detects player specialization based on talents for all classes.

DpsHelper = DpsHelper or {}
DpsHelper.TalentManager = DpsHelper.TalentManager or {}

-- Mapeamento de índices de árvores de talentos por classe
local talentTreeMap = {
    ROGUE = {assassination = 1,  combat = 2, subtlety = 3},
    WARRIOR = {arms = 1, fury = 2, protection = 3},
    PALADIN = {holy = 1, protection = 2, retribution = 3},
    HUNTER = {beast_mastery = 1, marksmanship = 2, survival = 3},
    PRIEST = {discipline = 1, holy = 2, shadow = 3},
    SHAMAN = {elemental = 1, enhancement = 2, restoration = 3},
    MAGE = {arcane = 1, fire = 2, frost = 3},
    WARLOCK = {affliction = 1, demonology = 2, destruction = 3},
    DRUID = {balance = 1, feral = 2, restoration = 3},
    DEATHKNIGHT = {blood = 1, frost = 2, unholy = 3}
}

-- Função para detectar a especialização do jogador
function DpsHelper.TalentManager:DetectSpec()
    local playerClass = select(2, UnitClass("player")):upper()
    DpsHelper.Utils:Print("Detecting specialization for class: " .. playerClass)
    local treeMap = talentTreeMap[playerClass] or {}
    local detectedSpec = "unknown"
    local maxPoints, maxSpec = 0, "unknown"

    -- Detecção por pontos de talento
    local tabCount = GetNumTalentTabs() or 0
    if tabCount > 0 then
        DpsHelper.Utils:Print("Scanning talent trees...")
        for tabIndex = 1, tabCount do
            local name, _, pointsSpent = GetTalentTabInfo(tabIndex)
            pointsSpent = pointsSpent or 0
            local specName = nil
            for spec, index in pairs(treeMap) do
                if index == tabIndex then
                    specName = spec
                    break
                end
            end
            DpsHelper.Utils:Print(string.format("Tree %s (%d): %d points", name or "Unknown", tabIndex, pointsSpent))
            if pointsSpent > maxPoints then
                maxPoints = pointsSpent
                maxSpec = specName or "unknown"
            end
        end
        if maxPoints > 0 then -- Qualquer árvore com pontos é considerada
            detectedSpec = maxSpec
            DpsHelper.Utils:Print("Detected specialization by points: " .. detectedSpec .. " (" .. maxPoints .. " points)")
            DpsHelper.Config:Set("currentSpec", detectedSpec)
            DpsHelper.Config:Set("currentClass", playerClass:lower())
            return detectedSpec
        else
            DpsHelper.Utils:Print("No points found in any talent tree, defaulting to unknown")
        end
    else
        DpsHelper.Utils:Print("No talent tabs available, defaulting to unknown")
    end

    -- Default para "unknown" se nenhuma árvore tiver pontos
    DpsHelper.Utils:Print("No specialization detected, defaulting to unknown")
    DpsHelper.Config:Set("currentSpec", "unknown")
    DpsHelper.Config:Set("currentClass", playerClass:lower())
    return detectedSpec
end

DpsHelper.Utils:Print("TalentManager.lua initialized")