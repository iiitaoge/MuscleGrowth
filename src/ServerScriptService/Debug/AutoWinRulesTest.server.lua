local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

if not RunService:IsStudio() then
	return
end

local AutoWinRules = require(
	ServerScriptService:WaitForChild("T"):WaitForChild("Rules"):WaitForChild("AutoWinRules")
)
local TestHarness = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("Testing"):WaitForChild("TestHarness"))

local test = TestHarness.New("AutoWinRules")

test:Check("World1 is not a push track", AutoWinRules.GetTrackInfo("World1") == nil)
test:Equal("World2 starts at stage 1", AutoWinRules.GetTrackInfo("World2").FirstStageId, 1)
test:Equal("World3 starts at stage 11", AutoWinRules.GetTrackInfo("World3").FirstStageId, 11)
test:Check("below first World2 threshold has no reachable stage", AutoWinRules.GetHighestReachableStage("World2", 44) == nil)
test:Equal("exact first World2 threshold reaches stage 1", AutoWinRules.GetHighestReachableStage("World2", 45), 1)
test:Equal("exact second World2 threshold reaches stage 2", AutoWinRules.GetHighestReachableStage("World2", 650), 2)
test:Equal("World2 does not cross into World3", AutoWinRules.GetHighestReachableStage("World2", math.huge), 10)
test:Check("below first World3 threshold has no reachable stage", AutoWinRules.GetHighestReachableStage("World3", 449999999) == nil)
test:Equal("exact first World3 threshold reaches stage 11", AutoWinRules.GetHighestReachableStage("World3", 450000000), 11)
test:Equal("World3 reaches its final configured stage", AutoWinRules.GetHighestReachableStage("World3", math.huge), 20)

assert(test:Summary(), "AutoWinRules tests failed.")
