-- 宠物倍率规则

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("PetTheta"))
local PetSystemRules = require(script.Parent.PetSystemRules)

local PetMultiplierRules = {}

local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

local function getPetInstance(progressState, petInstanceId)
	if not progressState or type(progressState.OwnedPets) ~= "table" then
		return nil
	end

	return progressState.OwnedPets[tostring(petInstanceId)]
end

function PetMultiplierRules.GetPetTypeMultiplier(petTypeId)
	local pet = PetTheta[petTypeId]
	return normalizeMultiplier(pet and pet.Multiplier or 1)
end

function PetMultiplierRules.GetEquippedPetMultiplier(progressState)
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	if type(equippedSlots) ~= "table" then
		return 1
	end

	local seenInstanceIds = {}
	local totalMultiplier = 0

	for slotIndex = 1, PetSystemRules.GetMaxEquippedPets() do
		local petInstanceId = equippedSlots[slotIndex]
		if not PetSystemRules.IsEmptyPetSlot(petInstanceId) then
			local normalizedInstanceId = tostring(petInstanceId)
			local petInstance = getPetInstance(progressState, normalizedInstanceId)
			if petInstance and not seenInstanceIds[normalizedInstanceId] then
				local petConfig = PetTheta[petInstance.PetTypeId]
				if petConfig then
					totalMultiplier += normalizeMultiplier(petConfig.Multiplier)
					seenInstanceIds[normalizedInstanceId] = true
				end
			end
		end
	end

	if totalMultiplier <= 0 then
		return 1
	end

	return totalMultiplier
end

return PetMultiplierRules
