local PlayerProgressState = require(script.Parent.Parent.Parent.Parent.S.PlayerProgressState)

local PetStateNormalizer = require(script.Parent.Parent.Parent.Rules.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Parent.Parent.Rules.Pet.PetSystemRules)
local TransitionResult = require(script.Parent.Parent.TransitionResult)
local PlayerVisualStateSync = require(script.Parent.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PetEquipTransition = {}

local INVALID_REQUEST_MESSAGE = "Invalid request"

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

--
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

-- 处理宠物装备请求 slotIndex是装备槽的意思
-- 拒绝也返回snapshot的价值在于真实数据可以帮助客户端刷新UI等
function PetEquipTransition.RequestEquip(player, petInstanceId, slotIndex)
	-- 意思是把客户端传来的槽位转成整数。比如 "2" 会变成 2，2.8 会变成 2，乱传字符串会变成 0。
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	-- 判断槽位是否合法
	if normalizedSlotIndex < 1 or normalizedSlotIndex > PetSystemRules.GetMaxEquippedPets() then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	-- 检查宠物实例ID是否为空槽标记
	if PetSystemRules.IsEmptyPetSlot(petInstanceId) then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	-- 获取规格化宠物实例
	local normalizedInstanceId = tostring(petInstanceId)
	-- 获规格化宠物数据之后的玩家数据
	local nextprogressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not nextprogressState then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end


	-- 检测玩家是否拥有宠物实例
	if not nextprogressState.OwnedPets[normalizedInstanceId] then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	-- 检测同一只宠物是否装在别的槽位
	if isPetInstanceEquippedOutsideSlot(nextprogressState, normalizedInstanceId, normalizedSlotIndex) then
		return TransitionResult.FailureWithSnapshot(player, "Pet already equipped")
	end

	--设置克隆数据状态，然后写回真正的数据
	nextprogressState.EquippedPetInstanceIds[normalizedSlotIndex] = normalizedInstanceId
	PlayerProgressState.Set(player, nextprogressState)
	PlayerVisualStateSync.Refresh(player)

	return TransitionResult.SuccessWithSnapshot(player, "Pet equipped", {
		PetInstanceId = normalizedInstanceId,
		SlotIndex = normalizedSlotIndex,
	})
end

function PetEquipTransition.RequestUnequip(player, slotIndex)
	local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
	if normalizedSlotIndex < 1 or normalizedSlotIndex > PetSystemRules.GetMaxEquippedPets() then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	if not progressState then
		return TransitionResult.FailureWithSnapshot(player, INVALID_REQUEST_MESSAGE)
	end

	progressState.EquippedPetInstanceIds[normalizedSlotIndex] = PetSystemRules.GetEmptyPetSlot()
	PlayerProgressState.Set(player, progressState)
	PlayerVisualStateSync.Refresh(player)

	return TransitionResult.SuccessWithSnapshot(player, "Pet unequipped", {
		SlotIndex = normalizedSlotIndex,
	})
end

function PetEquipTransition.IsPetInstanceEquipped(player, petInstanceId)
	local progressState = PetStateNormalizer.NormalizeProgressState(PlayerProgressState.Get(player))
	return isPetInstanceEquipped(progressState, petInstanceId)
end

return PetEquipTransition
