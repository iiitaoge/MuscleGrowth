local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local TrainingAreaObservation = {}

local AREA_CONTACT_PADDING = 1
local ENTER_CONTACT_RETRY_COUNT = 4
local ENTER_CONTACT_RETRY_INTERVAL = 0.05

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

local function isPointInsidePart(part, position, extraHalfSize)
	local relative = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size * 0.5 + (extraHalfSize or Vector3.new())

	return math.abs(relative.X) <= halfSize.X
		and math.abs(relative.Y) <= halfSize.Y
		and math.abs(relative.Z) <= halfSize.Z
end

local function isPartOverlappingPart(areaPart, targetPart)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { targetPart }
	overlapParams.MaxParts = 1

	local success, parts = pcall(function()
		return Workspace:GetPartsInPart(areaPart, overlapParams)
	end)

	return success and parts[1] ~= nil
end

local function isRootOverlappingTouch(root, touch)
	if isPartOverlappingPart(touch, root) then
		return true
	end

	local rootHalfSize = root.Size * 0.5
	local extraHalfSize = rootHalfSize
		+ Vector3.new(AREA_CONTACT_PADDING, AREA_CONTACT_PADDING, AREA_CONTACT_PADDING)

	return isPointInsidePart(touch, root.Position, extraHalfSize)
end

function TrainingAreaObservation.IsValidAreaId(areaId)
	return type(areaId) == "string" and AutoAreaTheta[areaId] ~= nil
end

function TrainingAreaObservation.IsPlayerInArea(player, areaId)
	if not TrainingAreaObservation.IsValidAreaId(areaId) then
		return false
	end

	local root = getCharacterRoot(player)
	local touch = getAutoAreaTouchPart(areaId)

	return root ~= nil and touch ~= nil and isRootOverlappingTouch(root, touch)
end

function TrainingAreaObservation.WaitForPlayerInArea(player, areaId)
	for _ = 1, ENTER_CONTACT_RETRY_COUNT do
		if TrainingAreaObservation.IsPlayerInArea(player, areaId) then
			return true
		end

		task.wait(ENTER_CONTACT_RETRY_INTERVAL)
	end

	return false
end

return TrainingAreaObservation
