-- 宠物系统规则

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetSystemTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetSystemTheta"))

local PetSystemRules = {}

function PetSystemRules.GetMaxEquippedPets()
	return math.max(0, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 0))
end

function PetSystemRules.GetEmptyPetSlot()
	return PetSystemTheta.EmptyPetSlot == nil and 0 or PetSystemTheta.EmptyPetSlot
end

function PetSystemRules.IsEmptyPetSlot(value)
	local emptySlot = PetSystemRules.GetEmptyPetSlot()
	return value == nil or value == emptySlot or tostring(value) == tostring(emptySlot)
end

function PetSystemRules.GetRollCooldownSeconds()
	return math.max(0, tonumber(PetSystemTheta.RollCooldownSeconds) or 0)
end

return PetSystemRules
