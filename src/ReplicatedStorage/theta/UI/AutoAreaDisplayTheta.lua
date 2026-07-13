-- AutoAreaDisplayTheta
-- 自动区场景 BillboardGui 的语义节点合同。

local AutoAreaDisplayTheta = {
	FieldPathSpecs = {
		PowerText = {
			RootKey = "AutoAreaInstance",
			Path = { "Attachment", "BillboardGui", "Frame", "Power" },
		},
		RebirthText = {
			RootKey = "AutoAreaInstance",
			Path = { "Attachment", "BillboardGui", "Frame", "Rebirth" },
		},
		Locked = {
			RootKey = "AutoAreaInstance",
			Path = { "Attachment", "BillboardGui", "Frame", "Locked" },
		},
		Unlocked = {
			RootKey = "AutoAreaInstance",
			Path = { "Attachment", "BillboardGui", "Frame", "Unlocked" },
		},
	},
}

return AutoAreaDisplayTheta
