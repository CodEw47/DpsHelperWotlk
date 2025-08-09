-- Rotations\Rogue\Combat.lua
-- Rotation logic for Rogue Combat in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.ROGUE = DpsHelper.Rotations.ROGUE or {}
DpsHelper.Rotations.ROGUE.Combat = DpsHelper.Rotations.ROGUE.Combat or {}

function DpsHelper.Rotations.ROGUE.Combat:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local comboPoints = GetComboPoints("player", "target") or 0
    local energy = UnitPower("player", 3)
    local targetHealthPct = UnitHealth("target") / UnitHealthMax("target") * 100

    -- Verificar buffs/itens antes da rotação
    local missing = DpsHelper.BuffReminder:GetMissingBuffs()
    for _, buff in ipairs(missing.buffs) do
        if DpsHelper.SpellManager:IsSpellUsable(buff.name) then
            table.insert(queue, { name = buff.name, spellID = buff.id, type = "buff" })
            DpsHelper.Utils:Print("Added buff to queue: " .. buff.name)
        end
    end
    for _, item in ipairs(missing.items) do
        table.insert(queue, { name = item.name, spellID = item.id, type = "item" })
        DpsHelper.Utils:Print("Added item to queue: " .. item.name)
    end

    -- Rotação de Combat
    if target and #queue == 0 then
        local spells = {
            { name = "Slice and Dice", id = 5171, condition = function()
                local remaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice")
                return comboPoints >= 5 and remaining <= 3 and energy >= 25
            end},
            { name = "Rupture", id = 1943, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rupture")
                return comboPoints >= 5 and remaining <= 3 and energy >= 25 and targetHealthPct > 35
            end},
            { name = "Eviscerate", id = 2098, condition = function()
                return comboPoints >= 5 and energy >= 35 and targetHealthPct <= 35
            end},
            { name = "Sinister Strike", id = 1752, condition = function()
                return comboPoints < 5 and energy >= 45
            end},
        }

        for _, spell in ipairs(spells) do
            if DpsHelper.SpellManager:IsSpellUsable(spell.name) and spell.condition() then
                table.insert(queue, { name = spell.name, spellID = spell.id, type = "spell" })
                DpsHelper.Utils:Print("Added " .. spell.name .. " to rotation queue")
            end
        end
    end

    if #queue == 0 then
        DpsHelper.Utils:Print("No usable items in rotation queue")
    else
        DpsHelper.Utils:Print("Rotation queue generated with " .. #queue .. " items")
    end
    return queue
end

DpsHelper.Utils:Print("Combat.lua loaded for Rogue")