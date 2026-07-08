-- 宠物掉落选择器

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("PetTheta"))

local PetRollSelector = {}

local random = Random.new()
local REWARD_ROLL_WEIGHT_DENOMINATOR = 10000

local function chooseFromWeightedPetTypes(weightedPetTypeIds, rollWeightDenominator)
	local totalWeight = 0
	local validWeightedPetTypeIds = {}

	for _, weightedPetType in ipairs(weightedPetTypeIds) do
		local petTypeId = weightedPetType.PetTypeId
		local petConfig = type(petTypeId) == "string" and PetTheta[petTypeId] or nil
		local rollWeight = math.max(0, tonumber(weightedPetType.RollWeight) or 0)
		if petConfig and rollWeight > 0 then
			totalWeight += rollWeight
			table.insert(validWeightedPetTypeIds, {
				PetTypeId = petTypeId,
				RollWeight = rollWeight,
			})
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local rollMax = math.max(tonumber(rollWeightDenominator) or totalWeight, totalWeight)
	local roll = random:NextNumber(0, rollMax)
	local cursor = 0
	for _, weightedPetType in ipairs(validWeightedPetTypeIds) do
		cursor += weightedPetType.RollWeight
		if roll < cursor then
			return weightedPetType.PetTypeId
		end
	end

	return nil
end

local function getWeightedPetTypesFromRewards(rewards)
	if type(rewards) ~= "table" then
		return nil
	end

	local weightedPetTypeIds = {}
	for _, reward in ipairs(rewards) do
		if type(reward) == "table" then
			table.insert(weightedPetTypeIds, {
				PetTypeId = reward.PetTypeId,
				RollWeight = reward.RollWeight,
			})
		end
	end

	return weightedPetTypeIds
end

function PetRollSelector.ChoosePetTypeId(rewards)
	return chooseFromWeightedPetTypes(
		getWeightedPetTypesFromRewards(rewards) or {},
		REWARD_ROLL_WEIGHT_DENOMINATOR
	)
end

return PetRollSelector
