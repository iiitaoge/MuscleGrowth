local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("RemoteTheta"))

local PlayerLifecycleTransition = require(script.Parent.Parent.T.PlayerLifecycleTransition)
local RebirthTransition = require(script.Parent.Parent.T.RebirthTransition)
local SnapshotTransition = require(script.Parent.Parent.T.SnapshotTransition)
local TrainingTransition = require(script.Parent.Parent.T.TrainingTransition)

local function getOrCreateRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	local remote = ReplicatedStorage:FindFirstChild(remoteSpec.Name)

	if remote and not remote:IsA(remoteSpec.ClassName) then
		remote:Destroy()
		remote = nil
	end

	if not remote then
		remote = Instance.new(remoteSpec.ClassName)
		remote.Name = remoteSpec.Name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

local moveStart = getOrCreateRemote("MoveStart")
local moveStop = getOrCreateRemote("MoveStop")
local onAutoArea = getOrCreateRemote("OnAutoArea")
local leaveAutoArea = getOrCreateRemote("LeaveAutoArea")
local getData = getOrCreateRemote("GetData")
local rebirthEvent = getOrCreateRemote("ReBirth")
local requestRebirth = getOrCreateRemote("RequestRebirth")

local function initPlayer(player)
	PlayerLifecycleTransition.Init(player)
end

moveStart.OnServerEvent:Connect(function(player)
	TrainingTransition.SetMoving(player, true)
end)

moveStop.OnServerEvent:Connect(function(player)
	TrainingTransition.SetMoving(player, false)
end)

onAutoArea.OnServerEvent:Connect(function(player, areaId)
	TrainingTransition.EnterAutoAreaClaim(player, areaId)
end)

leaveAutoArea.OnServerEvent:Connect(function(player, areaId)
	TrainingTransition.LeaveAutoAreaClaim(player, areaId)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	RebirthTransition.TryApply(player)
	TrainingTransition.RefreshGrowth(player)
end)

getData.OnServerInvoke = function(player)
	return SnapshotTransition.GetPlayerSnapshot(player)
end

requestRebirth.OnServerInvoke = function(player)
	local result = RebirthTransition.Request(player)
	TrainingTransition.RefreshGrowth(player)

	return result
end

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	PlayerLifecycleTransition.Remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end
