-- AutoWinRules
-- 只根据共享关卡配置和玩家力量决定当前赛道可连续到达的最高关卡。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))

local AutoWinRules = {}

function AutoWinRules.GetTrackInfo(trackId)
	local trackConfig = type(PushBallTheta.Tracks) == "table" and PushBallTheta.Tracks[trackId] or nil
	if type(trackId) ~= "string" or type(trackConfig) ~= "table" then
		return nil
	end

	local firstStageId = math.max(1, math.floor(tonumber(trackConfig.FirstStageId) or 0))
	local lastStageId = math.floor(tonumber(trackConfig.LastStageId) or 0)
	if lastStageId < firstStageId then
		return nil
	end

	return {
		TrackId = trackId,
		FirstStageId = firstStageId,
		LastStageId = lastStageId,
		TravelDestinationId = type(trackConfig.TravelDestinationId) == "string"
			and trackConfig.TravelDestinationId
			or trackId,
	}
end

function AutoWinRules.GetHighestReachableStage(trackId, strength)
	local trackInfo = AutoWinRules.GetTrackInfo(trackId)
	if not trackInfo then
		return nil
	end

	local normalizedStrength = math.max(0, tonumber(strength) or 0)
	local highestStageId = nil
	for stageId = trackInfo.FirstStageId, trackInfo.LastStageId do
		local stageConfig = type(StageTheta.Stages) == "table" and StageTheta.Stages[stageId] or nil
		local requiredStrength = tonumber(stageConfig and stageConfig.RecommendedStrength)
		if not requiredStrength or normalizedStrength < requiredStrength then
			break
		end

		highestStageId = stageId
	end

	return highestStageId
end

return AutoWinRules
