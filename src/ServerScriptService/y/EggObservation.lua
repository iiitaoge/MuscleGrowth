local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local eggTheta = theta:WaitForChild("EggTheta")

local EggSceneTheta = require(eggTheta:WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local EggObservation = {}

local DEFAULT_SCENE_ROOT_NAME = SceneTheta.SceneEggRootName
local DEFAULT_INTERACTION_DISTANCE = SceneTheta.EggInteractionDistance
local PROMPT_PART_NAME = SceneTheta.EggPromptPartName

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
	return Workspace:FindFirstChild(SceneTheta.WorkspaceRootName) or Workspace
end

local function getSceneRoot(eggSceneConfig)
	local sceneRootName = type(eggSceneConfig) == "table" and eggSceneConfig.SceneRootName or DEFAULT_SCENE_ROOT_NAME
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
	return type(eggId) == "string" and EggSceneTheta[eggId] ~= nil
end

function EggObservation.GetEggInteractionNode(eggId)
	local eggSceneConfig = EggSceneTheta[eggId]
	if not eggSceneConfig then
		return nil
	end

	local sceneRoot = getSceneRoot(eggSceneConfig)
	local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
	local promptPartName = eggSceneConfig.PromptPartName or PROMPT_PART_NAME
	local eggModel = sceneRoot and sceneRoot:FindFirstChild(sceneNodeName)
	if not eggModel then
		return nil
	end

	return eggModel:FindFirstChild(promptPartName) or eggModel
end

function EggObservation.IsPlayerNearEgg(player, eggId)
	local eggSceneConfig = EggSceneTheta[eggId]
	if not eggSceneConfig then
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
		tonumber(eggSceneConfig.InteractionDistance) or DEFAULT_INTERACTION_DISTANCE
	)

	return (root.Position - interactionPosition).Magnitude <= interactionDistance
end

return EggObservation
