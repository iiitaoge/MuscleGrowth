local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("SceneTheta"))

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
	player:SetAttribute(ATTRIBUTES.EquippedPetsJson, "[]")
	player:SetAttribute(ATTRIBUTES.LastTrainingGainSerial, 0)
	player:SetAttribute(ATTRIBUTES.LastTrainingStrengthGain, 0)
end

return PlayerVisualStateSync
