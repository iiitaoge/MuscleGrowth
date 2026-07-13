local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)

local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local TransitionResult = require(script.Parent.Parent.TransitionResult)
local PlayerVisualStateSync = require(script.Parent.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PetDeleteTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"

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
	local maxDeleteCount = PetSystemRules.GetMaxDeletePetsPerRequest()

	if type(petInstanceIds) == "table" then
		for _, value in ipairs(petInstanceIds) do
			appendInstanceId(instanceIds, seenInstanceIds, value)
			if #instanceIds >= maxDeleteCount then
				return instanceIds
			end
		end

		if #instanceIds == 0 then
			for _, value in pairs(petInstanceIds) do
				appendInstanceId(instanceIds, seenInstanceIds, value)
				if #instanceIds >= maxDeleteCount then
					return instanceIds
				end
			end
		end
	else
		appendInstanceId(instanceIds, seenInstanceIds, petInstanceIds)
	end

	return instanceIds
end

local function buildEquippedInstanceIdSet(progressState)
	local equippedInstanceIds = {}
	for _, slotValue in ipairs(progressState.EquippedPetInstanceIds) do
		if not PetSystemRules.IsEmptyPetSlot(slotValue) then
			equippedInstanceIds[tostring(slotValue)] = true
		end
	end

	return equippedInstanceIds
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

	-- 已装备宠物必须先卸下；整批拒绝，避免部分删除。
	local equippedInstanceIds = buildEquippedInstanceIdSet(progressState)
	for _, instanceId in ipairs(normalizedInstanceIds) do
		if equippedInstanceIds[instanceId] then
			return TransitionResult.FailureWithSnapshot(player, "Unequip pets before deleting")
		end
	end

	-- 需要删除的ID标为true
	for _, instanceId in ipairs(normalizedInstanceIds) do
		progressState.OwnedPets[instanceId] = nil
	end

	PlayerProgressState.Set(player, progressState)
	PlayerVisualStateSync.Refresh(player)

	return TransitionResult.SuccessWithSnapshot(player, "Pet deleted", {
		DeletedPetInstanceIds = normalizedInstanceIds,
	})
end

return PetDeleteTransition
