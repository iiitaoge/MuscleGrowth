-- EggPanel/Renderer
-- 只负责查找蛋面板节点、填充文本图片和切换可见性。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local eggTheta = theta:WaitForChild("EggTheta")
local EggPanelTheta = require(eggTheta:WaitForChild("EggPanelTheta"))

local Renderer = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local DEFAULT_REWARD_SLOT_FIELDS = {
	Icon = "Icon",
	ChanceText = "ChanceText",
	MultiplierText = "MultiplierText",
}

local DEFAULT_RESULT_TEMPLATE_FIELDS = {
	Icon = "Icon",
	NameText = "NameText",
	RarityText = "RarityText",
}

-- 按路径等待 UI 节点。
local function waitForPath(root, path)
	if type(path) ~= "table" then
		warn("Missing Egg UI path config.")
		return nil
	end

	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
	end

	return current
end

-- 将路径表转换成日志可读文本。
local function formatPath(path)
	if type(path) ~= "table" then
		return tostring(path)
	end

	return table.concat(path, "/")
end

-- 给根节点或第一个文本子节点写入文本。
local function setFirstText(root, value)
	if not root then
		return
	end

	if root:IsA("TextLabel") or root:IsA("TextButton") then
		root.Text = value
		return
	end

	local label = root:FindFirstChildWhichIsA("TextLabel", true)
		or root:FindFirstChildWhichIsA("TextButton", true)
	if label then
		label.Text = value
	end
end

-- 给文本节点写入文本。
local function setTextObject(textObject, value)
	if not textObject then
		return
	end

	if textObject:IsA("TextLabel") or textObject:IsA("TextButton") then
		textObject.Text = value or ""
		return
	end

	setFirstText(textObject, value or "")
end

-- 给图片节点写入资源 id。
local function setImageObject(imageObject, image)
	if imageObject and (imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton")) then
		imageObject.Image = image or ""
		imageObject.Visible = type(image) == "string" and image ~= ""
	end
end

-- 切换 GUI 节点可见性。
local function setVisible(instance, isVisible)
	if not instance then
		return
	end

	if instance:IsA("GuiObject") then
		instance.Visible = isVisible == true
	elseif instance:IsA("ScreenGui") then
		instance.Enabled = isVisible == true
	end
end

-- 在槽位里查找字段节点。
local function findSlotField(slotRoot, fieldName, slotLabel)
	if not slotRoot or type(fieldName) ~= "string" or fieldName == "" then
		return nil
	end

	local field = slotRoot:FindFirstChild(fieldName, true)
	if not field then
		warn("Missing " .. slotLabel .. " field: " .. slotRoot:GetFullName() .. "/" .. fieldName)
	end

	return field
end

-- 根据合同解析固定奖池槽位。
local function resolveRewardSlots(mainGui, slotPaths, slotFields)
	if type(slotPaths) ~= "table" then
		warn("Missing Egg UI path config.")
		return {}, 0
	end

	local slots = {}
	local slotCount = 0
	for index, path in ipairs(slotPaths) do
		slotCount = index
		local slotRoot = waitForPath(mainGui, path)
		if not slotRoot then
			warn("Missing egg reward slot: " .. formatPath(path))
		else
			slots[index] = {
				Root = slotRoot,
				Icon = findSlotField(slotRoot, slotFields.Icon, "reward slot"),
				ChanceText = findSlotField(slotRoot, slotFields.ChanceText, "reward slot"),
				MultiplierText = findSlotField(slotRoot, slotFields.MultiplierText, "reward slot"),
			}
		end
	end

	return slots, slotCount
end

-- 根据合同解析抽奖结果模板。
local function resolveResultTemplate(mainGui, templatePath, templateFields)
	local templateRoot = waitForPath(mainGui, templatePath)
	if not templateRoot then
		warn("Missing egg result template: " .. formatPath(templatePath))
		return nil
	end

	return {
		Root = templateRoot,
		Icon = findSlotField(templateRoot, templateFields.Icon, "result template"),
		NameText = findSlotField(templateRoot, templateFields.NameText, "result template"),
		RarityText = findSlotField(templateRoot, templateFields.RarityText, "result template"),
	}
end

-- 渲染单个奖池槽。
local function renderRewardSlot(slot, rewardModel)
	if not slot then
		return
	end

	local hasReward = type(rewardModel) == "table"
	setVisible(slot.Root, hasReward)
	if not hasReward then
		setImageObject(slot.Icon, "")
		setTextObject(slot.ChanceText, "")
		setTextObject(slot.MultiplierText, "")
		return
	end

	setImageObject(slot.Icon, rewardModel.Icon)
	setTextObject(slot.ChanceText, rewardModel.ChanceText)
	setTextObject(slot.MultiplierText, rewardModel.MultiplierText)
end

-- 渲染固定数量的奖池槽。
local function renderFixedRewards(rewardSlots, rewardSlotCount, rewardModels)
	local rewardCount = type(rewardModels) == "table" and #rewardModels or 0
	for index = 1, rewardSlotCount do
		renderRewardSlot(rewardSlots[index], type(rewardModels) == "table" and rewardModels[index] or nil)
	end

	if rewardCount > rewardSlotCount then
		warn("Egg reward pool has " .. tostring(rewardCount) .. " rewards but only " .. tostring(rewardSlotCount) .. " UI slots.")
	end
end

-- 渲染一个抽奖按钮上的按键和消耗。
local function setButton(button, buttonModel)
	if not button then
		return
	end

	local labels = {}
	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			table.insert(labels, descendant)
		end
	end

	if labels[1] then
		labels[1].Text = buttonModel and buttonModel.KeyText or ""
	end
	if labels[2] then
		labels[2].Text = buttonModel and buttonModel.CostText or ""
	end
end

-- 渲染抽奖结果模板。
local function renderResultTemplate(resultTemplate, resultModel)
	if not resultTemplate then
		return
	end

	local hasResult = type(resultModel) == "table"
	setVisible(resultTemplate.Root, hasResult)
	setImageObject(resultTemplate.Icon, hasResult and resultModel.Icon or "")
	setTextObject(resultTemplate.NameText, hasResult and resultModel.NameText or "")
	setTextObject(resultTemplate.RarityText, hasResult and resultModel.RarityText or "")
end

-- 解析蛋面板所需的所有 UI 引用。
function Renderer.Resolve(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild(EggPanelTheta.ScreenGuiName or "Main", GUI_WAIT_SECONDS)
	if not mainGui then
		return nil
	end

	local paths = EggPanelTheta.Paths or {}
	local panelRoot = waitForPath(mainGui, paths.PanelRoot)
	if not panelRoot then
		return nil
	end

	local rewardSlotFields = EggPanelTheta.RewardSlotFields or DEFAULT_REWARD_SLOT_FIELDS
	local resultTemplateFields = EggPanelTheta.ResultTemplateFields or DEFAULT_RESULT_TEMPLATE_FIELDS
	local rewardSlots, rewardSlotCount = resolveRewardSlots(
		mainGui,
		paths.RewardSlots,
		rewardSlotFields
	)

	return {
		PanelRoot = panelRoot,
		TitleRoot = waitForPath(mainGui, paths.TitleRoot),
		CloseButton = waitForPath(mainGui, paths.CloseButton),
		RewardSlots = rewardSlots,
		RewardSlotCount = rewardSlotCount,
		ResultTemplate = resolveResultTemplate(
			mainGui,
			paths.ResultTemplate,
			resultTemplateFields
		),
		SingleButton = waitForPath(mainGui, paths.SingleRollButton),
		TripleButton = waitForPath(mainGui, paths.TripleRollButton),
		AutoButton = waitForPath(mainGui, paths.AutoRollButton),
	}
end

-- 给按钮或可点击 GUI 节点绑定 Activated 事件。
function Renderer.ConnectActivated(root, callback)
	if not root or not callback then
		return nil
	end

	if root:IsA("GuiButton") then
		root.Activated:Connect(callback)
		return root
	end

	local button = root:FindFirstChildWhichIsA("GuiButton", true)
	if button then
		button.Activated:Connect(callback)
		return button
	end

	if root:IsA("GuiObject") then
		local hitButton = root:FindFirstChild("InteractionButton")
		if not hitButton then
			hitButton = Instance.new("TextButton")
			hitButton.Name = "InteractionButton"
			hitButton.BackgroundTransparency = 1
			hitButton.BorderSizePixel = 0
			hitButton.Text = ""
			hitButton.Size = UDim2.fromScale(1, 1)
			hitButton.Position = UDim2.fromScale(0, 0)
			hitButton.ZIndex = root.ZIndex + 100
			hitButton.Parent = root
		end

		hitButton.Activated:Connect(callback)
		return hitButton
	end

	return nil
end

-- 切换蛋面板开关。
function Renderer.SetOpen(refs, isOpen)
	if refs then
		setVisible(refs.PanelRoot, isOpen == true)
	end
end

-- 判断蛋面板当前是否打开。
function Renderer.IsOpen(refs)
	return refs and refs.PanelRoot and refs.PanelRoot.Visible == true
end

-- 渲染蛋面板主体。
function Renderer.RenderEgg(refs, eggModel)
	if not refs or not eggModel then
		return
	end

	setFirstText(refs.TitleRoot, eggModel.Title or "")
	setButton(refs.SingleButton, eggModel.Buttons and eggModel.Buttons.Single)
	setButton(refs.TripleButton, eggModel.Buttons and eggModel.Buttons.Triple)
	setButton(refs.AutoButton, eggModel.Buttons and eggModel.Buttons.Auto)
	renderFixedRewards(refs.RewardSlots, refs.RewardSlotCount, eggModel.Rewards)
end

-- 清空抽奖结果展示。
function Renderer.ClearResult(refs)
	if refs then
		renderResultTemplate(refs.ResultTemplate, nil)
	end
end

-- 渲染抽奖结果展示。
function Renderer.RenderResult(refs, resultModel)
	if refs then
		renderResultTemplate(refs.ResultTemplate, resultModel)
	end
end

return Renderer
