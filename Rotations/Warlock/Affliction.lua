-- Rotations\Warlock\Affliction.lua
-- Rotation logic for Warlock Affliction in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}
DpsHelper.Rotations.WARLOCK.Affliction = DpsHelper.Rotations.WARLOCK.Affliction or {}

function DpsHelper.Rotations.WARLOCK.Affliction:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    -- Verificar pré-requisitos (buffs, itens, pets)
    local prereqs = DpsHelper.BuffReminder:GetRotationPrequesites()
    if #prereqs > 0 then
        return prereqs -- Retorna imediatamente se houver pré-requisitos ausentes
    end

    -- Adicionar até três habilidades da rotação se houver um alvo válido
    if target then
        local spells = {
            { name = "Haunt", id = 48181, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Haunt")
                return remaining <= 2 and remaining >= 0
            end, priority = 1},
            { name = "Unstable Affliction", id = 30108, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Unstable Affliction")
                return remaining <= 2 and remaining >= 0
            end, priority = 2},
            { name = "Corruption", id = 172, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Corruption")
                return remaining <= 2 and remaining >= 0
            end, priority = 3},
            { name = "Curse of Agony", id = 980, condition = function()
                local agonyRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony")
                local doomRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                return agonyRemaining <= 2 and agonyRemaining >= 0 and doomRemaining == 0
            end, priority = 4},
            { name = "Curse of Doom", id = 603, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                return UnitHealth("target") > UnitHealthMax("player") * 3 and remaining <= 2 and remaining >= 0
            end, priority = 5},
            { name = "Drain Life", id = 689, condition = function()
                return UnitHealth("player") / UnitHealthMax("player") < 0.7
            end, priority = 6},
            { name = "Shadow Bolt", id = 686, condition = function()
                return true -- Filler spell
            end, priority = 7}
        }

        -- Criar uma lista de habilidades válidas
        local validSpells = {}
        for _, spell in ipairs(spells) do
            if DpsHelper.SpellManager:IsSpellUsable(spell.name) and spell.condition() then
                table.insert(validSpells, spell)
            end
        end

        -- Ordenar por prioridade, mas mover DoTs prestes a expirar para o topo
        table.sort(validSpells, function(a, b)
            local aRemaining = a.condition() and DpsHelper.Utils:GetDebuffRemainingTime("target", a.name) or 999
            local bRemaining = b.condition() and DpsHelper.Utils:GetDebuffRemainingTime("target", b.name) or 999
            if aRemaining <= 2 and bRemaining > 2 then
                return true
            elseif bRemaining <= 2 and aRemaining > 2 then
                return false
            else
                return a.priority < b.priority
            end
        end)

        -- Adicionar até três habilidades à fila
        for i = 1, math.min(3, #validSpells) do
            local spell = validSpells[i]
            table.insert(queue, { name = spell.name, spellID = spell.id, type = "spell", priority = spell.priority })
            DpsHelper.Utils:Print("Added to queue: " .. spell.name .. " (priority " .. spell.priority .. ")")
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