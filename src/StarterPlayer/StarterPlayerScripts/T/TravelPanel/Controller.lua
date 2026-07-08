-- TravelPanel/Controller
-- Owns travel panel open/close state and destination button callbacks.

local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

function Controller.Init(player)
	local refs = UIRefs.ResolveTravelPanel(player)
	local destinationHandler = nil

	-- 使其打开
	local function setOpen(nextIsOpen)
		refs.PanelRoot.Visible = nextIsOpen == true
	end

	-- 检测是否打开
	local function isOpen()
		return refs.PanelRoot.Visible == true
	end

	-- 设置目的地
	local function setDestinationHandler(nextDestinationHandler)
		destinationHandler = nextDestinationHandler
	end

	-- 初始化为false
	setOpen(false)

	refs.OpenButton.Activated:Connect(function()
		setOpen(true)
	end)

	refs.CloseButton.Activated:Connect(function()
		setOpen(false)
	end)

	for _, destinationButton in ipairs(refs.DestinationButtons) do
		local button = destinationButton.Button
		local destinationId = destinationButton.DestinationId

		button.Activated:Connect(function()
			if destinationHandler then
				destinationHandler(destinationId)
			end
		end)
	end

	return {
		SetOpen = setOpen,
		IsOpen = isOpen,
		SetDestinationHandler = setDestinationHandler,
	}
end

return Controller
