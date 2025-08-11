-- Rotations\Warrior\Fury.lua
-- Rotation logic for Warrior Fury in WoW 3.3.5, optimized for rage dumping and procs.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.WARRIOR = DpsHelper.Rotations.WARRIOR or {}

DpsHelper.Rotations.WARRIOR.Fury = DpsHelper.Rotations.WARRIOR.Fury or {}
function DpsHelper.Rotations.WARRIOR.Fury:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Fury: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local bloodsurge = DpsHelper.Utils:GetBuffRemainingTime("player", "Bloodsurge") > 0

    local rage = UnitPower("player", 1)

    local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

    local isExecutePhase = targetHealthPercent <= 0.2
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Whirlwind",
            id = 1680,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Whirlwind")

            end,
            priority = 1
        }, {
            name = "Cleave",
            id = 845,
            condition = function()

                return rage > 30 and DpsHelper.SpellManager:IsSpellUsable("Cleave")

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
            name = "Execute",
            id = 5308,
            condition = function()

                return isExecutePhase and DpsHelper.SpellManager:IsSpellUsable("Execute")

            end,
            priority = 1
        }, {
            name = "Bloodthirst",
            id = 23881,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Bloodthirst")

            end,
            priority = 2
        }, {
            name = "Whirlwind",
            id = 1680,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Whirlwind")

            end,
            priority = 3
        }, {
            name = "Slam",
            id = 1464,
            condition = function()

                return bloodsurge and DpsHelper.SpellManager:IsSpellUsable("Slam")

            end,
            priority = 4
        }, {
            name = "Heroic Strike",
            id = 78,
            condition = function()

                return rage > 50 and DpsHelper.SpellManager:IsSpellUsable("Heroic Strike")

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
