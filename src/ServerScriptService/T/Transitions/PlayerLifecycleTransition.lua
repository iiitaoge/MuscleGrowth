local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))
local PlayerProgressInitialTheta = require(theta:WaitForChild("PlayerProgressInitialTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrainingTransition = require(script.Parent.TrainingTransition)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PlayerLifecycleTransition = {}

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

local function nonNegativeNumber(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(0, numberValue)
end

local function positiveInteger(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(1, math.floor(numberValue))
end

local function stringOrFallback(value, fallback)
	if type(value) == "string" then
		return value
	end

	return fallback
end

local function getMaxEquippedPets()
	return math.max(0, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 0))
end

local function getEmptyPetSlot()
	return PetSystemTheta.EmptyPetSlot == nil and 0 or PetSystemTheta.EmptyPetSlot
end

local function normalizePetSlots(value)
	local normalizedSlots = {}
	local emptySlot = getEmptyPetSlot()
	local emptySlotText = tostring(emptySlot)

	for slotIndex = 1, getMaxEquippedPets() do
		local slotValue = type(value) == "table" and value[slotIndex] or emptySlot
		if slotValue == nil or slotValue == emptySlot or tostring(slotValue) == emptySlotText then
			normalizedSlots[slotIndex] = emptySlot
		else
			normalizedSlots[slotIndex] = tostring(slotValue)
		end
	end

	return normalizedSlots
end

-- 扩展性很强，配置可以加，可以改，我只需要改这个函数即可正确初始化，粘合层
local function createInitialProgressState()
	return {
		Strength = nonNegativeNumber(PlayerProgressInitialTheta.Strength, 0),
		Trophies = nonNegativeNumber(PlayerProgressInitialTheta.Trophies, 0),
		Exp = nonNegativeNumber(PlayerProgressInitialTheta.Exp, 0),
		RebirthCount = nonNegativeNumber(PlayerProgressInitialTheta.RebirthCount, 0),
		CurrentBarbellId = stringOrFallback(PlayerProgressInitialTheta.CurrentBarbellId, "T1"),
		OwnedPets = cloneValue(PlayerProgressInitialTheta.OwnedPets) or {},
		EquippedPetInstanceIds = normalizePetSlots(PlayerProgressInitialTheta.EquippedPetInstanceIds),
		NextPetInstanceId = positiveInteger(PlayerProgressInitialTheta.NextPetInstanceId, 1),
	}
end

-- 初始化进度数据和训练运行时数据，进度数据被createInitialProgressState决定
function PlayerLifecycleTransition.Init(player)
	PlayerProgressState.Init(player, createInitialProgressState())
	TrainingTransition.InitRuntime(player)	--运行时的初始化
	PlayerVisualStateSync.Refresh(player)
	PlayerVisualStateSync.SetTrainingActive(player, false)
end

function PlayerLifecycleTransition.Remove(player)
	TrainingTransition.RemoveRuntime(player)
	PlayerProgressState.Remove(player)
	PlayerVisualStateSync.Clear(player)
end

return PlayerLifecycleTransition
