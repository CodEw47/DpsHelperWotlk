-- Rotations/Rogue/Assassination.lua
-- Intelligent rotation logic for Assassination Rogue with optimized buff/DoT management.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.rogue = DpsHelper.Rotations.rogue or {}
DpsHelper.Rotations.rogue.assassination = DpsHelper.Rotations.rogue.assassination or {}

function DpsHelper.Rotations.rogue.assassination.GetRotationQueue()
    DpsHelper.Utils:Print("Calling GetRotationQueue for rogue.assassination")
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        DpsHelper.Utils:Print("No valid target, returning empty queue")
        return {}
    end

    local queue = {}
    local energy = DpsHelper.Utils:GetCurrentEnergy()
    local cp = DpsHelper.Utils:GetCurrentComboPoints()
    local sndRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice") or 0
    local hfbRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Hunger for Blood") or 0
    local ruptureRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rupture") or 0
    local usedSpells = {} -- Track used spells to avoid redundancy

    -- Debug: Logar os tempos restantes de Slice and Dice, Hunger for Blood e Rupture
    DpsHelper.Utils:Print(string.format("Debug: Slice and Dice remaining: %.2f seconds, Hunger for Blood remaining: %.2f seconds, Rupture remaining: %.2f seconds", sndRemaining, hfbRemaining, ruptureRemaining))

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
        -- Aplicar Deadly Poison se não estiver ativo ou com menos de 10s restantes
        { name = "Deadly Poison", condition = function() return not DpsHelper.Utils:HasWeaponPoison() and energy >= 25 end },
        -- Aplicar Instant Poison se não estiver ativo ou com menos de 10s restantes
        { name = "Instant Poison", condition = function() return not DpsHelper.Utils:HasWeaponPoison() and energy >= 25 end },
        -- Hunger for Blood se não estiver ativo ou com menos de 3s (duração ~24s)
        { name = "Hunger for Blood", condition = function() return hfbRemaining <= 3 and energy >= 15 and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Slice and Dice se não estiver ativo ou com menos de 3s (duração ~21s com 5 CP)
        { name = "Slice and Dice", condition = function() return cp >= 3 and energy >= 25 and sndRemaining <= 3 end },
        -- Rupture se não estiver ativo ou com menos de 4s (duração ~16s com 5 CP)
        { name = "Rupture", condition = function() return cp >= 4 and energy >= 25 and ruptureRemaining <= 4 and DpsHelper.Utils:IsTargetAliveFor(6) end },
        -- Envenom como finisher, se Rupture e Hunger for Blood estiverem ativos ou alvo estiver prestes a morrer
        { name = "Envenom", condition = function() return cp >= 4 and energy >= 35 and (hfbRemaining > 6 and ruptureRemaining > 6 or not DpsHelper.Utils:IsTargetAliveFor(6)) end },
        -- Mutilate para gerar combo points, com alta prioridade
        { name = "Mutilate", condition = function() return cp < 4 and energy >= 60 end }
    }

    -- Adicionar até 4 habilidades válidas, sem parar na primeira
    for _, entry in ipairs(priorities) do
        if #queue < 4 then
            addToQueue(entry.name, entry.condition)
        end
    end

    -- Preencher a fila com Mutilate, se necessário
    while #queue < 4 and (DpsHelper.SpellManager and DpsHelper.SpellManager.IsSpellUsable and DpsHelper.SpellManager:IsSpellUsable("Mutilate") or (DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID("Mutilate") > 0 and IsSpellKnown(DpsHelper.SpellManager:GetSpellID("Mutilate")))) and energy >= 60 and not usedSpells["Mutilate"] do
        local spellID = DpsHelper.SpellManager:GetSpellID("Mutilate")
        if spellID > 0 then
            table.insert(queue, { spellID = spellID, name = "Mutilate" })
            usedSpells["Mutilate"] = true
            DpsHelper.Utils:Print("Added fallback Mutilate to queue (ID: " .. spellID .. ")")
        else
            DpsHelper.Utils:Print("Mutilate spellID not found")
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
        DpsHelper.Utils:Print("Assassination.lua initialized after addon load")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

DpsHelper.Utils:Print("Assassination.lua rotation defined")