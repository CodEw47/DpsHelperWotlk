-- Rotations\Druid\FeralCat.lua
-- Rotation logic for Druid Feral Cat in WoW 3.3.5, optimized for combo points and bleeds.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.DRUID = DpsHelper.Rotations.DRUID or {}

DpsHelper.Rotations.DRUID.FeralCat = DpsHelper.Rotations.DRUID.FeralCat or {}
function DpsHelper.Rotations.DRUID.FeralCat:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Feral Cat: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local comboPoints = GetComboPoints("player", "target")

    local energy = UnitPower("player", 3)

    local ripRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Rip")

    local savageRoarRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Savage Roar")
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Swipe (Cat)",
            id = 62078,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Swipe (Cat)") and energy > 45

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
            name = "Savage Roar",
            id = 52610,
            condition = function()

                return savageRoarRemaining <= 2 and comboPoints >= 1 and
                           DpsHelper.SpellManager:IsSpellUsable("Savage Roar")

            end,
            priority = 1
        }, {
            name = "Rip",
            id = 1079,
            condition = function()

                return ripRemaining <= 2 and comboPoints >= 5 and DpsHelper.SpellManager:IsSpellUsable("Rip")

            end,
            priority = 2
        }, {
            name = "Ferocious Bite",
            id = 22568,
            condition = function()

                return comboPoints >= 5 and DpsHelper.SpellManager:IsSpellUsable("Ferocious Bite")

            end,
            priority = 3
        }, {
            name = "Rake",
            id = 1822,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Rake") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Rake")

            end,
            priority = 4
        }, {
            name = "Shred",
            id = 5221,
            condition = function()

                return comboPoints < 5 and DpsHelper.SpellManager:IsSpellUsable("Shred")

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
