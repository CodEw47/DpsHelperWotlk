-- Rotations/Rogue/Subtlety.lua
-- Intelligent rotation logic for Subtlety Rogue with optimized buff/DoT management.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.rogue = DpsHelper.Rotations.rogue or {}
DpsHelper.Rotations.rogue.subtlety = DpsHelper.Rotations.rogue.subtlety or {}

function DpsHelper.Rotations.rogue.subtlety.GetRotationQueue()
    DpsHelper.Utils:Print("Calling GetRotationQueue for rogue.subtlety")
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        DpsHelper.Utils:Print("No valid target, returning empty queue")
        return {}
    end

    local queue = {}
    local energy = DpsHelper.Utils:GetCurrentEnergy()
    local cp = DpsHelper.Utils:GetCurrentComboPoints()
    local sndRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice") or 0
    local ruptureRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rupture") or 0
    local hemorrhageRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Hemorrhage") or 0
    local shadowDanceRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Shadow Dance") or 0
    local usedSpells = {} -- Track used spells to avoid redundancy

    -- Debug: Logar os tempos restantes de Slice and Dice, Rupture, Hemorrhage e Shadow Dance
    DpsHelper.Utils:Print(string.format("Debug: Slice and Dice remaining: %.2f seconds, Rupture remaining: %.2f seconds, Hemorrhage remaining: %.2f seconds, Shadow Dance remaining: %.2f seconds", sndRemaining, ruptureRemaining, hemorrhageRemaining, shadowDanceRemaining))

    local function addToQueue(spellName, condition)
        if usedSpells[spellName] then return false end
        local isUsable = DpsHelper.SpellManager and DpsHelper.SpellManager.IsSpellUsable and DpsHelper.SpellManager:IsSpellUsable(spellName)
        if not isUsable then
            isUsable = DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID(spellName) > 0 and IsSpellKnown(DpsHelper.SpellManager:GetSpellID(spellName))
        end
        if isUsable and condition() then
            local spellID = DpsHelper.SpellManager:GetSpellID(spellName)
            if spellID > 0 then
                table.insert(queue, { spellID = spellID, name = spellName })
                usedSpells[spellName] = true
                DpsHelper.Utils:Print("Added to queue: " .. spellName .. " (ID: " .. spellID .. ")")
                return true
            else
                DpsHelper.Utils:Print("Invalid spellID for " .. spellName)
            end
        end
        return false
    end

    local function IsBehindTarget()
        -- Simples verificação de posicionamento (não precisa estar em stealth para Backstab em WotLK)
        return not UnitIsUnit("target", "player") -- Aproximação básica para "atrás do alvo"
    end

    local priorities = {
        -- Aplicar Deadly Poison se não estiver ativo ou com menos de 10s restantes
        { name = "Deadly Poison", condition = function() return not DpsHelper.Utils:HasWeaponPoison() and energy >= 25 end },
        -- Shadow Dance para burst, se disponível e em alvos elite/chefes
        { name = "Shadow Dance", condition = function() return energy >= 40 and DpsHelper.Utils:GetSpellCooldownRemaining("Shadow Dance") == 0 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Shadowstep para mobilidade em alvos elite/chefes
        { name = "Shadowstep", condition = function() return energy >= 10 and DpsHelper.Utils:GetSpellCooldownRemaining("Shadowstep") == 0 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Slice and Dice se não estiver ativo ou com menos de 3s (duração ~21s com 5 CP)
        { name = "Slice and Dice", condition = function() return cp >= 3 and energy >= 25 and sndRemaining <= 3 end },
        -- Rupture se não estiver ativo ou com menos de 4s (duração ~16s com 5 CP)
        { name = "Rupture", condition = function() return cp >= 4 and energy >= 25 and ruptureRemaining <= 4 and DpsHelper.Utils:IsTargetAliveFor(6) and not hemorrhageRemaining > 4 end },
        -- Hemorrhage como DoT alternativo ou para alvos com pouca vida
        { name = "Hemorrhage", condition = function() return cp < 4 and energy >= 35 and hemorrhageRemaining <= 4 and DpsHelper.Utils:IsTargetAliveFor(6) end },
        -- Eviscerate como finisher, se Rupture ou Hemorrhage estiverem ativos ou alvo estiver prestes a morrer
        { name = "Eviscerate", condition = function() return cp >= 4 and energy >= 35 and (ruptureRemaining > 6 or hemorrhageRemaining > 6 or not DpsHelper.Utils:IsTargetAliveFor(6)) end },
        -- Ambush durante Shadow Dance, se posicionado
        { name = "Ambush", condition = function() return shadowDanceRemaining > 0 and cp < 4 and energy >= 60 and IsBehindTarget() end },
        -- Backstab para gerar combo points, se posicionado
        { name = "Backstab", condition = function() return cp < 4 and energy >= 60 and IsBehindTarget() end },
        -- Hemorrhage como gerador de combo points, se Backstab não for viável
        { name = "Hemorrhage", condition = function() return cp < 4 and energy >= 35 end }
    }

    -- Adicionar até 4 habilidades válidas, sem parar na primeira
    for _, entry in ipairs(priorities) do
        if #queue < 4 then
            addToQueue(entry.name, entry.condition)
        end
    end

    -- Preencher a fila com Hemorrhage (ou Backstab, se viável), se necessário
    local fallbackSpell = IsBehindTarget() and "Backstab" or "Hemorrhage"
    local fallbackCost = IsBehindTarget() and 60 or 35
    while #queue < 4 and (DpsHelper.SpellManager and DpsHelper.SpellManager.IsSpellUsable and DpsHelper.SpellManager:IsSpellUsable(fallbackSpell) or (DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID(fallbackSpell) > 0 and IsSpellKnown(DpsHelper.SpellManager:GetSpellID(fallbackSpell)))) and energy >= fallbackCost and not usedSpells[fallbackSpell] do
        local spellID = DpsHelper.SpellManager:GetSpellID(fallbackSpell)
        if spellID > 0 then
            table.insert(queue, { spellID = spellID, name = fallbackSpell })
            usedSpells[fallbackSpell] = true
            DpsHelper.Utils:Print("Added fallback " .. fallbackSpell .. " to queue (ID: " .. spellID .. ")")
        else
            DpsHelper.Utils:Print(fallbackSpell .. " spellID not found")
            break
        end
    end

    while #queue > 4 do
        table.remove(queue, #queue)
    end

    DpsHelper.Utils:Print("Rotation queue size: " .. #queue)
    return queue
end

-- Registrar evento para garantir inicialização após carregamento do addon
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "DpsHelper" then
        DpsHelper.Utils:Print("Subtlety.lua initialized after addon load")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

DpsHelper.Utils:Print("Subtlety.lua rotation defined")