-- BarbellDisplayTheta
-- 杠铃场景展示的语义节点合同。

local BarbellDisplayTheta = {
	-- 杠铃展示所在的场景装备根目录名。
	SceneEquipmentRootName = "SceneEquipment",
	-- 每个杠铃内部优先查找的展示模型名。
	DisplayModelName = "DisplayModel",

	Fields = {
		-- 力量倍率文本节点名。
		PowerText = "power",
		-- 解锁所需奖杯文本节点名。
		CostText = "num",
		-- 未解锁展示节点名。
		Locked = "Locked",
		-- 可装备展示节点名。
		Equip = "Equip",
		-- 已装备展示节点名。
		Equipped = "Equipped",
	},
}

return BarbellDisplayTheta
