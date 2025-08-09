-- Rotations\DeathKnight\Unholy.lua
-- Rotation logic for Death Knight Unholy DPS in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.DEATHKNIGHT = DpsHelper.Rotations.DEATHKNIGHT or {}
DpsHelper.Rotations.DEATHKNIGHT.Unholy = DpsHelper.Rotations.DEATHKNIGHT.Unholy or {}

function DpsHelper.Rotations.DEATHKNIGHT.Unholy:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local frostRunes = select(1, GetRuneCount(1)) + select(1, GetRuneCount(2))
    local unholyRunes = select(1, GetRuneCount(3)) + select(1, GetRuneCount(4))
    local bloodRunes = select(1, GetRuneCount(5)) + select(1, GetRuneCount(6))
    local runicPower = UnitPower("player", 6)

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

    -- Rotação de Unholy
    if target and #queue == 0 then
        local spells = {
            { name = "Icy Touch", id = 49909, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Frost Fever")
                return remaining <= 2 and frostRunes >= 1 and unholyRunes >= 1
            end},
            { name = "Plague Strike", id = 49921, condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Blood Plague")
                return remaining <= 2 and frostRunes >= 1 and unholyRunes >= 1
            end},
            { name = "Scourge Strike", id = 55271, condition = function()
                return frostRunes >= 1 and unholyRunes >= 1
            end},
            { name = "Death Coil", id = 49895, condition = function()
                return runicPower >= 40
            end},
            { name = "Blood Strike", id = 49930, condition = function()
                return bloodRunes >= 1
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

DpsHelper.Utils:Print("Unholy.lua loaded for Death Knight")