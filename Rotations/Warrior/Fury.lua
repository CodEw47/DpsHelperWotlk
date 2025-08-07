-- Rotations/Warrior/Fury.lua
-- Intelligent rotation logic for Fury Warrior with optimized buff/DoT management.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.warrior = DpsHelper.Rotations.warrior or {}
DpsHelper.Rotations.warrior.fury = DpsHelper.Rotations.warrior.fury or {}

function DpsHelper.Rotations.warrior.fury.GetRotationQueue()
    DpsHelper.Utils:Print("Calling GetRotationQueue for warrior.fury")
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        DpsHelper.Utils:Print("No valid target, returning empty queue")
        return {}
    end

    local queue = {}
    local rage = DpsHelper.Utils:GetCurrentRage()
    local rendRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rend") or 0
    local battleShoutRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Battle Shout") or 0
    local commandingShoutRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Commanding Shout") or 0
    local deathWishRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Death Wish") or 0
    local usedSpells = {} -- Track used spells to avoid redundancy

    -- Debug: Logar os tempos restantes de Rend, Battle Shout, Commanding Shout e Death Wish
    DpsHelper.Utils:Print(string.format("Debug: Rend remaining: %.2f seconds, Battle Shout remaining: %.2f seconds, Commanding Shout remaining: %.2f seconds, Death Wish remaining: %.2f seconds", rendRemaining, battleShoutRemaining, commandingShoutRemaining, deathWishRemaining))

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
        -- Battle Shout ou Commanding Shout se não estiver ativo ou com menos de 3s (duração ~120s)
        { name = "Battle Shout", condition = function() return battleShoutRemaining <= 3 and commandingShoutRemaining <= 3 and rage >= 10 end },
        -- Death Wish para burst em alvos elite/chefes
        { name = "Death Wish", condition = function() return rage >= 10 and DpsHelper.Utils:GetSpellCooldownRemaining("Death Wish") == 0 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:IsTargetAliveFor(15) end },
        -- Recklessness para burst em alvos elite/chefes
        { name = "Recklessness", condition = function() return rage >= 0 and DpsHelper.Utils:GetSpellCooldownRemaining("Recklessness") == 0 and DpsHelper.Utils:IsTargetBossOrElite() and DpsHelper.Utils:IsTargetAliveFor(15) end },
        -- Berserker Rage para gerar raiva ou prevenir fear
        { name = "Berserker Rage", condition = function() return rage <= 50 and DpsHelper.Utils:GetSpellCooldownRemaining("Berserker Rage") == 0 and DpsHelper.Utils:IsTargetAliveFor(10) end },
        -- Rend se não estiver ativo ou com menos de 3s (duração ~15s)
        { name = "Rend", condition = function() return rage >= 10 and rendRemaining <= 3 and DpsHelper.Utils:IsTargetAliveFor(6) end },
        -- Execute em alvos com menos de 20% de vida
        { name = "Execute", condition = function() return rage >= 15 and not DpsHelper.Utils:IsTargetAliveFor(6) end },
        -- Whirlwind para múltiplos alvos ou como filler single-target
        { name = "Whirlwind", condition = function() return rage >= 25 and DpsHelper.Utils:GetSpellCooldownRemaining("Whirlwind") == 0 end },
        -- Bloodthirst como principal habilidade de dano
        { name = "Bloodthirst", condition = function() return rage >= 30 and DpsHelper.Utils:GetSpellCooldownRemaining("Bloodthirst") == 0 end },
        -- Heroic Strike como rage dump quando raiva está alta
        { name = "Heroic Strike", condition = function() return rage >= 40 end }
    }

    -- Adicionar até 4 habilidades válidas, sem parar na primeira
    for _, entry in ipairs(priorities) do
        if #queue < 4 then
            addToQueue(entry.name, entry.condition)
        end
    end

    -- Preencher a fila com Heroic Strike, se necessário
    while #queue < 4 and (DpsHelper.SpellManager and DpsHelper.SpellManager.IsSpellUsable and DpsHelper.SpellManager:IsSpellUsable("Heroic Strike") or (DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID("Heroic Strike") > 0 and IsSpellKnown(DpsHelper.SpellManager:GetSpellID("Heroic Strike")))) and rage >= 40 and not usedSpells["Heroic Strike"] do
        local spellID = DpsHelper.SpellManager:GetSpellID("Heroic Strike")
        if spellID > 0 then
            table.insert(queue, { spellID = spellID, name = "Heroic Strike" })
            usedSpells["Heroic Strike"] = true
            DpsHelper.Utils:Print("Added fallback Heroic Strike to queue (ID: " .. spellID .. ")")
        else
            DpsHelper.Utils:Print("Heroic Strike spellID not found")
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
        DpsHelper.Utils:Print("Fury.lua initialized after addon load")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

DpsHelper.Utils:Print("Fury.lua rotation defined")