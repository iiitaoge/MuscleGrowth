-- FloatingGainTheta
-- 训练和奖杯飘字的 UI 模板与动画合同。

local FloatingGainTheta = {
	-- 飘字模板所在 ScreenGui 名。
	ScreenGuiName = "HUD",

	Templates = {
		-- 训练力量增长飘字模板名。
		StrengthGain = "+1",
		-- 奖杯增长飘字模板名。
		TrophyGain = "+1trophy",
	},

	Animation = {
		-- 飘字向上移动的 Scale 偏移。
		OffsetScaleY = -0.08,
		-- 移动和淡出的时长。
		Duration = 0.65,
		-- 克隆节点销毁延迟。
		DestroyDelay = 0.75,
	},
}

return FloatingGainTheta
