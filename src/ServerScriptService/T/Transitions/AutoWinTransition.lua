-- AutoWinTransition
-- 服务端权威的自动推球状态机；客户端只能请求开关，不能指定关卡或奖励。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local AutoWinRules = require(script.Parent.Parent.Rules.AutoWinRules)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)
local PushBallTransition = require(script.Parent.PushBallTransition)
local TransitionResult = require(script.Parent.TransitionResult)
local TrophyTransition = require(script.Parent.TrophyTransition)

local AutoWinTransition = {}

local STAGE_DELAY_SECONDS = 0.25
local CYCLE_DELAY_SECONDS = 0.5
local FREE_RETURN_TYPE = "FreeReturn"
local CURRENT_DESTINATION_ATTRIBUTE = "CurrentDestinationId"

local states = setmetatable({}, { __mode = "k" })
local lifecycleConnections = setmetatable({}, { __mode = "k" })
local tokenByPlayer = setmetatable({}, { __mode = "k" })

local function actionResult(success, message, enabled, trackId)
	return TransitionResult.New(success, message, {
		Enabled = enabled == true,
		TrackId = type(trackId) == "string" and trackId or "",
	})
end

local function nextToken(player)
	local token = math.max(0, math.floor(tonumber(tokenByPlayer[player]) or 0)) + 1
	tokenByPlayer[player] = token
	return token
end

local function isCurrent(player, state)
	return state ~= nil
		and states[player] == state
		and state.Token == tokenByPlayer[player]
		and player.Parent == Players
end

local function getBallInstanceIdForStage(stageId)
	local matchedBallInstanceId = nil
	for ballInstanceId, ballConfig in pairs(PushBallSceneTheta.Balls or {}) do
		if type(ballInstanceId) == "string"
			and type(ballConfig) == "table"
			and math.floor(tonumber(ballConfig.StageId) or 0) == stageId
		then
			if matchedBallInstanceId then
				return nil
			end
			matchedBallInstanceId = ballInstanceId
		end
	end

	return matchedBallInstanceId
end

local function stop(player)
	local state = states[player]
	states[player] = nil
	nextToken(player)
	PlayerVisualStateSync.SetAutoWinEnabled(player, false)
	PushBallTransition.RequestStopAuto(player)
	return state and state.TrackId or nil
end

local advance

local function scheduleAdvance(player, state, delaySeconds)
	task.delay(math.max(0, tonumber(delaySeconds) or 0), function()
		if isCurrent(player, state) then
			advance(player, state)
		end
	end)
end

local function claimAndRestart(player, state, stageId)
	state.AwaitingStage = true
	local claimResult = TrophyTransition.ClaimStageReturn(player, stageId, FREE_RETURN_TYPE)
	state.AwaitingStage = false

	if not isCurrent(player, state) then
		return
	end
	if not claimResult or claimResult.Success == false then
		stop(player)
		return
	end

	scheduleAdvance(player, state, CYCLE_DELAY_SECONDS)
end

advance = function(player, state, mayStartStage)
	if not isCurrent(player, state) or state.AwaitingStage then
		return
	end
	if player:GetAttribute(CURRENT_DESTINATION_ATTRIBUTE) ~= state.TrackId then
		stop(player)
		return
	end

	local progressState = PlayerProgressState.Get(player)
	local strength = tonumber(progressState and progressState.Strength)
	local highestReachableStage = AutoWinRules.GetHighestReachableStage(state.TrackId, strength)
	local trackProgress = PushBallTransition.GetTrackProgress(player, state.TrackId)
	if not highestReachableStage or not trackProgress then
		stop(player)
		return
	end

	local completedStage = math.floor(tonumber(trackProgress.CompletedStage) or 0)
	local nextStageId = trackProgress.NextStageId
	if completedStage >= trackProgress.FirstStageId
		and (nextStageId == nil or nextStageId > highestReachableStage)
	then
		claimAndRestart(player, state, completedStage)
		return
	end

	if type(nextStageId) ~= "number" or nextStageId > highestReachableStage then
		stop(player)
		return
	end
	if mayStartStage == false then
		scheduleAdvance(player, state, STAGE_DELAY_SECONDS)
		return
	end

	local ballInstanceId = getBallInstanceIdForStage(nextStageId)
	if not ballInstanceId then
		stop(player)
		return
	end

	state.AwaitingStage = true
	local startResult = PushBallTransition.RequestAutoStart(
		player,
		state.TrackId,
		ballInstanceId,
		function(completion)
			if not isCurrent(player, state) then
				return
			end

			state.AwaitingStage = false
			if completion.Cancelled == true then
				stop(player)
				return
			end

			-- 目标关在完成回调中立刻领奖；只有继续下一关时才等待关卡间隔。
			advance(player, state, false)
		end
	)

	if not startResult or startResult.Success == false then
		state.AwaitingStage = false
		stop(player)
	end
end

function AutoWinTransition.RequestSet(player, enabled)
	if type(enabled) ~= "boolean" then
		return actionResult(false, "Auto Win enabled must be a boolean", false)
	end

	if not enabled then
		local trackId = stop(player)
		return actionResult(true, "Auto Win disabled", false, trackId)
	end

	local currentState = states[player]
	if currentState then
		return actionResult(true, "Auto Win already enabled", true, currentState.TrackId)
	end

	local trackId = player:GetAttribute(CURRENT_DESTINATION_ATTRIBUTE)
	local trackInfo = AutoWinRules.GetTrackInfo(trackId)
	if not trackInfo then
		return actionResult(false, "Auto Win is only available in a push-ball world", false, trackId)
	end

	local progressState = PlayerProgressState.Get(player)
	local highestReachableStage = AutoWinRules.GetHighestReachableStage(
		trackId,
		progressState and progressState.Strength
	)
	if not highestReachableStage then
		return actionResult(false, "Not enough Strength for this world's first stage", false, trackId)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return actionResult(false, "Missing player character", false, trackId)
	end

	-- 开启时接管现有手动推球；未完成关卡不会改变运行时进度，随后由自动模式重推。
	PushBallTransition.RequestStop(player)

	local state = {
		TrackId = trackInfo.TrackId,
		Token = nextToken(player),
		AwaitingStage = false,
	}
	states[player] = state
	PlayerVisualStateSync.SetAutoWinEnabled(player, true)
	scheduleAdvance(player, state, STAGE_DELAY_SECONDS)

	return actionResult(true, "Auto Win enabled", true, trackInfo.TrackId)
end

function AutoWinTransition.IsEnabled(player)
	return states[player] ~= nil
end

function AutoWinTransition.Stop(player)
	return stop(player)
end

function AutoWinTransition.InitPlayer(player)
	if lifecycleConnections[player] then
		lifecycleConnections[player]:Disconnect()
	end

	stop(player)
	lifecycleConnections[player] = player.CharacterRemoving:Connect(function()
		stop(player)
	end)
end

function AutoWinTransition.RemovePlayer(player)
	stop(player)
	local connection = lifecycleConnections[player]
	if connection then
		connection:Disconnect()
		lifecycleConnections[player] = nil
	end
	tokenByPlayer[player] = nil
end

return AutoWinTransition
