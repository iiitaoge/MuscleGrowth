local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() or Workspace:GetAttribute("RunCharacterMorphTests") ~= true then
	return
end

local player = Players.LocalPlayer
local bridge = ReplicatedStorage:WaitForChild("MG_CharacterMorphTestBridge", 30)
if not bridge or not bridge:IsA("RemoteEvent") then
	warn("[MorphTest][FAIL] client observer - test bridge was not created")
	return
end

local humanoidIdentityByInstance = setmetatable({}, { __mode = "k" })
local nextHumanoidIdentity = 0

local function getHumanoidIdentity(humanoid)
	if not humanoid then
		return "nil"
	end
	if not humanoidIdentityByInstance[humanoid] then
		nextHumanoidIdentity += 1
		humanoidIdentityByInstance[humanoid] = nextHumanoidIdentity
	end
	return tostring(humanoidIdentityByInstance[humanoid])
end

local function instancePath(instance)
	if not instance then
		return "nil"
	end
	local ok, fullName = pcall(instance.GetFullName, instance)
	return ok and fullName or tostring(instance)
end

local function getCharacterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	return character, humanoid, root
end

local function collectPhysicalOffenders(character)
	local result = {
		CanCollide = {},
		CanTouch = {},
		CanQuery = {},
		Massless = {},
		AllCollidable = {},
	}
	if not character then
		return result
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.CanCollide then
				table.insert(result.AllCollidable, instancePath(descendant))
			end
			if descendant.Parent ~= character then
				if descendant.CanCollide then
					table.insert(result.CanCollide, instancePath(descendant))
				end
				if descendant.CanTouch then
					table.insert(result.CanTouch, instancePath(descendant))
				end
				if descendant.CanQuery then
					table.insert(result.CanQuery, instancePath(descendant))
				end
				if not descendant.Massless then
					table.insert(result.Massless, instancePath(descendant))
				end
			end
		end
	end
	return result
end

local function inspectCharacter()
	local character, humanoid, root = getCharacterParts()
	local camera = Workspace.CurrentCamera
	local offenders = collectPhysicalOffenders(character)
	return {
		CharacterPath = instancePath(character),
		HumanoidPath = instancePath(humanoid),
		HumanoidIdentity = getHumanoidIdentity(humanoid),
		HumanoidRootPartPath = instancePath(root),
		PrimaryPartPath = instancePath(character and character.PrimaryPart),
		MorphRigIndex = character and character:GetAttribute("MuscleGrowthRigIndex"),
		MorphScale = character and character:GetAttribute("MuscleGrowthRigScale"),
		TestCharacterToken = character and character:GetAttribute("MorphTestCharacterToken"),
		CameraType = camera and camera.CameraType.Name or "nil",
		CameraSubjectPath = instancePath(camera and camera.CameraSubject),
		SubjectIsCurrentHumanoid = camera ~= nil and camera.CameraSubject == humanoid,
		CameraMode = player.CameraMode.Name,
		MouseBehavior = UserInputService.MouseBehavior.Name,
		MouseIconEnabled = UserInputService.MouseIconEnabled,
		RootCanCollide = root and root.CanCollide,
		AutomaticScalingEnabled = humanoid and humanoid.AutomaticScalingEnabled,
		AssemblyMass = root and root.AssemblyMass or 0,
		FloorMaterial = humanoid and humanoid.FloorMaterial.Name or "nil",
		HumanoidState = humanoid and humanoid:GetState().Name or "nil",
		NestedCanCollide = offenders.CanCollide,
		NestedCanTouch = offenders.CanTouch,
		NestedCanQuery = offenders.CanQuery,
		NestedNotMassless = offenders.Massless,
		AllCollidable = offenders.AllCollidable,
	}
end

local function exerciseMovementAndJump()
	local character, humanoid, root = getCharacterParts()
	assert(character and humanoid and root, "current character is missing Humanoid or HumanoidRootPart")

	local startPosition = root.Position
	local moveBindingName = "CharacterMorphTestMove"
	RunService:BindToRenderStep(moveBindingName, Enum.RenderPriority.Input.Value + 1, function()
		if player.Character == character and humanoid.Health > 0 then
			humanoid:Move(Vector3.new(0, 0, -1), false)
		end
	end)
	task.wait(0.8)
	RunService:UnbindFromRenderStep(moveBindingName)
	humanoid:Move(Vector3.zero, false)
	local movedPosition = root.Position
	local horizontalDisplacement = Vector3.new(
		movedPosition.X - startPosition.X,
		0,
		movedPosition.Z - startPosition.Z
	).Magnitude

	local groundDeadline = os.clock() + 2
	while humanoid.FloorMaterial == Enum.Material.Air and os.clock() < groundDeadline do
		RunService.Heartbeat:Wait()
	end

	local jumpStartY = root.Position.Y
	local maxY = jumpStartY
	local maxVerticalVelocity = root.AssemblyLinearVelocity.Y
	local sawJumping = false
	local states = {}
	local stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		states[newState.Name] = true
		if newState == Enum.HumanoidStateType.Jumping then
			sawJumping = true
		end
	end)

	humanoid.Jump = true
	local jumpDeadline = os.clock() + 1.5
	while os.clock() < jumpDeadline and player.Character == character and humanoid.Health > 0 do
		maxY = math.max(maxY, root.Position.Y)
		maxVerticalVelocity = math.max(maxVerticalVelocity, root.AssemblyLinearVelocity.Y)
		RunService.Heartbeat:Wait()
	end
	stateConnection:Disconnect()

	local stateNames = {}
	for stateName in pairs(states) do
		table.insert(stateNames, stateName)
	end
	table.sort(stateNames)
	local offenders = collectPhysicalOffenders(character)
	return {
		HorizontalDisplacement = horizontalDisplacement,
		JumpHeightDelta = maxY - jumpStartY,
		MaxVerticalVelocity = maxVerticalVelocity,
		SawJumping = sawJumping,
		States = stateNames,
		FloorMaterial = humanoid.FloorMaterial.Name,
		AssemblyMass = root.AssemblyMass,
		CollidableParts = offenders.AllCollidable,
	}
end

local function invokeRebirth()
	local playerScripts = player:WaitForChild("PlayerScripts")
	local RemoteClient = require(
		playerScripts:WaitForChild("u"):WaitForChild("ClientInputModules"):WaitForChild("RemoteClient")
	)
	local remoteClient = RemoteClient.Init()
	local transportSuccess, result = remoteClient.SafeInvoke("RequestRebirth")
	return {
		TransportSuccess = transportSuccess,
		ResultSuccess = transportSuccess and type(result) == "table" and result.Success == true,
		Message = transportSuccess and type(result) == "table" and result.Message or tostring(result),
	}
end

local handlers = {
	Inspect = inspectCharacter,
	ExerciseMovementJump = exerciseMovementAndJump,
	InvokeRebirth = invokeRebirth,
}

bridge.OnClientEvent:Connect(function(requestId, command)
	local handler = handlers[command]
	if not handler then
		bridge:FireServer("Response", requestId, false, "unknown client test command: " .. tostring(command))
		return
	end

	local ok, result = xpcall(handler, debug.traceback)
	bridge:FireServer("Response", requestId, ok, result)
end)

bridge:FireServer("Ready")
