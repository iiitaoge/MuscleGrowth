-- EggPanel/Renderer
-- 只负责填充蛋面板文本图片、切换可见性和绑定点击层。

local Renderer = {}

local function setFirstText(root, value)
	if root:IsA("TextLabel") or root:IsA("TextButton") then
		root.Text = value
		return
	end

	local label = root:FindFirstChildWhichIsA("TextLabel", true)
		or root:FindFirstChildWhichIsA("TextButton", true)
	assert(label, "Egg text target has no descendant text object: " .. root:GetFullName())
	label.Text = value
end

local function setTextObject(textObject, value)
	textObject.Text = value
end

local function setImageObject(imageObject, image)
	imageObject.Image = image
	imageObject.Visible = image ~= ""
end

local function setVisible(instance, isVisible)
	if instance:IsA("ScreenGui") then
		instance.Enabled = isVisible == true
	else
		instance.Visible = isVisible == true
	end
end

local function renderRewardSlot(slot, rewardModel)
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

local function renderFixedRewards(rewardSlots, rewardSlotCount, rewardModels)
	local rewardCount = type(rewardModels) == "table" and #rewardModels or 0
	assert(
		rewardCount <= rewardSlotCount,
		"Egg reward pool has " .. tostring(rewardCount) .. " rewards but only " .. tostring(rewardSlotCount) .. " UI slots."
	)

	for index = 1, rewardSlotCount do
		renderRewardSlot(rewardSlots[index], rewardModels[index])
	end
end

local function setButton(button, buttonModel)
	local labels = {}
	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			table.insert(labels, descendant)
		end
	end

	if labels[1] then
		labels[1].Text = buttonModel.KeyText
	end
	if labels[2] then
		labels[2].Text = buttonModel.CostText
	end
end

local function renderResultTemplate(resultTemplate, resultModel)
	local hasResult = type(resultModel) == "table"
	setVisible(resultTemplate.Root, hasResult)
	setImageObject(resultTemplate.Icon, hasResult and resultModel.Icon or "")
	setTextObject(resultTemplate.NameText, hasResult and resultModel.NameText or "")
	setTextObject(resultTemplate.RarityText, hasResult and resultModel.RarityText or "")
end

function Renderer.ConnectActivated(root, callback)
	if root:IsA("GuiButton") then
		root.Activated:Connect(callback)
		return root
	end

	local hitButton = root:FindFirstChild("InteractionButton")
	if hitButton and not hitButton:IsA("GuiButton") then
		hitButton:Destroy()
		hitButton = nil
	end

	if not hitButton then
		hitButton = Instance.new("TextButton")
		hitButton.Name = "InteractionButton"
		hitButton.BackgroundTransparency = 1
		hitButton.BorderSizePixel = 0
		hitButton.Text = ""
		hitButton.AutoButtonColor = false
		hitButton.Size = UDim2.fromScale(1, 1)
		hitButton.Position = UDim2.fromScale(0, 0)
		hitButton.AnchorPoint = Vector2.new(0, 0)
		hitButton.ZIndex = root.ZIndex + 100
		hitButton.Parent = root
	end

	hitButton.Visible = true
	hitButton.Active = true
	hitButton.Activated:Connect(callback)
	return hitButton
end

function Renderer.SetOpen(refs, isOpen)
	setVisible(refs.PanelRoot, isOpen == true)
end

function Renderer.IsOpen(refs)
	return refs.PanelRoot.Visible == true
end

function Renderer.RenderEgg(refs, eggModel)
	setFirstText(refs.TitleRoot, eggModel.Title)
	setButton(refs.SingleButton, eggModel.Buttons.Single)
	setButton(refs.TripleButton, eggModel.Buttons.Triple)
	setButton(refs.AutoButton, eggModel.Buttons.Auto)
	renderFixedRewards(refs.RewardSlots, refs.RewardSlotCount, eggModel.Rewards)
end

function Renderer.ClearResult(refs)
	renderResultTemplate(refs.ResultTemplate, nil)
end

function Renderer.RenderResult(refs, resultModel)
	renderResultTemplate(refs.ResultTemplate, resultModel)
end

return Renderer
