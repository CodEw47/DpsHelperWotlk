-- Rotations\Paladin\Retribution.lua
-- Rotation logic for Paladin Retribution in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.PALADIN = DpsHelper.Rotations.PALADIN or {}
DpsHelper.Rotations.PALADIN.Retribution = DpsHelper.Rotations.PALADIN.Retribution or {}

function DpsHelper.Rotations.PALADIN.Retribution:GetRotationQueue()
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

    -- Rotação de Retribution
    if target and #queue == 0 then
        local spells = {
            { name = "Seal of Vengeance", id = 31801, condition = function()
                local remaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Seal of Vengeance")
                return remaining <= 2 and mana >= 0.14
            end},
            { name = "Judgement of Vengeance", id = 31804, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Judgement of Vengeance") and mana >= 0.07
            end},
            { name = "Crusader Strike", id = 35395, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Crusader Strike") and mana >= 0.05
            end},
            { name = "Divine Storm", id = 53385, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Divine Storm") and mana >= 0.12
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

DpsHelper.Utils:Print("Retribution.lua loaded for Paladin")