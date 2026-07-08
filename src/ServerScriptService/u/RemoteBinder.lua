local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("System"):WaitForChild("RemoteTheta"))
local RemoteRateLimiter = require(script.Parent.RemoteRateLimiter)

local RemoteBinder = {}

local function getOrCreateRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	local remote = ReplicatedStorage:FindFirstChild(remoteSpec.Name)
	if remote and not remote:IsA(remoteSpec.ClassName) then
		remote:Destroy()
		remote = nil
	end

	if not remote then
		remote = Instance.new(remoteSpec.ClassName)
		remote.Name = remoteSpec.Name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

function RemoteBinder.GetOrCreate(remoteId)
	return getOrCreateRemote(remoteId)
end

function RemoteBinder.BindFunction(remoteId, handler)
	local remote = getOrCreateRemote(remoteId)
	assert(remote:IsA("RemoteFunction"), "Remote must be RemoteFunction: " .. tostring(remoteId))

	remote.OnServerInvoke = handler
	return remote
end

function RemoteBinder.BindFunctions(handlers)
	for remoteId, handler in pairs(handlers) do
		RemoteBinder.BindFunction(remoteId, handler)
	end
end

function RemoteBinder.BindEvent(remoteId, minInterval, handler)
	local remote = getOrCreateRemote(remoteId)
	assert(remote:IsA("RemoteEvent"), "Remote must be RemoteEvent: " .. tostring(remoteId))

	remote.OnServerEvent:Connect(function(player, ...)
		if not RemoteRateLimiter.Allow(player, remoteId, minInterval) then
			return
		end

		handler(player, ...)
	end)

	return remote
end

function RemoteBinder.BindEvents(minIntervals, handlers)
	for remoteId, handler in pairs(handlers) do
		RemoteBinder.BindEvent(remoteId, minIntervals and minIntervals[remoteId], handler)
	end
end

function RemoteBinder.RemovePlayer(player)
	RemoteRateLimiter.Remove(player)
end

return RemoteBinder
