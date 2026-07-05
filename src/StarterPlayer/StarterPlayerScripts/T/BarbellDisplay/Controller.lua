-- BarbellDisplay/Controller
-- 编排杠铃场景展示刷新。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 空视图里使用的无操作函数。
local function noop() end

-- 构造杠铃展示不可用时的空视图。
local function createNoopView()
	return {
		Refresh = noop,
	}
end

-- 初始化杠铃展示控制器。
function Controller.Init()
	local refs = Renderer.Resolve()
	if not refs then
		return createNoopView()
	end

	-- 根据玩家快照刷新杠铃展示。
	local function refresh(data)
		Renderer.Render(refs, DataAdapter.BuildModels(data))
	end

	return {
		Refresh = refresh,
	}
end

return Controller
