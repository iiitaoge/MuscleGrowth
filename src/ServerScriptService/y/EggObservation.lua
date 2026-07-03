local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EggTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("EggTheta"))

local EggObservation = {}

local DEFAULT_SCENE_ROOT_NAME = "SceneEgg"
local DEFAULT_INTERACTION_DISTANCE = 12
local PROMPT_PART_NAME = "PromptPart"
local WORLD_ROOT_NAME = "World1"

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

local function getWorldRoot()
	return Workspace:FindFirstChild(WORLD_ROOT_NAME) or Workspace
end

local function getSceneRoot(eggConfig)
	local sceneRootName = type(eggConfig) == "table" and eggConfig.SceneRootName or DEFAULT_SCENE_ROOT_NAME
	local worldRoot = getWorldRoot()

	return worldRoot:FindFirstChild(sceneRootName)
		or Workspace:FindFirstChild(sceneRootName)
		or Workspace:FindFirstChild(sceneRootName, true)
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

	local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)
	return firstPart and firstPart.Position or nil
end

function EggObservation.IsValidEggId(eggId)
	return type(eggId) == "string" and EggTheta[eggId] ~= nil
end

function EggObservation.GetEggInteractionNode(eggId)
	local eggConfig = EggTheta[eggId]
	if not eggConfig then
		return nil
	end

	local sceneRoot = getSceneRoot(eggConfig)
	local eggModel = sceneRoot and sceneRoot:FindFirstChild(eggId)
	if not eggModel then
		return nil
	end

	return eggModel:FindFirstChild(PROMPT_PART_NAME) or eggModel
end

function EggObservation.IsPlayerNearEgg(player, eggId)
	local eggConfig = EggTheta[eggId]
	if not eggConfig then
		return false
	end

	local root = getCharacterRoot(player)
	local interactionNode = EggObservation.GetEggInteractionNode(eggId)
	local interactionPosition = getInstancePosition(interactionNode)
	if not root or not interactionPosition then
		return false
	end

	local interactionDistance = math.max(
		0,
		tonumber(eggConfig.InteractionDistance) or DEFAULT_INTERACTION_DISTANCE
	)

	return (root.Position - interactionPosition).Magnitude <= interactionDistance
end

return EggObservation
