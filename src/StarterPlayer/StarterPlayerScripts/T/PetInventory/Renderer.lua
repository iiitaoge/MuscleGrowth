-- PetInventory/Renderer
-- 只负责宠物背包 UI 节点解析、模板克隆和字段填充。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetInventoryPanelTheta = require(theta:WaitForChild("PetInventoryPanelTheta"))

local Renderer = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local GENERATED_ATTRIBUTE = "MuscleGrowthGeneratedPetUi"

local DEFAULT_PET_CARD_FIELDS = {
	Icon = "Icon",
	MultiplierText = "MultiplierText",
}

-- 按合同路径等待 UI 节点。
local function waitForPath(root, path)
	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
		if not current then
			warn("Missing Pet UI node: " .. table.concat(path, "/"))
			return nil
		end
	end

	return current
end

-- 清理上次渲染克隆出来的子节点。
local function clearGeneratedChildren(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:GetAttribute(GENERATED_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

-- 切换 GUI 节点可见性。
local function setVisible(instance, isVisible)
	if instance and instance:IsA("GuiObject") then
		instance.Visible = isVisible == true
	end
end

-- 查找指定名称的任意子孙节点。
local function findDescendant(root, childName)
	if not root or type(childName) ~= "string" or childName == "" then
		return nil
	end

	return root:FindFirstChild(childName, true)
end

-- 给文本节点写入文本。
local function setTextObject(textObject, value)
	if textObject and (textObject:IsA("TextLabel") or textObject:IsA("TextButton")) then
		textObject.Text = value or ""
	end
end

-- 给宠物卡图标写入图片。
local function setPetIcon(root, fieldName, image)
	local icon = findDescendant(root, fieldName)
	if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon.Image = image or ""
		icon.Visible = type(image) == "string" and image ~= ""
	end
end

-- 按显示模型填充宠物卡。
local function setPetCard(card, petModel, cardFields)
	if not card then
		return
	end

	local fields = cardFields or DEFAULT_PET_CARD_FIELDS
	local hasPet = type(petModel) == "table"
	card.Visible = hasPet

	setPetIcon(card, fields.Icon, hasPet and petModel.Icon or nil)
	setTextObject(findDescendant(card, fields.MultiplierText), hasPet and petModel.MultiplierText or "")
end

-- 设置宠物卡的选中描边。
local function setCardSelected(card, isSelected)
	if not card then
		return
	end

	local stroke = card:FindFirstChild("SelectedStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "SelectedStroke"
		stroke.Thickness = 3
		stroke.Parent = card
	end

	stroke.Color = Color3.fromRGB(255, 230, 70)
	stroke.Enabled = isSelected == true
end

-- 克隆模板并标记为渲染生成节点。
local function cloneTemplate(template, parent, name, layoutOrder)
	if not template then
		return nil
	end

	local clone = template:Clone()
	clone.Name = name
	clone.LayoutOrder = layoutOrder
	clone:SetAttribute(GENERATED_ATTRIBUTE, true)
	clone.Visible = true
	clone.Parent = parent

	return clone
end

-- 解析宠物背包需要的所有 UI 节点。
function Renderer.Resolve(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild(PetInventoryPanelTheta.HudScreenGuiName or "HUD", GUI_WAIT_SECONDS)
	local mainGui = playerGui:WaitForChild(PetInventoryPanelTheta.ScreenGuiName or "Main", GUI_WAIT_SECONDS)

	if not hud or not mainGui then
		warn("Pet UI requires HUD and Main ScreenGui.")
		return nil
	end

	local paths = PetInventoryPanelTheta.Paths or {}
	return {
		CardFields = PetInventoryPanelTheta.PetCardFields or DEFAULT_PET_CARD_FIELDS,
		PetButton = waitForPath(hud, paths.PetButton or { "LeftButtons", "Button", "Pet" }),
		PanelRoot = waitForPath(mainGui, paths.PanelRoot or { "NewPet" }),
		CloseButton = waitForPath(mainGui, paths.CloseButton or { "NewPet", "BackPack", "Title", "Close" }),
		OwnedContainer = waitForPath(mainGui, paths.OwnedList or { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame" }),
		OwnedTemplate = waitForPath(
			mainGui,
			paths.OwnedTemplate or { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame", "BackPackPet" }
		),
		EquippedContainer = waitForPath(mainGui, paths.EquippedList or { "NewPet", "BackPack", "Main", "Info", "PetEquipList" }),
		EquippedTemplate = waitForPath(
			mainGui,
			paths.EquippedTemplate or { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedPet" }
		),
		EquippedText = waitForPath(mainGui, paths.EquippedText or { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedText" }),
		NoPet = waitForPath(mainGui, paths.NoPet or { "NewPet", "BackPack", "Main", "Info", "NoPet" }),
		EquipBestButton = waitForPath(mainGui, paths.EquipBestButton or { "NewPet", "BackPack", "Main", "BottomButton", "EquipBest" }),
		UnequipAllButton = waitForPath(mainGui, paths.UnequipAllButton or { "NewPet", "BackPack", "Main", "BottomButton", "UnEquipAll" }),
		DeleteButton = waitForPath(mainGui, paths.DeleteButton or { "NewPet", "BackPack", "Main", "BottomButton", "Delete" }),
	}
end

-- 给按钮或 GUI 节点绑定点击事件。
function Renderer.ConnectActivated(root, callback)
	if not root or not callback then
		return nil
	end

	-- 绑定指定回调函数
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

-- 切换背包面板开关。
function Renderer.SetOpen(refs, isOpen)
	if refs then
		setVisible(refs.PanelRoot, isOpen == true)
	end
end

-- 判断背包面板是否打开。
function Renderer.IsOpen(refs)
	return refs and refs.PanelRoot and refs.PanelRoot.Visible == true
end

-- 渲染拥有宠物列表并返回生成卡片。
function Renderer.RenderOwnedPets(refs, petModels)
	clearGeneratedChildren(refs and refs.OwnedContainer)
	setVisible(refs and refs.OwnedTemplate, false)

	local renderedCards = {}
	if not refs or type(petModels) ~= "table" then
		return renderedCards
	end

	for _, petModel in ipairs(petModels) do
		local card = cloneTemplate(refs.OwnedTemplate, refs.OwnedContainer, petModel.Name, petModel.LayoutOrder)
		if card then
			setPetCard(card, petModel, refs.CardFields)
			setCardSelected(card, petModel.IsSelected)
			table.insert(renderedCards, {
				Root = card,
				Model = petModel,
			})
		end
	end

	return renderedCards
end

-- 渲染已装备宠物列表并返回生成卡片。
function Renderer.RenderEquippedPets(refs, petModels)
	clearGeneratedChildren(refs and refs.EquippedContainer)
	setVisible(refs and refs.EquippedTemplate, false)

	local renderedCards = {}
	if not refs or type(petModels) ~= "table" then
		return renderedCards
	end

	for _, petModel in ipairs(petModels) do
		local card = cloneTemplate(refs.EquippedTemplate, refs.EquippedContainer, petModel.Name, petModel.LayoutOrder)
		if card then
			setPetCard(card, petModel, refs.CardFields)
			table.insert(renderedCards, {
				Root = card,
				Model = petModel,
			})
		end
	end

	return renderedCards
end

-- 设置装备数量文本。
function Renderer.SetEquippedText(refs, text)
	if refs then
		setTextObject(refs.EquippedText, text)
	end
end

-- 切换空背包提示。
function Renderer.SetNoPetVisible(refs, isVisible)
	if refs then
		setVisible(refs.NoPet, isVisible == true)
	end
end

return Renderer
