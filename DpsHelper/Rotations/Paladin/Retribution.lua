-- Rotations\Paladin\Retribution.lua
-- Rotation logic for Paladin Retribution in WoW 3.3.5, optimized for holy power and cooldowns.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.PALADIN = DpsHelper.Rotations.PALADIN or {}

DpsHelper.Rotations.PALADIN.Retribution = DpsHelper.Rotations.PALADIN.Retribution or {}
function DpsHelper.Rotations.PALADIN.Retribution:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Retribution: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local artOfWar = DpsHelper.Utils:GetBuffRemainingTime("player", "The Art of War") > 0

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Divine Storm",
            id = 53385,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Divine Storm")

            end,
            priority = 1
        }, {
            name = "Consecration",
            id = 26573,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Consecration") and manaPercent > 0.3

            end,
            priority = 2
        }}
        local validSpells = {}

        for _, spell in ipairs(spells) do

            if spell.condition() then
                table.insert(validSpells, spell)
            end

        end
        table.sort(validSpells, function(a, b)
            return a.priority < b.priority
        end)
        for i = 1, math.min(3, #validSpells) do

            table.insert(queue, {
                name = validSpells[i].name,
                spellID = validSpells[i].id,
                type = "spell",
                priority = validSpells[i].priority
            })

        end

        -- Rotação Single-Target

    elseif target then

        local spells = {{
            name = "Judgement of Wisdom",
            id = 20184,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Judgement of Wisdom")

            end,
            priority = 1
        }, {
            name = "Crusader Strike",
            id = 35395,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Crusader Strike")

            end,
            priority = 2
        }, {
            name = "Divine Storm",
            id = 53385,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Divine Storm")

            end,
            priority = 3
        }, {
            name = "Consecration",
            id = 26573,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Consecration") and manaPercent > 0.3

            end,
            priority = 4
        }, {
            name = "Exorcism",
            id = 879,
            condition = function()

                return artOfWar and DpsHelper.SpellManager:IsSpellUsable("Exorcism")

            end,
            priority = 5
        }}
        local validSpells = {}

        for _, spell in ipairs(spells) do

            if spell.condition() then
                table.insert(validSpells, spell)
            end

        end
        table.sort(validSpells, function(a, b)
            return a.priority < b.priority
        end)
        for i = 1, math.min(3, #validSpells) do

            table.insert(queue, {
                name = validSpells[i].name,
                spellID = validSpells[i].id,
                type = "spell",
                priority = validSpells[i].priority
            })

        end

    end
    return queue

end
