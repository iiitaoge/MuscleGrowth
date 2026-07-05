local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local eggTheta = theta:WaitForChild("EggTheta")

local EggDisplayTheta = require(eggTheta:WaitForChild("EggDisplayTheta"))
local EggSceneTheta = require(eggTheta:WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)

local EggWorldSync = {}

local WORLD_WAIT_SECONDS = 10
local PROMPT_BOUND_ATTRIBUTE = "MuscleGrowthEggPromptConfigured"

local function getUseSceneRoot()
	return Workspace:WaitForChild(SceneTheta.WorkspaceRootName, WORLD_WAIT_SECONDS)
end

local function getSceneRoot(sceneRootName)
	local useScene = getUseSceneRoot()
	return useScene and useScene:WaitForChild(sceneRootName or SceneTheta.SceneEggRootName, WORLD_WAIT_SECONDS)
end

local function getEggSourceRoot(sourceRootName)
	local toUseScene = ServerStorage:WaitForChild(SceneTheta.ServerToUseSceneRootName, WORLD_WAIT_SECONDS)
	return toUseScene and toUseScene:WaitForChild(sourceRootName or SceneTheta.EggSourceFolderName, WORLD_WAIT_SECONDS)
end

local function disableScripts(instance)
	if instance:IsA("BaseScript") then
		instance.Disabled = true
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant.Disabled = true
		end
	end
end

local function prepareDisplayModel(instance)
	disableScripts(instance)

	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
	end
end

local function pivotInstanceTo(instance, targetCFrame)
	if not instance or not targetCFrame then
		return false
	end

	if instance:IsA("Model") then
		instance:PivotTo(targetCFrame)
		return true
	end

	if instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
		return true
	end

	return false
end

local function alignInstanceAnchorTo(instance, targetCFrame)
	if not instance or not targetCFrame then
		return false
	end

	local sourceAnchor = BarbellObservation.GetFirstBasePart(instance)
	if not sourceAnchor then
		return pivotInstanceTo(instance, targetCFrame)
	end

	local delta = targetCFrame * sourceAnchor.CFrame:Inverse()
	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.CFrame = delta * part.CFrame
	end

	return true
end

local function getExistingVisual(holder, promptPartName)
	local namedVisual = holder and holder:FindFirstChild(SceneTheta.EggDisplayModelName)
	if namedVisual then
		return namedVisual
	end

	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "Base" and child.Name ~= promptPartName then
			return child
		end
	end

	return nil
end

local function configurePrompt(holder, eggId)
	local prompt = holder and holder:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		return
	end

	local eggDisplayConfig = EggDisplayTheta[eggId]
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.ActionText = "Open"
	prompt.ObjectText = eggDisplayConfig and eggDisplayConfig.DisplayName or eggId
	prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
end

function EggWorldSync.RefreshDisplays()
	local hasMissingRoot = false

	for eggId, eggSceneConfig in pairs(EggSceneTheta) do
		local sceneRoot = getSceneRoot(eggSceneConfig.SceneRootName)
		local sourceRoot = getEggSourceRoot(eggSceneConfig.SourceRootName)
		if not sceneRoot or not sourceRoot then
			hasMissingRoot = true
			continue
		end

		local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
		local sourceNodeName = eggSceneConfig.SourceNodeName or eggId
		local promptPartName = eggSceneConfig.PromptPartName or SceneTheta.EggPromptPartName
		local source = sourceRoot:FindFirstChild(sourceNodeName)
		local holder = sceneRoot:FindFirstChild(sceneNodeName)
		local existingVisual = getExistingVisual(holder, promptPartName)

		if source and holder then
			local targetAnchor = BarbellObservation.GetFirstBasePart(existingVisual)
			local targetCFrame = targetAnchor and targetAnchor.CFrame
				or BarbellObservation.GetInstancePivot(holder)
			local nextVisual = source:Clone()
			nextVisual.Name = SceneTheta.EggDisplayModelName
			nextVisual.Parent = holder

			if existingVisual and existingVisual ~= nextVisual then
				existingVisual:Destroy()
			end

			prepareDisplayModel(nextVisual)
			alignInstanceAnchorTo(nextVisual, targetCFrame)
		end

		if holder then
			configurePrompt(holder, eggId)
		end
	end

	if hasMissingRoot then
		warn("Egg scene root or source root was not found. Some egg visuals were skipped.")
	end

	return not hasMissingRoot
end

function EggWorldSync.InitWorld()
	task.spawn(function()
		EggWorldSync.RefreshDisplays()
	end)
end

return EggWorldSync
