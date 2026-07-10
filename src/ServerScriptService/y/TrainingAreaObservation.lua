local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("AutoAreaTheta"))
local AutoAreaSceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("AutoAreaSceneTheta"))

local TrainingAreaObservation = {}

local AREA_CONTACT_PADDING = 1
local ENTER_CONTACT_RETRY_COUNT = 4
local ENTER_CONTACT_RETRY_INTERVAL = 0.05

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:WaitForChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getAutoAreaTouchParts(areaId)
	local touchParts = {}

	for _, instanceConfig in pairs(AutoAreaSceneTheta.Instances or {}) do
		if type(instanceConfig) == "table" and instanceConfig.AreaId == areaId then
			local touch = InstancePath.FindSpec({ Workspace = Workspace }, instanceConfig.TouchPath)
			if touch and touch:IsA("BasePart") then
				table.insert(touchParts, touch)
			end
		end
	end

	return touchParts
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
	if not root then
		return false
	end

	for _, touch in ipairs(getAutoAreaTouchParts(areaId)) do
		if isRootOverlappingTouch(root, touch) then
			return true
		end
	end

	return false
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
