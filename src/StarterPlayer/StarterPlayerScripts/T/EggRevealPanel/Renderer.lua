-- EggRevealPanel/Renderer
-- 负责开奖展示层显隐、槽位填充、摇蛋动画和点击绑定。

local TweenService = game:GetService("TweenService")

local ButtonMotion = require(script.Parent.Parent.ButtonMotion)

local Renderer = {}

local SHAKE_ROTATIONS = { -12, 12, -10, 10, -6, 6, 0 }
local SHAKE_STEP_SECONDS = 0.07

local function setVisible(instance, isVisible)
	if instance:IsA("ScreenGui") then
		instance.Enabled = isVisible == true
	else
		instance.Visible = isVisible == true
	end
end

local function setTextObject(textObject, value, isVisible)
	textObject.Text = value or ""
	textObject.Visible = isVisible == true
end

local function setImageObject(imageObject, image)
	imageObject.Image = image or ""
	imageObject.Visible = imageObject.Image ~= ""
end

local function getSlotIndex(cardCount, cardIndex, slotCount)
	if cardCount == 1 and slotCount >= 2 then
		return 2
	end

	return cardIndex
end

local function getActiveSlotEntries(refs, revealModel)
	local cards = revealModel.Cards or {}
	local cardCount = #cards
	assert(
		cardCount <= refs.RewardSlotCount,
		"Egg reveal has " .. tostring(cardCount) .. " results but only " .. tostring(refs.RewardSlotCount) .. " UI slots."
	)

	local entries = {}
	for cardIndex, cardModel in ipairs(cards) do
		local slotIndex = getSlotIndex(cardCount, cardIndex, refs.RewardSlotCount)
		local slot = refs.RewardSlots[slotIndex]
		if slot then
			table.insert(entries, {
				Slot = slot,
				Card = cardModel,
			})
		end
	end

	return entries
end

local function clearSlot(slot)
	slot.Icon.Rotation = 0
	setImageObject(slot.Icon, "")
	setTextObject(slot.NameText, "", false)
	setTextObject(slot.RarityText, "", false)
	setVisible(slot.Root, false)
end

local function configureContinueButton(refs)
	refs.ContinueButton.BackgroundTransparency = 1
	refs.ContinueButton.BorderSizePixel = 0
	refs.ContinueButton.ZIndex = math.max(refs.ContinueButton.ZIndex, refs.PanelRoot.ZIndex + 100)
	refs.ContinueText.ZIndex = math.max(refs.ContinueText.ZIndex, refs.ContinueButton.ZIndex + 1)
	refs.StopButton.ZIndex = math.max(refs.StopButton.ZIndex, refs.ContinueButton.ZIndex + 2)

	if refs.ContinueButton:IsA("TextButton") or refs.ContinueButton:IsA("ImageButton") then
		refs.ContinueButton.AutoButtonColor = false
	end
	if refs.ContinueButton:IsA("TextButton") then
		refs.ContinueButton.Text = ""
	end
end

function Renderer.ConnectActivated(root, callback, options)
	local shouldBindMotion = not (options and options.DisableMotion == true)

	if root:IsA("GuiButton") then
		if shouldBindMotion then
			ButtonMotion.Bind(root)
		end
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
	if shouldBindMotion then
		ButtonMotion.Bind(hitButton, root)
	end
	hitButton.Activated:Connect(callback)
	return hitButton
end

function Renderer.SetOpen(refs, isOpen)
	local nextIsOpen = isOpen == true
	configureContinueButton(refs)
	setVisible(refs.PanelRoot, nextIsOpen)
	setVisible(refs.ContinueButton, nextIsOpen)
	refs.ContinueButton.Active = nextIsOpen

	if not nextIsOpen then
		Renderer.Clear(refs)
	end
end

function Renderer.SetStopVisible(refs, isVisible)
	setVisible(refs.StopButton, isVisible == true)
end

function Renderer.SetContinuePrompt(refs, isVisible, promptText)
	setTextObject(refs.ContinueText, isVisible and promptText or "", isVisible == true)
end

function Renderer.ClearSlots(refs)
	for _, slot in ipairs(refs.RewardSlots) do
		clearSlot(slot)
	end
end

function Renderer.Clear(refs)
	Renderer.ClearSlots(refs)
	Renderer.SetContinuePrompt(refs, false, "")
	Renderer.SetStopVisible(refs, false)
end

function Renderer.RenderEggs(refs, revealModel)
	Renderer.SetOpen(refs, true)
	Renderer.ClearSlots(refs)
	Renderer.SetContinuePrompt(refs, false, "")

	for _, entry in ipairs(getActiveSlotEntries(refs, revealModel)) do
		local slot = entry.Slot
		setVisible(slot.Root, true)
		slot.Icon.Rotation = 0
		setImageObject(slot.Icon, revealModel.EggIcon)
		setTextObject(slot.NameText, "", false)
		setTextObject(slot.RarityText, "", false)
	end
end

function Renderer.PlayShake(refs, revealModel)
	local activeEntries = getActiveSlotEntries(refs, revealModel)
	local tweenInfo = TweenInfo.new(SHAKE_STEP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	for _, rotation in ipairs(SHAKE_ROTATIONS) do
		for _, entry in ipairs(activeEntries) do
			TweenService:Create(entry.Slot.Icon, tweenInfo, {
				Rotation = rotation,
			}):Play()
		end
		task.wait(SHAKE_STEP_SECONDS)
	end

	for _, entry in ipairs(activeEntries) do
		entry.Slot.Icon.Rotation = 0
	end
end

function Renderer.RenderRewards(refs, revealModel)
	Renderer.ClearSlots(refs)

	for _, entry in ipairs(getActiveSlotEntries(refs, revealModel)) do
		local slot = entry.Slot
		local card = entry.Card
		setVisible(slot.Root, true)
		slot.Icon.Rotation = 0
		setImageObject(slot.Icon, card.Icon)
		setTextObject(slot.NameText, card.NameText, true)
		setTextObject(slot.RarityText, card.RarityText, true)
	end

	Renderer.SetContinuePrompt(refs, true, revealModel.ContinueText)
end

return Renderer
