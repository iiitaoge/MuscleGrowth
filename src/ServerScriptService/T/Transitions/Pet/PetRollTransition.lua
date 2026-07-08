local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")

local EggCostTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("EggCostTheta"))
local EggRewardTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("EggRewardTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.Parent.Parent.S.TrainingRuntimeState)
local EggObservation = require(script.Parent.Parent.Parent.Parent.y.EggObservation)
local PetRollSelector = require(script.Parent.Parent.Parent.Rules.Pet.PetRollSelector)
local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Parent.Snapshots.PlayerSnapshotBuilder)

local PetRollTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"
local TOO_FREQUENT_MESSAGE = "Too frequent"
local NOT_ENOUGH_TROPHIES_MESSAGE = "Not enough trophies"
local VALID_ROLL_COUNTS = {
	[1] = true,
	[3] = true,
}

local function failure(message, player)
	return {
		Success = false,
		Message = message,
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}
end

local function success(message, player, extraResult)
	local result = {
		Success = true,
		Message = message,
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}

	if type(extraResult) == "table" then
		for key, value in pairs(extraResult) do
			result[key] = value
		end
	end

	return result
end

local function getRuntimeOrInit(player)
	local runtimeState = TrainingRuntimeState.Get(player)
	if type(runtimeState) ~= "table" then
		runtimeState = {
			LastPetRollTime = 0,
		}
	end

	runtimeState.LastPetRollTime = math.max(0, tonumber(runtimeState.LastPetRollTime) or 0)
	return runtimeState
end

local function setPetRollTime(player, runtimeState, rollTime)
	runtimeState.LastPetRollTime = math.max(0, tonumber(rollTime) or 0)
	TrainingRuntimeState.Set(player, runtimeState)
end

local function isRollOnCooldown(runtimeState, now)
	return now - runtimeState.LastPetRollTime < PetSystemRules.GetRollCooldownSeconds()
end

local function getCostConfig(eggId)
	local costConfig = EggCostTheta.Costs and EggCostTheta.Costs[eggId]
	return type(costConfig) == "table" and costConfig or nil
end

local function getRewardConfig(eggId)
	local rewardConfig = EggRewardTheta[eggId]
	return type(rewardConfig) == "table" and rewardConfig or nil
end

local function isSupportedCostConfig(costConfig)
	local costResource = costConfig and costConfig.CostResource
	return type(costResource) == "string"
		and EggCostTheta.AllowedCostResources
		and EggCostTheta.AllowedCostResources[costResource] == true
		and costResource == "Trophies"
end

local function getCostAmount(costConfig)
	return math.max(0, tonumber(costConfig and costConfig.CostAmount) or 0)
end

local function getTrophies(progressState)
	return math.max(0, tonumber(progressState and progressState.Trophies) or 0)
end

local function normalizeRollCount(rollCount)
	local normalizedRollCount = math.floor(tonumber(rollCount) or 1)
	if not VALID_ROLL_COUNTS[normalizedRollCount] then
		return nil
	end

	return normalizedRollCount
end

local function createPetInstance(progressState, petTypeId)
	local petInstanceId = tostring(progressState.NextPetInstanceId)
	progressState.NextPetInstanceId += 1
	progressState.OwnedPets[petInstanceId] = {
		InstanceId = petInstanceId,
		PetTypeId = petTypeId,
	}

	return petInstanceId
end

function PetRollTransition.RequestRoll(player, eggId, rollCount)
	local costConfig = getCostConfig(eggId)
	local rewardConfig = getRewardConfig(eggId)
	if not costConfig or not rewardConfig or not isSupportedCostConfig(costConfig) then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local normalizedRollCount = normalizeRollCount(rollCount)
	if not normalizedRollCount then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local now = os.clock()
	local runtimeState = getRuntimeOrInit(player)
	if isRollOnCooldown(runtimeState, now) then
		return failure(TOO_FREQUENT_MESSAGE, player)
	end
	setPetRollTime(player, runtimeState, now)

	if not EggObservation.IsPlayerNearEgg(player, eggId) then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local costAmount = getCostAmount(costConfig)
	local totalCostAmount = costAmount * normalizedRollCount
	if getTrophies(progressState) < totalCostAmount then
		return failure(NOT_ENOUGH_TROPHIES_MESSAGE, player)
	end

	local rollResults = {}
	local hasRolledPet = false
	for _ = 1, normalizedRollCount do
		local petTypeId = PetRollSelector.ChoosePetTypeId(rewardConfig.Rewards)
		if not petTypeId then
			table.insert(rollResults, {
				EggId = eggId,
				IsMiss = true,
			})
			continue
		end

		local petInstanceId = createPetInstance(progressState, petTypeId)
		hasRolledPet = true
		table.insert(rollResults, {
			EggId = eggId,
			PetInstanceId = petInstanceId,
			PetTypeId = petTypeId,
		})
	end

	progressState.Trophies = getTrophies(progressState) - totalCostAmount

	PlayerProgressState.Set(player, progressState)

	local firstResult = rollResults[1] or {}
	local resultMessage = hasRolledPet and "Pet rolled" or "No pet rolled"
	return success(resultMessage, player, {
		EggId = eggId,
		RollCount = normalizedRollCount,
		RollResults = rollResults,
		PetInstanceId = firstResult.PetInstanceId,
		PetTypeId = firstResult.PetTypeId,
	})
end

return PetRollTransition
