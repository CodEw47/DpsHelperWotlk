-- Rotations\Rogue\Combat.lua
-- Rotation logic for Rogue Combat in WoW 3.3.5, optimized for energy dumping.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.ROGUE = DpsHelper.Rotations.ROGUE or {}

DpsHelper.Rotations.ROGUE.Combat = DpsHelper.Rotations.ROGUE.Combat or {}
function DpsHelper.Rotations.ROGUE.Combat:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Combat: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local comboPoints = GetComboPoints("player", "target")

    local energy = UnitPower("player", 3)

    local sndRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Blade Flurry",
            id = 13877,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Blade Flurry")

            end,
            priority = 1
        }, {
            name = "Fan of Knives",
            id = 51723,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Fan of Knives") and energy > 60

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
            name = "Slice and Dice",
            id = 5171,
            condition = function()

                return sndRemaining <= 2 and comboPoints >= 1 and DpsHelper.SpellManager:IsSpellUsable("Slice and Dice")

            end,
            priority = 1
        }, {
            name = "Adrenaline Rush",
            id = 13750,
            condition = function()

                return isBossOrElite and DpsHelper.SpellManager:IsSpellUsable("Adrenaline Rush")

            end,
            priority = 2
        }, {
            name = "Eviscerate",
            id = 2098,
            condition = function()

                return comboPoints >= 5 and DpsHelper.SpellManager:IsSpellUsable("Eviscerate")

            end,
            priority = 3
        }, {
            name = "Rupture",
            id = 1943,
            condition = function()

                return comboPoints >= 4 and DpsHelper.Utils:GetDebuffRemainingTime("target", "Rupture") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Rupture")

            end,
            priority = 4
        }, {
            name = "Sinister Strike",
            id = 1752,
            condition = function()

                return comboPoints < 5 and DpsHelper.SpellManager:IsSpellUsable("Sinister Strike")

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
