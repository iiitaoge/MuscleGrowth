local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if not RunService:IsStudio() then
	return
end

local CharacterBodyVisualTransition = require(
	ServerScriptService
		:WaitForChild("T")
		:WaitForChild("Transitions")
		:WaitForChild("CharacterBodyVisualTransition")
)
local CharacterBodyVisualRules = require(
	ServerScriptService
		:WaitForChild("T")
		:WaitForChild("Rules")
		:WaitForChild("CharacterBodyVisualRules")
)
local LevelRules = require(
	ServerScriptService
		:WaitForChild("T")
		:WaitForChild("Rules")
		:WaitForChild("LevelRules")
)

local applying = {}
local chatConnections = {}

local function assertRigAtLevel(rebirthCount, level)
	local maxLevel = LevelRules.GetMaxLevel(rebirthCount)
	local expectedRigIndex = math.clamp(math.ceil(level / maxLevel * 5), 1, 5)
	local actualRigIndex = CharacterBodyVisualRules.ResolveRigIndex({
		Exp = LevelRules.GetRequiredExp(level),
		RebirthCount = rebirthCount,
	})

	assert(actualRigIndex == expectedRigIndex, ("rebirth=%d level=%d expected=Rig%d actual=Rig%d"):format(
		rebirthCount,
		level,
		expectedRigIndex,
		actualRigIndex
	))
end

local function runRuleTests()
	assert(CharacterBodyVisualRules.ResolveRigIndex({ Exp = 0, RebirthCount = 0 }) == 1, "Exp=0 must use Rig1")

	local firstCycleExpected = {
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 3,
		[6] = 3,
		[7] = 4,
		[8] = 4,
		[9] = 5,
	}
	assert(LevelRules.GetMaxLevel(0) == 10, "First rebirth cycle must have max level 10")
	for level, expectedRigIndex in pairs(firstCycleExpected) do
		local actualRigIndex = CharacterBodyVisualRules.ResolveRigIndex({
			Exp = LevelRules.GetRequiredExp(level),
			RebirthCount = 0,
		})
		assert(actualRigIndex == expectedRigIndex, ("level=%d expected=Rig%d actual=Rig%d"):format(
			level,
			expectedRigIndex,
			actualRigIndex
		))
	end

	for rebirthCount = 0, 2 do
		local maxLevel = LevelRules.GetMaxLevel(rebirthCount)
		for level = 1, maxLevel do
			assertRigAtLevel(rebirthCount, level)
		end
		assert(CharacterBodyVisualRules.ResolveRigIndex({
			Exp = LevelRules.GetMaxExp(rebirthCount),
			RebirthCount = rebirthCount,
		}) == 5, ("rebirth=%d max Exp must use Rig5"):format(rebirthCount))
	end

	print("[CharacterBodyVisualTest] Rule tests passed")
end

local function applyRig(player, character, rigIndex, force)
	if applying[player] or player.Character ~= character then
		return
	end
	applying[player] = true

	local callSucceeded, success, message, appliedCount = pcall(
		CharacterBodyVisualTransition.Apply,
		character,
		rigIndex,
		force
	)
	if not callSucceeded then
		warn(("[CharacterBodyVisualTest] player=%s rig=Rig%d error=%s"):format(
			player.Name,
			rigIndex,
			tostring(success)
		))
	elseif not success then
		warn(("[CharacterBodyVisualTest] player=%s rig=Rig%d error=%s"):format(
			player.Name,
			rigIndex,
			tostring(message)
		))
	else
		print(("[CharacterBodyVisualTest] player=%s rig=Rig%d applied=%d characterPreserved=%s"):format(
			player.Name,
			rigIndex,
			tonumber(appliedCount) or 0,
			tostring(player.Character == character)
		))
	end

	applying[player] = nil
end

local function bindPlayer(player)
	if chatConnections[player] then
		chatConnections[player]:Disconnect()
	end

	chatConnections[player] = player.Chatted:Connect(function(message)
		local rigIndex = tonumber(string.match(string.lower(message), "^!rig%s+([1-5])$"))
		if rigIndex and player.Character then
			applyRig(player, player.Character, rigIndex, false)
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	applying[player] = nil
	local connection = chatConnections[player]
	if connection then
		connection:Disconnect()
		chatConnections[player] = nil
	end
end)

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

runRuleTests()
print("[CharacterBodyVisualTest] Ready. Use chat commands !rig 1 through !rig 5")
