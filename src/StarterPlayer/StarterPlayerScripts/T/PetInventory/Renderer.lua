-- PetInventory/Renderer
-- 只负责宠物背包 UI 显示、模板克隆和点击层绑定。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ButtonMotion = require(script.Parent.Parent.ButtonMotion)
local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local Renderer = {}

local GENERATED_ATTRIBUTE = "MuscleGrowthGeneratedPetUi"

local function clearGeneratedChildren(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:GetAttribute(GENERATED_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function setVisible(instance, isVisible)
	instance.Visible = isVisible == true
end

local function requireCardField(root, pathSpec, context)
	return InstancePath.RequireSpec({ PetCard = root }, pathSpec, context)
end

local function setTextObject(textObject, value)
	textObject.Text = value
end

local function setPetIcon(root, pathSpec, image)
	local icon = requireCardField(root, pathSpec, "Pet card icon")
	assert(icon:IsA("ImageLabel") or icon:IsA("ImageButton"), "Pet card icon must be an image object.")
	icon.Image = image or ""
	icon.Visible = type(image) == "string" and image ~= ""
end

local function setPetCard(card, petModel, cardFields)
	local hasPet = type(petModel) == "table"
	card.Visible = hasPet

	setPetIcon(card, cardFields.Icon, hasPet and petModel.Icon or nil)
	setTextObject(
		requireCardField(card, cardFields.MultiplierText, "Pet card multiplier text"),
		hasPet and petModel.MultiplierText or ""
	)
end

local function setCardSelected(card, isSelected)
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

local function cloneTemplate(template, parent, name, layoutOrder)
	local clone = template:Clone()
	clone.Name = name
	clone.LayoutOrder = layoutOrder
	clone:SetAttribute(GENERATED_ATTRIBUTE, true)
	clone.Visible = true
	clone.Parent = parent

	return clone
end

function Renderer.GetActivatedTarget(root)
	if root:IsA("GuiButton") then
		ButtonMotion.Bind(root)
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
		hitButton.Parent = root
	end

	hitButton.Size = UDim2.fromScale(1, 1)
	hitButton.Position = UDim2.fromScale(0, 0)
	hitButton.AnchorPoint = Vector2.new(0, 0)
	hitButton.ZIndex = root.ZIndex + 100
	hitButton.Visible = true
	hitButton.Active = true
	ButtonMotion.Bind(hitButton, root)

	return hitButton
end

function Renderer.ConnectActivated(root, callback)
	local target = Renderer.GetActivatedTarget(root)
	target.Activated:Connect(callback)
	return target
end

function Renderer.SetOpen(refs, isOpen)
	setVisible(refs.PanelRoot, isOpen == true)
end

function Renderer.IsOpen(refs)
	return refs.PanelRoot.Visible == true
end

function Renderer.RenderOwnedPets(refs, petModels)
	clearGeneratedChildren(refs.OwnedContainer)
	setVisible(refs.OwnedTemplate, false)

	local renderedCards = {}
	for _, petModel in ipairs(petModels) do
		local card = cloneTemplate(refs.OwnedTemplate, refs.OwnedContainer, petModel.Name, petModel.LayoutOrder)
		setPetCard(card, petModel, refs.CardFields)
		setCardSelected(card, petModel.IsSelected)
		table.insert(renderedCards, {
			Root = card,
			Model = petModel,
		})
	end

	return renderedCards
end

function Renderer.RenderEquippedPets(refs, petModels)
	clearGeneratedChildren(refs.EquippedContainer)
	setVisible(refs.EquippedTemplate, false)

	local renderedCards = {}
	for _, petModel in ipairs(petModels) do
		local card = cloneTemplate(refs.EquippedTemplate, refs.EquippedContainer, petModel.Name, petModel.LayoutOrder)
		setPetCard(card, petModel, refs.CardFields)
		table.insert(renderedCards, {
			Root = card,
			Model = petModel,
		})
	end

	return renderedCards
end

function Renderer.SetEquippedText(refs, text)
	setTextObject(refs.EquippedText, text)
end

function Renderer.SetNoPetVisible(refs, isVisible)
	setVisible(refs.NoPet, isVisible == true)
end

return Renderer
