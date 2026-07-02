local Configs = script.Parent.Parent.Configs

local BarbellConfig = require(Configs.BarbellConfig)
local RebirthConfig = require(Configs.RebirthConfig)
local BodyQualityConfig = require(Configs.BodyQualityConfig)


local FormulaService = {}

-- growthContext 由 GameManager 在每次增长时传入，表示本次增长的临时状态。
-- 公式层只关心“最终自动区倍率是多少”，不直接依赖地图区域和解锁校验。
local function getAutoAreaMultiplier(growthContext)
	local multiplier = growthContext and growthContext.AutoAreaMultiplier or 1
	if typeof(multiplier) ~= "number" then
		return 1
	end

	return math.max(multiplier, 0)
end

function FormulaService.GetStrengthMultiplier(playerData, growthContext)
	local barbell = BarbellConfig[playerData.CurrentBarbellId]
	local rebirth = RebirthConfig.GetConfig(playerData.RebirthCount)

	local barbellMult = barbell and barbell.StrengthMultiplier or 1
	local rebirthMult = rebirth and rebirth.StrengthMultiplier or 1

	return barbellMult * rebirthMult * getAutoAreaMultiplier(growthContext)
end

function FormulaService.GetExpMultiplier(playerData, growthContext)
	local body = BodyQualityConfig[playerData.BodyQuality]
	local rebirth = RebirthConfig.GetConfig(playerData.RebirthCount)

	local testMult = 50
	local bodyMult = body and body.ExpMultiplier or 1
	local rebirthMult = rebirth and rebirth.ExpMultiplier or 1

	return bodyMult * rebirthMult * testMult * getAutoAreaMultiplier(growthContext)
end

function FormulaService.GetStrengthGain(playerData, growthContext)
	return FormulaService.GetStrengthMultiplier(playerData, growthContext)
end

function FormulaService.GetExpGain(playerData, growthContext)
	return FormulaService.GetExpMultiplier(playerData, growthContext)
end

return FormulaService
