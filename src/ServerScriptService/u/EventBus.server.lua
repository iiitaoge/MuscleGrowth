local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("RemoteTheta"))

local BarbellTransition = require(script.Parent.Parent.T.Transitions.BarbellEquipTransition)
local PlayerLifecycleTransition = require(script.Parent.Parent.T.Transitions.PlayerLifecycleTransition)
local PetTransition = require(script.Parent.Parent.T.Transitions.Pet.PetTransition)
local RebirthTransition = require(script.Parent.Parent.T.Transitions.RebirthTransition)
local RemoteRateLimiter = require(script.Parent.RemoteRateLimiter)
local PlayerSnapshotBuilder = require(script.Parent.Parent.T.Snapshots.PlayerSnapshotBuilder)
local TrophyTransition = require(script.Parent.Parent.T.Transitions.TrophyTransition)
local TrainingTransition = require(script.Parent.Parent.T.Transitions.TrainingTransition)

local REMOTE_EVENT_MIN_INTERVALS = {
	MoveStart = 0.05,
	MoveStop = 0.05,
	OnAutoArea = 0.25,
	LeaveAutoArea = 0.25,
}

-- 模版绑定
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

local function isRemoteEventAllowed(player, remoteId)
	return RemoteRateLimiter.Allow(player, remoteId, REMOTE_EVENT_MIN_INTERVALS[remoteId])
end

-- 绑定事件
local moveStart = getOrCreateRemote("MoveStart")
local moveStop = getOrCreateRemote("MoveStop")
local onAutoArea = getOrCreateRemote("OnAutoArea")
local leaveAutoArea = getOrCreateRemote("LeaveAutoArea")
local getData = getOrCreateRemote("GetData")
local requestRebirth = getOrCreateRemote("RequestRebirth")
-- 请求装备杠铃
local requestBarbellEquip = getOrCreateRemote("RequestBarbellEquip")

local requestPetEquip = getOrCreateRemote("RequestPetEquip")
local requestPetUnequip = getOrCreateRemote("RequestPetUnequip")
local requestPetRoll = getOrCreateRemote("RequestPetRoll")

BarbellTransition.InitWorld()
TrophyTransition.InitWorld()

local function initPlayer(player)
	PlayerLifecycleTransition.Init(player)
end

moveStart.OnServerEvent:Connect(function(player)
	if not isRemoteEventAllowed(player, "MoveStart") then
		return
	end

	TrainingTransition.SetMoving(player, true)
end)

moveStop.OnServerEvent:Connect(function(player)
	if not isRemoteEventAllowed(player, "MoveStop") then
		return
	end

	TrainingTransition.SetMoving(player, false)
end)

onAutoArea.OnServerEvent:Connect(function(player, areaId)
	if not isRemoteEventAllowed(player, "OnAutoArea") then
		return
	end

	TrainingTransition.EnterAutoAreaClaim(player, areaId)
end)

leaveAutoArea.OnServerEvent:Connect(function(player, areaId)
	if not isRemoteEventAllowed(player, "LeaveAutoArea") then
		return
	end

	TrainingTransition.LeaveAutoAreaClaim(player, areaId)
end)


-- Invoke 是客户端等待返回值的东西
-- 处理获取玩家数据请求，返回当前玩家数据快照
getData.OnServerInvoke = function(player)
	return PlayerSnapshotBuilder.GetPlayerSnapshot(player)
end

-- 处理重生请求
requestRebirth.OnServerInvoke = function(player)
	local result = RebirthTransition.Request(player)
	TrainingTransition.RefreshGrowth(player)

	return result
end

-- 处理装备杠铃请求
requestBarbellEquip.OnServerInvoke = function(player, barbellId)
	return BarbellTransition.RequestEquip(player, barbellId)
end

-- 处理玩家装备宠物的请求
requestPetEquip.OnServerInvoke = function(player, petInstanceId, slotIndex)
	return PetTransition.RequestEquip(player, petInstanceId, slotIndex)
end

requestPetUnequip.OnServerInvoke = function(player, slotIndex)
	return PetTransition.RequestUnequip(player, slotIndex)
end

requestPetRoll.OnServerInvoke = function(player, eggId)
	return PetTransition.RequestRoll(player, eggId)
end

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	RemoteRateLimiter.Remove(player)
	TrophyTransition.RemovePlayer(player)
	PlayerLifecycleTransition.Remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end
