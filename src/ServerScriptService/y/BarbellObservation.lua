local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))
local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
local BarbellDisplayTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("UI"):WaitForChild("BarbellDisplayTheta"))
local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta"))

local BarbellObservation = {}

local DISPLAY_MODEL_NAME = SceneTheta.BarbellDisplayModelName
local PROMPT_PART_NAME = SceneTheta.BarbellPromptPartName
local TRAIN_MODEL_NAME = SceneTheta.BarbellTrainModelName
local WORLD_WAIT_SECONDS = 10
local MAX_EQUIP_DISTANCE = SceneTheta.BarbellMaxEquipDistance

-- 获取玩家的 HumanoidRootPart，用于计算玩家与杠铃的距离
local function getCharacterRoot(player)
	local character = player.Character
	return character and character:WaitForChild("HumanoidRootPart")
end

local function getWorldRoot()
	return InstancePath.FindSpec({ Workspace = Workspace }, BarbellDisplayTheta.DisplayRootPathSpec)
end

local function getServerToUseSceneRoot()
	return InstancePath.FindSpec({ ServerStorage = ServerStorage }, BarbellDisplayTheta.TrainSourceRootPathSpec)
end

local function findSceneChild(childName)
	local worldRoot = getWorldRoot()
	return worldRoot and worldRoot:FindFirstChild(childName)
end

local function findServerSourceChild(childName)
	local sourceRoot = getServerToUseSceneRoot()
	return sourceRoot and sourceRoot:FindFirstChild(childName)
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

-- 类型检查：判断杠铃ID是否是有效的字符串，并且在 BarbellTheta 中存在对应的配置
function BarbellObservation.IsValidBarbellId(barbellId)
	return type(barbellId) == "string" and BarbellTheta[barbellId] ~= nil
end

function BarbellObservation.WaitForWorldRoots()
	local dumbbellRoot = InstancePath.WaitSpec(
		{ ServerStorage = ServerStorage },
		BarbellDisplayTheta.TrainSourceRootPathSpec,
		WORLD_WAIT_SECONDS
	)
	local displayRoot = InstancePath.WaitSpec(
		{ Workspace = Workspace },
		BarbellDisplayTheta.DisplayRootPathSpec,
		WORLD_WAIT_SECONDS
	)

	return dumbbellRoot, displayRoot
end

-- 这个函数有点奇怪，不是很理解
function BarbellObservation.GetTrainSource(barbellId)
	local barbellNode = findServerSourceChild(tostring(barbellId))

	return barbellNode and barbellNode:FindFirstChild(TRAIN_MODEL_NAME)
end

function BarbellObservation.GetDisplayHolder(barbellId)
	return findSceneChild(tostring(barbellId))
end

function BarbellObservation.GetDisplayNode(barbellId)
	local barbellNode = BarbellObservation.GetDisplayHolder(barbellId)
	if not barbellNode then
		return nil
	end

	return barbellNode:FindFirstChild(DISPLAY_MODEL_NAME) or barbellNode
end

function BarbellObservation.GetInteractionNode(barbellId)
	local barbellNode = BarbellObservation.GetDisplayHolder(barbellId)
	if not barbellNode then
		return nil
	end

	return barbellNode:FindFirstChild(PROMPT_PART_NAME)
		or BarbellObservation.GetDisplayNode(barbellId)
		or barbellNode
end

-- 检查玩家是否处于杠铃的显示位置附近，允许玩家与杠铃进行交互
function BarbellObservation.IsPlayerNearDisplay(player, barbellId)
	if not BarbellObservation.IsValidBarbellId(barbellId) then
		return false
	end

	local root = getCharacterRoot(player)
	local interactionNode = BarbellObservation.GetInteractionNode(barbellId)
	local displayPivot = BarbellObservation.GetInstancePivot(interactionNode)

	if not root or not displayPivot then
		return false
	end

	return (root.Position - displayPivot.Position).Magnitude <= MAX_EQUIP_DISTANCE
end

return BarbellObservation
