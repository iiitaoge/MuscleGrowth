local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PushBallTransition = require(script.Parent.PushBallTransition)
local TrophyWorldSync = require(script.Parent.Parent.WorldSync.TrophyWorldSync)

local theta = ReplicatedStorage:WaitForChild("theta")
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

local function getStageReward(stageId)
	local stageConfig = type(StageTheta.Stages) == "table" and StageTheta.Stages[stageId] or nil
	return math.max(0, tonumber(stageConfig and stageConfig.RewardTrophies) or 0)
end

local function teleportToDestination(player, destinationId)
	if type(destinationId) ~= "string" or destinationId == "" then
		return
	end

	local result = TravelTransition.Request(player, destinationId)
	if result.Success == false and result.Message then
		warn(result.Message)
	end
end

local function onStageReturnTouched(player, stageReturnId, stageReturnConfig, returnType, returnConfig)
	if not player or not canTouchNow(player) then
		return
	end

	local resolvedStageReturnConfig = getStageReturnConfig(stageReturnId, stageReturnConfig)
	if type(resolvedStageReturnConfig) ~= "table" then
		return
	end

	local stageId = math.floor(tonumber(resolvedStageReturnConfig.StageId) or 0)
	local rewardMultiplier = math.max(0, tonumber(returnConfig and returnConfig.RewardMultiplier) or 1)

	if stageId > 0 and PushBallTransition.ConsumeClaimableStageReward(player, stageId) then
		local rewardTrophies = getStageReward(stageId) * rewardMultiplier
		if rewardTrophies > 0 then
			TrophyTransition.AddTrophies(player, rewardTrophies)
		end
	end

	teleportToDestination(player, resolvedStageReturnConfig.TravelDestinationId)
end

function TrophyTransition.InitWorld()
	TrophyWorldSync.BindStageReturns(onStageReturnTouched)
end

function TrophyTransition.RemovePlayer(player)
	touchDebounceByPlayer[player] = nil
end

return TrophyTransition
