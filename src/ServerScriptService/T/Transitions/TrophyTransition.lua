local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrophyWorldSync = require(script.Parent.Parent.WorldSync.TrophyWorldSync)
local TrophyTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("TrophyTheta"))

local TravelDestinationWorldSync = require(script.Parent.Parent.WorldSync.TravelDestinationWorldSync)

local TrophyTransition = {}
local TravelDestinationId = "World1"	--传送目的地

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

local function getFreeReturnConfig(trophyId, fallbackConfig)
	if type(fallbackConfig) == "table" then
		return fallbackConfig
	end

	local freeReturnConfigs = TrophyTheta.FreeReturns
	return type(freeReturnConfigs) == "table" and freeReturnConfigs[trophyId] or nil
end

local function getRewardTrophies(trophyId, fallbackConfig)
	local freeReturnConfig = getFreeReturnConfig(trophyId, fallbackConfig)
	return math.max(0, tonumber(freeReturnConfig and freeReturnConfig.RewardTrophies) or 0)
end

local function onFreeReturnTouched(player, trophyId, freeReturnConfig)
	if not player or not canTouchNow(player) then
		return
	end

	local rewardTrophies = getRewardTrophies(trophyId, freeReturnConfig)
	if rewardTrophies <= 0 then
		return
	end
	local world1 = workspace:WaitForChild("World1")

	print("Teleport check children:")
	for _, child in ipairs(world1:GetChildren()) do
		print(child.Name, child.ClassName, child:GetFullName())
	end
	-- 进行传送
	if TrophyTransition.AddTrophies(player, rewardTrophies) then
		TravelDestinationWorldSync.TeleportPlayer(player, TravelDestinationId)
	end
end

function TrophyTransition.InitWorld()
	TrophyWorldSync.BindFreeReturns(onFreeReturnTouched)
end

function TrophyTransition.RemovePlayer(player)
	touchDebounceByPlayer[player] = nil
end

return TrophyTransition
