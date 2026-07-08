local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)

local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local TransitionResult = require(script.Parent.Parent.TransitionResult)
local PlayerVisualStateSync = require(script.Parent.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PetDeleteTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"
local MAX_DELETE_COUNT = 50

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

-- 服务侧删除宠物
function PetDeleteTransition.RequestDelete(player, petInstanceIds)
	-- 先标准化传过来的宠物ID数据
	local normalizedInstanceIds = normalizeInstanceIds(petInstanceIds)
	if #normalizedInstanceIds <= 0 then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	-- 在获得标准化的玩家进度数据
	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	-- 判断需要删除的ID是否属于该玩家
	for _, instanceId in ipairs(normalizedInstanceIds) do
		if not progressState.OwnedPets[instanceId] then
			return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
		end
	end

	-- 需要删除的ID标为true
	local deletedInstanceIds = {}
	for _, instanceId in ipairs(normalizedInstanceIds) do
		progressState.OwnedPets[instanceId] = nil
		deletedInstanceIds[instanceId] = true
	end
	clearEquippedDeletedPets(progressState, deletedInstanceIds)

	PlayerProgressState.Set(player, progressState)
	PlayerVisualStateSync.Refresh(player)

	return TransitionResult.SuccessWithSnapshot(player, "Pet deleted", {
		DeletedPetInstanceIds = normalizedInstanceIds,
	})
end

return PetDeleteTransition
