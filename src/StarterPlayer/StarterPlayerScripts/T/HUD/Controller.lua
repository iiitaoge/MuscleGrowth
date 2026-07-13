-- HUD/Controller
-- 编排 HUD 长期数值刷新，并暴露重生与 Auto Win 入口。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

-- 初始化 HUD 控制器。
function Controller.Init(player)
	local refs = UIRefs.ResolveHUD(player)

	-- 根据快照刷新 HUD。
	local function refresh(data)
		Renderer.Render(refs, DataAdapter.BuildModel(data))
	end

	-- 返回重生入口按钮。
	local function getRebirthButton()
		return Renderer.GetRebirthButton(refs)
	end

	local function getStrengthGainTarget()
		return refs.StrengthIconGlow
	end

	local function setAutoWinEnabled(isEnabled)
		Renderer.SetAutoWinEnabled(refs, isEnabled)
	end

	local function getAutoWinButton()
		return Renderer.GetAutoWinButton(refs)
	end

	return {
		Refresh = refresh,
		GetRebirthButton = getRebirthButton,
		GetStrengthGainTarget = getStrengthGainTarget,
		SetAutoWinEnabled = setAutoWinEnabled,
		GetAutoWinButton = getAutoWinButton,
	}
end

return Controller
