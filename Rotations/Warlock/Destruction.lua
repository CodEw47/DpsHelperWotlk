-- Rotations\Warlock\Destruction.lua
-- Rotation logic for Warlock Destruction in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}
DpsHelper.Rotations.WARLOCK.Destruction = DpsHelper.Rotations.WARLOCK.Destruction or {}

function DpsHelper.Rotations.WARLOCK.Destruction:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

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

    -- Rotação de Destruction
    if target and #queue == 0 then
        local spells = {
            { name = "Immolate", id = 348, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate")
                return remaining <= 2 and remaining >= 0
            end},
            { name = "Chaos Bolt", id = 50796, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Chaos Bolt")
            end},
            { name = "Conflagrate", id = 17962, condition = function()
                return DpsHelper.SpellManager:IsSpellUsable("Conflagrate") and DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate") > 0
            end},
            { name = "Incinerate", id = 29722, condition = function()
                return true -- Filler spell
            end},
            { name = "Shadow Bolt", id = 686, condition = function()
                return not DpsHelper.SpellManager:IsSpellUsable("Incinerate")
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

DpsHelper.Utils:Print("Destruction.lua loaded for Warlock")