-- Rotations\Warlock\Affliction.lua
-- Rotation logic for Warlock Affliction in WoW 3.3.5, optimized for DoT management and sustained DPS.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}

DpsHelper.Rotations.WARLOCK.Affliction = DpsHelper.Rotations.WARLOCK.Affliction or {}
function DpsHelper.Rotations.WARLOCK.Affliction:GetRotationQueue()

    local queue = {}

    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

    DpsHelper.Utils:DebugPrint(2,
        "Affliction: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
    -- Verificar estados de buffs, debuffs e procs

    local shadowTrance = DpsHelper.Utils:GetBuffRemainingTime("player", "Shadow Trance") > 0

    local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

    local isExecutePhase = targetHealthPercent <= 0.25

    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")

    local soulShards = DpsHelper.Utils:GetCurrentSoulShards()
    -- Rotação AoE

    if target and isAoE then

        local spells = {{
            name = "Seed of Corruption",
            id = 47836,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Seed of Corruption") and manaPercent > 0.2

            end,
            priority = 1
        }, {
            name = "Haunt",
            id = 48181,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Haunt") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Haunt")

            end,
            priority = 2
        }, {
            name = "Shadow Bolt",
            id = 686,
            condition = function()

                return shadowTrance and DpsHelper.SpellManager:IsSpellUsable("Shadow Bolt")

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

        -- Rotação Single-Target

    elseif target then

        local spells = {{
            name = "Haunt",
            id = 48181,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Haunt") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Haunt")

            end,
            priority = 1
        }, {
            name = "Curse of Agony",
            id = 980,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Curse of Agony")

            end,
            priority = 2
        }, {
            name = "Corruption",
            id = 172,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Corruption") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Corruption")

            end,
            priority = 3
        }, {
            name = "Unstable Affliction",
            id = 47843,
            condition = function()

                return DpsHelper.Utils:GetDebuffRemainingTime("target", "Unstable Affliction") <= 2 and
                           DpsHelper.SpellManager:IsSpellUsable("Unstable Affliction")

            end,
            priority = 4
        }, {
            name = "Drain Soul",
            id = 47855,
            condition = function()

                return isExecutePhase and soulShards < 4 and DpsHelper.SpellManager:IsSpellUsable("Drain Soul")

            end,
            priority = 5
        }, {
            name = "Shadow Bolt",
            id = 686,
            condition = function()

                return shadowTrance and DpsHelper.SpellManager:IsSpellUsable("Shadow Bolt")

            end,
            priority = 6
        }, {
            name = "Shadow Bolt",
            id = 686,
            condition = function()

                return DpsHelper.SpellManager:IsSpellUsable("Shadow Bolt")

            end,
            priority = 7
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
    -- Fallback para alvo inválido: Life Tap se necessário

    if not target and manaPercent < 0.4 and DpsHelper.SpellManager:IsSpellUsable("Life Tap") and UnitHealth("player") /
        UnitHealthMax("player") > 0.3 then

        table.insert(queue, {
            name = "Life Tap",
            spellID = 1454,
            type = "spell",
            priority = 1
        })

    end
    return queue

end
