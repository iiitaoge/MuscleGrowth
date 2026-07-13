local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta"))

local AutoWinTransition = require(script.Parent.Parent.T.Transitions.AutoWinTransition)
local BarbellTransition = require(script.Parent.Parent.T.Transitions.BarbellEquipTransition)
local CharacterBodyVisualTransition = require(script.Parent.Parent.T.Transitions.CharacterBodyVisualTransition)
local PlayerLifecycleTransition = require(script.Parent.Parent.T.Transitions.PlayerLifecycleTransition)
local PlayerPersistenceTransition = require(script.Parent.Parent.T.Transitions.PlayerPersistenceTransition)
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
local TransitionResult = require(script.Parent.Parent.T.Transitions.TransitionResult)
local EggWorldSync = require(script.Parent.Parent.T.WorldSync.EggWorldSync)

local REMOTE_EVENT_MIN_INTERVALS = {
	MoveStart = 0.05,
	MoveStop = 0.05,
	OnAutoArea = 0.25,
	LeaveAutoArea = 0.25,
	PushBallLateralInput = 0.05,
}

local REBIRTH_DESTINATION_ID = "World1"
local DATA_LOADED_ATTRIBUTE = SceneTheta.Attributes.DataLoaded

local initializingPlayers = setmetatable({}, { __mode = "k" })
local removingPlayers = setmetatable({}, { __mode = "k" })

BarbellTransition.InitWorld()
TrophyTransition.InitWorld()
PushBallWorldSync.InitWorld(function(player, ballInstanceId)
	if AutoWinTransition.IsEnabled(player) then
		return
	end

	local result = PushBallTransition.RequestStart(player, ballInstanceId)
	if result.Success == false and result.Message and result.Message ~= "Push ball does not match current stage" then
		warn(result.Message)
	end
end)
EggWorldSync.InitWorld()

local function initPlayer(player)
	if initializingPlayers[player] or removingPlayers[player] then
		return
	end

	initializingPlayers[player] = true
	player:SetAttribute(DATA_LOADED_ATTRIBUTE, false)

	local loadSucceeded, stateOrReason = PlayerPersistenceTransition.LoadPlayer(player)
	if not loadSucceeded then
		initializingPlayers[player] = nil
		if player.Parent == Players then
			if stateOrReason == "SessionLocked" then
				player:Kick("玩家数据仍在另一台服务器中使用，请稍后重试。")
			else
				warn(("[PlayerPersistence] failed to load player %s: %s"):format(
					player.Name,
					tostring(stateOrReason)
				))
				player:Kick("玩家数据加载失败，请稍后重试。")
			end
		end
		return
	end

	PlayerLifecycleTransition.Init(player, stateOrReason)
	if player.Parent ~= Players then
		TrainingTransition.RemoveRuntime(player)
		PlayerPersistenceTransition.SavePlayer(player, true)
		PlayerLifecycleTransition.Remove(player)
		initializingPlayers[player] = nil
		return
	end

	CharacterBodyVisualTransition.InitPlayer(player)
	AutoWinTransition.InitPlayer(player)
	player:SetAttribute(DATA_LOADED_ATTRIBUTE, true)
	initializingPlayers[player] = nil
end

local function removePlayer(player)
	if removingPlayers[player] then
		return
	end

	removingPlayers[player] = true
	player:SetAttribute(DATA_LOADED_ATTRIBUTE, false)

	RemoteBinder.RemovePlayer(player)
	AutoWinTransition.RemovePlayer(player)
	PushBallTransition.RemovePlayer(player)
	TrophyTransition.RemovePlayer(player)
	CharacterBodyVisualTransition.RemovePlayer(player)
	TrainingTransition.RemoveRuntime(player)

	local saveSucceeded, saveReason = PlayerPersistenceTransition.SavePlayer(player, true)
	if not saveSucceeded and saveReason ~= "NotLoaded" then
		warn(("[PlayerPersistence] failed to save departing player %s: %s"):format(
			player.Name,
			tostring(saveReason)
		))
	end

	PlayerLifecycleTransition.Remove(player)
	initializingPlayers[player] = nil
end

PlayerPersistenceTransition.StartAutosave()

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
		if result.Success then
			AutoWinTransition.Stop(player)
			PushBallTransition.RequestStop(player)
			TrainingTransition.ResetActivity(player)

			local travelResult = TravelTransition.Request(player, REBIRTH_DESTINATION_ID)
			if travelResult.Success == false and travelResult.Message then
				warn(travelResult.Message)
			end
		else
			TrainingTransition.RefreshGrowth(player)
		end

		return result
	end,
	RequestBarbellEquip = BarbellTransition.RequestEquip,
	RequestPetEquip = PetEquipTransition.RequestEquip,
	RequestPetUnequip = PetEquipTransition.RequestUnequip,
	RequestPetRoll = PetRollTransition.RequestRoll,
	RequestPetDelete = PetDeleteTransition.RequestDelete,
	RequestTravelDestination = function(player, destinationId)
		local result = TravelTransition.Request(player, destinationId)
		if result.Success then
			AutoWinTransition.Stop(player)
		end
		return result
	end,
	RequestStartPushBall = function(player, ballInstanceId)
		if AutoWinTransition.IsEnabled(player) then
			return TransitionResult.New(false, "Auto Win is active")
		end
		return PushBallTransition.RequestStart(player, ballInstanceId)
	end,
	RequestStopPushBall = function(player)
		AutoWinTransition.Stop(player)
		return PushBallTransition.RequestStop(player)
	end,
	RequestSetAutoWin = AutoWinTransition.RequestSet,
})

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(removePlayer)

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute(DATA_LOADED_ATTRIBUTE, false)
		AutoWinTransition.RemovePlayer(player)
		PushBallTransition.RemovePlayer(player)
		TrainingTransition.RemoveRuntime(player)
	end

	PlayerPersistenceTransition.Shutdown()
end)
