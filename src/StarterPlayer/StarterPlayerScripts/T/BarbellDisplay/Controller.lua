-- BarbellDisplay/Controller
-- 编排杠铃场景展示刷新。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

-- 初始化杠铃展示控制器。
function Controller.Init()
	local refs = UIRefs.ResolveBarbellDisplay()

	-- 根据玩家快照刷新杠铃展示。
	local function refresh(data)
		Renderer.Render(refs, DataAdapter.BuildModels(data))
	end

	return {
		Refresh = refresh,
	}
end

return Controller
