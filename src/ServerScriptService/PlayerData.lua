local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage.Configs
local ConfigServices = ReplicatedStorage.ConfigServices
local Template = ReplicatedStorage.Template

local PlayerDataTemplate = require(Template.PlayerDataTemplate)
local RebirthConfig = require(Configs.RebirthConfig)
local FormulaService = require(ConfigServices.FormulaService)
local LevelService = require(ConfigServices.LevelService)

local PlayerData = {}

local store = {}

local function applyRebirthConfig(playerData)
	local rebirthConfig = RebirthConfig.GetConfig(playerData.RebirthCount)
	if rebirthConfig then
		playerData.MaxLevel = rebirthConfig.MaxLevel
	end
end

function PlayerData.init(player)
	local template = table.clone(PlayerDataTemplate)
	applyRebirthConfig(template)
	store[player] = template
end

function PlayerData.get(player)
	return store[player]
end

function PlayerData.canRebirth(player)
	local playerData = store[player]
	return playerData ~= nil and playerData.Level >= playerData.MaxLevel
end

function PlayerData.getSnapshot(player)
	local playerData = store[player]
	if not playerData then
		return nil
	end

	local snapshot = table.clone(playerData)
	snapshot.CanRebirth = PlayerData.canRebirth(player)
	snapshot.MaxExp = LevelService.GetMaxLevelRequiredExp(playerData.MaxLevel)

	return snapshot
end

function PlayerData.addProgress(player, growthContext)
	local playerData = store[player]
	if not playerData then
		return
	end

	local strengthGain = FormulaService.GetStrengthGain(playerData, growthContext)
	playerData.Strength += strengthGain

	local expGain = FormulaService.GetExpGain(playerData, growthContext)
	LevelService.AddExp(playerData, expGain)
end

function PlayerData.doRebirth(player)
	local playerData = store[player]
	if not playerData then
		return false, "Player data does not exist"
	end

	if not PlayerData.canRebirth(player) then
		return false, "Current max level has not been reached"
	end

	playerData.RebirthCount += 1
	playerData.Strength = 0
	playerData.Exp = 0
	playerData.Level = 1
	applyRebirthConfig(playerData)

	return true, "Rebirth succeeded"
end

function PlayerData.remove(player)
	store[player] = nil
end

return PlayerData
