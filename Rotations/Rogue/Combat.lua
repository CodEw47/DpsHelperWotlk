-- Rotations/Rogue/Combat.lua
-- Intelligent rotation logic for Combat Rogue with optimized buff/DoT management.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.rogue = DpsHelper.Rotations.rogue or {}
DpsHelper.Rotations.rogue.combat = DpsHelper.Rotations.rogue.combat or {}

function DpsHelper.Rotations.rogue.combat.GetRotationQueue()
    DpsHelper.Utils:Print("Calling GetRotationQueue for rogue.combat")
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        DpsHelper.Utils:Print("No valid target, returning empty queue")
        return {}
    end

    local queue = {}
    local energy = DpsHelper.Utils:GetCurrentEnergy()
    local cp = DpsHelper.Utils:GetCurrentComboPoints()
    local sndRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice") or 0
    local ruptureRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rupture") or 0
    local usedSpells = {} -- Track used spells to avoid redundancy

    -- Debug: Logar os tempos restantes de Slice and Dice e Rupture
    DpsHelper.Utils:Print(string.format("Debug: Slice and Dice remaining: %.2f seconds, Rupture remaining: %.2f seconds", sndRemaining, ruptureRemaining))

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

    local priorities = {
        -- Aplicar Deadly Poison apenas se não estiver ativo ou com menos de 10s restantes
        { name = "Deadly Poison", condition = function() return not DpsHelper.Utils:HasWeaponPoison() and energy >= 25 end },
        -- Slice and Dice só se não estiver ativo ou com menos de 3s (duração ~21s com 5 CP)
        { name = "Slice and Dice", condition = function() return cp >= 3 and energy >= 25 and sndRemaining <= 3 end },
        -- Adrenaline Rush para burst, apenas se energia baixa e em alvos elite/chefes
        { name = "Adrenaline Rush", condition = function() return energy <= 50 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:GetSpellCooldownRemaining("Adrenaline Rush") == 0 and DpsHelper.Utils:IsTargetAliveFor(15) end },
        -- Killing Spree para burst em alvos elite/chefes
        { name = "Killing Spree", condition = function() return cp >= 3 and energy >= 90 and DpsHelper.Utils:GetSpellCooldownRemaining("Killing Spree") == 0 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Blade Flurry para múltiplos alvos
        { name = "Blade Flurry", condition = function() return DpsHelper.Utils:HasMultipleTargets() and energy >= 25 and DpsHelper.Utils:GetSpellCooldownRemaining("Blade Flurry") == 0 and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Rupture só se não estiver ativo ou com menos de 4s (duração ~16s com 5 CP)
        { name = "Rupture", condition = function() return cp >= 4 and energy >= 25 and ruptureRemaining <= 4 and DpsHelper.Utils:IsTargetAliveFor(6) end },
        -- Eviscerate como finisher, se Rupture estiver ativo ou alvo estiver prestes a morrer
        { name = "Eviscerate", condition = function() return cp >= 4 and energy >= 35 and (ruptureRemaining > 6 or not DpsHelper.Utils:IsTargetAliveFor(6)) end },
        -- Sinister Strike para gerar combo points, com alta prioridade
        { name = "Sinister Strike", condition = function() return cp < 4 and energy >= 40 end }
    }

    -- Adicionar até 4 habilidades válidas, sem parar na primeira
    for _, entry in ipairs(priorities) do
        if #queue < 4 then
            addToQueue(entry.name, entry.condition)
        end
    end

    -- Preencher a fila com Sinister Strike, se necessário
    while #queue < 4 and (DpsHelper.SpellManager and DpsHelper.SpellManager.IsSpellUsable and DpsHelper.SpellManager:IsSpellUsable("Sinister Strike") or (DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID("Sinister Strike") > 0 and IsSpellKnown(DpsHelper.SpellManager:GetSpellID("Sinister Strike")))) and energy >= 40 and not usedSpells["Sinister Strike"] do
        local spellID = DpsHelper.SpellManager:GetSpellID("Sinister Strike")
        if spellID > 0 then
            table.insert(queue, { spellID = spellID, name = "Sinister Strike" })
            usedSpells["Sinister Strike"] = true
            DpsHelper.Utils:Print("Added fallback Sinister Strike to queue (ID: " .. spellID .. ")")
        else
            DpsHelper.Utils:Print("Sinister Strike spellID not found")
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
        DpsHelper.Utils:Print("Combat.lua initialized after addon load")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

DpsHelper.Utils:Print("Combat.lua rotation defined")