-- Rotations\Warlock\Demonology.lua
-- Rotation logic for Warlock Demonology in WoW 3.3.5, optimized for maximum DPS with burst reserved for boss targets.
DpsHelper = DpsHelper or {}
DpsHelper.Rotations = DpsHelper.Rotations or {}
DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}
DpsHelper.Rotations.WARLOCK.Demonology = DpsHelper.Rotations.WARLOCK.Demonology or {}

function DpsHelper.Rotations.WARLOCK.Demonology:GetRotationQueue()
    local queue = {}
    local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3
    local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()
    DpsHelper.Utils:DebugPrint(2,
        "Demonology: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" ..
            (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))

    -- Verificar estados de buffs, debuffs e procs
    local moltenCore = DpsHelper.Utils:GetBuffRemainingTime("player", "Molten Core") > 0
    local decimation = DpsHelper.Utils:GetBuffRemainingTime("player", "Decimation") > 0
    local inMetamorphosis = DpsHelper.Utils:GetBuffRemainingTime("player", "Metamorphosis") > 0
    local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1
    local isExecutePhase = targetHealthPercent <= 0.35
    local canCastInMelee = target and DpsHelper.Utils:GetDistanceToUnit("target") <= 8
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
    local soulShards = DpsHelper.Utils:GetCurrentSoulShards()

    -- Rotação AoE
    if target and isAoE then
        local spells = {{
            name = "Metamorphosis",
            id = 47241,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Metamorphosis")
                DpsHelper.Utils:DebugPrint(2, "Metamorphosis usable: " .. tostring(usable))
                return not inMetamorphosis and canCastInMelee and isBossOrElite and usable
            end,
            priority = 1
        }, {
            name = "Immolation Aura",
            id = 50589,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Immolation Aura")
                DpsHelper.Utils:DebugPrint(2, "Immolation Aura usable: " .. tostring(usable))
                return inMetamorphosis and DpsHelper.Utils:GetBuffRemainingTime("player", "Immolation Aura") == 0 and
                           usable
            end,
            priority = 2
        }, {
            name = "Shadow Cleave",
            id = 50590,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Shadow Cleave")
                DpsHelper.Utils:DebugPrint(2, "Shadow Cleave usable: " .. tostring(usable))
                return inMetamorphosis and usable
            end,
            priority = 3
        }, {
            name = "Shadowflame",
            id = 47897,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Shadowflame")
                DpsHelper.Utils:DebugPrint(2, "Shadowflame usable: " .. tostring(usable))
                return canCastInMelee and usable
            end,
            priority = 4
        }, {
            name = "Seed of Corruption",
            id = 47836,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Seed of Corruption")
                DpsHelper.Utils:DebugPrint(2, "Seed of Corruption usable: " .. tostring(usable))
                return usable and manaPercent > 0.2
            end,
            priority = 5
        }}

        local validSpells = {}
        for _, spell in ipairs(spells) do
            if spell.condition() then
                table.insert(validSpells, spell)
                DpsHelper.Utils:DebugPrint(2, "Demonology: Valid AoE spell: " .. spell.name)
            end
        end

        table.sort(validSpells, function(a, b)
            return a.priority < b.priority
        end)

        for i = 1, math.min(3, #validSpells) do
            local spell = validSpells[i]
            table.insert(queue, {
                name = spell.name,
                spellID = spell.id,
                type = "spell",
                priority = spell.priority
            })
            DpsHelper.Utils:DebugPrint(2, "Demonology: Added to AoE queue: " .. spell.name .. " (priority " ..
                spell.priority .. ")")
        end
        -- Rotação Single-Target
    elseif target then
        local spells = {{
            name = "Life Tap",
            id = 1454,
            condition = function()
                local buffRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Life Tap")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Life Tap")
                DpsHelper.Utils:DebugPrint(2, "Life Tap usable: " .. tostring(usable) .. ", buff remaining: " ..
                    buffRemaining .. ", mana: " .. manaPercent)
                return (manaPercent < 0.15 or (buffRemaining <= 2 and manaPercent < 0.5)) and usable and
                           UnitHealth("player") / UnitHealthMax("player") > 0.3
            end,
            priority = 1
        }, {
            name = "Metamorphosis",
            id = 47241,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Metamorphosis")
                DpsHelper.Utils:DebugPrint(2, "Metamorphosis usable: " .. tostring(usable))
                return not inMetamorphosis and isBossOrElite and usable
            end,
            priority = 2
        }, {
            name = "Demonic Empowerment",
            id = 47193,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Demonic Empowerment")
                local petExists = UnitExists("pet") and not UnitIsDead("pet")
                DpsHelper.Utils:DebugPrint(2, "Demonic Empowerment usable: " .. tostring(usable) .. ", pet exists: " ..
                    tostring(petExists))
                return usable and petExists and (isBossOrElite or inMetamorphosis)
            end,
            priority = 3
        }, {
            name = "Shadowflame",
            id = 47897,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Shadowflame")
                DpsHelper.Utils:DebugPrint(2, "Shadowflame usable: " .. tostring(usable))
                return canCastInMelee and isBossOrElite and usable
            end,
            priority = 4
        }, {
            name = "Corruption",
            id = 172,
            condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Corruption")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Corruption")
                DpsHelper.Utils:DebugPrint(2, "Corruption usable: " .. tostring(usable) .. ", remaining: " .. remaining)
                return remaining <= 2 and remaining >= 0 and usable
            end,
            priority = 5
        }, {
            name = "Immolate",
            id = 348,
            condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Immolate")
                DpsHelper.Utils:DebugPrint(2, "Immolate usable: " .. tostring(usable) .. ", remaining: " .. remaining)
                return remaining <= 2 and remaining >= 0 and usable
            end,
            priority = 6
        }, {
            name = "Curse of Doom",
            id = 603,
            condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                local agonyRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony")
                local elementsRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of the Elements")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Curse of Doom")
                DpsHelper.Utils:DebugPrint(2,
                    "Curse of Doom usable: " .. tostring(usable) .. ", remaining: " .. remaining .. ", boss/elite: " ..
                        tostring(isBossOrElite))
                return remaining <= 2 and remaining >= 0 and isBossOrElite and DpsHelper.Utils:IsTargetAliveFor(60) and
                           agonyRemaining == 0 and elementsRemaining == 0 and usable
            end,
            priority = 7
        }, {
            name = "Curse of Agony",
            id = 980,
            condition = function()
                local agonyRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony")
                local doomRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                local elementsRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of the Elements")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Curse of Agony")
                DpsHelper.Utils:DebugPrint(2,
                    "Curse of Agony usable: " .. tostring(usable) .. ", agony remaining: " .. agonyRemaining ..
                        ", doom remaining: " .. doomRemaining)
                return agonyRemaining <= 2 and agonyRemaining >= 0 and doomRemaining == 0 and elementsRemaining == 0 and
                           not isBossOrElite and DpsHelper.Utils:IsTargetAliveFor(24) and usable
            end,
            priority = 8
        }, {
            name = "Curse of the Elements",
            id = 27228,
            condition = function()
                local remaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of the Elements")
                local doomRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Doom")
                local agonyRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Curse of Agony")
                local usable = DpsHelper.SpellManager:IsSpellUsable("Curse of the Elements")
                DpsHelper.Utils:DebugPrint(2, "Curse of the Elements usable: " .. tostring(usable) .. ", remaining: " ..
                    remaining)
                return remaining <= 2 and remaining >= 0 and doomRemaining == 0 and agonyRemaining == 0 and usable
            end,
            priority = 9
        }, {
            name = "Soul Fire",
            id = 6353,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Soul Fire")
                DpsHelper.Utils:DebugPrint(2, "Soul Fire usable: " .. tostring(usable) .. ", decimation: " ..
                    tostring(decimation) .. ", shards: " .. soulShards)
                return (decimation or isExecutePhase) and usable and soulShards >= 1
            end,
            priority = 10
        }, {
            name = "Incinerate",
            id = 29722,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Incinerate")
                local immolateRemaining = DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate")
                DpsHelper.Utils:DebugPrint(2,
                    "Incinerate usable: " .. tostring(usable) .. ", moltenCore: " .. tostring(moltenCore) ..
                        ", immolate: " .. immolateRemaining)
                return (moltenCore or immolateRemaining > 0) and usable
            end,
            priority = 11
        }, {
            name = "Shadow Bolt",
            id = 686,
            condition = function()
                local usable = DpsHelper.SpellManager:IsSpellUsable("Shadow Bolt")
                DpsHelper.Utils:DebugPrint(2, "Shadow Bolt usable: " .. tostring(usable))
                return usable and not moltenCore and DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate") == 0
            end,
            priority = 12
        }}

        local validSpells = {}
        for _, spell in ipairs(spells) do
            if spell.condition() then
                table.insert(validSpells, spell)
                DpsHelper.Utils:DebugPrint(2, "Demonology: Valid single-target spell: " .. spell.name)
            end
        end

        table.sort(validSpells, function(a, b)
            local aRemaining =
                (a.name == "Immolate" or a.name == "Corruption" or a.name == "Curse of Agony" or a.name ==
                    "Curse of Doom" or a.name == "Curse of the Elements") and
                    DpsHelper.Utils:GetDebuffRemainingTime("target", a.name) or 999
            local bRemaining =
                (b.name == "Immolate" or b.name == "Corruption" or a.name == "Curse of Agony" or a.name ==
                    "Curse of Doom" or a.name == "Curse of the Elements") and
                    DpsHelper.Utils:GetDebuffRemainingTime("target", b.name) or 999
            if aRemaining <= 2 and bRemaining > 2 then
                return true
            elseif bRemaining <= 2 and aRemaining > 2 then
                return false
            else
                return a.priority < b.priority
            end
        end)

        for i = 1, math.min(3, #validSpells) do
            local spell = validSpells[i]
            table.insert(queue, {
                name = spell.name,
                spellID = spell.id,
                type = "spell",
                priority = spell.priority
            })
            DpsHelper.Utils:DebugPrint(2, "Demonology: Added to single-target queue: " .. spell.name .. " (priority " ..
                spell.priority .. ")")
        end
    end

    -- Fallback para alvo inválido: sugerir Life Tap se necessário
    if not target then
        local lifeTapUsable = DpsHelper.SpellManager:IsSpellUsable("Life Tap")
        local lifeTapRemaining = DpsHelper.Utils:GetBuffRemainingTime("player", "Life Tap")
        DpsHelper.Utils:DebugPrint(2,
            "Demonology: Fallback check for Life Tap: usable=" .. tostring(lifeTapUsable) .. ", remaining=" ..
                lifeTapRemaining .. ", mana=" .. manaPercent)
        if manaPercent < 0.4 and lifeTapUsable and UnitHealth("player") / UnitHealthMax("player") > 0.3 then
            table.insert(queue, {
                name = "Life Tap",
                spellID = 1454,
                type = "spell",
                priority = 1
            })
            DpsHelper.Utils:DebugPrint(2, "Demonology: Added Life Tap to queue for invalid target")
        end
    end

    if #queue == 0 then
        DpsHelper.Utils:DebugPrint(2, "Demonology: No usable items in rotation queue")
    else
        DpsHelper.Utils:DebugPrint(2, "Demonology: Rotation queue generated with " .. #queue .. " items")
    end
    return queue
end

DpsHelper.Utils:DebugPrint(2, "Demonology.lua loaded for Warlock")
