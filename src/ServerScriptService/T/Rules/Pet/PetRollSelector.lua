-- 宠物掉落选择器

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetTheta"))

local PetRollSelector = {}

local random = Random.new()

local function chooseFromWeightedPetTypes(weightedPetTypeIds)
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

	local roll = random:NextNumber(0, totalWeight)
	local cursor = 0
	for _, weightedPetType in ipairs(validWeightedPetTypeIds) do
		cursor += weightedPetType.RollWeight
		if roll <= cursor then
			return weightedPetType.PetTypeId
		end
	end

	return validWeightedPetTypeIds[#validWeightedPetTypeIds].PetTypeId
end

local function getWeightedPetTypesFromRewards(eggConfig)
	local rewards = eggConfig and eggConfig.Rewards
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

local function getWeightedPetTypesFromPetConfig(eggConfig)
	local petTypeIds = eggConfig and eggConfig.PetTypeIds
	if type(petTypeIds) ~= "table" then
		return nil
	end

	local weightedPetTypeIds = {}
	for _, petTypeId in ipairs(petTypeIds) do
		local petConfig = type(petTypeId) == "string" and PetTheta[petTypeId] or nil
		if petConfig then
			table.insert(weightedPetTypeIds, {
				PetTypeId = petTypeId,
				RollWeight = petConfig.RollWeight,
			})
		end
	end

	return weightedPetTypeIds
end

function PetRollSelector.ChoosePetTypeId(eggConfig)
	local weightedPetTypeIds = getWeightedPetTypesFromRewards(eggConfig)
	if weightedPetTypeIds then
		local petTypeId = chooseFromWeightedPetTypes(weightedPetTypeIds)
		if petTypeId then
			return petTypeId
		end
	end

	return chooseFromWeightedPetTypes(getWeightedPetTypesFromPetConfig(eggConfig) or {})
end

return PetRollSelector
