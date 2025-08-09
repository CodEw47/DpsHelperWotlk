-- Rotations\Hunter\Marksmanship.lua
-- Rotation logic for Hunter Marksmanship in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.HUNTER = DpsHelper.Rotations.HUNTER or {}
DpsHelper.Rotations.HUNTER.Marksmanship = DpsHelper.Rotations.HUNTER.Marksmanship or {}

function DpsHelper.Rotations.HUNTER.Marksmanship:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local mana = UnitPower("player", 0) / UnitPowerMax("player", 0)

    -- Verificar buffs/itens/pets antes da rotação
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
    if missing.pet then
        table.insert(queue, { name = missing.pet.action, spellID = missing.pet.id, type = "pet" })
        DpsHelper.Utils:Print("Added pet summon to queue: " .. missing.pet.action)
    end

    -- Rotação de Marksmanship
    if target and #queue == 0 then
        local spells = {
            { name = "Serpent Sting", id = 1978, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Serpent Sting")
                return remaining <= 2 and remaining >= 0 and mana >= 0.1
            end},
            { name = "Chimera Shot", id = 53209, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Chimera Shot") and mana >= 0.12
            end},
            { name = "Aimed Shot", id = 19434, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Aimed Shot") and mana >= 0.12
            end},
            { name = "Steady Shot", id = 56641, condition = function()
                return mana >= 0.05
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

DpsHelper.Utils:Print("Marksmanship.lua loaded for Hunter")