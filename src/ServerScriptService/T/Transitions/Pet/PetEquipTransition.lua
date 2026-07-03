local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)

local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Parent.Snapshots.PlayerSnapshotBuilder)

local PetEquipTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"

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

local function isPetInstanceEquipped(progressState, petInstanceId)
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	if type(equippedSlots) ~= "table" then
		return false
	end

	local normalizedInstanceId = tostring(petInstanceId)
	for _, slotValue in ipairs(equippedSlots) do
		if not PetSystemRules.IsEmptyPetSlot(slotValue) and tostring(slotValue) == normalizedInstanceId then
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
			and not PetSystemRules.IsEmptyPetSlot(slotValue)
			and tostring(slotValue) == normalizedInstanceId then
			return true
		end
	end

	return false
end

function PetEquipTransition.RequestEquip(player, petInstanceId, slotIndex)
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	if normalizedSlotIndex < 1 or normalizedSlotIndex > PetSystemRules.GetMaxEquippedPets() then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	if PetSystemRules.IsEmptyPetSlot(petInstanceId) then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local normalizedInstanceId = tostring(petInstanceId)
	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
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

function PetEquipTransition.RequestUnequip(player, slotIndex)
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	if normalizedSlotIndex < 1 or normalizedSlotIndex > PetSystemRules.GetMaxEquippedPets() then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return failure(INVALID_REQUEST_MESSAGE, player)
	end

	progressState.EquippedPetInstanceIds[normalizedSlotIndex] = PetSystemRules.GetEmptyPetSlot()
	PlayerProgressState.Set(player, progressState)

	return success("Pet unequipped", player, {
		SlotIndex = normalizedSlotIndex,
	})
end

function PetEquipTransition.IsPetInstanceEquipped(player, petInstanceId)
	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	return isPetInstanceEquipped(progressState, petInstanceId)
end

return PetEquipTransition
