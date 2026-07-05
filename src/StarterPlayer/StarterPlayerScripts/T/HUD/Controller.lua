-- HUD/Controller
-- 编排 HUD 长期数值刷新，并暴露重生入口按钮。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 空视图里使用的无操作函数。
local function noop() end

-- 空视图里使用的 nil 返回函数。
local function returnNil()
	return nil
end

-- 构造 HUD 不可用时的空视图。
local function createNoopView()
	return {
		Refresh = noop,
		GetRebirthButton = returnNil,
	}
end

-- 初始化 HUD 控制器。
function Controller.Init(player)
	local refs = Renderer.Resolve(player)
	if not refs then
		return createNoopView()
	end

	-- 根据快照刷新 HUD。
	local function refresh(data)
		Renderer.Render(refs, DataAdapter.BuildModel(data))
	end

	-- 返回重生入口按钮。
	local function getRebirthButton()
		return Renderer.GetRebirthButton(refs)
	end

	return {
		Refresh = refresh,
		GetRebirthButton = getRebirthButton,
	}
end

return Controller
