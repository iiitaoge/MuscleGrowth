-- PushBallController
-- 客户端推球输入层：触发交互、禁用普通移动、只发送左右输入。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local PushBallController = {}

local ATTRIBUTES = SceneTheta.Attributes
local LEFT_KEYS = {
	[Enum.KeyCode.A] = true,
	[Enum.KeyCode.Left] = true,
}
local RIGHT_KEYS = {
	[Enum.KeyCode.D] = true,
	[Enum.KeyCode.Right] = true,
}

function PushBallController.Init(player, remoteClient, movementController)
	local isActive = false
	local leftDown = false
	local rightDown = false
	local lastSentInput = 0
	local controls = nil
	local connections = {}

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

	local function getFirstBasePart(instance)
		if not instance then
			return nil
		end

		if instance:IsA("BasePart") then
			return instance
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	local function getControls()
		if controls then
			return controls
		end

		local success, result = pcall(function()
			local playerScripts = player:WaitForChild("PlayerScripts")
			local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
			return playerModule:GetControls()
		end)

		if success then
			controls = result
		end

		return controls
	end

	local function setControlsEnabled(enabled)
		local playerControls = getControls()
		if not playerControls then
			return
		end

		if enabled then
			playerControls:Enable()
		else
			playerControls:Disable()
		end
	end

	local function getLateralInput()
		if leftDown and not rightDown then
			return -1
		end

		if rightDown and not leftDown then
			return 1
		end

		return 0
	end

	local function sendLateralInput(force)
		local nextInput = getLateralInput()
		if not force and nextInput == lastSentInput then
			return
		end

		lastSentInput = nextInput
		remoteClient.Fire("PushBallLateralInput", nextInput)
	end

	local function enterLocalMode()
		if isActive then
			return
		end

		isActive = true
		leftDown = false
		rightDown = false
		lastSentInput = 0
		movementController.SetSuspended(true)
		setControlsEnabled(false)
		sendLateralInput(true)
	end

	local function exitLocalMode()
		if not isActive then
			return
		end

		isActive = false
		leftDown = false
		rightDown = false
		sendLateralInput(true)
		setControlsEnabled(true)
		movementController.SetSuspended(false)
	end

	local function syncLocalModeFromAttribute()
		if player:GetAttribute(ATTRIBUTES.IsPushingBall) == true then
			enterLocalMode()
		else
			exitLocalMode()
		end
	end

	local function requestStart()
		local ok, response = remoteClient.SafeInvoke("RequestStartPushBall")
		if not ok then
			warn(response)
			return
		end

		if type(response) == "table" and response.Success == true then
			enterLocalMode()
		elseif type(response) == "table" and response.Message then
			warn(response.Message)
		end
	end

	local function requestStop()
		remoteClient.SafeInvoke("RequestStopPushBall")
		exitLocalMode()
	end

	local function ensurePrompt(ball)
		local existingPrompt = ball:FindFirstChildWhichIsA("ProximityPrompt", true)
		if existingPrompt then
			return existingPrompt
		end

		local promptParent = getFirstBasePart(ball)
		if not promptParent then
			return nil
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = PushBallTheta.PromptActionText or "Push"
		prompt.ObjectText = PushBallTheta.PromptObjectText or "Ball"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = math.max(0, tonumber(PushBallTheta.InteractionDistance) or 14)
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptParent

		return prompt
	end

	local function bindBallPrompt()
		local ball = waitForPath(Workspace, PushBallSceneTheta.BallPath, 30)
		if not ball then
			warn("Missing push ball source")
			return
		end

		local prompt = ensurePrompt(ball)
		if not prompt then
			warn("Missing push ball prompt target")
			return
		end

		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer and triggeringPlayer ~= player then
				return
			end

			requestStart()
		end)
	end

	local function bindCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			table.insert(connections, humanoid.Died:Connect(requestStop))
		end
	end

	local function handleInputBegan(input, gameProcessed)
		if not isActive or gameProcessed then
			return
		end

		if LEFT_KEYS[input.KeyCode] then
			leftDown = true
			sendLateralInput(false)
		elseif RIGHT_KEYS[input.KeyCode] then
			rightDown = true
			sendLateralInput(false)
		end
	end

	local function handleInputEnded(input)
		if not isActive then
			return
		end

		if LEFT_KEYS[input.KeyCode] then
			leftDown = false
			sendLateralInput(false)
		elseif RIGHT_KEYS[input.KeyCode] then
			rightDown = false
			sendLateralInput(false)
		end
	end

	local function bind()
		table.insert(connections, player:GetAttributeChangedSignal(ATTRIBUTES.IsPushingBall):Connect(syncLocalModeFromAttribute))
		table.insert(connections, UserInputService.InputBegan:Connect(handleInputBegan))
		table.insert(connections, UserInputService.InputEnded:Connect(handleInputEnded))
		table.insert(connections, player.CharacterAdded:Connect(function(character)
			requestStop()
			bindCharacter(character)
		end))

		if player.Character then
			bindCharacter(player.Character)
		end

		task.spawn(bindBallPrompt)
		syncLocalModeFromAttribute()
	end

	return {
		Bind = bind,
	}
end

return PushBallController
