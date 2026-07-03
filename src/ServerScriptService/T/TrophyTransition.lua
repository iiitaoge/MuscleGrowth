local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)

local TrophyTransition = {}

local TROPHY_MODEL_NAME = "trophy1"
local FREE_RETURN_PART_NAME = "FreeReturn"
local FREE_RETURN_REWARD = 130
local TOUCH_COOLDOWN_SECONDS = 1
local WORLD_ROOT_NAME = "World1"
local WORLD_WAIT_SECONDS = 10

local touchDebounceByPlayer = setmetatable({}, {
	__mode = "k",
})

local isWorldBound = false
local isWorldBindingStarted = false

local function getWorldRoot()
	return Workspace:WaitForChild(WORLD_ROOT_NAME) or Workspace
end

local function findDescendantByName(root, childName, timeoutSeconds)
	local endTime = os.clock() + timeoutSeconds

	repeat
		local found = root:WaitForChild(childName, true)
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

	local mainPart = root:WaitForChild("Main", true)
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
		if current:IsA("Model") and current:WaitForChildWhichIsA("Humanoid") then
			return Players:GetPlayerFromCharacter(current)
		end

		current = current.Parent
	end

	return nil
end

local function getCharacterRoot(player)
	local character = player.Character
	return character and character:WaitForChild("HumanoidRootPart")
end

local function findSpawnPart()
	local namedSpawn = Workspace:WaitForChild("SpawnLocation", true)
	if namedSpawn and namedSpawn:IsA("BasePart") then
		return namedSpawn
	end

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("SpawnLocation") then
			return instance
		end
	end

	local fallbackSpawn = Workspace:WaitForChild("Spawn", true)
	if fallbackSpawn and fallbackSpawn:IsA("BasePart") then
		return fallbackSpawn
	end

	return nil
end

local function teleportToSpawn(player)
	local root = getCharacterRoot(player)
	local spawnPart = findSpawnPart()

	if root and spawnPart then
		root.CFrame = spawnPart.CFrame + Vector3.new(0, 5, 0)
	end
end

function TrophyTransition.AddTrophies(player, amount)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.Trophies = math.max(0, (tonumber(nextProgressState.Trophies) or 0) + (tonumber(amount) or 0))
	PlayerProgressState.Set(player, nextProgressState)

	return true
end

local function canTouchNow(player)
	local now = os.clock()
	local lastTouchTime = touchDebounceByPlayer[player]

	if lastTouchTime and now - lastTouchTime < TOUCH_COOLDOWN_SECONDS then
		return false
	end

	touchDebounceByPlayer[player] = now
	return true
end

local function onFreeReturnTouched(hit)
	local player = getPlayerFromHit(hit)
	if not player or not canTouchNow(player) then
		return
	end

	if TrophyTransition.AddTrophies(player, FREE_RETURN_REWARD) then
		teleportToSpawn(player)
	end
end

function TrophyTransition.InitWorld()
	if isWorldBound or isWorldBindingStarted then
		return
	end

	isWorldBindingStarted = true

	task.spawn(function()
		local trophy = findDescendantByName(getWorldRoot(), TROPHY_MODEL_NAME, WORLD_WAIT_SECONDS)
			or findDescendantByName(Workspace, TROPHY_MODEL_NAME, WORLD_WAIT_SECONDS)
		local freeReturn = trophy and trophy:WaitForChild(FREE_RETURN_PART_NAME, true)
		local touchParts = getTouchParts(freeReturn)

		if #touchParts == 0 then
			warn("trophy1.FreeReturn was not found. Trophy reward touch is disabled.")
			return
		end

		isWorldBound = true
		for _, touchPart in ipairs(touchParts) do
			touchPart.CanTouch = true
			touchPart.Touched:Connect(onFreeReturnTouched)
		end
	end)
end

function TrophyTransition.RemovePlayer(player)
	touchDebounceByPlayer[player] = nil
end

return TrophyTransition
