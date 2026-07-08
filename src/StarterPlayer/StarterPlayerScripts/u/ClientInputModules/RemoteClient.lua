-- RemoteClient
-- 客户端 Remote 访问层，只负责按 RemoteTheta 找 Remote 并安全调用。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local RemoteTheta = require(theta:WaitForChild("System"):WaitForChild("RemoteTheta"))

local RemoteClient = {}

-- 根据 Remote id 等待真实 Remote 实例。
local function waitForRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	return ReplicatedStorage:WaitForChild(remoteSpec.Name)
end

-- 初始化客户端需要的所有 Remote 引用。
function RemoteClient.Init()
	local remotes = {}

	-- 返回指定 Remote id 对应的实例，并按需缓存。
	local function get(remoteId)
		if not remotes[remoteId] then
			remotes[remoteId] = waitForRemote(remoteId)
		end

		return remotes[remoteId]
	end

	-- 安全调用 RemoteFunction，保持 pcall 的 success/result 形状。
	local function safeInvoke(remoteId, ...)
		local remote = get(remoteId)
		if not remote then
			local message = "Missing remote instance: " .. tostring(remoteId)
			warn(message)
			return false, message
		end

		-- 真正执行 InvokeServer，交给 pcall 捕获网络调用错误。
		local function invokeServer(...)
			return remote:InvokeServer(...)
		end

		return pcall(invokeServer, ...)
	end

	-- 触发 RemoteEvent，不做服务端结果处理。
	local function fire(remoteId, ...)
		local remote = get(remoteId)
		if not remote then
			warn("Missing remote instance: " .. tostring(remoteId))
			return
		end


		-- 真正触发
		remote:FireServer(...)
	end

	return {
		Get = get,
		SafeInvoke = safeInvoke,
		Fire = fire,
	}
end

return RemoteClient
