-- Rotations\Warlock\Affliction.lua
-- Rotation logic for Warlock Affliction in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}
DpsHelper.Rotations.WARLOCK.Affliction = DpsHelper.Rotations.WARLOCK.Affliction or {}

function DpsHelper.Rotations.WARLOCK.Affliction:GetRotationQueue()
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
        DpsHelper.Utils:Print("Added pet summon to queue: " .. (missing.pet.action or "Unknown"))
    end

    -- Adicionar rotação apenas se houver um alvo válido e buffs/itens/pets estiverem ok
    if target and #queue == 0 then
        local spells = {
            { name = "Haunt", id = 48181, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Haunt")
                return remaining <= 2 and remaining >= 0
            end},
            { name = "Unstable Affliction", id = 30108, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Unstable Affliction")
                return remaining <= 2 and remaining >= 0
            end},
            { name = "Corruption", id = 172, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Corruption")
                return remaining <= 2 and remaining >= 0
            end},
            { name = "Curse of Agony", id = 980, condition = function()
                local agonyRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony")
                local doomRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                return agonyRemaining <= 2 and agonyRemaining >= 0 and doomRemaining == 0
            end},
            { name = "Curse of Doom", id = 603, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                return UnitHealth("target") > UnitHealthMax("player") * 3 and remaining <= 2 and remaining >= 0
            end},
            { name = "Drain Life", id = 689, condition = function()
                return UnitHealth("player") / UnitHealthMax("player") < 0.7
            end},
            { name = "Shadow Bolt", id = 686, condition = function()
                return true -- Filler spell
            end}
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

DpsHelper.Utils:Print("Affliction.lua loaded for Warlock")
