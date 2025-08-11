-- Rotations\Hunter\Survival.lua

-- Rotation logic for Hunter Survival in WoW 3.3.5, optimized for traps and explosives.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.HUNTER = DpsHelper.Rotations.HUNTER or {}

DpsHelper.Rotations.HUNTER.Survival = DpsHelper.Rotations.HUNTER.Survival or {}
function DpsHelper.Rotations.HUNTER.Survival:GetRotationQueue()

local queue = {}

local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

DpsHelper.Utils:DebugPrint(2, "Survival: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" .. (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
-- Verificar estados de buffs, debuffs e procs

local lockAndLoad = DpsHelper.Utils:GetBuffRemainingTime("player", "Lock and Load") > 0

local focusPercent = UnitPower("player", 2) / UnitPowerMax("player", 2)

local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

local isExecutePhase = targetHealthPercent <= 0.2
-- Rotação AoE

if target and isAoE then

local spells = {

{ name = "Explosive Trap", id = 13813, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Explosive Trap")

end, priority = 1 },

{ name = "Multi-Shot", id = 2643, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Multi-Shot")

end, priority = 2 }

}
local validSpells = {}

for _, spell in ipairs(spells) do

if spell.condition() then table.insert(validSpells, spell) end

end
table.sort(validSpells, function(a, b) return a.priority < b.priority end)
for i = 1, math.min(3, #validSpells) do

table.insert(queue, { name = validSpells[i].name, spellID = validSpells[i].id, type = "spell", priority = validSpells[i].priority })

end

-- Rotação Single-Target

elseif target then

local spells = {

{ name = "Kill Shot", id = 53351, condition = function()

return isExecutePhase and DpsHelper.SpellManager:IsSpellUsable("Kill Shot")

end, priority = 1 },

{ name = "Explosive Shot", id = 53301, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Explosive Shot")

end, priority = 2 },

{ name = "Black Arrow", id = 3674, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Black Arrow")

end, priority = 3 },

{ name = "Aimed Shot", id = 19434, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Aimed Shot")

end, priority = 4 },

{ name = "Steady Shot", id = 56641, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Steady Shot")

end, priority = 5 },

{ name = "Serpent Sting", id = 1978, condition = function()

return DpsHelper.Utils:GetDebuffRemainingTime("target", "Serpent Sting") <= 2 and DpsHelper.SpellManager:IsSpellUsable("Serpent Sting")

end, priority = 6 }

}
local validSpells = {}

for _, spell in ipairs(spells) do

if spell.condition() then table.insert(validSpells, spell) end

end
table.sort(validSpells, function(a, b) return a.priority < b.priority end)
for i = 1, math.min(3, #validSpells) do

table.insert(queue, { name = validSpells[i].name, spellID = validSpells[i].id, type = "spell", priority = validSpells[i].priority })

end

end
return queue

end