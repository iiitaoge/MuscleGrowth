-- FloatingGain/Controller
-- 编排训练力量飘字和奖杯增长飘字的触发时机。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

local STRENGTH_GAIN_PART_COUNT = 5

-- 初始化飘字控制器。
function Controller.Init(player, strengthGainTarget)
	local refs = UIRefs.ResolveFloatingGain(player)
	assert(
		strengthGainTarget and strengthGainTarget:IsA("GuiObject"),
		"Floating gain strength target must be a GuiObject."
	)

	local lastTrophies = nil

	-- 播放训练力量增长飘字。
	local function playStrengthGain(amount)
		for _, text in ipairs(DataAdapter.BuildSplitGainTexts(amount, STRENGTH_GAIN_PART_COUNT)) do
			Renderer.PlayGainInRandomAreaToTarget(refs.StrengthTemplate, refs.Animation, text, strengthGainTarget)
		end
	end

	-- 根据快照变化播放奖杯增长飘字。
	local function refresh(data)
		local nextTrophies = DataAdapter.ReadTrophies(data)
		if lastTrophies ~= nil then
			local trophyGain = DataAdapter.CalculateTrophyGain(lastTrophies, nextTrophies)
			if trophyGain > 0 then
				Renderer.PlayGain(refs.TrophyTemplate, refs.Animation, DataAdapter.BuildGainText(trophyGain))
			end
		end

		lastTrophies = nextTrophies
	end

	return {
		Refresh = refresh,
		PlayStrengthGain = playStrengthGain,
	}
end

return Controller
