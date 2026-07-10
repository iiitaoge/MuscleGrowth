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
		-- 奖杯飘字上浮和淡出的时长。
		Duration = 0.65,
		-- 力量飘字上浮阶段时长。
		FloatDuration = 0.22,
		-- 力量飘字归拢到 IconGlow 的时长。
		ConvergeDuration = 0.38,
		-- 动画完成后的克隆节点销毁延迟。
		DestroyDelay = 0.05,
	},
}

return FloatingGainTheta
