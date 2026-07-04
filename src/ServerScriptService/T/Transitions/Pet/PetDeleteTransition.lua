local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)

local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Parent.Snapshots.PlayerSnapshotBuilder)
local PlayerVisualStateSync = require(script.Parent.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PetDeleteTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"
local MAX_DELETE_COUNT = 50

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

local function appendInstanceId(instanceIds, seenInstanceIds, value)
	if PetSystemRules.IsEmptyPetSlot(value) then
		return
	end

	local instanceId = tostring(value)
	if seenInstanceIds[instanceId] then
		return
	end

	seenInstanceIds[instanceId] = true
	table.insert(instanceIds, instanceId)
end

local function normalizeInstanceIds(petInstanceIds)
	local instanceIds = {}
	local seenInstanceIds = {}

	if type(petInstanceIds) == "table" then
		for _, value in ipairs(petInstanceIds) do
			appendInstanceId(instanceIds, seenInstanceIds, value)
			if #instanceIds >= MAX_DELETE_COUNT then
				return instanceIds
			end
		end

		if #instanceIds == 0 then
			for _, value in pairs(petInstanceIds) do
				appendInstanceId(instanceIds, seenInstanceIds, value)
				if #instanceIds >= MAX_DELETE_COUNT then
					return instanceIds
				end
			end
		end
	else
		appendInstanceId(instanceIds, seenInstanceIds, petInstanceIds)
	end

	return instanceIds
end

local function clearEquippedDeletedPets(progressState, deletedInstanceIds)
	for slotIndex, slotValue in ipairs(progressState.EquippedPetInstanceIds) do
		local slotInstanceId = tostring(slotValue)
		if deletedInstanceIds[slotInstanceId] then
			progressState.EquippedPetInstanceIds[slotIndex] = PetSystemRules.GetEmptyPetSlot()
		end
	end
end

function PetDeleteTransition.RequestDelete(player, petInstanceIds)
	local normalizedInstanceIds = normalizeInstanceIds(petInstanceIds)
	if #normalizedInstanceIds <= 0 then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	for _, instanceId in ipairs(normalizedInstanceIds) do
		if not progressState.OwnedPets[instanceId] then
			return failure(INVALID_REQUEST_MESSAGE, player)
		end
	end

	local deletedInstanceIds = {}
	for _, instanceId in ipairs(normalizedInstanceIds) do
		progressState.OwnedPets[instanceId] = nil
		deletedInstanceIds[instanceId] = true
	end
	clearEquippedDeletedPets(progressState, deletedInstanceIds)

	PlayerProgressState.Set(player, progressState)
	PlayerVisualStateSync.Refresh(player)

	return success("Pet deleted", player, {
		DeletedPetInstanceIds = normalizedInstanceIds,
	})
end

return PetDeleteTransition
