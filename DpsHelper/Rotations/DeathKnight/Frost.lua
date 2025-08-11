-- Rotations\DeathKnight\Frost.lua
-- Rotation logic for Death Knight Frost in WoW 3.3.5, optimized for runes and procs.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.DEATHKNIGHT = DpsHelper.Rotations.DEATHKNIGHT or {}

DpsHelper.Rotations.DEATHKNIGHT.Frost = DpsHelper.Rotations.DEATHKNIGHT.Frost or {}
function DpsHelper.Rotations.DEATHKNIGHT.Frost:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Frost: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local killingMachine = DpsHelper.Utils:GetBuffRemainingTime("player", "Killing Machine") > 0

    local runicPower = UnitPower("player", 6)

    local diseasesUp = DpsHelper.Utils:GetDebuffRemainingTime("target", "Frost Fever") > 0 and
                           DpsHelper.Utils:GetDebuffRemainingTime("target", "Blood Plague") > 0
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Howling Blast",
            id = 49184,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Howling Blast")

            end,
            priority = 1
        }, {
            name = "Pestilence",
            id = 50842,
            condition = function()

                return diseasesUp and DpsHelper.SpellManager:IsSpellUsable("Pestilence")

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
            name = "Icy Touch",
            id = 49909,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Frost Fever") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Icy Touch")

            end,
            priority = 1
        }, {
            name = "Plague Strike",
            id = 49921,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Blood Plague") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Plague Strike")

            end,
            priority = 2
        }, {
            name = "Obliterate",
            id = 51425,
            condition = function()

                return diseasesUp and DpsHelper.SpellManager:IsSpellUsable("Obliterate")

            end,
            priority = 3
        }, {
            name = "Frost Strike",
            id = 49143,
            condition = function()

                return killingMachine and runicPower > 40 and DpsHelper.SpellManager:IsSpellUsable("Frost Strike")

            end,
            priority = 4
        }, {
            name = "Frost Strike",
            id = 49143,
            condition = function()

                return runicPower > 80 and DpsHelper.SpellManager:IsSpellUsable("Frost Strike")

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
