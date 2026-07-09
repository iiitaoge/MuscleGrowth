-- PushBallController
-- 客户端推球输入层：触发交互、禁用普通移动、只发送左右输入。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
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
local LOCAL_AREA_OVERLAP_SIZE = Vector3.new(10, 12, 10)
local LOCAL_AREA_MAX_PARTS = 8

local function debugLog(...)
	if PushBallTheta.DebugPushBall == true then
		print("[PushBallController]", ...)
	end
end

function PushBallController.Init(player, remoteClient, movementController)
	local isActive = false
	local leftDown = false
	local rightDown = false
	local lastSentInput = 0
	local controls = nil
	local connections = {}

	local function debugLocalArea(context, character, root)
		if PushBallTheta.DebugPushBall ~= true or not root then
			return
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }
		raycastParams.IgnoreWater = true

		local raycastResult = Workspace:Raycast(root.Position + Vector3.new(0, 5, 0), Vector3.new(0, -85, 0), raycastParams)

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = { character }
		local parts = Workspace:GetPartBoundsInBox(CFrame.new(root.Position), LOCAL_AREA_OVERLAP_SIZE, overlapParams)
		local collidableParts = {}
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") and part.CanCollide then
				table.insert(collidableParts, part)
			end
		end

		debugLog(
			context .. " localArea",
			"ground=", raycastResult and raycastResult.Instance and raycastResult.Instance:GetFullName() or "nil",
			"groundPosition=", raycastResult and raycastResult.Position or nil,
			"groundMaterial=", raycastResult and raycastResult.Material.Name or "nil",
			"overlapCount=", #collidableParts
		)

		for index, part in ipairs(collidableParts) do
			if index > LOCAL_AREA_MAX_PARTS then
				break
			end

			debugLog(
				context .. " localOverlap",
				index,
				part:GetFullName(),
				"size=", part.Size,
				"position=", part.Position,
				"transparency=", part.Transparency,
				"collisionGroup=", part.CollisionGroup
			)
		end
	end

	local function debugCharacterState(context)
		if PushBallTheta.DebugPushBall ~= true then
			return
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			debugLog(context, "characterReady=false", "attr=", player:GetAttribute(ATTRIBUTES.IsPushingBall), "isActive=", isActive)
			return
		end

		debugLog(
			context,
			"attr=", player:GetAttribute(ATTRIBUTES.IsPushingBall),
			"isActive=", isActive,
			"pos=", root.Position,
			"rootAnchored=", root.Anchored,
			"velocity=", root.AssemblyLinearVelocity,
			"walkSpeed=", humanoid.WalkSpeed,
			"jumpPower=", humanoid.JumpPower,
			"autoRotate=", humanoid.AutoRotate,
			"state=", humanoid:GetState().Name,
			"floor=", humanoid.FloorMaterial.Name
		)

		if string.find(context, "ExitLocalMode") or string.find(context, "HumanoidDied") then
			debugLocalArea(context, character, root)
		end
	end

	local function debugPostExitStates(reason)
		if PushBallTheta.DebugPushBall ~= true then
			return
		end

		task.defer(function()
			debugCharacterState(reason .. " defer")
		end)
		task.delay(0.25, function()
			debugCharacterState(reason .. " 0.25s")
		end)
		task.delay(1, function()
			debugCharacterState(reason .. " 1s")
		end)
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

		debugLog("GetControls", "success=", success, "hasControls=", controls ~= nil, "error=", success and nil or tostring(result))
		return controls
	end

	local function setControlsEnabled(enabled)
		local playerControls = getControls()
		if not playerControls then
			debugLog("SetControlsEnabled skipped", "enabled=", enabled)
			return
		end

		if enabled then
			playerControls:Enable()
		else
			playerControls:Disable()
		end

		debugLog("SetControlsEnabled", "enabled=", enabled)
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
		debugLog("SendLateralInput", "input=", nextInput, "force=", force)
	end

	local function enterLocalMode()
		if isActive then
			debugLog("EnterLocalMode skipped", "reason=", "already active")
			return
		end

		debugCharacterState("EnterLocalMode before")
		isActive = true
		leftDown = false
		rightDown = false
		lastSentInput = 0
		movementController.SetSuspended(true)
		setControlsEnabled(false)
		sendLateralInput(true)
		debugCharacterState("EnterLocalMode after")
	end

	local function exitLocalMode()
		if not isActive then
			debugLog("ExitLocalMode skipped", "reason=", "not active", "attr=", player:GetAttribute(ATTRIBUTES.IsPushingBall))
			debugPostExitStates("ExitLocalMode skipped")
			return
		end

		debugCharacterState("ExitLocalMode before")
		isActive = false
		leftDown = false
		rightDown = false
		sendLateralInput(true)
		setControlsEnabled(true)
		movementController.SetSuspended(false)
		debugCharacterState("ExitLocalMode after")
		debugPostExitStates("ExitLocalMode post")
	end

	local function syncLocalModeFromAttribute()
		local isPushingBall = player:GetAttribute(ATTRIBUTES.IsPushingBall) == true
		debugLog("SyncLocalModeFromAttribute", "attr=", isPushingBall, "isActive=", isActive)
		if isPushingBall then
			enterLocalMode()
		else
			exitLocalMode()
		end
	end

	local function requestStop()
		debugCharacterState("RequestStop before")
		remoteClient.SafeInvoke("RequestStopPushBall")
		exitLocalMode()
		debugCharacterState("RequestStop after")
	end

	local function bindCharacter(character)
		debugLog("BindCharacter", "character=", character and character.Name or nil)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			debugLog(
				"BindCharacter humanoid",
				"walkSpeed=", humanoid.WalkSpeed,
				"jumpPower=", humanoid.JumpPower,
				"autoRotate=", humanoid.AutoRotate,
				"state=", humanoid:GetState().Name,
				"floor=", humanoid.FloorMaterial.Name
			)
			table.insert(connections, humanoid.Died:Connect(function()
				debugCharacterState("HumanoidDied")
				requestStop()
			end))
		else
			debugLog("BindCharacter missing humanoid")
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
		debugLog("Bind")
		table.insert(connections, player:GetAttributeChangedSignal(ATTRIBUTES.IsPushingBall):Connect(syncLocalModeFromAttribute))
		table.insert(connections, UserInputService.InputBegan:Connect(handleInputBegan))
		table.insert(connections, UserInputService.InputEnded:Connect(handleInputEnded))
		table.insert(connections, player.CharacterAdded:Connect(function(character)
			debugLog("CharacterAdded", "character=", character and character.Name or nil)
			requestStop()
			bindCharacter(character)
		end))

		if player.Character then
			bindCharacter(player.Character)
		end

		syncLocalModeFromAttribute()
	end

	return {
		Bind = bind,
	}
end

return PushBallController
