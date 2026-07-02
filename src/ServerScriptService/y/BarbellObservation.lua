local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BarbellTheta"))

local BarbellObservation = {}

local DISPLAY_ROOT_NAME = "GameDumbbell"
local TRAIN_ROOT_NAME = "Dumbbell"
local DISPLAY_MODEL_NAME = "DisplayModel"
local TRAIN_MODEL_NAME = "Train"
local WORLD_WAIT_SECONDS = 10
local MAX_EQUIP_DISTANCE = 18

local function getCharacterRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function BarbellObservation.GetBaseParts(instance)
	local parts = {}

	if not instance then
		return parts
	end

	if instance:IsA("BasePart") then
		table.insert(parts, instance)
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	return parts
end

function BarbellObservation.GetFirstBasePart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function BarbellObservation.GetInstancePivot(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	local firstPart = BarbellObservation.GetFirstBasePart(instance)
	return firstPart and firstPart.CFrame or nil
end

function BarbellObservation.IsValidBarbellId(barbellId)
	return type(barbellId) == "string" and BarbellTheta[barbellId] ~= nil
end

function BarbellObservation.WaitForWorldRoots()
	local dumbbellRoot = Workspace:WaitForChild(TRAIN_ROOT_NAME, WORLD_WAIT_SECONDS)
	local displayRoot = Workspace:WaitForChild(DISPLAY_ROOT_NAME, WORLD_WAIT_SECONDS)

	return dumbbellRoot, displayRoot
end

function BarbellObservation.GetTrainSource(barbellId)
	local dumbbellRoot = Workspace:FindFirstChild(TRAIN_ROOT_NAME)
	local barbellNode = dumbbellRoot and dumbbellRoot:FindFirstChild(barbellId)

	return barbellNode and barbellNode:FindFirstChild(TRAIN_MODEL_NAME)
end

function BarbellObservation.GetDisplayHolder(barbellId)
	local displayRoot = Workspace:FindFirstChild(DISPLAY_ROOT_NAME)

	return displayRoot and displayRoot:FindFirstChild(barbellId)
end

function BarbellObservation.GetDisplayNode(barbellId)
	local barbellNode = BarbellObservation.GetDisplayHolder(barbellId)
	if not barbellNode then
		return nil
	end

	return barbellNode:FindFirstChild(DISPLAY_MODEL_NAME) or barbellNode
end

function BarbellObservation.IsPlayerNearDisplay(player, barbellId)
	if not BarbellObservation.IsValidBarbellId(barbellId) then
		return false
	end

	local root = getCharacterRoot(player)
	local displayNode = BarbellObservation.GetDisplayNode(barbellId)
	local displayPivot = BarbellObservation.GetInstancePivot(displayNode)

	if not root or not displayPivot then
		return false
	end

	return (root.Position - displayPivot.Position).Magnitude <= MAX_EQUIP_DISTANCE
end

return BarbellObservation
