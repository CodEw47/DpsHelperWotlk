-- Rotations\Shaman\Elemental.lua
-- Rotation logic for Shaman Elemental DPS in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.SHAMAN = DpsHelper.Rotations.SHAMAN or {}
DpsHelper.Rotations.SHAMAN.Elemental = DpsHelper.Rotations.SHAMAN.Elemental or {}

function DpsHelper.Rotations.SHAMAN.Elemental:GetRotationQueue()
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

    -- Rotação de Elemental
    if target and #queue == 0 then
        local spells = {
            { name = "Flame Shock", id = 49233, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Flame Shock")
                return remaining <= 2 and mana >= 0.17
            end},
            { name = "Lava Burst", id = 51505, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Lava Burst") and mana >= 0.1
            end},
            { name = "Lightning Bolt", id = 49238, condition = function()
                return mana >= 0.08
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

DpsHelper.Utils:Print("Elemental.lua loaded for Shaman")