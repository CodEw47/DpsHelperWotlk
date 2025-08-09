-- Rotations\Mage\Frost.lua
-- Rotation logic for Mage Frost DPS in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.MAGE = DpsHelper.Rotations.MAGE or {}
DpsHelper.Rotations.MAGE.Frost = DpsHelper.Rotations.MAGE.Frost or {}

function DpsHelper.Rotations.MAGE.Frost:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local mana = UnitPower("player", 0) / UnitPowerMax("player", 0)

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

    -- Rotação de Frost
    if target and #queue == 0 then
        local spells = {
            { name = "Frostbolt", id = 42842, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Frostbolt")
                return remaining <= 2 and mana >= 0.16
            end},
            { name = "Deep Freeze", id = 44572, condition = function()
                return DpsHelper.Utils:GetBuffRemainingTime("player", "Fingers of Frost") > 0 and mana >= 0.09
            end},
            { name = "Frostbolt", id = 42842, condition = function()
                return mana >= 0.16
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

DpsHelper.Utils:Print("Frost.lua loaded for Mage")