-- Rotations\Shaman\Elemental.lua
-- Rotation logic for Shaman Elemental in WoW 3.3.5, optimized for shocks and totems.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.SHAMAN = DpsHelper.Rotations.SHAMAN or {}

DpsHelper.Rotations.SHAMAN.Elemental = DpsHelper.Rotations.SHAMAN.Elemental or {}
function DpsHelper.Rotations.SHAMAN.Elemental:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Elemental: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local clearcasting = DpsHelper.Utils:GetBuffRemainingTime("player", "Clearcasting") > 0

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Chain Lightning",
            id = 421,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Chain Lightning")

            end,
            priority = 1
        }, {
            name = "Magma Totem",
            id = 8190,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Magma Totem")

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
            name = "Flame Shock",
            id = 8050,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Flame Shock") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Flame Shock")

            end,
            priority = 1
        }, {
            name = "Lava Burst",
            id = 51505,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Lava Burst")

            end,
            priority = 2
        }, {
            name = "Lightning Bolt",
            id = 403,
            condition = function()

                return clearcasting and DpsHelper.SpellManager:IsSpellUsable("Lightning Bolt")

            end,
            priority = 3
        }, {
            name = "Lightning Bolt",
            id = 403,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Lightning Bolt")

            end,
            priority = 4
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
