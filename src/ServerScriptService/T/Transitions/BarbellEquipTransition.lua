local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BarbellTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Snapshots.PlayerSnapshotBuilder)
local BarbellWorldSync = require(script.Parent.Parent.WorldSync.BarbellWorldSync)

local BarbellEquipTransition = {}

function BarbellEquipTransition.TryEquip(player, barbellId)
	if not BarbellObservation.IsValidBarbellId(barbellId) then
		return false, "Invalid barbell id"
	end

	local barbellConfig = BarbellTheta[barbellId]
	if not barbellConfig then
		return false, "Barbell does not exist"
	end

	if not BarbellObservation.IsPlayerNearDisplay(player, barbellId) then
		return false, "Player is not near this barbell"
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	local trophies = tonumber(progressState.Trophies) or 0
	local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
	if trophies < requiredTrophies then
		return false, "Not enough trophies"
	end

	local visualEquipped, visualMessage = BarbellWorldSync.EquipVisual(player, barbellId)
	if not visualEquipped then
		return false, visualMessage
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.CurrentBarbellId = barbellId
	PlayerProgressState.Set(player, nextProgressState)

	return true, "Barbell equipped"
end

function BarbellEquipTransition.RequestEquip(player, barbellId)
	local success, message = BarbellEquipTransition.TryEquip(player, barbellId)

	return {
		Success = success,
		Message = message,
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}
end

function BarbellEquipTransition.RefreshDisplays()
	return BarbellWorldSync.RefreshDisplays(function(player, barbellId)
		BarbellEquipTransition.TryEquip(player, barbellId)
	end)
end

function BarbellEquipTransition.InitWorld()
	BarbellWorldSync.InitWorld(function(player, barbellId)
		BarbellEquipTransition.TryEquip(player, barbellId)
	end)
end

return BarbellEquipTransition
