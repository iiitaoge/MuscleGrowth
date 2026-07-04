local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TrophyTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("TrophyTheta"))

local TrophyWorldSync = {}

local DEFAULT_SCENE_ROOT_NAME = "UseScene"
local DEFAULT_FREE_RETURN_PART_NAME = "FreeReturn"
local WORLD_WAIT_SECONDS = 10

local boundFreeReturnIds = {}
local bindingStarted = false

local function waitForDirectChild(root, childName, timeoutSeconds)
	if not root or type(childName) ~= "string" then
		return nil
	end

	local endTime = os.clock() + timeoutSeconds

	repeat
		local found = root:FindFirstChild(childName)
		if found then
			return found
		end

		task.wait(0.25)
	until os.clock() >= endTime

	return nil
end

local function getSceneRoot(freeReturnConfig)
	local sceneRootName = freeReturnConfig.SceneRootName or DEFAULT_SCENE_ROOT_NAME
	return waitForDirectChild(Workspace, sceneRootName, WORLD_WAIT_SECONDS)
end

local function getFreeReturnNode(trophyId, freeReturnConfig)
	local sceneRoot = getSceneRoot(freeReturnConfig)
	if not sceneRoot then
		return nil
	end

	local nodeName = freeReturnConfig.NodeName or trophyId
	local node = waitForDirectChild(sceneRoot, nodeName, WORLD_WAIT_SECONDS)
	if not node then
		return nil
	end

	local freeReturnName = freeReturnConfig.FreeReturnName or DEFAULT_FREE_RETURN_PART_NAME
	return node:FindFirstChild(freeReturnName, true)
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

local function getCharacterRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function findSpawnPart()
	local namedSpawn = Workspace:FindFirstChild("SpawnLocation", true)
	if namedSpawn and namedSpawn:IsA("BasePart") then
		return namedSpawn
	end

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("SpawnLocation") then
			return instance
		end
	end

	local fallbackSpawn = Workspace:FindFirstChild("Spawn", true)
	if fallbackSpawn and fallbackSpawn:IsA("BasePart") then
		return fallbackSpawn
	end

	return nil
end

local function bindFreeReturn(trophyId, freeReturnConfig, onPlayerTouched)
	if boundFreeReturnIds[trophyId] then
		return
	end

	local freeReturn = getFreeReturnNode(trophyId, freeReturnConfig)
	local touchParts = getTouchParts(freeReturn)

	if #touchParts == 0 then
		warn(("Trophy free return %s was not found. Trophy reward touch is disabled."):format(tostring(trophyId)))
		return
	end

	boundFreeReturnIds[trophyId] = true

	for _, touchPart in ipairs(touchParts) do
		touchPart.CanTouch = true
		touchPart.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)
			if player and onPlayerTouched then
				onPlayerTouched(player, trophyId, freeReturnConfig)
			end
		end)
	end
end

function TrophyWorldSync.TeleportToSpawn(player)
	local root = getCharacterRoot(player)
	local spawnPart = findSpawnPart()

	if root and spawnPart then
		root.CFrame = spawnPart.CFrame + Vector3.new(0, 5, 0)
	end
end

function TrophyWorldSync.BindFreeReturns(onPlayerTouched)
	if bindingStarted then
		return
	end

	bindingStarted = true

	task.spawn(function()
		local freeReturnConfigs = TrophyTheta.FreeReturns
		if type(freeReturnConfigs) ~= "table" then
			warn("TrophyTheta.FreeReturns is missing. Trophy reward touch is disabled.")
			return
		end

		for trophyId, freeReturnConfig in pairs(freeReturnConfigs) do
			if type(trophyId) == "string" and type(freeReturnConfig) == "table" then
				bindFreeReturn(trophyId, freeReturnConfig, onPlayerTouched)
			end
		end
	end)
end

function TrophyWorldSync.BindFreeReturn(onPlayerTouched)
	TrophyWorldSync.BindFreeReturns(onPlayerTouched)
end

return TrophyWorldSync
