local Workspace = game:GetService("Workspace")

local GameManager = {}
local growthLoops = {}

local PlayerData = require(script.Parent.PlayerData)
local GrowthState = require(script.Parent.GrowthState)
local AutoAreaConfig = require(game:GetService("ReplicatedStorage").Configs.AutoAreaConfig)

local AREA_PADDING = 2

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getAutoAreaTouchPart(areaId)
	local world = Workspace:FindFirstChild("World1")
	local trainAreas = world and world:FindFirstChild("TrainAreas")
	local area = trainAreas and trainAreas:FindFirstChild(areaId)
	local touch = area and area:FindFirstChild("Touch")

	if touch and touch:IsA("BasePart") then
		return touch
	end

	return nil
end

local function isPointInsidePart(part, position)
	local relative = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size * 0.5

	return math.abs(relative.X) <= halfSize.X + AREA_PADDING
		and math.abs(relative.Y) <= halfSize.Y + AREA_PADDING
		and math.abs(relative.Z) <= halfSize.Z + AREA_PADDING
end

local function isPlayerInsideAutoArea(player, areaId)
	local root = getCharacterRoot(player)
	local touch = getAutoAreaTouchPart(areaId)

	return root ~= nil and touch ~= nil and isPointInsidePart(touch, root.Position)
end

local function isValidAutoAreaContact(player, areaId)
	return AutoAreaConfig[areaId] ~= nil and isPlayerInsideAutoArea(player, areaId)
end

local function pruneInvalidAutoAreas(player)
	local autoAreas = GrowthState.getAutoAreas(player)

	for areaId in pairs(autoAreas) do
		if not isValidAutoAreaContact(player, areaId) then
			GrowthState.leaveAutoArea(player, areaId)
		end
	end
end

local function getGrowthContext(player)
	local playerData = PlayerData.get(player)
	if not playerData then
		return nil
	end

	pruneInvalidAutoAreas(player)
	return GrowthState.getActiveContext(player, playerData)
end

local function stopGrowthLoop(player)
	growthLoops[player] = nil
end

local function startGrowthLoop(player)
	if growthLoops[player] then
		return
	end

	growthLoops[player] = true

	task.spawn(function()
		while growthLoops[player] do
			task.wait(1)

			local context = getGrowthContext(player)
			if not context or not context.ShouldGrow then
				stopGrowthLoop(player)
				break
			end

			PlayerData.addProgress(player, context)
		end
	end)
end

function GameManager.refreshGrowth(player)
	local context = getGrowthContext(player)
	if context and context.ShouldGrow then
		startGrowthLoop(player)
	else
		stopGrowthLoop(player)
	end
end

function GameManager.setMoving(player, isMoving)
	GrowthState.setMoving(player, isMoving)
	GameManager.refreshGrowth(player)
end

function GameManager.enterAutoArea(player, areaId)
	if type(areaId) ~= "string" then
		return false
	end

	if not isValidAutoAreaContact(player, areaId) then
		return false
	end

	GrowthState.enterAutoArea(player, areaId)
	GameManager.refreshGrowth(player)
	return true
end

function GameManager.leaveAutoArea(player, areaId)
	if type(areaId) ~= "string" then
		return
	end

	GrowthState.leaveAutoArea(player, areaId)
	GameManager.refreshGrowth(player)
end

function GameManager.stopGrowth(player)
	stopGrowthLoop(player)
end

function GameManager.removePlayer(player)
	stopGrowthLoop(player)
	GrowthState.remove(player)
end

return GameManager
