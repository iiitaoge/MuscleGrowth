local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterBodyVisualTransition = require(
	ServerScriptService
		:WaitForChild("T")
		:WaitForChild("Transitions")
		:WaitForChild("CharacterBodyVisualTransition")
)

local DEFAULT_RIG_INDEX = 1
local applying = {}

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

local function bindCharacter(player, character)
	task.defer(function()
		if character:WaitForChild("Humanoid", 5) and player.Character == character then
			applyRig(player, character, DEFAULT_RIG_INDEX, true)
		end
	end)
end

local function bindPlayer(player)
	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)

	player.Chatted:Connect(function(message)
		local rigIndex = tonumber(string.match(string.lower(message), "^!rig%s+([1-5])$"))
		if rigIndex and player.Character then
			applyRig(player, player.Character, rigIndex, false)
		end
	end)

	if player.Character then
		bindCharacter(player, player.Character)
	end
end

Players.PlayerRemoving:Connect(function(player)
	applying[player] = nil
end)

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

print("[CharacterBodyVisualTest] Ready. Use chat commands !rig 1 through !rig 5")
