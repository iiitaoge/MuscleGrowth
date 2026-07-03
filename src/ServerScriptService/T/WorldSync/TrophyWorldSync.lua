local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TrophyWorldSync = {}

local TROPHY_MODEL_NAME = "trophy1"
local FREE_RETURN_PART_NAME = "FreeReturn"
local WORLD_ROOT_NAME = "World1"
local WORLD_WAIT_SECONDS = 10

local isWorldBound = false
local isWorldBindingStarted = false

local function getWorldRoot()
	return Workspace:WaitForChild(WORLD_ROOT_NAME) or Workspace
end

local function findDescendantByName(root, childName, timeoutSeconds)
	local endTime = os.clock() + timeoutSeconds

	repeat
		local found = root:FindFirstChild(childName, true)
		if found then
			return found
		end

		task.wait(0.25)
	until os.clock() >= endTime

	return nil
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
		if descendant:IsA("BasePart") and descendant ~= mainPart and descendant.CanTouch then
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

function TrophyWorldSync.TeleportToSpawn(player)
	local root = getCharacterRoot(player)
	local spawnPart = findSpawnPart()

	if root and spawnPart then
		root.CFrame = spawnPart.CFrame + Vector3.new(0, 5, 0)
	end
end

function TrophyWorldSync.BindFreeReturn(onPlayerTouched)
	if isWorldBound or isWorldBindingStarted then
		return
	end

	isWorldBindingStarted = true

	task.spawn(function()
		local trophy = findDescendantByName(getWorldRoot(), TROPHY_MODEL_NAME, WORLD_WAIT_SECONDS)
			or findDescendantByName(Workspace, TROPHY_MODEL_NAME, WORLD_WAIT_SECONDS)
		local freeReturn = trophy and trophy:FindFirstChild(FREE_RETURN_PART_NAME, true)
		local touchParts = getTouchParts(freeReturn)

		if #touchParts == 0 then
			warn("trophy1.FreeReturn was not found. Trophy reward touch is disabled.")
			return
		end

		isWorldBound = true
		for _, touchPart in ipairs(touchParts) do
			touchPart.CanTouch = true
			touchPart.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				if player and onPlayerTouched then
					onPlayerTouched(player)
				end
			end)
		end
	end)
end

return TrophyWorldSync
