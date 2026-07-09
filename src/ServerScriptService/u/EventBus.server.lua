local Players = game:GetService("Players")

local BarbellTransition = require(script.Parent.Parent.T.Transitions.BarbellEquipTransition)
local PlayerLifecycleTransition = require(script.Parent.Parent.T.Transitions.PlayerLifecycleTransition)
local PetDeleteTransition = require(script.Parent.Parent.T.Transitions.Pet.PetDeleteTransition)
local PetEquipTransition = require(script.Parent.Parent.T.Transitions.Pet.PetEquipTransition)
local PetRollTransition = require(script.Parent.Parent.T.Transitions.Pet.PetRollTransition)
local PushBallTransition = require(script.Parent.Parent.T.Transitions.PushBallTransition)
local RebirthTransition = require(script.Parent.Parent.T.Transitions.RebirthTransition)
local RemoteBinder = require(script.Parent.RemoteBinder)
local PlayerSnapshotBuilder = require(script.Parent.Parent.T.Snapshots.PlayerSnapshotBuilder)
local PushBallWorldSync = require(script.Parent.Parent.T.WorldSync.PushBallWorldSync)
local TrophyTransition = require(script.Parent.Parent.T.Transitions.TrophyTransition)
local TrainingTransition = require(script.Parent.Parent.T.Transitions.TrainingTransition)
local TravelTransition = require(script.Parent.Parent.T.Transitions.TravelTransition)
local EggWorldSync = require(script.Parent.Parent.T.WorldSync.EggWorldSync)

local REMOTE_EVENT_MIN_INTERVALS = {
	MoveStart = 0.05,
	MoveStop = 0.05,
	OnAutoArea = 0.25,
	LeaveAutoArea = 0.25,
	PushBallLateralInput = 0.05,
}

BarbellTransition.InitWorld()
TrophyTransition.InitWorld()
PushBallWorldSync.InitWorld(function(player, ballInstanceId)
	local result = PushBallTransition.RequestStart(player, ballInstanceId)
	if result.Success == false and result.Message and result.Message ~= "Push ball does not match current stage" then
		warn(result.Message)
	end
end)
EggWorldSync.InitWorld()

local function initPlayer(player)
	PlayerLifecycleTransition.Init(player)
end

RemoteBinder.BindEvents(REMOTE_EVENT_MIN_INTERVALS, {
	MoveStart = function(player)
		TrainingTransition.SetMoving(player, true)
	end,
	MoveStop = function(player)
		TrainingTransition.SetMoving(player, false)
	end,
	OnAutoArea = function(player, areaId)
		TrainingTransition.EnterAutoAreaClaim(player, areaId)
	end,
	LeaveAutoArea = function(player, areaId)
		TrainingTransition.LeaveAutoAreaClaim(player, areaId)
	end,
	PushBallLateralInput = function(player, lateralInput)
		PushBallTransition.SetLateralInput(player, lateralInput)
	end,
})

RemoteBinder.BindFunctions({
	GetData = PlayerSnapshotBuilder.GetPlayerSnapshot,
	RequestRebirth = function(player)
		local result = RebirthTransition.Request(player)
		TrainingTransition.RefreshGrowth(player)

		return result
	end,
	RequestBarbellEquip = BarbellTransition.RequestEquip,
	RequestPetEquip = PetEquipTransition.RequestEquip,
	RequestPetUnequip = PetEquipTransition.RequestUnequip,
	RequestPetRoll = PetRollTransition.RequestRoll,
	RequestPetDelete = PetDeleteTransition.RequestDelete,
	RequestTravelDestination = TravelTransition.Request,
	RequestStartPushBall = PushBallTransition.RequestStart,
	RequestStopPushBall = PushBallTransition.RequestStop,
})
RemoteBinder.GetOrCreate("PushBallPrepareTeleport")

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	RemoteBinder.RemovePlayer(player)
	PushBallTransition.RemovePlayer(player)
	TrophyTransition.RemovePlayer(player)
	PlayerLifecycleTransition.Remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end
