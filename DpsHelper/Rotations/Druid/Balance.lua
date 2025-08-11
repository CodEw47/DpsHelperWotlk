-- Rotations\Druid\Balance.lua
-- Rotation logic for Druid Balance in WoW 3.3.5, optimized for eclipses.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.DRUID = DpsHelper.Rotations.DRUID or {}

DpsHelper.Rotations.DRUID.Balance = DpsHelper.Rotations.DRUID.Balance or {}
function DpsHelper.Rotations.DRUID.Balance:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Balance: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local eclipseSolar = DpsHelper.Utils:GetBuffRemainingTime("player", "Eclipse (Solar)") > 0

    local eclipseLunar = DpsHelper.Utils:GetBuffRemainingTime("player", "Eclipse (Lunar)") > 0

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Hurricane",
            id = 16914,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Hurricane") and manaPercent > 0.3

            end,
            priority = 1
        }, {
            name = "Typhoon",
            id = 50516,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Typhoon")

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
            name = "Insect Swarm",
            id = 5570,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Insect Swarm") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Insect Swarm")

            end,
            priority = 1
        }, {
            name = "Moonfire",
            id = 8921,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Moonfire") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Moonfire")

            end,
            priority = 2
        }, {
            name = "Wrath",
            id = 5176,
            condition = function()

                return eclipseSolar and DpsHelper.SpellManager:IsSpellUsable("Wrath")

            end,
            priority = 3
        }, {
            name = "Starfire",
            id = 2912,
            condition = function()

                return eclipseLunar and DpsHelper.SpellManager:IsSpellUsable("Starfire")

            end,
            priority = 4
        }, {
            name = "Wrath",
            id = 5176,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Wrath")

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
