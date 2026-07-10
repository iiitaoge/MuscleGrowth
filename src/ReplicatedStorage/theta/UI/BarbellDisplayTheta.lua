-- BarbellDisplayTheta
-- 杠铃场景展示的语义节点合同。

local BarbellDisplayTheta = {
	-- 每个杠铃内部优先查找的展示模型名。
	DisplayModelName = "DisplayModel",
	-- 杠铃展示和训练源的固定根路径；杠铃 ID 是根下的动态直接子节点。
	DisplayRootPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEquipment" } },
	TrainSourceRootPathSpec = { RootKey = "ServerStorage", Path = { "ToUseScene", "TrainEquipment" } },
	-- 展示 BillboardGui 在 DisplayModel 下的语义路径。
	BillboardGuiPathSpec = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui" } },

	FieldPathSpecs = {
		-- 力量倍率文本节点路径，根节点是 DisplayModel。
		PowerText = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui", "Frame", "power" } },
		-- 解锁所需奖杯文本节点路径，根节点是 DisplayModel。
		CostText = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui", "Frame", "trophy", "num" } },
		-- 未解锁展示节点路径，根节点是 DisplayModel。
		Locked = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui", "Frame", "State", "Locked" } },
		-- 可装备展示节点路径，根节点是 DisplayModel。
		Equip = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui", "Frame", "State", "Equip" } },
		-- 已装备展示节点路径，根节点是 DisplayModel。
		Equipped = { RootKey = "DisplayModel", Path = { "Glove", "BillboardGui", "Frame", "State", "Equipped" } },
	},
}

return BarbellDisplayTheta
