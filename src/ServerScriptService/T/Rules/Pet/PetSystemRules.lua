-- 宠物系统规则

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetSystemTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetSystemTheta"))

local PetSystemRules = {}

function PetSystemRules.GetMaxEquippedPets()
	return math.max(0, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 0))
end

-- 返回约定的空槽标记
function PetSystemRules.GetEmptyPetSlot()
	return PetSystemTheta.EmptyPetSlot == nil and 0 or PetSystemTheta.EmptyPetSlot
end

-- 判断值是否是空槽标记
function PetSystemRules.IsEmptyPetSlot(value)
	local emptySlot = PetSystemRules.GetEmptyPetSlot()
	return value == nil or value == emptySlot or tostring(value) == tostring(emptySlot)
end

function PetSystemRules.GetRollCooldownSeconds()
	return math.max(0, tonumber(PetSystemTheta.RollCooldownSeconds) or 0)
end

return PetSystemRules
