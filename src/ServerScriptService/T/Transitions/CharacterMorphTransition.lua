local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local CharacterMorphTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("CharacterMorphTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local CharacterMorphRules = require(script.Parent.Parent.Rules.CharacterMorphRules)

local CharacterMorphTransition = {}

local IS_MORPH_ATTRIBUTE = "MuscleGrowthCharacterMorph"
local RIG_INDEX_ATTRIBUTE = "MuscleGrowthRigIndex"
local RIG_SCALE_ATTRIBUTE = "MuscleGrowthRigScale"
local SCALE_EPSILON = 0.0001

local playerStates = {}

local function resolveTemplateFolder()
	local current = ReplicatedStorage
	for _, childName in ipairs(CharacterMorphTheta.TemplateFolderPath or {}) do
		if type(childName) ~= "string" or childName == "" then
			return nil, "Character morph template path contains an invalid child name"
		end

		current = current:FindFirstChild(childName)
		if not current then
			return nil, "Missing character morph template folder: ReplicatedStorage/"
				.. table.concat(CharacterMorphTheta.TemplateFolderPath, "/")
		end
	end

	return current
end

local function resolveAppearance(player)
	return CharacterMorphRules.ResolveAppearance(PlayerProgressState.Get(player))
end

local function isCurrentAppearance(character, appearance)
	return character
		and character:GetAttribute(IS_MORPH_ATTRIBUTE) == true
		and character:GetAttribute(RIG_INDEX_ATTRIBUTE) == appearance.RigIndex
		and math.abs((tonumber(character:GetAttribute(RIG_SCALE_ATTRIBUTE)) or 0) - appearance.Scale) <= SCALE_EPSILON
end

local function getCharacterPivot(character)
	if not character or not character:IsA("Model") then
		return CFrame.new(0, 5, 0)
	end

	local success, pivot = pcall(character.GetPivot, character)
	return success and pivot or CFrame.new(0, 5, 0)
end

local function prepareCharacter(character, player, appearance)
	character.Name = player.Name
	character:SetAttribute(IS_MORPH_ATTRIBUTE, true)
	character:SetAttribute(RIG_INDEX_ATTRIBUTE, appearance.RigIndex)
	character:SetAttribute(RIG_SCALE_ATTRIBUTE, appearance.Scale)

	local root = character:FindFirstChild("HumanoidRootPart")
	character.PrimaryPart = root
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
	root.CanCollide = false

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = player.DisplayName

	local success, err = pcall(character.ScaleTo, character, appearance.Scale)
	if not success then
		return false, "Failed to scale character morph " .. appearance.RigName .. ": " .. tostring(err)
	end

	return true
end


local function replaceCharacter(player, appearance)
	local templateFolder, folderError = resolveTemplateFolder()
	if not templateFolder then
		return false, folderError
	end

	local template = templateFolder:FindFirstChild(appearance.RigName)
	local valid, validationError = CharacterMorphRules.ValidateRigTemplate(template, appearance.RigName)
	if not valid then
		return false, validationError
	end

	local oldCharacter = player.Character
	if not oldCharacter then
		return false, "Player has no character to replace: " .. player.Name
	end

	local oldPivot = getCharacterPivot(oldCharacter)
	local oldHumanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
	if oldHumanoid then
		oldHumanoid:UnequipTools()
	end

	local newCharacter = template:Clone()
	if not newCharacter then
		return false, "Failed to clone character morph template: " .. appearance.RigName
	end
	local prepared, prepareError = prepareCharacter(newCharacter, player, appearance)
	if not prepared then
		newCharacter:Destroy()
		return false, prepareError
	end

	newCharacter:PivotTo(oldPivot)
	newCharacter.Parent = Workspace
	player.Character = newCharacter
	oldCharacter:Destroy()

	return true
end


function CharacterMorphTransition.Refresh(player, force)
	local runtimeState = playerStates[player]
	if not runtimeState then
		return false, "Character morph player state is not initialized"
	end
	if runtimeState.Replacing then
		return false, "Character morph replacement is already in progress"
	end

	local appearance, appearanceError = resolveAppearance(player)
	if not appearance then
		return false, appearanceError
	end
	if force ~= true and isCurrentAppearance(player.Character, appearance) then
		return true
	end

	runtimeState.Replacing = true
	local callSucceeded, success, message = pcall(replaceCharacter, player, appearance)
	runtimeState.Replacing = false
	if not callSucceeded then
		message = "Unexpected character morph replacement error: " .. tostring(success)
		success = false
	end
	if not success then
		warn(("[CharacterMorph] player=%s error=%s"):format(player.Name, tostring(message)))
	end

	return success, message
end


function CharacterMorphTransition.InitPlayer(player)
	if playerStates[player] then
		return
	end

	local runtimeState = {
		Replacing = false,
		Connections = {},
	}
	playerStates[player] = runtimeState

	table.insert(runtimeState.Connections, player.CharacterAdded:Connect(function(character)
		if character:GetAttribute(IS_MORPH_ATTRIBUTE) == true then
			return
		end

		task.defer(function()
			if playerStates[player] == runtimeState and player.Character == character then
				CharacterMorphTransition.Refresh(player, true)
			end
		end)
	end))

	if player.Character and player.Character:GetAttribute(IS_MORPH_ATTRIBUTE) ~= true then
		task.defer(function()
			if playerStates[player] == runtimeState then
				CharacterMorphTransition.Refresh(player, true)
			end
		end)
	end
end


function CharacterMorphTransition.RemovePlayer(player)
	local runtimeState = playerStates[player]
	if not runtimeState then
		return
	end

	for _, connection in ipairs(runtimeState.Connections or {}) do
		connection:Disconnect()
	end
	playerStates[player] = nil
end

return CharacterMorphTransition
