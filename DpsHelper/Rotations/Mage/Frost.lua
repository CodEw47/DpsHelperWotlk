-- Rotations\Mage\Frost.lua
-- Rotation logic for Mage Frost in WoW 3.3.5, optimized for control and AoE.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.MAGE = DpsHelper.Rotations.MAGE or {}

DpsHelper.Rotations.MAGE.Frost = DpsHelper.Rotations.MAGE.Frost or {}
function DpsHelper.Rotations.MAGE.Frost:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Frost: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local fingersOfFrost = DpsHelper.Utils:GetBuffRemainingTime("player", "Fingers of Frost") > 0

    local brainFreeze = DpsHelper.Utils:GetBuffRemainingTime("player", "Brain Freeze") > 0

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Blizzard",
            id = 10,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Blizzard")

            end,
            priority = 1
        }, {
            name = "Cone of Cold",
            id = 120,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Cone of Cold")

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
            name = "Frostbolt",
            id = 116,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Frostbolt")

            end,
            priority = 1
        }, {
            name = "Ice Lance",
            id = 30455,
            condition = function()

                return fingersOfFrost and DpsHelper.SpellManager:IsSpellUsable("Ice Lance")

            end,
            priority = 2
        }, {
            name = "Fire Blast",
            id = 2136,
            condition = function()

                return brainFreeze and DpsHelper.SpellManager:IsSpellUsable("Fire Blast")

            end,
            priority = 3
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
