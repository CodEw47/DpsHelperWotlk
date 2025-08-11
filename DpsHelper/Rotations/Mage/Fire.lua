-- Rotations\Mage\Fire.lua
-- Rotation logic for Mage Fire in WoW 3.3.5, optimized for crit procs and DoTs.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.MAGE = DpsHelper.Rotations.MAGE or {}

DpsHelper.Rotations.MAGE.Fire = DpsHelper.Rotations.MAGE.Fire or {}
function DpsHelper.Rotations.MAGE.Fire:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Fire: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local hotStreak = DpsHelper.Utils:GetBuffRemainingTime("player", "Hot Streak") > 0

    local combustion = DpsHelper.Utils:GetBuffRemainingTime("player", "Combustion") > 0

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Flamestrike",
            id = 2120,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Flamestrike")

            end,
            priority = 1
        }, {
            name = "Blizzard",
            id = 10,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Blizzard")

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
            name = "Living Bomb",
            id = 44457,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Living Bomb") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Living Bomb")

            end,
            priority = 1
        }, {
            name = "Pyroblast",
            id = 11366,
            condition = function()

                return hotStreak and DpsHelper.SpellManager:IsSpellUsable("Pyroblast")

            end,
            priority = 2
        }, {
            name = "Combustion",
            id = 11129,
            condition = function()

                return not combustion and isBossOrElite and DpsHelper.SpellManager:IsSpellUsable("Combustion")

            end,
            priority = 3
        }, {
            name = "Fireball",
            id = 133,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Fireball")

            end,
            priority = 4
        }, {
            name = "Scorch",
            id = 2948,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Improved Scorch") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Scorch")

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
