local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local SnapshotTransition = require(script.Parent.SnapshotTransition)

local PetTransition = {}

function PetTransition.TryEquip(player, petId)
	if type(petId) ~= "string" then
		return false, "Invalid pet id"
	end

	local petConfig = PetTheta[petId]
	if not petConfig then
		return false, "Pet does not exist"
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	local trophies = tonumber(progressState.Trophies) or 0
	local requiredTrophies = tonumber(petConfig.RequiredTrophies) or 0
	if trophies < requiredTrophies then
		return false, "Not enough trophies"
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.CurrentPetId = petId
	PlayerProgressState.Set(player, nextProgressState)

	return true, "Pet equipped"
end

function PetTransition.RequestEquip(player, petId)
	local success, message = PetTransition.TryEquip(player, petId)

	return {
		Success = success,
		Message = message,
		Data = SnapshotTransition.GetPlayerSnapshot(player),
	}
end

return PetTransition
