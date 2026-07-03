-- 宠物状态归一化器

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetTheta"))
local PetSystemRules = require(script.Parent.PetSystemRules)

local PetStateNormalizer = {}

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in pairs(value) do
		copy[cloneValue(key)] = cloneValue(childValue)
	end

	return copy
end

function PetStateNormalizer.NormalizeSlots(equippedSlots)
	local normalizedSlots = {}
	local emptySlot = PetSystemRules.GetEmptyPetSlot()

	for slotIndex = 1, PetSystemRules.GetMaxEquippedPets() do
		local slotValue = type(equippedSlots) == "table" and equippedSlots[slotIndex] or emptySlot
		if PetSystemRules.IsEmptyPetSlot(slotValue) then
			normalizedSlots[slotIndex] = emptySlot
		else
			normalizedSlots[slotIndex] = tostring(slotValue)
		end
	end

	return normalizedSlots
end

function PetStateNormalizer.NormalizeOwnedPets(ownedPets)
	local normalizedOwnedPets = {}

	if type(ownedPets) ~= "table" then
		return normalizedOwnedPets
	end

	for instanceId, petInstance in pairs(ownedPets) do
		if type(petInstance) == "table" and type(petInstance.PetTypeId) == "string" then
			local normalizedInstanceId = tostring(petInstance.InstanceId or instanceId)
			if PetTheta[petInstance.PetTypeId] then
				normalizedOwnedPets[normalizedInstanceId] = {
					InstanceId = normalizedInstanceId,
					PetTypeId = petInstance.PetTypeId,
				}
			end
		end
	end

	return normalizedOwnedPets
end

function PetStateNormalizer.GetNextPetInstanceId(ownedPets, nextPetInstanceId)
	local nextInstanceNumber = math.max(1, math.floor(tonumber(nextPetInstanceId) or 1))

	for instanceId in pairs(ownedPets) do
		local instanceNumber = tonumber(instanceId)
		if instanceNumber and instanceNumber >= nextInstanceNumber then
			nextInstanceNumber = math.floor(instanceNumber) + 1
		end
	end

	return nextInstanceNumber
end

function PetStateNormalizer.NormalizeProgressState(progressState)
	if type(progressState) ~= "table" then
		return nil
	end

	local normalizedState = cloneValue(progressState)
	normalizedState.OwnedPets = PetStateNormalizer.NormalizeOwnedPets(normalizedState.OwnedPets)
	normalizedState.EquippedPetInstanceIds = PetStateNormalizer.NormalizeSlots(normalizedState.EquippedPetInstanceIds)
	normalizedState.NextPetInstanceId = PetStateNormalizer.GetNextPetInstanceId(
		normalizedState.OwnedPets,
		normalizedState.NextPetInstanceId
	)

	return normalizedState
end

return PetStateNormalizer
