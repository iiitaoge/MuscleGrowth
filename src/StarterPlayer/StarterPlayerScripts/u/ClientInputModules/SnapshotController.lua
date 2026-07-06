-- SnapshotController
-- 客户端快照刷新中心，统一把服务端数据分发给所有 UI/视觉控制器。

local SnapshotController = {}

-- 初始化快照控制器。
function SnapshotController.Init(remoteClient, views)
	local latestData = nil

	-- 把快照写入所有需要刷新的视图。
	local function refresh(data)
		latestData = data
		views.HUD.Refresh(data)
		views.FloatingGain.Refresh(data)
		views.PetInventory.Refresh(data)
		views.RebirthPanel.Refresh(data)
		views.EggPanel.Refresh(data)
		views.BarbellDisplay.Refresh(data)
	end

	-- 统一 处理 RemoteFunction 返回值，并在包含 Data 时刷新快照。
	-- 两种Success ：1.事件本身成功没 2.业务逻辑本身成功没？
	local function applyRemoteResult(success, result)
		-- 第一段：远程调用本身失败
		if not success then
			warn(result)
			return nil
		end

		-- 第二段：服务器返回了新数据，就刷新 UI
		if result and result.Data then
			refresh(result.Data)
		end

		-- 第三段：业务失败时打印服务器消息
		if result and result.Success == false and result.Message then
			warn(result.Message)
		end

		return result
	end

	-- 主动向服务端请求完整快照。
	local function refreshFromServer()
		local success, data = remoteClient.SafeInvoke("GetData")
		if not success then
			warn(data)
			return nil
		end

		refresh(data)
		return data
	end

	-- 返回最近一次缓存的玩家快照。
	local function getLatestData()
		return latestData
	end

	return {
		Refresh = refresh,
		RefreshFromServer = refreshFromServer,
		ApplyRemoteResult = applyRemoteResult,
		GetLatestData = getLatestData,
	}
end

return SnapshotController
