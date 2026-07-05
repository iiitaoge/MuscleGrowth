-- FloatingGain/Controller
-- 编排训练力量飘字和奖杯增长飘字的触发时机。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 空视图里使用的无操作函数。
local function noop() end

-- 构造飘字 UI 不可用时的空视图。
local function createNoopView()
	return {
		Refresh = noop,
		PlayStrengthGain = noop,
	}
end

-- 初始化飘字控制器。
function Controller.Init(player)
	local refs = Renderer.Resolve(player)
	if not refs then
		return createNoopView()
	end

	local lastTrophies = nil

	-- 播放训练力量增长飘字。
	local function playStrengthGain(amount)
		Renderer.PlayGain(refs.StrengthTemplate, refs.Animation, DataAdapter.BuildGainModel(amount))
	end

	-- 根据快照变化播放奖杯增长飘字。
	local function refresh(data)
		local trophyGain = DataAdapter.CalculateTrophyGain(lastTrophies, data)
		Renderer.PlayGain(refs.TrophyTemplate, refs.Animation, DataAdapter.BuildGainModel(trophyGain))
		lastTrophies = DataAdapter.ReadTrophies(data)
	end

	return {
		Refresh = refresh,
		PlayStrengthGain = playStrengthGain,
	}
end

return Controller
