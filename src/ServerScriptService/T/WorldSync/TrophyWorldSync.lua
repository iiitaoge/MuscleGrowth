local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))
local TrophyTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("TrophyTheta"))

local TrophyWorldSync = {}

local WORLD_WAIT_SECONDS = 10

local boundReturnKeys = {}
local bindingStarted = false

local function waitForPath(root, path, timeoutSeconds)
	if not root or type(path) ~= "table" then
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current:WaitForChild(childName, timeoutSeconds or WORLD_WAIT_SECONDS)
		if not current then
			return nil
		end
	end

	return current
end

local function findPath(root, path)
	if not root or type(path) ~= "table" then
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

local function getStageReward(stageId)
	local stageConfig = type(StageTheta.Stages) == "table" and StageTheta.Stages[stageId] or nil
	return math.max(0, tonumber(stageConfig and stageConfig.RewardTrophies) or 0)
end

local function renderReturnText(root, stageReturnConfig, returnType, returnConfig)
	local textPath = returnConfig and returnConfig.TextPath
	if type(textPath) ~= "table" then
		return
	end

	local label = findPath(root, textPath)
	if not label then
		warn(("Missing trophy return text: %s %s"):format(tostring(stageReturnConfig.StageId), tostring(returnType)))
		return
	end

	if not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
		warn("Trophy return text target is not a text object: " .. label:GetFullName())
		return
	end

	local multiplier = math.max(0, tonumber(returnConfig.RewardMultiplier) or 1)
	label.Text = "+ " .. formatNumber(getStageReward(stageReturnConfig.StageId) * multiplier) .. " Wins"
end

local function getReturnNode(root, returnConfig)
	local returnName = returnConfig and returnConfig.Name
	if type(returnName) ~= "string" or returnName == "" then
		return nil
	end

	return root:FindFirstChild(returnName) or root:FindFirstChild(returnName, true)
end

local function getTouchParts(root)
	local touchParts = {}

	if not root then
		return touchParts
	end

	if root:IsA("BasePart") then
		table.insert(touchParts, root)
		return touchParts
	end

	local mainPart = root:FindFirstChild("Main", true)
	if mainPart and mainPart:IsA("BasePart") then
		table.insert(touchParts, mainPart)
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= mainPart then
			table.insert(touchParts, descendant)
		end
	end

	return touchParts
end

local function getPlayerFromHit(hit)
	local current = hit

	while current and current ~= Workspace do
		if current:IsA("Model") and current:FindFirstChildWhichIsA("Humanoid") then
			return Players:GetPlayerFromCharacter(current)
		end

		current = current.Parent
	end

	return nil
end

local function bindReturnNode(stageReturnId, stageReturnConfig, root, returnType, returnConfig, onPlayerTouched)
	local boundKey = tostring(stageReturnId) .. "." .. tostring(returnType)
	if boundReturnKeys[boundKey] then
		return
	end

	renderReturnText(root, stageReturnConfig, returnType, returnConfig)

	local returnNode = getReturnNode(root, returnConfig)
	local touchParts = getTouchParts(returnNode)
	if #touchParts == 0 then
		warn(("Trophy return %s was not found. Touch reward is disabled."):format(boundKey))
		return
	end

	boundReturnKeys[boundKey] = true

	for _, touchPart in ipairs(touchParts) do
		touchPart.CanTouch = true
		touchPart.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)
			if player and onPlayerTouched then
				onPlayerTouched(player, stageReturnId, stageReturnConfig, returnType, returnConfig)
			end
		end)
	end
end

local function bindStageReturn(stageReturnId, stageReturnConfig, onPlayerTouched)
	local root = waitForPath(Workspace, stageReturnConfig.RootPath, WORLD_WAIT_SECONDS)
	if not root then
		warn("Trophy stage return root was not found: " .. tostring(stageReturnId))
		return
	end

	if type(stageReturnConfig.FreeReturn) == "table" then
		bindReturnNode(stageReturnId, stageReturnConfig, root, "FreeReturn", stageReturnConfig.FreeReturn, onPlayerTouched)
	end

	if type(stageReturnConfig.VIPReturn) == "table" then
		bindReturnNode(stageReturnId, stageReturnConfig, root, "VIPReturn", stageReturnConfig.VIPReturn, onPlayerTouched)
	end
end

function TrophyWorldSync.BindStageReturns(onPlayerTouched)
	if bindingStarted then
		return
	end

	bindingStarted = true

	task.spawn(function()
		local stageReturns = TrophyTheta.StageReturns
		if type(stageReturns) ~= "table" then
			warn("TrophyTheta.StageReturns is missing. Trophy stage returns are disabled.")
			return
		end

		for stageReturnId, stageReturnConfig in pairs(stageReturns) do
			if type(stageReturnId) == "string" and type(stageReturnConfig) == "table" then
				bindStageReturn(stageReturnId, stageReturnConfig, onPlayerTouched)
			end
		end
	end)
end

function TrophyWorldSync.BindFreeReturns(onPlayerTouched)
	TrophyWorldSync.BindStageReturns(onPlayerTouched)
end

function TrophyWorldSync.BindFreeReturn(onPlayerTouched)
	TrophyWorldSync.BindStageReturns(onPlayerTouched)
end

return TrophyWorldSync
