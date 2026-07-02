local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local GameManager = require(script.Parent.GameManager)

local function getOrCreateRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)

	if remote and not remote:IsA(className) then
		remote:Destroy()
		remote = nil
	end

	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

local moveStart = getOrCreateRemote("MoveStart", "RemoteEvent")
local moveStop = getOrCreateRemote("MoveStop", "RemoteEvent")
local onAutoArea = getOrCreateRemote("OnAutoArea", "RemoteEvent")
local leaveAutoArea = getOrCreateRemote("LeaveAutoArea", "RemoteEvent")
local getData = getOrCreateRemote("GetData", "RemoteFunction")
local rebirthEvent = getOrCreateRemote("ReBirth", "RemoteEvent")
local requestRebirth = getOrCreateRemote("RequestRebirth", "RemoteFunction")

moveStart.OnServerEvent:Connect(function(player)
	GameManager.setMoving(player, true)
end)

moveStop.OnServerEvent:Connect(function(player)
	GameManager.setMoving(player, false)
end)

onAutoArea.OnServerEvent:Connect(function(player, areaId)
	print("onAutoArea.OnServerEvent", player, areaId)
	GameManager.enterAutoArea(player, areaId)
end)

leaveAutoArea.OnServerEvent:Connect(function(player, areaId)
	print("leaveAutoArea.OnServerEvent", player, areaId)
	GameManager.leaveAutoArea(player, areaId)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	PlayerData.doRebirth(player)
	GameManager.refreshGrowth(player)
end)

getData.OnServerInvoke = function(player)
	return PlayerData.getSnapshot(player)
end

requestRebirth.OnServerInvoke = function(player)
	local success, message = PlayerData.doRebirth(player)
	GameManager.refreshGrowth(player)

	return {
		Success = success,
		Message = message,
		Data = PlayerData.getSnapshot(player),
	}
end

Players.PlayerAdded:Connect(function(player)
	PlayerData.init(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameManager.removePlayer(player)
	PlayerData.remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	PlayerData.init(player)
end
