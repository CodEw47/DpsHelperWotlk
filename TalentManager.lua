-- TalentManager.lua
-- Detects player specialization based on talents for all classes.

DpsHelper = DpsHelper or {}
DpsHelper.TalentManager = DpsHelper.TalentManager or {}

-- Lista de talentos-chave por classe e especialização
local keyTalents = {
    ROGUE = {
        combat = {"Blade Flurry", "Killing Spree", "Adrenaline Rush"},
        assassination = {"Mutilate", "Hunger for Blood", "Envenom"},
        subtlety = {"Shadow Dance", "Shadowstep", "Preparation"}
    },
    WARRIOR = {
        arms = {"Mortal Strike", "Bladestorm", "Sudden Death"},
        fury = {"Bloodthirst", "Titan's Grip", "Death Wish"},
        protection = {"Shield Slam", "Vigilance", "Shockwave"}
    },
    PALADIN = {
        holy = {"Holy Shock", "Beacon of Light", "Divine Illumination"},
        protection = {"Hammer of the Righteous", "Divine Sacrifice", "Shield of Righteousness"},
        retribution = {"Crusader Strike", "Divine Storm", "The Art of War"}
    },
    HUNTER = {
        beast_mastery = {"The Beast Within", "Bestial Wrath", "Kindred Spirits"},
        marksmanship = {"Aimed Shot", "Chimera Shot", "Trueshot Aura"},
        survival = {"Explosive Shot", "Lock and Load", "Wyvern Sting"}
    },
    PRIEST = {
        discipline = {"Penance", "Power Infusion", "Pain Suppression"},
        holy = {"Guardian Spirit", "Divine Hymn", "Circle of Healing"},
        shadow = {"Vampiric Touch", "Dispersion", "Mind Flay"}
    },
    SHAMAN = {
        elemental = {"Thunderstorm", "Elemental Mastery", "Lava Burst"},
        enhancement = {"Stormstrike", "Shamanistic Rage", "Maelstrom Weapon"},
        restoration = {"Riptide", "Earth Shield", "Tidal Force"}
    },
    MAGE = {
        arcane = {"Arcane Barrage", "Arcane Power", "Missile Barrage"},
        fire = {"Living Bomb", "Dragon's Breath", "Combustion"},
        frost = {"Icy Veins", "Deep Freeze", "Summon Water Elemental"}
    },
    WARLOCK = {
        affliction = {"Haunt", "Unstable Affliction", "Curse of Doom"},
        demonology = {"Metamorphosis", "Demonic Pact", "Fel Domination"},
        destruction = {"Chaos Bolt", "Conflagrate", "Shadowfury"}
    },
    DRUID = {
        balance = {"Starfall", "Typhoon", "Eclipse"},
        feral = {"Mangle (Cat)", "Mangle (Bear)", "Berserk"},
        restoration = {"Wild Growth", "Tree of Life", "Lifebloom"}
    },
    DEATHKNIGHT = {
        blood = {"Heart Strike", "Dancing Rune Weapon", "Vampiric Blood"},
        frost = {"Frost Strike", "Howling Blast", "Killing Machine"},
        unholy = {"Scourge Strike", "Unholy Blight", "Summon Gargoyle"}
    }
}

-- Mapeamento de índices de árvores de talentos por classe
local talentTreeMap = {
    ROGUE = {combat = 1, assassination = 2, subtlety = 3},
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
    local talents = keyTalents[playerClass] or {}
    local treeMap = talentTreeMap[playerClass] or {}
    local detectedSpec = "unknown"
    local maxPoints, maxSpec = 0, "unknown"

    -- Passo 1: Detecção por pontos de talento
    local tabCount = GetNumTalentTabs()
    if tabCount and tabCount > 0 then
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
        if maxPoints >= 20 then -- Limiar para considerar uma spec dominante
            detectedSpec = maxSpec
            DpsHelper.Utils:Print("Detected specialization by points: " .. detectedSpec .. " (" .. maxPoints .. " points)")
            DpsHelper.Config:Set("currentSpec", detectedSpec)
            DpsHelper.Config:Set("currentClass", playerClass:lower())
            return detectedSpec
        else
            DpsHelper.Utils:Print("No dominant talent tree found (max points: " .. maxPoints .. "), falling back to key talents")
        end
    else
        DpsHelper.Utils:Print("No talent tabs available, falling back to key talents")
    end

    -- Passo 2: Fallback por talentos-chave
    if DpsHelper.SpellManager then
        for spec, talentList in pairs(talents) do
            for _, talent in ipairs(talentList) do
                local spellID = DpsHelper.SpellManager:GetSpellID(talent)
                if spellID > 0 and IsSpellKnown(spellID) then
                    detectedSpec = spec
                    DpsHelper.Utils:Print("Detected specialization by talent: " .. detectedSpec .. " via talent: " .. talent)
                    DpsHelper.Config:Set("currentSpec", detectedSpec)
                    DpsHelper.Config:Set("currentClass", playerClass:lower())
                    return detectedSpec
                end
            end
        end
        DpsHelper.Utils:Print("No key talents found, defaulting to unknown spec")
    else
        DpsHelper.Utils:Print("SpellManager not initialized, cannot check key talents")
    end

    -- Passo 3: Default para "unknown" se nada for detectado
    DpsHelper.Utils:Print("No specialization detected, defaulting to unknown")
    DpsHelper.Config:Set("currentSpec", "unknown")
    DpsHelper.Config:Set("currentClass", playerClass:lower())
    return detectedSpec
end

-- Função para atualizar a detecção de especialização em eventos
function DpsHelper.TalentManager:UpdateOnEvent(event)
    if event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_LOGIN" then
        DpsHelper.Utils:Print("Talent or specialization changed, updating detection...")
        self:DetectSpec()
    end
end

-- Registrar eventos para atualizar a detecção dinamicamente
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "DpsHelper" then
        DpsHelper.Utils:Print("DpsHelper loaded, initializing TalentManager")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        DpsHelper.Utils:Print("Player logged in, detecting specialization...")
        DpsHelper.TalentManager:DetectSpec()
    else
        DpsHelper.TalentManager:UpdateOnEvent(event)
    end
end)

DpsHelper.Utils:Print("TalentManager.lua initialized")