-- BarbellDisplayTheta
-- 杠铃场景展示的语义节点合同。

local function displayModelPath(path)
	return { RootKey = "DisplayModel", Path = path }
end

local BarbellDisplayTheta = {
	-- 杠铃展示所在的场景装备根目录名。
	SceneEquipmentRootName = "SceneEquipment",
	-- 每个杠铃内部优先查找的展示模型名。
	DisplayModelName = "DisplayModel",
	-- 展示 BillboardGui 在 DisplayModel 下的语义路径。
	BillboardGuiPath = displayModelPath({ "Glove", "BillboardGui" }),

	FieldPaths = {
		-- 力量倍率文本节点路径，根节点是 DisplayModel。
		PowerText = displayModelPath({ "Glove", "BillboardGui", "Frame", "power" }),
		-- 解锁所需奖杯文本节点路径，根节点是 DisplayModel。
		CostText = displayModelPath({ "Glove", "BillboardGui", "Frame", "trophy", "num" }),
		-- 未解锁展示节点路径，根节点是 DisplayModel。
		Locked = displayModelPath({ "Glove", "BillboardGui", "Frame", "State", "Locked" }),
		-- 可装备展示节点路径，根节点是 DisplayModel。
		Equip = displayModelPath({ "Glove", "BillboardGui", "Frame", "State", "Equip" }),
		-- 已装备展示节点路径，根节点是 DisplayModel。
		Equipped = displayModelPath({ "Glove", "BillboardGui", "Frame", "State", "Equipped" }),
	},
}

return BarbellDisplayTheta
