local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local EggTheta = require(theta:WaitForChild("EggTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))
local PetTheta = require(theta:WaitForChild("PetTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.S.TrainingRuntimeState)
local EggObservation = require(script.Parent.Parent.y.EggObservation)
local SnapshotTransition = require(script.Parent.SnapshotTransition)

local PetTransition = {}

local random = Random.new()
local INVALID_REQUEST_MESSAGE = "Invalid request"
local TOO_FREQUENT_MESSAGE = "Too frequent"
local NOT_ENOUGH_TROPHIES_MESSAGE = "Not enough trophies"

local function getMaxEquippedPets()
	return math.max(0, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 0))
end

local function getEmptyPetSlot()
	return PetSystemTheta.EmptyPetSlot == nil and 0 or PetSystemTheta.EmptyPetSlot
end

local function isEmptyPetSlot(value)
	local emptySlot = getEmptyPetSlot()
	return value == nil or value == emptySlot or tostring(value) == tostring(emptySlot)
end

local function getRollCooldownSeconds()
	return math.max(0, tonumber(PetSystemTheta.RollCooldownSeconds) or 0)
end

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

local function failure(message, player)
	return {
		Success = false,
		Message = message,
		Data = SnapshotTransition.GetPlayerSnapshot(player),
	}
end

local function success(message, player, extraResult)
	local result = {
		Success = true,
		Message = message,
		Data = SnapshotTransition.GetPlayerSnapshot(player),
	}

	if type(extraResult) == "table" then
		for key, value in pairs(extraResult) do
			result[key] = value
		end
	end

	return result
end

local function normalizePetSlots(equippedSlots)
	local normalizedSlots = {}
	local emptySlot = getEmptyPetSlot()

	for slotIndex = 1, getMaxEquippedPets() do
		local slotValue = type(equippedSlots) == "table" and equippedSlots[slotIndex] or emptySlot
		if isEmptyPetSlot(slotValue) then
			normalizedSlots[slotIndex] = emptySlot
		else
			normalizedSlots[slotIndex] = tostring(slotValue)
		end
	end

	return normalizedSlots
end

local function normalizeOwnedPets(ownedPets)
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

local function getNextPetInstanceId(ownedPets, nextPetInstanceId)
	local nextInstanceNumber = math.max(1, math.floor(tonumber(nextPetInstanceId) or 1))

	for instanceId in pairs(ownedPets) do
		local instanceNumber = tonumber(instanceId)
		if instanceNumber and instanceNumber >= nextInstanceNumber then
			nextInstanceNumber = math.floor(instanceNumber) + 1
		end
	end

	return nextInstanceNumber
end

local function normalizeProgressState(progressState)
	if type(progressState) ~= "table" then
		return nil
	end

	local normalizedState = cloneValue(progressState)
	normalizedState.OwnedPets = normalizeOwnedPets(normalizedState.OwnedPets)
	normalizedState.EquippedPetInstanceIds = normalizePetSlots(normalizedState.EquippedPetInstanceIds)
	normalizedState.NextPetInstanceId = getNextPetInstanceId(
		normalizedState.OwnedPets,
		normalizedState.NextPetInstanceId
	)

	return normalizedState
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
	return now - runtimeState.LastPetRollTime < getRollCooldownSeconds()
end

local function getCostAmount(eggConfig)
	return math.max(0, tonumber(eggConfig and eggConfig.CostAmount) or 0)
end

local function getTrophies(progressState)
	return math.max(0, tonumber(progressState and progressState.Trophies) or 0)
end

local function choosePetTypeId(eggConfig)
	local petTypeIds = eggConfig and eggConfig.PetTypeIds
	if type(petTypeIds) ~= "table" then
		return nil
	end

	local totalWeight = 0
	local weightedPetTypeIds = {}

	for _, petTypeId in ipairs(petTypeIds) do
		local petConfig = type(petTypeId) == "string" and PetTheta[petTypeId] or nil
		local rollWeight = math.max(0, tonumber(petConfig and petConfig.RollWeight) or 0)
		if petConfig and rollWeight > 0 then
			totalWeight += rollWeight
			table.insert(weightedPetTypeIds, {
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
	for _, weightedPetType in ipairs(weightedPetTypeIds) do
		cursor += weightedPetType.RollWeight
		if roll <= cursor then
			return weightedPetType.PetTypeId
		end
	end

	return weightedPetTypeIds[#weightedPetTypeIds].PetTypeId
end

local function isPetInstanceEquipped(progressState, petInstanceId)
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	if type(equippedSlots) ~= "table" then
		return false
	end

	local normalizedInstanceId = tostring(petInstanceId)
	for _, slotValue in ipairs(equippedSlots) do
		if not isEmptyPetSlot(slotValue) and tostring(slotValue) == normalizedInstanceId then
			return true
		end
	end

	return false
end

local function isPetInstanceEquippedOutsideSlot(progressState, petInstanceId, slotIndex)
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	if type(equippedSlots) ~= "table" then
		return false
	end

	local normalizedInstanceId = tostring(petInstanceId)
	for currentSlotIndex, slotValue in ipairs(equippedSlots) do
		if currentSlotIndex ~= slotIndex
			and not isEmptyPetSlot(slotValue)
			and tostring(slotValue) == normalizedInstanceId then
			return true
		end
	end

	return false
end

function PetTransition.RequestRoll(player, eggId)
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

	local progressState = normalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local costAmount = getCostAmount(eggConfig)
	if getTrophies(progressState) < costAmount then
		return failure(NOT_ENOUGH_TROPHIES_MESSAGE, player)
	end

	local petTypeId = choosePetTypeId(eggConfig)
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

function PetTransition.RequestEquip(player, petInstanceId, slotIndex)
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	if normalizedSlotIndex < 1 or normalizedSlotIndex > getMaxEquippedPets() then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	if isEmptyPetSlot(petInstanceId) then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local normalizedInstanceId = tostring(petInstanceId)
	local progressState = normalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	if not progressState.OwnedPets[normalizedInstanceId] then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	if isPetInstanceEquippedOutsideSlot(progressState, normalizedInstanceId, normalizedSlotIndex) then
		return failure("Pet already equipped", player)
	end

	progressState.EquippedPetInstanceIds[normalizedSlotIndex] = normalizedInstanceId
	PlayerProgressState.Set(player, progressState)

	return success("Pet equipped", player, {
		PetInstanceId = normalizedInstanceId,
		SlotIndex = normalizedSlotIndex,
	})
end

function PetTransition.RequestUnequip(player, slotIndex)
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	if normalizedSlotIndex < 1 or normalizedSlotIndex > getMaxEquippedPets() then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local progressState = normalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	progressState.EquippedPetInstanceIds[normalizedSlotIndex] = getEmptyPetSlot()
	PlayerProgressState.Set(player, progressState)

	return success("Pet unequipped", player, {
		SlotIndex = normalizedSlotIndex,
	})
end

function PetTransition.IsPetInstanceEquipped(player, petInstanceId)
	local progressState = normalizeProgressState(PlayerProgressState.Get(player))
	return isPetInstanceEquipped(progressState, petInstanceId)
end

return PetTransition
