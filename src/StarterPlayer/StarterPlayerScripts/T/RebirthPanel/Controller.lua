-- RebirthPanel/Controller
-- 编排重生面板打开关闭和请求按钮事件。

local DataAdapter = require(script.Parent.DataAdapter)
local Refs = require(script.Parent.Refs)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 初始化重生面板控制器。
function Controller.Init(player)
	local refs = Refs.Resolve(player)

	local requestHandler = nil
	local latestData = nil

	-- 按快照刷新重生面板。
	local function refresh(data)
		latestData = data
		Renderer.Render(refs, DataAdapter.BuildModel(data))
	end

	-- 打开或关闭重生面板。
	local function setOpen(isOpen)
		Renderer.SetOpen(refs, isOpen == true)
		if Renderer.IsOpen(refs) then
			refresh(latestData)
		end
	end

	-- 设置外部重生请求处理器。
	local function setRequestHandler(handler)
		requestHandler = handler
	end

	Renderer.SetOpen(refs, false)

	-- 关闭按钮隐藏面板。
	Renderer.ConnectActivated(refs.CloseButton, function()
		setOpen(false)
	end)
	-- 请求按钮交给外部服务端调用流程。
	Renderer.ConnectActivated(refs.RequestButton, function()
		if requestHandler then
			requestHandler()
		end
	end)

	return {
		Refresh = refresh,
		SetOpen = setOpen,
		SetRequestHandler = setRequestHandler,
	}
end

return Controller
