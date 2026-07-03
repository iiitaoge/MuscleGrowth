local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrophyWorldSync = require(script.Parent.Parent.WorldSync.TrophyWorldSync)

local TrophyTransition = {}

local FREE_RETURN_REWARD = 130
local TOUCH_COOLDOWN_SECONDS = 1

local touchDebounceByPlayer = setmetatable({}, {
	__mode = "k",
})

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

local function onFreeReturnTouched(player)
	if not player or not canTouchNow(player) then
		return
	end

	if TrophyTransition.AddTrophies(player, FREE_RETURN_REWARD) then
		TrophyWorldSync.TeleportToSpawn(player)
	end
end

function TrophyTransition.InitWorld()
	TrophyWorldSync.BindFreeReturn(onFreeReturnTouched)
end

function TrophyTransition.RemovePlayer(player)
	touchDebounceByPlayer[player] = nil
end

return TrophyTransition
