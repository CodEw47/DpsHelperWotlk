-- Rotations\Rogue\Assassination.lua
-- Rotation logic for Rogue Assassination in WoW 3.3.5, optimized for poisons and bleeds.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.ROGUE = DpsHelper.Rotations.ROGUE or {}

DpsHelper.Rotations.ROGUE.Assassination = DpsHelper.Rotations.ROGUE.Assassination or {}
function DpsHelper.Rotations.ROGUE.Assassination:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Assassination: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local comboPoints = GetComboPoints("player", "target")

    local energy = UnitPower("player", 3)

    local sndRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Slice and Dice")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Fan of Knives",
            id = 51723,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Fan of Knives") and energy > 60

            end,
            priority = 1
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
            name = "Hunger for Blood",
            id = 51662,
            condition = function()

                return DpsHelper.Utils:GetBuffRemainingTime("player", "Hunger for Blood") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Hunger for Blood")

            end,
            priority = 2
        }, {
            name = "Envenom",
            id = 32645,
            condition = function()

                return comboPoints >= 4 and DpsHelper.SpellManager:IsSpellUsable("Envenom")

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
            name = "Mutilate",
            id = 1329,
            condition = function()

                return comboPoints < 5 and DpsHelper.SpellManager:IsSpellUsable("Mutilate")

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
