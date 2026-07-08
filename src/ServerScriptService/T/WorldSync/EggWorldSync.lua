local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")

local EggDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("EggDisplayTheta"))
local EggSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)

local EggWorldSync = {}

local WORLD_WAIT_SECONDS = 10
local PROMPT_BOUND_ATTRIBUTE = "MuscleGrowthEggPromptConfigured"

local function waitForPath(root, path, context)
	if not root or type(path) ~= "table" then
		warn(context .. " path is invalid.")
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			warn(context .. " path contains an invalid child name.")
			return nil
		end

		current = current:WaitForChild(childName, WORLD_WAIT_SECONDS)
		if not current then
			warn(context .. " missing child: " .. childName)
			return nil
		end
	end

	return current
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

local function configurePrompt(holder, eggId, promptPartName)
	local promptRoot = holder and holder:FindFirstChild(promptPartName, true)
	local prompt = promptRoot and promptRoot:FindFirstChildWhichIsA("ProximityPrompt", true)
		or holder and holder:FindFirstChildWhichIsA("ProximityPrompt", true)
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

local function refreshEggInstance(instanceId, instanceConfig)
	if type(instanceConfig) ~= "table" then
		warn("Egg scene instance config is invalid: " .. tostring(instanceId))
		return false
	end

	local eggId = instanceConfig.EggId
	local eggConfig = type(eggId) == "string" and EggSceneTheta.Eggs[eggId] or nil
	if type(eggConfig) ~= "table" then
		warn("Egg scene instance has invalid EggId: " .. tostring(instanceId))
		return false
	end

	local source = waitForPath(ServerStorage, eggConfig.SourcePath, "Egg source " .. tostring(eggId))
	local holder = waitForPath(Workspace, instanceConfig.HolderPath, "Egg holder " .. tostring(instanceId))
	if not source or not holder then
		return false
	end

	local promptPartName = instanceConfig.PromptPartName or eggConfig.PromptPartName or SceneTheta.EggPromptPartName
	local existingVisual = getExistingVisual(holder, promptPartName)
	local targetAnchor = BarbellObservation.GetFirstBasePart(existingVisual)
	local targetCFrame = targetAnchor and targetAnchor.CFrame or BarbellObservation.GetInstancePivot(holder)
	local nextVisual = source:Clone()
	nextVisual.Name = SceneTheta.EggDisplayModelName
	nextVisual.Parent = holder

	if existingVisual and existingVisual ~= nextVisual then
		existingVisual:Destroy()
	end

	prepareDisplayModel(nextVisual)
	alignInstanceAnchorTo(nextVisual, targetCFrame)
	configurePrompt(holder, eggId, promptPartName)

	return true
end

function EggWorldSync.RefreshDisplays()
	local hasMissingInstance = false
	local instances = EggSceneTheta.Instances

	if type(instances) ~= "table" then
		warn("EggSceneTheta.Instances is missing. Egg scene refresh skipped.")
		return false
	end

	for instanceId, instanceConfig in pairs(instances) do
		print("instanceId =", instanceId)	-- 测试
		if not refreshEggInstance(instanceId, instanceConfig) then
			hasMissingInstance = true
		end
	end

	return not hasMissingInstance
end

function EggWorldSync.InitWorld()
	task.spawn(function()
		EggWorldSync.RefreshDisplays()
	end)
end

return EggWorldSync
