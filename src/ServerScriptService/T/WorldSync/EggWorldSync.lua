local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local EggTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("EggTheta"))
local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("SceneTheta"))

local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)

local EggWorldSync = {}

local WORLD_WAIT_SECONDS = 10
local PROMPT_BOUND_ATTRIBUTE = "MuscleGrowthEggPromptConfigured"

local function getUseSceneRoot()
	return Workspace:WaitForChild(SceneTheta.WorkspaceRootName, WORLD_WAIT_SECONDS)
end

local function getSceneEggRoot()
	local useScene = getUseSceneRoot()
	return useScene and useScene:WaitForChild(SceneTheta.SceneEggRootName, WORLD_WAIT_SECONDS)
end

local function getEggSourceRoot()
	local toUseScene = ServerStorage:WaitForChild(SceneTheta.ServerToUseSceneRootName, WORLD_WAIT_SECONDS)
	return toUseScene and toUseScene:WaitForChild(SceneTheta.EggSourceFolderName, WORLD_WAIT_SECONDS)
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

local function getExistingVisual(holder)
	local namedVisual = holder and holder:FindFirstChild(SceneTheta.EggDisplayModelName)
	if namedVisual then
		return namedVisual
	end

	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "Base" and child.Name ~= SceneTheta.EggPromptPartName then
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

	local eggConfig = EggTheta[eggId]
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.ActionText = "Open"
	prompt.ObjectText = eggConfig and eggConfig.DisplayName or eggId
	prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
end

function EggWorldSync.RefreshDisplays()
	local sceneEggRoot = getSceneEggRoot()
	local sourceRoot = getEggSourceRoot()
	if not sceneEggRoot or not sourceRoot then
		warn("UseScene.SceneEgg or ToUseScene.Egg was not found. Egg replacement skipped.")
		return false
	end

	for eggId in pairs(EggTheta) do
		local source = sourceRoot:FindFirstChild(eggId)
		local holder = sceneEggRoot:FindFirstChild(eggId)
		local existingVisual = getExistingVisual(holder)

		if source and holder then
			local targetPivot = BarbellObservation.GetInstancePivot(existingVisual)
				or BarbellObservation.GetInstancePivot(holder)
			local nextVisual = source:Clone()
			nextVisual.Name = SceneTheta.EggDisplayModelName
			nextVisual.Parent = holder

			if existingVisual and existingVisual ~= nextVisual then
				existingVisual:Destroy()
			end

			prepareDisplayModel(nextVisual)
			pivotInstanceTo(nextVisual, targetPivot)
		end

		if holder then
			configurePrompt(holder, eggId)
		end
	end

	return true
end

function EggWorldSync.InitWorld()
	task.spawn(function()
		EggWorldSync.RefreshDisplays()
	end)
end

return EggWorldSync
