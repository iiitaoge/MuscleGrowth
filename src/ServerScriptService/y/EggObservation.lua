local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local theta = ReplicatedStorage:WaitForChild("theta")

local EggSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local EggObservation = {}

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

local function getEggConfig(eggId)
	local eggs = EggSceneTheta.Eggs
	return type(eggs) == "table" and eggs[eggId] or nil
end

local function getEggInteractionNode(instanceConfig, eggConfig)
	local holder = InstancePath.FindSpec({ Workspace = Workspace }, instanceConfig.HolderPathSpec)
	if not holder then
		return nil
	end

	local promptPartName = instanceConfig.PromptPartName or eggConfig.PromptPartName or PROMPT_PART_NAME
	return holder:FindFirstChild(promptPartName, true) or holder
end

function EggObservation.IsValidEggId(eggId)
	return type(eggId) == "string" and type(getEggConfig(eggId)) == "table"
end

function EggObservation.GetEggInteractionNode(eggId)
	local eggConfig = getEggConfig(eggId)
	if not eggConfig then
		return nil
	end

	for _, instanceConfig in pairs(EggSceneTheta.Instances or {}) do
		if type(instanceConfig) == "table" and instanceConfig.EggId == eggId then
			local interactionNode = getEggInteractionNode(instanceConfig, eggConfig)
			if interactionNode then
				return interactionNode
			end
		end
	end

	return nil
end

function EggObservation.IsPlayerNearEgg(player, eggId)
	local eggConfig = getEggConfig(eggId)
	if not eggConfig then
		return false
	end

	local root = getCharacterRoot(player)
	if not root then
		return false
	end

	for _, instanceConfig in pairs(EggSceneTheta.Instances or {}) do
		if type(instanceConfig) == "table" and instanceConfig.EggId == eggId then
			local interactionNode = getEggInteractionNode(instanceConfig, eggConfig)
			local interactionPosition = getInstancePosition(interactionNode)
			if interactionPosition then
				local interactionDistance = math.max(
					0,
					tonumber(instanceConfig.InteractionDistance)
						or tonumber(eggConfig.InteractionDistance)
						or DEFAULT_INTERACTION_DISTANCE
				)

				if (root.Position - interactionPosition).Magnitude <= interactionDistance then
					return true
				end
			end
		end
	end

	return false
end

return EggObservation
