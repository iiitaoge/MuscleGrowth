local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() or Workspace:GetAttribute("RunCharacterMorphTests") ~= true then
	return
end

local TestHarness = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("Testing"):WaitForChild("TestHarness"))
local CharacterMorphTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("CharacterMorphTheta")
)
local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)
local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.S.TrainingRuntimeState)
local CharacterMorphRules = require(script.Parent.Parent.T.Rules.CharacterMorphRules)
local LevelRules = require(script.Parent.Parent.T.Rules.LevelRules)
local CharacterMorphTransition = require(script.Parent.Parent.T.Transitions.CharacterMorphTransition)
local PushBallTransition = require(script.Parent.Parent.T.Transitions.PushBallTransition)
local TrainingTransition = require(script.Parent.Parent.T.Transitions.TrainingTransition)
local PlayerVisualStateSync = require(script.Parent.Parent.T.WorldSync.PlayerVisualStateSync)

local BRIDGE_NAME = "MG_CharacterMorphTestBridge"
local harness = TestHarness.New("CharacterMorph")
local bridge = Instance.new("RemoteEvent")
bridge.Name = BRIDGE_NAME
bridge.Parent = ReplicatedStorage
harness:AddCleanup(function()
	bridge:Destroy()
end)

local readyPlayers = setmetatable({}, { __mode = "k" })
local requestSerial = 0
local inspectionSerial = 0
local responses = {}
local selectedPlayer

local bridgeConnection = bridge.OnServerEvent:Connect(function(player, messageType, requestId, success, result)
	if selectedPlayer and player ~= selectedPlayer then
		return
	end
	if messageType == "Ready" then
		readyPlayers[player] = true
	elseif messageType == "Response" and type(requestId) == "number" then
		responses[requestId] = {
			Success = success == true,
			Result = result,
		}
	end
end)
harness:AddCleanup(function()
	bridgeConnection:Disconnect()
end)

local function joinList(values)
	if type(values) ~= "table" or #values == 0 then
		return "none"
	end
	return table.concat(values, ", ")
end

local function runCase(name, callback)
	local ok, result, detail = xpcall(callback, debug.traceback)
	if not ok then
		harness:Fail(name, result)
	elseif result == nil or result == true then
		harness:Pass(name, detail)
	elseif result == false then
		harness:Fail(name, detail)
	end
end

local function waitForPlayer()
	local requestedUserId = tonumber(Workspace:GetAttribute("CharacterMorphTestUserId"))
	local deadline = os.clock() + 30
	repeat
		if requestedUserId then
			for _, player in ipairs(Players:GetPlayers()) do
				if player.UserId == requestedUserId then
					return player
				end
			end
		else
			local player = Players:GetPlayers()[1]
			if player then
				return player
			end
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return nil
end

local function requestClient(command, timeoutSeconds)
	if not readyPlayers[selectedPlayer] then
		return false, "client observer is not ready"
	end
	requestSerial += 1
	local requestId = requestSerial
	bridge:FireClient(selectedPlayer, requestId, command)

	local deadline = os.clock() + (timeoutSeconds or 8)
	repeat
		local response = responses[requestId]
		if response then
			responses[requestId] = nil
			return response.Success, response.Result
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return false, "client command timed out: " .. command
end

local function inspectCurrentClient(timeoutSeconds)
	local character = selectedPlayer and selectedPlayer.Character
	if not character then
		return false, "server player has no current Character"
	end
	inspectionSerial += 1
	local token = inspectionSerial
	character:SetAttribute("MorphTestCharacterToken", token)

	local deadline = os.clock() + (timeoutSeconds or 3)
	local lastResult = "client has not observed the current server Character"
	repeat
		local ok, result = requestClient("Inspect", 2)
		if ok and type(result) == "table" then
			lastResult = result
			if result.TestCharacterToken == token then
				return true, result
			end
		elseif not ok then
			return false, result
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return false, lastResult
end

local function resolveTemplateFolder()
	local current = ReplicatedStorage
	for _, childName in ipairs(CharacterMorphTheta.TemplateFolderPath or {}) do
		current = current and current:FindFirstChild(childName)
	end
	return current
end

local function setLevel(player, level, rebirthCount)
	local state = PlayerProgressState.Get(player)
	assert(state, "player progress state does not exist")
	state.RebirthCount = rebirthCount or 0
	state.Exp = level <= 1 and 0 or LevelRules.GetRequiredExp(level)
	PlayerProgressState.Set(player, state)
end

local function refreshAndWait(player, expectedRigIndex, expectedScale, force)
	local deadline = os.clock() + 8
	local lastMessage = "refresh did not run"
	repeat
		local success, message = CharacterMorphTransition.Refresh(player, force == true)
		lastMessage = message or tostring(success)
		local character = player.Character
		if success and character
			and character:GetAttribute("MuscleGrowthRigIndex") == expectedRigIndex
			and math.abs((tonumber(character:GetAttribute("MuscleGrowthRigScale")) or 0) - expectedScale) <= 0.001
		then
			return true
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return false, lastMessage
end

local function createTraditionalRigSample(template)
	local sample = template:Clone()
	sample.Name = "TraditionalMotor6DSample"
	for _, descendant in ipairs(sample:GetDescendants()) do
		if descendant:IsA("AnimationConstraint") then
			descendant:Destroy()
		end
	end

	local jointPairs = {
		{ "Root", "HumanoidRootPart", "LowerTorso" },
		{ "Waist", "LowerTorso", "UpperTorso" },
		{ "Neck", "UpperTorso", "Head" },
		{ "LeftShoulder", "UpperTorso", "LeftUpperArm" },
		{ "LeftElbow", "LeftUpperArm", "LeftLowerArm" },
		{ "LeftWrist", "LeftLowerArm", "LeftHand" },
		{ "RightShoulder", "UpperTorso", "RightUpperArm" },
		{ "RightElbow", "RightUpperArm", "RightLowerArm" },
		{ "RightWrist", "RightLowerArm", "RightHand" },
		{ "LeftHip", "LowerTorso", "LeftUpperLeg" },
		{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg" },
		{ "LeftAnkle", "LeftLowerLeg", "LeftFoot" },
		{ "RightHip", "LowerTorso", "RightUpperLeg" },
		{ "RightKnee", "RightUpperLeg", "RightLowerLeg" },
		{ "RightAnkle", "RightLowerLeg", "RightFoot" },
	}
	for _, spec in ipairs(jointPairs) do
		local part0 = sample:FindFirstChild(spec[2])
		local part1 = sample:FindFirstChild(spec[3])
		local motor = Instance.new("Motor6D")
		motor.Name = spec[1]
		motor.Part0 = part0
		motor.Part1 = part1
		motor.Parent = part0
	end
	return sample
end

local function assertClientBasics(label)
	local ok, snapshot = inspectCurrentClient(3)
	if not ok then
		harness:Fail(label .. " client inspection", snapshot)
		return nil
	end
	harness:Check(
		label .. " camera follows current Humanoid",
		snapshot.SubjectIsCurrentHumanoid == true,
		("subject=%s current=%s identity=%s"):format(
			tostring(snapshot.CameraSubjectPath),
			tostring(snapshot.HumanoidPath),
			tostring(snapshot.HumanoidIdentity)
		)
	)
	harness:Equal(label .. " CameraType", snapshot.CameraType, "Custom")
	harness:Equal(label .. " CameraMode", snapshot.CameraMode, "Classic")
	harness:Check(
		label .. " Humanoid RootPart is valid",
		snapshot.HumanoidRootPartPath ~= "nil",
		"RootPart=" .. tostring(snapshot.HumanoidRootPartPath)
	)
	harness:Equal(label .. " PrimaryPart matches Humanoid RootPart", snapshot.PrimaryPartPath, snapshot.HumanoidRootPartPath)
	harness:Check(
		label .. " mouse is not permanently locked",
		snapshot.MouseBehavior ~= "LockCenter",
		"MouseBehavior=" .. tostring(snapshot.MouseBehavior)
	)
	harness:Check(label .. " mouse icon is visible", snapshot.MouseIconEnabled == true)
	return snapshot
end

local function assertPhysicalPolicy(label, snapshot)
	harness:Check(label .. " HumanoidRootPart is non-collidable", snapshot.RootCanCollide == false)
	harness:Check(
		label .. " nested visual parts CanCollide=false",
		#snapshot.NestedCanCollide == 0,
		joinList(snapshot.NestedCanCollide)
	)
	harness:Check(
		label .. " nested visual parts CanTouch=false",
		#snapshot.NestedCanTouch == 0,
		joinList(snapshot.NestedCanTouch)
	)
	harness:Check(
		label .. " nested visual parts CanQuery=false",
		#snapshot.NestedCanQuery == 0,
		joinList(snapshot.NestedCanQuery)
	)
	harness:Check(
		label .. " nested visual parts Massless=true",
		#snapshot.NestedNotMassless == 0,
		joinList(snapshot.NestedNotMassless)
	)
	harness:Check(
		label .. " AutomaticScalingEnabled follows custom ScaleTo policy",
		snapshot.AutomaticScalingEnabled == false,
		"AutomaticScalingEnabled=" .. tostring(snapshot.AutomaticScalingEnabled)
	)
end

local function assertMovementAndJump(label)
	local ok, result = requestClient("ExerciseMovementJump", 12)
	if not ok then
		harness:Fail(label .. " movement/jump command", result)
		return
	end
	local diagnostics = ("displacement=%.3f floor=%s mass=%.3f collidable=%s"):format(
		result.HorizontalDisplacement or 0,
		tostring(result.FloorMaterial),
		result.AssemblyMass or 0,
		joinList(result.CollidableParts)
	)
	harness:Check(label .. " horizontal movement", (result.HorizontalDisplacement or 0) >= 0.5, diagnostics)
	harness:Check(
		label .. " enters Jumping state",
		result.SawJumping == true,
		"states=" .. joinList(result.States) .. " " .. diagnostics
	)
	harness:Check(
		label .. " produces upward movement",
		(result.JumpHeightDelta or 0) >= 0.5 or (result.MaxVerticalVelocity or 0) >= 2,
		("height=%.3f velocity=%.3f %s"):format(
			result.JumpHeightDelta or 0,
			result.MaxVerticalVelocity or 0,
			diagnostics
		)
	)
end

local function executeTests()
	selectedPlayer = waitForPlayer()
	if not selectedPlayer then
		harness:Fail("select test player", "no matching player joined within 30 seconds")
		return
	end

	harness:Eventually("player progress initialized", function()
		return PlayerProgressState.Get(selectedPlayer) ~= nil
	end, 15)
	harness:Eventually("player character initialized", function()
		return selectedPlayer.Character ~= nil and selectedPlayer.Character:FindFirstChildOfClass("Humanoid") ~= nil
	end, 15)
	harness:Eventually("client observer ready", function()
		return readyPlayers[selectedPlayer] == true
	end, 15)

	local originalProgress = PlayerProgressState.Get(selectedPlayer)
	local originalRuntime = TrainingRuntimeState.Get(selectedPlayer)
	local originalDestination = selectedPlayer:GetAttribute("CurrentDestinationId")
	local originalPivot = selectedPlayer.Character and selectedPlayer.Character:GetPivot()
	if not originalProgress or not selectedPlayer.Character then
		harness:Fail("capture original player state", "progress or character is unavailable")
		return
	end

	harness:AddCleanup(function()
		if not selectedPlayer.Parent then
			return
		end
		PlayerProgressState.Set(selectedPlayer, originalProgress)
		if originalRuntime and (originalRuntime.MoveRequested == true or originalRuntime.CurrentAutoAreaId ~= nil) then
			originalRuntime.GrowthLoopActive = false
			originalRuntime.NextGrowthAt = nil
		end
		TrainingRuntimeState.Set(selectedPlayer, originalRuntime)
		selectedPlayer:SetAttribute("CurrentDestinationId", originalDestination)
		PlayerVisualStateSync.Refresh(selectedPlayer)
		CharacterMorphTransition.Refresh(selectedPlayer, true)
		if originalPivot and selectedPlayer.Character then
			selectedPlayer.Character:PivotTo(originalPivot)
		end
		if originalRuntime and (originalRuntime.MoveRequested == true or originalRuntime.CurrentAutoAreaId ~= nil) then
			TrainingTransition.RefreshGrowth(selectedPlayer)
		end
	end)
	PushBallTransition.RequestStop(selectedPlayer)
	TrainingTransition.ResetActivity(selectedPlayer)

	for _, case in ipairs({
		{ 1, 10, 1 }, { 2, 10, 1 }, { 3, 10, 2 }, { 4, 10, 2 }, { 5, 10, 3 },
		{ 6, 10, 3 }, { 7, 10, 4 }, { 8, 10, 4 }, { 9, 10, 5 }, { 10, 10, 5 },
		{ 1, 15, 1 }, { 3, 15, 1 }, { 4, 15, 2 }, { 6, 15, 2 }, { 7, 15, 3 },
		{ 9, 15, 3 }, { 10, 15, 4 }, { 12, 15, 4 }, { 13, 15, 5 }, { 15, 15, 5 },
	}) do
		harness:Equal(
			("phase level=%d max=%d"):format(case[1], case[2]),
			CharacterMorphRules.ResolveRigIndex(case[1], case[2], 5),
			case[3]
		)
	end

	harness:Near("phase scale Rig1", CharacterMorphRules.ResolveScale(0, 1), 1, 0.0001)
	harness:Near("phase scale Rig5", CharacterMorphRules.ResolveScale(0, 5), 1.2, 0.0001)
	harness:Near("rebirth base scale", CharacterMorphRules.ResolveScale(1, 1), 1.05, 0.0001)
	harness:Near("scale upper bound", CharacterMorphRules.ResolveScale(1000, 5), 2.5, 0.0001)
	local resolvedAppearance, appearanceError = CharacterMorphRules.ResolveAppearance({
		Exp = LevelRules.GetRequiredExp(7),
		RebirthCount = 0,
	})
	harness:Check(
		"ResolveAppearance uses production LevelRules",
		resolvedAppearance ~= nil
			and resolvedAppearance.Level == 7
			and resolvedAppearance.RigIndex == 4
			and math.abs(resolvedAppearance.Scale - 1.15) <= 0.0001,
		appearanceError
	)

	local templateFolder = resolveTemplateFolder()
	local templatesValid = templateFolder ~= nil
	harness:Check("template folder exists", templatesValid, "ReplicatedStorage/Assets/Body")
	if templatesValid then
		for index, rigName in ipairs(CharacterMorphTheta.RigNames) do
			local template = templateFolder:FindFirstChild(rigName)
			local valid, validationError, mode = CharacterMorphRules.ValidateRigTemplate(template, rigName)
			harness:Check(
				("%s template validation"):format(rigName),
				valid,
				valid and ("mode=" .. tostring(mode)) or validationError
			)
			if not valid then
				templatesValid = false
			end
			if template then
				harness:Equal(rigName .. " PrimaryPart", template.PrimaryPart and template.PrimaryPart.Name, "HumanoidRootPart")
				harness:Equal(rigName .. " phase index", index, tonumber(rigName:match("%d+$")))
			end
		end
	end

	local sourceTemplate = templateFolder and templateFolder:FindFirstChild("Rig1")
	if sourceTemplate then
		runCase("missing AnimationConstraint is rejected", function()
			local sample = sourceTemplate:Clone()
			local constraint = sample:FindFirstChildWhichIsA("AnimationConstraint", true)
			constraint:Destroy()
			local valid = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid == false
		end)
		runCase("duplicate AnimationConstraint is rejected", function()
			local sample = sourceTemplate:Clone()
			local constraints = {}
			for _, descendant in ipairs(sample:GetDescendants()) do
				if descendant:IsA("AnimationConstraint") then
					table.insert(constraints, descendant)
				end
			end
			local duplicate = constraints[1]:Clone()
			duplicate.Parent = constraints[1].Parent
			constraints[2]:Destroy()
			local valid = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid == false
		end)
		runCase("disabled AnimationConstraint is rejected", function()
			local sample = sourceTemplate:Clone()
			local constraint = sample:FindFirstChildWhichIsA("AnimationConstraint", true)
			constraint.Enabled = false
			local valid = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid == false
		end)
		runCase("missing Attachment is rejected", function()
			local sample = sourceTemplate:Clone()
			local constraint = sample:FindFirstChildWhichIsA("AnimationConstraint", true)
			constraint.Attachment0 = nil
			local valid = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid == false
		end)
		runCase("mixed joints are rejected", function()
			local sample = sourceTemplate:Clone()
			local motor = Instance.new("Motor6D")
			motor.Part0 = sample.HumanoidRootPart
			motor.Part1 = sample.LowerTorso
			motor.Parent = sample.HumanoidRootPart
			local valid = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid == false
		end)
		runCase("traditional Motor6D R15 is accepted", function()
			local sample = createTraditionalRigSample(sourceTemplate)
			local valid, validationError, mode = CharacterMorphRules.ValidateRigTemplate(sample, sample.Name)
			sample:Destroy()
			return valid and mode == "Motor6D", validationError or ("mode=" .. tostring(mode))
		end)
	else
		harness:Skip("damaged-template validation", "Rig1 is missing")
	end

	if not templatesValid then
		harness:Skip("character replacement chain", "template preflight failed")
		return
	end

	local levelCases = {
		{ Level = 1, Rig = 1, Scale = 1 },
		{ Level = 3, Rig = 2, Scale = 1.05 },
		{ Level = 5, Rig = 3, Scale = 1.1 },
		{ Level = 7, Rig = 4, Scale = 1.15 },
		{ Level = 9, Rig = 5, Scale = 1.2 },
	}
	local previousClientHumanoidIdentity
	for _, case in ipairs(levelCases) do
		setLevel(selectedPlayer, case.Level, 0)
		local refreshed, refreshError = refreshAndWait(selectedPlayer, case.Rig, case.Scale, false)
		harness:Check(
			("real replacement Level %d -> Rig%d"):format(case.Level, case.Rig),
			refreshed,
			refreshError
		)
		local inspectOk, levelSnapshot = inspectCurrentClient(3)
		if inspectOk then
			harness:Check(
				("Level %d camera follows replacement Humanoid"):format(case.Level),
				levelSnapshot.SubjectIsCurrentHumanoid == true,
				("subject=%s current=%s oldIdentity=%s newIdentity=%s"):format(
					tostring(levelSnapshot.CameraSubjectPath),
					tostring(levelSnapshot.HumanoidPath),
					tostring(previousClientHumanoidIdentity),
					tostring(levelSnapshot.HumanoidIdentity)
				)
			)
			harness:Equal(("Level %d client RigIndex"):format(case.Level), levelSnapshot.MorphRigIndex, case.Rig)
			harness:Near(("Level %d client Scale"):format(case.Level), levelSnapshot.MorphScale, case.Scale, 0.001)
			if previousClientHumanoidIdentity then
				harness:Check(
					("Level %d uses a new Humanoid identity"):format(case.Level),
					levelSnapshot.HumanoidIdentity ~= previousClientHumanoidIdentity,
					("old=%s new=%s"):format(previousClientHumanoidIdentity, levelSnapshot.HumanoidIdentity)
				)
			end
			previousClientHumanoidIdentity = levelSnapshot.HumanoidIdentity
		else
			harness:Fail(("Level %d client inspection"):format(case.Level), levelSnapshot)
		end
	end

	setLevel(selectedPlayer, 1, 0)
	refreshAndWait(selectedPlayer, 1, 1, false)
	local phaseCharacter = selectedPlayer.Character
	setLevel(selectedPlayer, 2, 0)
	local samePhaseSuccess = CharacterMorphTransition.Refresh(selectedPlayer, false)
	harness:Check("same phase does not replace Character", samePhaseSuccess and selectedPlayer.Character == phaseCharacter)

	local initialSnapshot = assertClientBasics("replacement")
	if initialSnapshot then
		assertPhysicalPolicy("replacement", initialSnapshot)
	end
	assertMovementAndJump("replacement")

	setLevel(selectedPlayer, 5, 0)
	refreshAndWait(selectedPlayer, 3, 1.1, false)
	local killedCharacter = selectedPlayer.Character
	local killedHumanoid = killedCharacter and killedCharacter:FindFirstChildOfClass("Humanoid")
	local preDeathInspectOk, preDeathSnapshot = inspectCurrentClient(3)
	if killedHumanoid then
		killedHumanoid.Health = 0
		harness:Eventually("death creates and morphs a new Character", function()
			local character = selectedPlayer.Character
			return character ~= nil
				and character ~= killedCharacter
				and character:GetAttribute("MuscleGrowthRigIndex") == 3
				and character:FindFirstChildOfClass("Humanoid") ~= nil
		end, 20, 0.1)
		local postDeathSnapshot = assertClientBasics("post-death")
		if preDeathInspectOk and postDeathSnapshot then
			harness:Check(
				"death changes client Humanoid identity",
				preDeathSnapshot.HumanoidIdentity ~= postDeathSnapshot.HumanoidIdentity,
				("old=%s new=%s"):format(preDeathSnapshot.HumanoidIdentity, postDeathSnapshot.HumanoidIdentity)
			)
		end
	else
		harness:Fail("death lifecycle", "current character has no Humanoid")
	end

	local maxState = PlayerProgressState.Get(selectedPlayer)
	maxState.RebirthCount = 0
	maxState.Exp = LevelRules.GetMaxExp(0)
	maxState.Strength = math.max(tonumber(maxState.Strength) or 0, 1)
	PlayerProgressState.Set(selectedPlayer, maxState)
	refreshAndWait(selectedPlayer, 5, 1.2, false)
	local preRebirthInspectOk, preRebirthSnapshot = inspectCurrentClient(3)
	local rebirthCallOk, rebirthResult = requestClient("InvokeRebirth", 15)
	harness:Check(
		"RequestRebirth transport and EventBus result",
		rebirthCallOk and rebirthResult.TransportSuccess == true and rebirthResult.ResultSuccess == true,
		rebirthCallOk and tostring(rebirthResult.Message) or tostring(rebirthResult)
	)
	harness:Eventually("rebirth progress and Rig1 applied", function()
		local state = PlayerProgressState.Get(selectedPlayer)
		local character = selectedPlayer.Character
		return state and state.RebirthCount == 1 and state.Exp == 0
			and character and character:GetAttribute("MuscleGrowthRigIndex") == 1
			and math.abs((tonumber(character:GetAttribute("MuscleGrowthRigScale")) or 0) - 1.05) <= 0.001
	end, 10)
	harness:Equal("rebirth destination attribute", selectedPlayer:GetAttribute("CurrentDestinationId"), "World1")

	local world1Config = TravelDestinationTheta.Destinations.World1
	local world1Spawn = world1Config and InstancePath.FindSpec({ Workspace = Workspace }, world1Config.PathSpec)
	if world1Spawn and selectedPlayer.Character then
		local expectedPosition = world1Spawn.Position + Vector3.new(0, world1Config.OffsetY or 5, 0)
		local actualPosition = selectedPlayer.Character:GetPivot().Position
		harness:Check(
			"rebirth teleports to World1Spawn",
			(actualPosition - expectedPosition).Magnitude <= 12,
			("distance=%.3f"):format((actualPosition - expectedPosition).Magnitude)
		)
	else
		harness:Skip("rebirth teleports to World1Spawn", "World1Spawn is missing")
	end

	local rebirthSnapshot = assertClientBasics("post-rebirth")
	if preRebirthInspectOk and rebirthSnapshot then
		harness:Check(
			"rebirth changes client Humanoid identity",
			preRebirthSnapshot.HumanoidIdentity ~= rebirthSnapshot.HumanoidIdentity,
			("old=%s new=%s"):format(preRebirthSnapshot.HumanoidIdentity, rebirthSnapshot.HumanoidIdentity)
		)
	end
	if rebirthSnapshot then
		assertPhysicalPolicy("post-rebirth", rebirthSnapshot)
	end
	assertMovementAndJump("post-rebirth")
end

local ok, err = xpcall(executeTests, debug.traceback)
if not ok then
	harness:Fail("suite execution", err)
end
harness:RunCleanups()
harness:Summary()
