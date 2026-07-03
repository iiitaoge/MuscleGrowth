local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("EggTheta"))

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

local function getCostAmount(eggConfig)
	return math.max(0, tonumber(eggConfig and eggConfig.CostAmount) or 0)
end

local function getTrophies(progressState)
	return math.max(0, tonumber(progressState and progressState.Trophies) or 0)
end

function PetRollTransition.RequestRoll(player, eggId)
	if not EggObservation.IsValidEggId(eggId) then
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

	local eggConfig = EggTheta[eggId]
	if type(eggConfig) ~= "table" or eggConfig.CostResource ~= "Trophies" then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local costAmount = getCostAmount(eggConfig)
	if getTrophies(progressState) < costAmount then
		return failure(NOT_ENOUGH_TROPHIES_MESSAGE, player)
	end

	local petTypeId = PetRollSelector.ChoosePetTypeId(eggConfig)
	if not petTypeId then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local petInstanceId = tostring(progressState.NextPetInstanceId)
	progressState.NextPetInstanceId += 1
	progressState.Trophies = getTrophies(progressState) - costAmount
	progressState.OwnedPets[petInstanceId] = {
		InstanceId = petInstanceId,
		PetTypeId = petTypeId,
	}

	PlayerProgressState.Set(player, progressState)

	return success("Pet rolled", player, {
		EggId = eggId,
		PetInstanceId = petInstanceId,
		PetTypeId = petTypeId,
	})
end

return PetRollTransition
