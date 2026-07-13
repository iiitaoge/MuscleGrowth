-- PushBallController
-- 客户端推球输入层：触发交互、禁用普通移动、只发送左右输入。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local T = ReplicatedStorage:WaitForChild("T")
local InstancePath = require(T:WaitForChild("InstancePath"))

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

	-- 球隐藏相关
	local hiddenBallInstanceId = nil
	local hiddenSourceBall = nil
	local hiddenParts = {}
	local hiddenTextures = {}
	local hiddenPrompts = {}

	-- 恢复被隐藏的球
	local function restoreSourceBall()
		for part, originalState in pairs(hiddenParts) do
			if part.Parent then
				part.LocalTransparencyModifier = originalState.LocalTransparencyModifier
				part.CanCollide = originalState.CanCollide
				part.CanTouch = originalState.CanTouch
				part.CanQuery = originalState.CanQuery
			end
		end
		for texture, originalTransparency in pairs(hiddenTextures) do
			if texture.Parent then
				texture.Transparency = originalTransparency
			end
		end
		for prompt, originalEnabled in pairs(hiddenPrompts) do
			if prompt.Parent then
				prompt.Enabled = originalEnabled
			end
		end

		table.clear(hiddenParts)
		table.clear(hiddenTextures)
		table.clear(hiddenPrompts)
		hiddenBallInstanceId = nil
		hiddenSourceBall = nil
	end

	-- 只在当前客户端隐藏源球；运动中的服务端克隆球不受影响。
	local function hideSourceBall(ballInstanceId, sourceBall)
		assert(type(ballInstanceId) == "string" and ballInstanceId ~= "", "Push ball source id must be a non-empty string.")
		assert(sourceBall and sourceBall:IsA("Model"), "Push ball source must be a Model.")

		if hiddenBallInstanceId == ballInstanceId and hiddenSourceBall == sourceBall then
			return
		end

		local sourceParts = {}
		local sourceTextures = {}
		local sourcePrompts = {}
		for _, descendant in ipairs(sourceBall:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(sourceParts, descendant)
			elseif descendant:IsA("Texture") or descendant:IsA("Decal") then
				table.insert(sourceTextures, descendant)
			elseif descendant:IsA("ProximityPrompt") then
				table.insert(sourcePrompts, descendant)
			end
		end

		assert(#sourceParts > 0, "Push ball source must contain at least one BasePart: " .. sourceBall:GetFullName())

		restoreSourceBall()
		for _, part in ipairs(sourceParts) do
			hiddenParts[part] = {
				LocalTransparencyModifier = part.LocalTransparencyModifier,
				CanCollide = part.CanCollide,
				CanTouch = part.CanTouch,
				CanQuery = part.CanQuery,
			}
			part.LocalTransparencyModifier = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
		for _, texture in ipairs(sourceTextures) do
			hiddenTextures[texture] = texture.Transparency
			texture.Transparency = 1
		end
		for _, prompt in ipairs(sourcePrompts) do
			hiddenPrompts[prompt] = prompt.Enabled
			prompt.Enabled = false
		end

		hiddenBallInstanceId = ballInstanceId
		hiddenSourceBall = sourceBall
	end

	local function resolveSourceBall(ballInstanceId)
		local balls = PushBallSceneTheta.Balls
		local ballConfig = type(balls) == "table" and balls[ballInstanceId] or nil
		assert(type(ballConfig) == "table", "Missing push ball config: " .. tostring(ballInstanceId))

		local sourceBall = InstancePath.FindSpec({ Workspace = Workspace }, ballConfig.PathSpec)
		assert(sourceBall, "Missing push ball source: " .. tostring(ballInstanceId))
		return sourceBall
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
		restoreSourceBall()

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

	-- 处理推球
	local function syncLocalModeFromAttributes()
		local isPushingBall = player:GetAttribute(ATTRIBUTES.IsPushingBall) == true
		local ballInstanceId = player:GetAttribute(ATTRIBUTES.ActivePushBallInstanceId)
		local hasValidBallId = type(ballInstanceId) == "string" and ballInstanceId ~= ""

		if isPushingBall and hasValidBallId then
			local sourceBall = resolveSourceBall(ballInstanceId)
			hideSourceBall(ballInstanceId, sourceBall)
			enterLocalMode()
		else
			exitLocalMode()
		end
	end

	local function requestStop()
		remoteClient.SafeInvoke("RequestStopPushBall")
		exitLocalMode()
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
		table.insert(connections, player:GetAttributeChangedSignal(ATTRIBUTES.IsPushingBall):Connect(syncLocalModeFromAttributes))
		table.insert(
			connections,
			player:GetAttributeChangedSignal(ATTRIBUTES.ActivePushBallInstanceId):Connect(syncLocalModeFromAttributes)
		)
		table.insert(connections, UserInputService.InputBegan:Connect(handleInputBegan))
		table.insert(connections, UserInputService.InputEnded:Connect(handleInputEnded))
		table.insert(connections, player.CharacterAdded:Connect(function(character)
			requestStop()
			bindCharacter(character)
		end))

		if player.Character then
			bindCharacter(player.Character)
		end

		syncLocalModeFromAttributes()
	end

	return {
		Bind = bind,
	}
end

return PushBallController
