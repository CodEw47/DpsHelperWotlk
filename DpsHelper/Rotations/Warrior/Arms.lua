-- Rotations\Warrior\Arms.lua
-- Rotation logic for Warrior Arms in WoW 3.3.5, optimized for bleeds and executes.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.WARRIOR = DpsHelper.Rotations.WARRIOR or {}

DpsHelper.Rotations.WARRIOR.Arms = DpsHelper.Rotations.WARRIOR.Arms or {}
function DpsHelper.Rotations.WARRIOR.Arms:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Arms: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local tasteForBlood = DpsHelper.Utils:GetBuffRemainingTime("player", "Taste for Blood") > 0

    local rage = UnitPower("player", 1)

    local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

    local isExecutePhase = targetHealthPercent <= 0.2
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Bladestorm",
            id = 46924,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Bladestorm") and isBossOrElite

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
            name = "Rend",
            id = 772,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Rend") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Rend")

            end,
            priority = 2
        }, {
            name = "Overpower",
            id = 7384,
            condition = function()

                return tasteForBlood and DpsHelper.SpellManager:IsSpellUsable("Overpower")

            end,
            priority = 3
        }, {
            name = "Mortal Strike",
            id = 12294,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Mortal Strike")

            end,
            priority = 4
        }, {
            name = "Slam",
            id = 1464,
            condition = function()

                return rage > 20 and DpsHelper.SpellManager:IsSpellUsable("Slam")

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
