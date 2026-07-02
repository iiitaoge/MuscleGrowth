-- RebirthConfig.lua (ModuleScript)
local RebirthConfig = {	-- 重生配置表（力量倍率和经验倍率）
	[0] = {
		StrengthMultiplier = 1,
		ExpMultiplier = 1,
		MaxLevel = 5,
	},
	[1] = {
		StrengthMultiplier = 2,
		ExpMultiplier = 1.5,
		MaxLevel = 10,
	},
	[2] = {
		StrengthMultiplier = 4,
		ExpMultiplier = 2.0,
		MaxLevel = 15,
	},
	[3] = {
		StrengthMultiplier = 8,
		ExpMultiplier = 3.0,
		MaxLevel = 20,
	},
	-- 未配置的重生次数，使用最后一条配置（或使用公式计算）
}

-- 获取配置，并提供兜底
function RebirthConfig.GetConfig(rebirthCount)
	local config = RebirthConfig[rebirthCount]
	if not config then
		-- 从最后一条配置取，或用指数公式生成
		local lastConfig = RebirthConfig[#RebirthConfig]
		config = {
			StrengthMultiplier = lastConfig.StrengthMultiplier * (2 ^ (rebirthCount - #RebirthConfig)),
			ExpMultiplier = lastConfig.ExpMultiplier * (1.5 ^ (rebirthCount - #RebirthConfig)),
			MaxLevel = lastConfig.MaxLevel + 20 * (rebirthCount - #RebirthConfig)
		}
	end
	return config
end

return RebirthConfig
