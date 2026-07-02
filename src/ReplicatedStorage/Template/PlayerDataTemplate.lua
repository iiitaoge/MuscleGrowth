-- 玩家数据模板
local PlayerDataTemplate = {
	-- 核心累计状态（存储值）
	Strength = 0,           -- 当前总力量，重生后归零
	Exp = 0,                -- 当前总经验，重生后归零
	Level = 1,              -- 当前等级，重生后回到1

	-- 成长配置（影响增长速度）
	RebirthCount = 0,       -- 重生次数
	CurrentBarbellId = "WoodBarbell", -- 当前杠铃ID
	BodyQuality = "Normal", -- 身体素质ID

	-- 动态上限（由重生次数决定）
	MaxLevel = 5,         -- 当前最大等级
}

return PlayerDataTemplate
