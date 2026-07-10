local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PetSnapshotBuilder = require(script.Parent.Parent.Snapshots.PetSnapshotBuilder)

local PlayerVisualStateSync = {}

local ATTRIBUTES = SceneTheta.Attributes

local function encodeJson(value)
	local success, result = pcall(function()
		return HttpService:JSONEncode(value)
	end)

	return success and result or "[]"
end

local function getEquippedPetPayload(progressState)
	local payload = {}

	for _, petSnapshot in ipairs(PetSnapshotBuilder.GetEquippedPetSnapshots(progressState)) do
		if type(petSnapshot) == "table" and type(petSnapshot.PetTypeId) == "string" then
			table.insert(payload, {
				SlotIndex = petSnapshot.SlotIndex,
				InstanceId = petSnapshot.InstanceId,
				PetTypeId = petSnapshot.PetTypeId,
				ModelName = petSnapshot.ModelName,
				DisplayName = petSnapshot.DisplayName,
			})
		end
	end

	return payload
end

function PlayerVisualStateSync.Refresh(player)
	if not player then
		return
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		PlayerVisualStateSync.Clear(player)
		return
	end

	player:SetAttribute(ATTRIBUTES.CurrentBarbellId, tostring(progressState.CurrentBarbellId or ""))
	player:SetAttribute(ATTRIBUTES.EquippedPetsJson, encodeJson(getEquippedPetPayload(progressState)))
end

function PlayerVisualStateSync.SetTrainingActive(player, isTraining)
	if player then
		player:SetAttribute(ATTRIBUTES.IsTraining, isTraining == true)
	end
end

-- 发布自定义属性
-- 发布自定义属性
function PlayerVisualStateSync.SetPushBallActive(player, isPushingBall, ballInstanceId)
	if not player then
		return
	end

	local active = isPushingBall == true

	-- 设置是否正在推球
	player:SetAttribute(ATTRIBUTES.IsPushingBall, active)

	if active then
		-- 设置当前正在推动的球 ID
		player:SetAttribute(ATTRIBUTES.ActivePushBallInstanceId, ballInstanceId)
	else
		-- 停止推球时清空球 ID
		player:SetAttribute(ATTRIBUTES.ActivePushBallInstanceId, "")
	end
end

function PlayerVisualStateSync.PublishTrainingGain(player, strengthGain)
	if not player then
		return
	end

	local gainSerial = math.max(0, tonumber(player:GetAttribute(ATTRIBUTES.LastTrainingGainSerial)) or 0)
	player:SetAttribute(ATTRIBUTES.LastTrainingStrengthGain, math.max(0, tonumber(strengthGain) or 0))
	player:SetAttribute(ATTRIBUTES.LastTrainingGainSerial, gainSerial + 1)
end

function PlayerVisualStateSync.Clear(player)
	if not player then
		return
	end

	player:SetAttribute(ATTRIBUTES.CurrentBarbellId, "")
	player:SetAttribute(ATTRIBUTES.IsTraining, false)
	player:SetAttribute(ATTRIBUTES.IsPushingBall, false)
	player:SetAttribute(ATTRIBUTES.EquippedPetsJson, "[]")
	player:SetAttribute(ATTRIBUTES.LastTrainingGainSerial, 0)
	player:SetAttribute(ATTRIBUTES.LastTrainingStrengthGain, 0)
	player:SetAttribute(ATTRIBUTES.ActivePushBallInstanceId, "")
end

return PlayerVisualStateSync
