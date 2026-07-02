local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local getData = ReplicatedStorage:WaitForChild("GetData")
local moveStart = ReplicatedStorage:WaitForChild("MoveStart")
local moveStop = ReplicatedStorage:WaitForChild("MoveStop")
local onAutoArea = ReplicatedStorage:WaitForChild("OnAutoArea")
local leaveAutoArea = ReplicatedStorage:WaitForChild("LeaveAutoArea")
local requestRebirth = ReplicatedStorage:WaitForChild("RequestRebirth")

local AutoAreaConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("AutoAreaConfig"))

local latestData = nil
local isMoving = false
local touchingAreas = {}
local trainAreas = Workspace:WaitForChild("World1"):WaitForChild("TrainAreas")

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

for areaId, areaConfig in pairs(AutoAreaConfig) do
	if type(areaId) == "string" and type(areaConfig) == "table" then
		bindAutoArea(areaId)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DebugStatsGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 240, 0, 90)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.5
label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "Waiting for data..."
label.Parent = gui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.new(0, 240, 0, 36)
rebirthButton.Position = UDim2.new(0, 10, 0, 110)
rebirthButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Text = "Rebirth"
rebirthButton.Parent = gui

local function refreshUi(data)
	latestData = data

	if not data then
		label.Text = "No data"
		rebirthButton.Active = false
		rebirthButton.AutoButtonColor = false
		rebirthButton.Text = "Rebirth unavailable"
		return
	end

	label.Text = string.format(
		"Strength: %d\nExp: %d / %d\nLevel: %d / %d\nRebirth: %d",
		data.Strength,
		data.Exp,
		data.MaxExp,
		data.Level,
		data.MaxLevel,
		data.RebirthCount
	)

	rebirthButton.Active = data.CanRebirth
	rebirthButton.AutoButtonColor = data.CanRebirth
	rebirthButton.Text = if data.CanRebirth then "Rebirth" else "Reach max level first"
end

rebirthButton.Activated:Connect(function()
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
