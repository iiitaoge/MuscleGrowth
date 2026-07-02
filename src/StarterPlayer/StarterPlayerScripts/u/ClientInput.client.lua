local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local theta = ReplicatedStorage:WaitForChild("theta")

local AutoAreaTheta = require(theta:WaitForChild("AutoAreaTheta"))
local RemoteTheta = require(theta:WaitForChild("RemoteTheta"))
local DebugStatsRender = require(script.Parent.Parent.T.DebugStatsRender)

local function waitForRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	return ReplicatedStorage:WaitForChild(remoteSpec.Name)
end

local getData = waitForRemote("GetData")
local moveStart = waitForRemote("MoveStart")
local moveStop = waitForRemote("MoveStop")
local onAutoArea = waitForRemote("OnAutoArea")
local leaveAutoArea = waitForRemote("LeaveAutoArea")
local requestRebirth = waitForRemote("RequestRebirth")

local view = DebugStatsRender.Init(player)
local latestData = nil
local isMoving = false
local touchingAreas = {}
local trainAreas = Workspace:WaitForChild("World1"):WaitForChild("TrainAreas")

local function refreshUi(data)
	latestData = data
	view.Refresh(data)
end

local function setMoving(nextIsMoving)
	if isMoving == nextIsMoving then
		return
	end

	isMoving = nextIsMoving
	if isMoving then
		moveStart:FireServer()
	else
		moveStop:FireServer()
	end
end

local function resetAutoAreas()
	for areaId in pairs(touchingAreas) do
		touchingAreas[areaId] = nil
		leaveAutoArea:FireServer(areaId)
	end
end

local function bindMovingDetection(character)
	setMoving(false)
	resetAutoAreas()

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Running:Connect(function(speed)
		setMoving(speed > 0.1)
	end)

	humanoid.Died:Connect(function()
		setMoving(false)
		resetAutoAreas()
	end)
end

local function isLocalRootPart(hit)
	local character = player.Character
	return character ~= nil and hit == character:FindFirstChild("HumanoidRootPart")
end

local function bindAutoArea(areaId)
	local area = trainAreas:WaitForChild(areaId, 10)
	if not area then
		warn("Missing auto area: " .. areaId)
		return
	end

	local touch = area:WaitForChild("Touch", 10)
	if not touch or not touch:IsA("BasePart") then
		warn("Missing auto area Touch part: " .. areaId)
		return
	end

	touch.Touched:Connect(function(hit)
		if not isLocalRootPart(hit) or touchingAreas[areaId] then
			return
		end

		touchingAreas[areaId] = true
		onAutoArea:FireServer(areaId)
	end)

	touch.TouchEnded:Connect(function(hit)
		if not isLocalRootPart(hit) or not touchingAreas[areaId] then
			return
		end

		touchingAreas[areaId] = nil
		leaveAutoArea:FireServer(areaId)
	end)
end

if player.Character then
	bindMovingDetection(player.Character)
end

player.CharacterAdded:Connect(bindMovingDetection)

for areaId, areaConfig in pairs(AutoAreaTheta) do
	if type(areaId) == "string" and type(areaConfig) == "table" then
		bindAutoArea(areaId)
	end
end

view.GetRebirthButton().Activated:Connect(function()
	if not latestData or not latestData.CanRebirth then
		return
	end

	local result = requestRebirth:InvokeServer()
	if result and result.Data then
		refreshUi(result.Data)
	end
end)

while task.wait(1) do
	refreshUi(getData:InvokeServer())
end
