-- 对事件的请求执行限流
local RemoteRateLimiter = {}

local DEFAULT_MIN_INTERVAL = 0.1

local lastAllowedAtByPlayer = {}

local function getPlayerBucket(player)
	local bucket = lastAllowedAtByPlayer[player]
	if not bucket then
		bucket = {}
		lastAllowedAtByPlayer[player] = bucket
	end

	return bucket
end

function RemoteRateLimiter.Allow(player, remoteId, minInterval)
	if not player or type(remoteId) ~= "string" then
		return false
	end

	local interval = tonumber(minInterval) or DEFAULT_MIN_INTERVAL
	if interval <= 0 then
		return true
	end

	local now = os.clock()
	local bucket = getPlayerBucket(player)
	local lastAllowedAt = bucket[remoteId]
	if lastAllowedAt and now - lastAllowedAt < interval then
		return false
	end

	bucket[remoteId] = now
	return true
end

function RemoteRateLimiter.Remove(player)
	lastAllowedAtByPlayer[player] = nil
end

return RemoteRateLimiter
