local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local theta = ReplicatedStorage:WaitForChild("theta")

local AutoAreaTheta = require(theta:WaitForChild("AutoAreaTheta"))
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))
local RemoteTheta = require(theta:WaitForChild("RemoteTheta"))
local HUDRender = require(script.Parent.Parent.T.HUDRender)

local BARBELL_EQUIP_DISTANCE = 18
local WORLD_ROOT_NAME = "World1"

-- 这个函数用于等待并获取指定的远程事件或远程函数
local function waitForRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	return ReplicatedStorage:WaitForChild(remoteSpec.Name)
end

-- 获取远程事件和远程函数的引用
local getData = waitForRemote("GetData")
local moveStart = waitForRemote("MoveStart")
local moveStop = waitForRemote("MoveStop")
local onAutoArea = waitForRemote("OnAutoArea")
local leaveAutoArea = waitForRemote("LeaveAutoArea")
local requestRebirth = waitForRemote("RequestRebirth")
local requestBarbellEquip = waitForRemote("RequestBarbellEquip")



local view = HUDRender.Init(player)
local latestData = nil
local isMoving = false
local isRequestingBarbellEquip = false
local touchingAreas = {}
local trainAreas = Workspace:WaitForChild("World1"):WaitForChild("TrainAreas")

local function getWorldChild(childName)
	local worldRoot = Workspace:WaitForChild(WORLD_ROOT_NAME)

	return (worldRoot and worldRoot:WaitForChild(childName))
		or Workspace:WaitForChild(childName)
		or Workspace:WaitForChild(childName, true)
end

local function getInstancePosition(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot().Position
	end

	if instance:IsA("BasePart") then
		return instance.Position
	end

	local firstPart = instance:WaitForChildWhichIsA("BasePart", true)
	return firstPart and firstPart.Position or nil
end

local function getNearestBarbellId()
	local character = player.Character
	local root = character and character:WaitForChild("HumanoidRootPart")
	local gameDumbbell = getWorldChild("GameDumbbell")

	if not root or not gameDumbbell then
		return nil
	end

	local nearestBarbellId = nil
	local nearestDistance = BARBELL_EQUIP_DISTANCE

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		if type(barbellId) == "string" and type(barbellConfig) == "table" then
			local barbellNode = gameDumbbell:WaitForChild(barbellId)
			local displayNode = barbellNode
				and (barbellNode:WaitForChild("PromptPart") or barbellNode:WaitForChild("DisplayModel") or barbellNode)
			local displayPosition = getInstancePosition(displayNode)

			if displayPosition then
				local distance = (root.Position - displayPosition).Magnitude
				if distance <= nearestDistance then
					nearestBarbellId = barbellId
					nearestDistance = distance
				end
			end
		end
	end

	return nearestBarbellId
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

local function setDisplayText(root, labelName, value)
	local label = root and root:WaitForChild(labelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function setDisplayVisible(root, labelName, isVisible)
	local label = root and root:WaitForChild(labelName, true)
	if label and label:IsA("GuiObject") then
		label.Visible = isVisible == true
	end
end

local function refreshBarbellDisplays(data)
	local gameDumbbell = getWorldChild("GameDumbbell")
	if not gameDumbbell then
		return
	end

	local trophies = data and tonumber(data.Trophies) or 0
	local currentBarbellId = data and data.CurrentBarbellId

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		if type(barbellId) == "string" and type(barbellConfig) == "table" then
			local barbellNode = gameDumbbell:WaitForChild(barbellId)
			local displayNode = barbellNode and (barbellNode:WaitForChild("DisplayModel") or barbellNode)
			local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
			local isEquipped = currentBarbellId == barbellId
			local isUnlocked = trophies >= requiredTrophies

			setDisplayText(displayNode, "power", formatMultiplier(barbellConfig.StrengthMultiplier) .. " Power")
			setDisplayText(displayNode, "num", formatNumber(requiredTrophies))
			setDisplayVisible(displayNode, "Locked", not isUnlocked)
			setDisplayVisible(displayNode, "Equip", isUnlocked and not isEquipped)
			setDisplayVisible(displayNode, "Equipped", isEquipped)
		end
	end
end

local function refreshUi(data)
	latestData = data
	view.Refresh(data)
	refreshBarbellDisplays(data)
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
	return character ~= nil and hit == character:WaitForChild("HumanoidRootPart")
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

local rebirthButton = view.GetRebirthButton()
if rebirthButton then
	rebirthButton.Activated:Connect(function()
		if not latestData or not latestData.CanRebirth then
			return
		end

		local result = requestRebirth:InvokeServer()
		if result and result.Data then
			refreshUi(result.Data)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.E or isRequestingBarbellEquip then
		return
	end

	local barbellId = getNearestBarbellId()
	if not barbellId then
		return
	end

	isRequestingBarbellEquip = true
	local success, result = pcall(function()
		return requestBarbellEquip:InvokeServer(barbellId)
	end)
	isRequestingBarbellEquip = false

	if not success then
		warn(result)
		return
	end

	if result and result.Data then
		refreshUi(result.Data)
	end

	if result and result.Success == false and result.Message then
		warn(result.Message)
	end
end)

while task.wait(1) do
	refreshUi(getData:InvokeServer())
end
