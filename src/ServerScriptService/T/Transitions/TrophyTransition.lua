local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PushBallTransition = require(script.Parent.PushBallTransition)
local TransitionResult = require(script.Parent.TransitionResult)
local TrophyWorldSync = require(script.Parent.Parent.WorldSync.TrophyWorldSync)

local theta = ReplicatedStorage:WaitForChild("theta")
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))
local TrophyTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("TrophyTheta"))

local TravelTransition = require(script.Parent.TravelTransition)

local TrophyTransition = {}

local TOUCH_COOLDOWN_SECONDS = 1

local touchDebounceByPlayer = setmetatable({}, {
	__mode = "k",
})

-- 给玩家增加指定数量的奖杯（以后这个函数只能作为一些拥有完整验证机制函数的内部函数，比如充值，地图奖励）
function TrophyTransition.AddTrophies(player, amount)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.Trophies = math.max(0, (tonumber(nextProgressState.Trophies) or 0) + (tonumber(amount) or 0))
	PlayerProgressState.Set(player, nextProgressState)

	return true
end

local function canTouchNow(player)
	local now = os.clock()
	local lastTouchTime = touchDebounceByPlayer[player]

	if lastTouchTime and now - lastTouchTime < TOUCH_COOLDOWN_SECONDS then
		return false
	end

	touchDebounceByPlayer[player] = now
	return true
end

local function getStageReturnConfig(stageReturnId, fallbackConfig)
	if type(fallbackConfig) == "table" then
		return fallbackConfig
	end

	local stageReturns = TrophyTheta.StageReturns
	return type(stageReturns) == "table" and stageReturns[stageReturnId] or nil
end

local function getStageReturnByStageId(stageId)
	local normalizedStageId = math.floor(tonumber(stageId) or 0)
	for stageReturnId, stageReturnConfig in pairs(TrophyTheta.StageReturns or {}) do
		if type(stageReturnConfig) == "table"
			and math.floor(tonumber(stageReturnConfig.StageId) or 0) == normalizedStageId
		then
			return stageReturnId, stageReturnConfig
		end
	end

	return nil, nil
end

local function getStageReward(stageId)
	local stageConfig = type(StageTheta.Stages) == "table" and StageTheta.Stages[stageId] or nil
	return math.max(0, tonumber(stageConfig and stageConfig.RewardTrophies) or 0)
end

local function teleportToDestination(player, destinationId)
	if type(destinationId) ~= "string" or destinationId == "" then
		return TransitionResult.New(false, "Missing trophy return destination")
	end

	local result = TravelTransition.Request(player, destinationId)
	if result.Success == false and result.Message then
		warn(result.Message)
	end
	return result
end

local function claimStageReward(player, stageReturnId, stageReturnConfig, returnType, returnConfig)
	local resolvedStageReturnConfig = getStageReturnConfig(stageReturnId, stageReturnConfig)
	if type(resolvedStageReturnConfig) ~= "table" then
		return TransitionResult.New(false, "Invalid trophy return")
	end

	local stageId = math.floor(tonumber(resolvedStageReturnConfig.StageId) or 0)
	local resolvedReturnConfig = type(returnConfig) == "table" and returnConfig or resolvedStageReturnConfig[returnType]
	if stageId <= 0 or type(resolvedReturnConfig) ~= "table" then
		return TransitionResult.New(false, "Invalid trophy return type", {
			StageId = stageId,
		})
	end

	local rewardMultiplier = math.max(0, tonumber(resolvedReturnConfig.RewardMultiplier) or 1)
	local rewardWasClaimable = stageId > 0 and PushBallTransition.ConsumeClaimableStageReward(player, stageId)
	warn(
		("[TrophyClaim] player=%s return=%s type=%s stage=%s claimable=%s multiplier=%s"):format(
			player.Name,
			tostring(stageReturnId),
			tostring(returnType),
			tostring(stageId),
			tostring(rewardWasClaimable),
			tostring(rewardMultiplier)
		)
	)

	if not rewardWasClaimable then
		return TransitionResult.New(false, "Stage reward is not claimable", {
			StageId = stageId,
			RewardTrophies = 0,
		})
	end

	local rewardTrophies = getStageReward(stageId) * rewardMultiplier
	local rewardAdded = rewardTrophies <= 0 or TrophyTransition.AddTrophies(player, rewardTrophies)
	warn(
		("[TrophyReward] player=%s stage=%s amount=%s added=%s"):format(
			player.Name,
			tostring(stageId),
			tostring(rewardTrophies),
			tostring(rewardAdded)
		)
	)

	return TransitionResult.New(rewardAdded, rewardAdded and "Stage reward claimed" or "Unable to add trophies", {
		StageId = stageId,
		RewardTrophies = rewardTrophies,
		TravelDestinationId = resolvedStageReturnConfig.TravelDestinationId,
	})
end

local function onStageReturnTouched(player, stageReturnId, stageReturnConfig, returnType, returnConfig)
	if not player then
		return
	end
	if player:GetAttribute(SceneTheta.Attributes.IsAutoWinEnabled) == true then
		return
	end
	if not canTouchNow(player) then
		return
	end

	local resolvedStageReturnConfig = getStageReturnConfig(stageReturnId, stageReturnConfig)
	if type(resolvedStageReturnConfig) ~= "table" then
		return
	end

	claimStageReward(player, stageReturnId, resolvedStageReturnConfig, returnType, returnConfig)
	PushBallTransition.ResetRuntimeState(player)
	teleportToDestination(player, resolvedStageReturnConfig.TravelDestinationId)
end

function TrophyTransition.ClaimStageReturn(player, stageId, returnType)
	local stageReturnId, stageReturnConfig = getStageReturnByStageId(stageId)
	if not stageReturnConfig then
		return TransitionResult.New(false, "Missing trophy return", {
			StageId = stageId,
		})
	end

	local result = claimStageReward(player, stageReturnId, stageReturnConfig, returnType)
	if result.Success == false then
		return result
	end

	PushBallTransition.ResetRuntimeState(player)
	local travelResult = teleportToDestination(player, stageReturnConfig.TravelDestinationId)
	if not travelResult or travelResult.Success == false then
		return TransitionResult.New(false, travelResult and travelResult.Message or "Trophy return failed", {
			StageId = result.StageId,
			RewardTrophies = result.RewardTrophies,
			RewardClaimed = true,
			TravelDestinationId = stageReturnConfig.TravelDestinationId,
		})
	end

	return TransitionResult.New(true, "Stage reward claimed and returned", {
		StageId = result.StageId,
		RewardTrophies = result.RewardTrophies,
		RewardClaimed = true,
		TravelDestinationId = stageReturnConfig.TravelDestinationId,
	})
end

function TrophyTransition.InitWorld()
	TrophyWorldSync.BindStageReturns(onStageReturnTouched)
end

function TrophyTransition.RemovePlayer(player)
	touchDebounceByPlayer[player] = nil
end

return TrophyTransition
