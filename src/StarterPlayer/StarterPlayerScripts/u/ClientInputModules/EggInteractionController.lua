-- EggInteractionController
-- Binds every configured egg scene instance to the shared egg panel for its EggId.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local EggSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local EggInteractionController = {}
local BIND_WAIT_SECONDS = 30
local PROMPT_RETRY_INTERVAL_SECONDS = 0.1

function EggInteractionController.Init(sceneQuery, eggPanelView, snapshotController)
	local function waitForPath(root, path, timeout)
		if not root or type(path) ~= "table" then
			return nil
		end

		local current = root
		for _, childName in ipairs(path) do
			if type(childName) ~= "string" or childName == "" then
				return nil
			end

			current = current:WaitForChild(childName, timeout or 10)
			if not current then
				return nil
			end
		end

		return current
	end

	local function findPath(root, path)
		if not root or type(path) ~= "table" then
			return nil
		end

		local current = root
		for _, childName in ipairs(path) do
			if type(childName) ~= "string" or childName == "" then
				return nil
			end

			current = current and current:FindFirstChild(childName)
			if not current then
				return nil
			end
		end

		return current
	end

	local function getEggConfig(eggId)
		local eggs = EggSceneTheta.Eggs
		return type(eggs) == "table" and eggs[eggId] or nil
	end

	local function getEggInteractionNode(instanceConfig, eggConfig)
		local holder = findPath(Workspace, instanceConfig.HolderPath)
		if not holder then
			return nil
		end

		local promptPartName = instanceConfig.PromptPartName or eggConfig.PromptPartName or SceneTheta.EggPromptPartName
		return holder:FindFirstChild(promptPartName, true) or holder
	end

	local function findPrompt(holder, promptPartName)
		local promptRoot = holder:FindFirstChild(promptPartName, true)
		local prompt = promptRoot and promptRoot:FindFirstChildWhichIsA("ProximityPrompt", true)
			or holder:FindFirstChildWhichIsA("ProximityPrompt", true)

		return prompt
	end

	local function waitForPrompt(holder, promptPartName, timeout)
		local deadline = os.clock() + (timeout or BIND_WAIT_SECONDS)

		repeat
			local prompt = findPrompt(holder, promptPartName)
			if prompt then
				return prompt
			end

			task.wait(PROMPT_RETRY_INTERVAL_SECONDS)
		until os.clock() >= deadline

		return findPrompt(holder, promptPartName)
	end

	local function isPlayerNearEgg(eggId)
		local eggConfig = getEggConfig(eggId)
		local root = sceneQuery.GetPlayerRootPart()
		if not eggConfig or not root then
			return false
		end

		for _, instanceConfig in pairs(EggSceneTheta.Instances or {}) do
			if type(instanceConfig) == "table" and instanceConfig.EggId == eggId then
				local interactionPosition = sceneQuery.GetInstancePosition(getEggInteractionNode(instanceConfig, eggConfig))
				if interactionPosition then
					local interactionDistance = tonumber(instanceConfig.InteractionDistance)
						or tonumber(eggConfig.InteractionDistance)
						or SceneTheta.EggInteractionDistance
					if (root.Position - interactionPosition).Magnitude <= interactionDistance + 2 then
						return true
					end
				end
			end
		end

		return false
	end

	local function bindEggInstance(instanceId, instanceConfig)
		if type(instanceConfig) ~= "table" then
			warn("Missing egg scene instance config: " .. tostring(instanceId))
			return
		end

		local eggId = instanceConfig.EggId
		local eggConfig = getEggConfig(eggId)
		if type(eggId) ~= "string" or type(eggConfig) ~= "table" then
			warn("Invalid egg scene instance EggId: " .. tostring(instanceId))
			return
		end

		local holder = waitForPath(Workspace, instanceConfig.HolderPath, BIND_WAIT_SECONDS)
		if not holder then
			warn("Missing egg holder: " .. tostring(instanceId))
			return
		end

		local promptPartName = instanceConfig.PromptPartName or eggConfig.PromptPartName or SceneTheta.EggPromptPartName
		local prompt = waitForPrompt(holder, promptPartName, BIND_WAIT_SECONDS)
		if not prompt then
			warn("Missing egg prompt: " .. tostring(instanceId))
			return
		end

		prompt.Triggered:Connect(function()
			eggPanelView.Open(eggId, snapshotController.GetLatestData())
			snapshotController.RefreshFromServer()
		end)
	end

	local function bindAll()
		for instanceId, instanceConfig in pairs(EggSceneTheta.Instances or {}) do
			task.spawn(bindEggInstance, instanceId, instanceConfig)
		end
	end

	return {
		BindAll = bindAll,
		IsPlayerNearEgg = isPlayerNearEgg,
	}
end

return EggInteractionController
