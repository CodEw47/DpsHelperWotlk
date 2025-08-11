-- Rotations\DeathKnight\Unholy.lua
-- Rotation logic for Death Knight Unholy in WoW 3.3.5, optimized for diseases and pet.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.DEATHKNIGHT = DpsHelper.Rotations.DEATHKNIGHT or {}

DpsHelper.Rotations.DEATHKNIGHT.Unholy = DpsHelper.Rotations.DEATHKNIGHT.Unholy or {}
function DpsHelper.Rotations.DEATHKNIGHT.Unholy:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Unholy: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local runicPower = UnitPower("player", 6)

    local diseasesUp = DpsHelper.Utils:GetDebuffRemainingTime("target", "Frost Fever") > 0 and
                           DpsHelper.Utils:GetDebuffRemainingTime("target", "Blood Plague") > 0
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Death and Decay",
            id = 43265,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Death and Decay")

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
            name = "Scourge Strike",
            id = 55090,
            condition = function()

                return diseasesUp and DpsHelper.SpellManager:IsSpellUsable("Scourge Strike")

            end,
            priority = 3
        }, {
            name = "Death Coil",
            id = 47541,
            condition = function()

                return runicPower > 40 and DpsHelper.SpellManager:IsSpellUsable("Death Coil")

            end,
            priority = 4
        }, {
            name = "Blood Strike",
            id = 45902,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Blood Strike")

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
