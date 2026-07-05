-- RebirthActionController
-- 客户端重生动作层，负责打开重生面板和提交重生请求。

local RebirthActionController = {}

-- 初始化重生动作控制器。
function RebirthActionController.Init(remoteClient, snapshotController, hudView, rebirthPanelView)
	-- 请求服务端执行重生并应用返回快照。
	local function requestRebirth()
		snapshotController.ApplyRemoteResult(remoteClient.SafeInvoke("RequestRebirth"))
	end

	-- 绑定 HUD 左侧重生入口按钮。
	local function bindRebirthButton()
		local rebirthButton = hudView.GetRebirthButton()
		if not rebirthButton then
			return
		end

		-- 打开重生面板并拉取最新快照。
		local function handleRebirthButtonActivated()
			rebirthPanelView.SetOpen(true)
			snapshotController.RefreshFromServer()
		end

		rebirthButton.Activated:Connect(handleRebirthButtonActivated)
	end

	rebirthPanelView.SetRequestHandler(requestRebirth)
	bindRebirthButton()

	return {}
end

return RebirthActionController
