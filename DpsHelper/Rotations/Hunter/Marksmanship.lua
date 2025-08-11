-- Rotations\Hunter\Marksmanship.lua
-- Rotation logic for Hunter Marksmanship in WoW 3.3.5, optimized for precise shots.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.HUNTER = DpsHelper.Rotations.HUNTER or {}

DpsHelper.Rotations.HUNTER.Marksmanship = DpsHelper.Rotations.HUNTER.Marksmanship or {}
function DpsHelper.Rotations.HUNTER.Marksmanship:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Marksmanship: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local rapidFire = DpsHelper.Utils:GetBuffRemainingTime("player", "Rapid Fire") > 0

    local focusPercent = UnitPower("player", 2) / UnitPowerMax("player", 2)

    local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

    local isExecutePhase = targetHealthPercent <= 0.2
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Multi-Shot",
            id = 2643,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Multi-Shot")

            end,
            priority = 1
        }, {
            name = "Volley",
            id = 1510,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Volley")

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
            name = "Kill Shot",
            id = 53351,
            condition = function()

                return isExecutePhase and DpsHelper.SpellManager:IsSpellUsable("Kill Shot")

            end,
            priority = 1
        }, {
            name = "Chimera Shot",
            id = 53209,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Chimera Shot")

            end,
            priority = 2
        }, {
            name = "Aimed Shot",
            id = 19434,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Aimed Shot")

            end,
            priority = 3
        }, {
            name = "Arcane Shot",
            id = 3044,
            condition = function()

                return focusPercent > 0.5 and DpsHelper.SpellManager:IsSpellUsable("Arcane Shot")

            end,
            priority = 4
        }, {
            name = "Steady Shot",
            id = 56641,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Steady Shot")

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
