local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local CharacterBodyVisualRules = require(script.Parent.Parent.Rules.CharacterBodyVisualRules)

local CharacterBodyVisualTransition = {}

local MIN_RIG_INDEX = 1
local MAX_RIG_INDEX = 5
local BODY_VISUAL_TIER_ATTRIBUTE = "MuscleGrowthBodyVisualTier"
local BODY_VISUAL_BASE_SIZE_ATTRIBUTE = "MuscleGrowthBodyVisualBaseSize"

local tierCache = {}
local playerConnections = {}
local refreshFailureStates = {}

local function getBodyFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("Body")
end

local function getDirectVisualMeshes(bodyPart)
	local meshes = {}
	for _, child in ipairs(bodyPart:GetChildren()) do
		if child:IsA("MeshPart") then
			table.insert(meshes, child)
		end
	end
	return meshes
end

local function buildTierCache(rigIndex)
	local cached = tierCache[rigIndex]
	if cached then
		return cached
	end

	local bodyFolder = getBodyFolder()
	if not bodyFolder then
		return nil, "ReplicatedStorage/Assets/Body does not exist"
	end

	local rigName = "Rig" .. rigIndex
	local rig = bodyFolder:FindFirstChild(rigName)
	if not rig or not rig:IsA("Model") then
		return nil, "Body template is missing or is not a Model: " .. rigName
	end

	local entries = {}
	local bodyPartNames = {}
	for _, bodyPart in ipairs(rig:GetChildren()) do
		if bodyPart:IsA("BasePart") then
			local visualMeshes = getDirectVisualMeshes(bodyPart)
			if #visualMeshes > 1 then
				return nil, ("%s.%s must contain at most one direct visual MeshPart"):format(
					rigName,
					bodyPart.Name
				)
			end

			local sourceMesh = visualMeshes[1]
			if sourceMesh then
				entries[bodyPart.Name] = {
					SourceMesh = sourceMesh,
					BaseSize = sourceMesh.Size,
					RelativeCFrame = bodyPart.CFrame:ToObjectSpace(sourceMesh.CFrame),
				}
				table.insert(bodyPartNames, bodyPart.Name)
			end
		end
	end

	if #bodyPartNames == 0 then
		return nil, rigName .. " has no nested visual MeshParts"
	end

	table.sort(bodyPartNames)
	cached = {
		RigName = rigName,
		Entries = entries,
		BodyPartNames = bodyPartNames,
	}
	tierCache[rigIndex] = cached
	return cached
end

local function destroyClonedBehavior(visualMesh)
	for _, descendant in ipairs(visualMesh:GetDescendants()) do
		if descendant:IsA("BaseScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("JointInstance")
			or descendant:IsA("Constraint")
			or descendant:IsA("WeldConstraint")
		then
			descendant:Destroy()
		end
	end
end

local function prepareVisualBasePart(part, collisionGroup)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CollisionGroup = collisionGroup
end

local function prepareVisualMesh(visualMesh, bodyPart, entry)
	destroyClonedBehavior(visualMesh)
	prepareVisualBasePart(visualMesh, bodyPart.CollisionGroup)

	for _, descendant in ipairs(visualMesh:GetDescendants()) do
		if descendant:IsA("BasePart") then
			prepareVisualBasePart(descendant, bodyPart.CollisionGroup)
		end
	end

	visualMesh:SetAttribute(BODY_VISUAL_BASE_SIZE_ATTRIBUTE, entry.BaseSize)
	visualMesh.CFrame = bodyPart.CFrame * entry.RelativeCFrame

	local weld = Instance.new("WeldConstraint")
	weld.Name = "BodyVisualWeld"
	weld.Part0 = bodyPart
	weld.Part1 = visualMesh
	weld.Parent = visualMesh
end

local function cleanupPreparedOperations(operations)
	for _, operation in ipairs(operations) do
		if operation.NewVisualMesh then
			operation.NewVisualMesh:Destroy()
		end
	end
end

function CharacterBodyVisualTransition.Apply(character, rigIndex, force)
	if not character or not character:IsA("Model") then
		return false, "Character must be a Model"
	end

	rigIndex = math.floor(tonumber(rigIndex) or 0)
	if rigIndex < MIN_RIG_INDEX or rigIndex > MAX_RIG_INDEX then
		return false, ("Rig index must be between %d and %d"):format(MIN_RIG_INDEX, MAX_RIG_INDEX)
	end

	if force ~= true and character:GetAttribute(BODY_VISUAL_TIER_ATTRIBUTE) == rigIndex then
		return true, "Body visual is already applied", 0
	end

	local tierData, tierError = buildTierCache(rigIndex)
	if not tierData then
		return false, tierError
	end

	local operations = {}
	for _, bodyPartName in ipairs(tierData.BodyPartNames) do
		local bodyPart = character:FindFirstChild(bodyPartName)
		if not bodyPart or not bodyPart:IsA("BasePart") then
			cleanupPreparedOperations(operations)
			return false, "Character is missing body carrier: " .. bodyPartName
		end

		local currentVisualMeshes = getDirectVisualMeshes(bodyPart)
		if #currentVisualMeshes > 1 then
			cleanupPreparedOperations(operations)
			return false, ("Character body carrier %s contains multiple direct visual MeshParts"):format(bodyPartName)
		end

		local entry = tierData.Entries[bodyPartName]
		local cloneSucceeded, newVisualMesh = pcall(function()
			return entry.SourceMesh:Clone()
		end)
		if not cloneSucceeded or not newVisualMesh then
			cleanupPreparedOperations(operations)
			return false, ("Failed to clone %s visual for %s"):format(tierData.RigName, bodyPartName)
		end

		prepareVisualMesh(newVisualMesh, bodyPart, entry)
		table.insert(operations, {
			BodyPart = bodyPart,
			OldVisualMesh = currentVisualMeshes[1],
			NewVisualMesh = newVisualMesh,
		})
	end

	for _, operation in ipairs(operations) do
		operation.NewVisualMesh.Parent = operation.BodyPart
		if operation.OldVisualMesh then
			operation.OldVisualMesh:Destroy()
		end
	end

	character:SetAttribute(BODY_VISUAL_TIER_ATTRIBUTE, rigIndex)
	return true, ("Applied %s nested body visuals"):format(tierData.RigName), #operations
end

local function clearRefreshFailure(player)
	refreshFailureStates[player] = nil
end

local function warnRefreshFailure(player, character, rigIndex, message)
	local previousFailure = refreshFailureStates[player]
	if previousFailure
		and previousFailure.Character == character
		and previousFailure.RigIndex == rigIndex
	then
		return
	end

	refreshFailureStates[player] = {
		Character = character,
		RigIndex = rigIndex,
	}

	warn(("[CharacterBodyVisual] player=%s rig=Rig%d error=%s"):format(
		player.Name,
		rigIndex,
		tostring(message)
	))
end

function CharacterBodyVisualTransition.RefreshPlayer(player, force)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player progress state does not exist"
	end

	local character = player.Character
	if not character then
		return false, "Player character does not exist"
	end

	local rigIndex = CharacterBodyVisualRules.ResolveRigIndex(progressState)
	local callSucceeded, success, message, appliedCount = pcall(
		CharacterBodyVisualTransition.Apply,
		character,
		rigIndex,
		force
	)

	if not callSucceeded then
		warnRefreshFailure(player, character, rigIndex, success)
		return false, tostring(success), 0, rigIndex
	end

	if not success then
		warnRefreshFailure(player, character, rigIndex, message)
		return false, message, appliedCount or 0, rigIndex
	end

	clearRefreshFailure(player)
	if (appliedCount or 0) > 0 then
		print(("[CharacterBodyVisual] player=%s rig=Rig%d applied=%d characterPreserved=%s"):format(
			player.Name,
			rigIndex,
			appliedCount,
			tostring(player.Character == character)
		))
	end

	return true, message, appliedCount or 0, rigIndex
end

local function refreshAddedCharacter(player, character)
	clearRefreshFailure(player)

	task.defer(function()
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and player.Character == character then
			CharacterBodyVisualTransition.RefreshPlayer(player, true)
		end
	end)
end

function CharacterBodyVisualTransition.InitPlayer(player)
	CharacterBodyVisualTransition.RemovePlayer(player)

	playerConnections[player] = player.CharacterAdded:Connect(function(character)
		refreshAddedCharacter(player, character)
	end)

	if player.Character then
		refreshAddedCharacter(player, player.Character)
	end
end

function CharacterBodyVisualTransition.RemovePlayer(player)
	local connection = playerConnections[player]
	if connection then
		connection:Disconnect()
		playerConnections[player] = nil
	end

	clearRefreshFailure(player)
end

function CharacterBodyVisualTransition.ClearCache()
	table.clear(tierCache)
end

return CharacterBodyVisualTransition
