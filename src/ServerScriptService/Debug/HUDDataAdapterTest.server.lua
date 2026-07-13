local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

if not RunService:IsStudio() then
	return
end

local DataAdapter = require(
	StarterPlayer:WaitForChild("StarterPlayerScripts")
		:WaitForChild("T")
		:WaitForChild("HUD")
		:WaitForChild("DataAdapter")
)
local TestHarness = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("Testing"):WaitForChild("TestHarness"))

local test = TestHarness.New("HUDDataAdapter")

local function buildSnapshot(level, maxLevel, exp, maxExp)
	return {
		Strength = 0,
		Trophies = 0,
		RebirthMultiplier = 1,
		BarbellMultiplier = 1,
		PetMultiplier = 1,
		Level = level,
		MaxLevel = maxLevel,
		Exp = exp,
		MaxExp = maxExp,
	}
end

local normalModel = DataAdapter.BuildModel(buildSnapshot(9, 10, 50, 100))
test:Equal("non-max experience stays numeric", normalModel.ExpText, "50/100")
test:Near("non-max experience ratio", normalModel.ExpRatio, 0.5)

local maxModel = DataAdapter.BuildModel(buildSnapshot(10, 10, 100, 100))
test:Equal("max level uses MAX LEVEL text", maxModel.ExpText, "MAX LEVEL")
test:Equal("max level keeps level text", maxModel.LevelText, "Level 10")
test:Equal("max level bar is full", maxModel.ExpRatio, 1)

assert(test:Summary(), "HUDDataAdapter tests failed.")
