-- EggDisplayTheta
-- 每个蛋的展示内容配置，只放玩家可见的文案/图标等展示数据。
-- 抽奖消耗、奖池、场景节点不要放在这里。

local EggDisplayTheta = {
	-- 以稳定 EggID 为 key。展示名可以改，EggID 不应随显示文案一起改。
	Egg1 = {
		-- UI/Prompt 展示名。
		DisplayName = "Egg1",
		-- 蛋图标资源；当前 UI 是否使用由渲染层决定。
		ModelIcon = "rbxassetid://118155185854767",
	},
	Egg2 = {
		DisplayName = "Egg2",
		ModelIcon = "rbxassetid://106440868789112",
	},
	PEgg1 = {
		DisplayName = "PEgg1",
		ModelIcon = "rbxassetid://124769272116110",
	},
	PEgg2 = {
		DisplayName = "PEgg2",
		ModelIcon = "rbxassetid://94227745241287",
	},
}

return EggDisplayTheta
