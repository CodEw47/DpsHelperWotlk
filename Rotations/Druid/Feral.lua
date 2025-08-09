-- Rotations\Druid\Feral.lua
-- Rotation logic for Druid Feral in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.DRUID = DpsHelper.Rotations.DRUID or {}
DpsHelper.Rotations.DRUID.Feral = DpsHelper.Rotations.DRUID.Feral or {}

function DpsHelper.Rotations.DRUID.Feral:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local comboPoints = GetComboPoints("player", "target") or 0
    local energy = UnitPower("player", 3)

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

    -- Rotação de Feral
    if target and #queue == 0 then
        local spells = {
            { name = "Savage Roar", id = 52610, condition = function()
                local remaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Savage Roar")
                return comboPoints >= 4 and remaining <= 2 and energy >= 25
            end},
            { name = "Rip", id = 49800, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rip")
                return comboPoints >= 4 and remaining <= 2 and energy >= 30
            end},
            { name = "Rake", id = 48574, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rake")
                return remaining <= 2 and energy >= 35
            end},
            { name = "Shred", id = 48572, condition = function()
                return comboPoints < 5 and energy >= 40
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

DpsHelper.Utils:Print("Feral.lua loaded for Druid")