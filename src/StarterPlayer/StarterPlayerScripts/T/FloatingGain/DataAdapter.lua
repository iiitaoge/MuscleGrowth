-- FloatingGain/DataAdapter
-- 把训练增长和奖杯差值转换成飘字显示模型。

local DataAdapter = {}

-- 将增长数值格式化成飘字文本。
local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

-- 生成飘字显示模型。
function DataAdapter.BuildGainModel(amount)
	local numberAmount = tonumber(amount) or 0
	if numberAmount <= 0 then
		return nil
	end

	return {
		Text = "+" .. formatNumber(numberAmount),
	}
end

-- 根据前后快照计算奖杯增长量。
function DataAdapter.CalculateTrophyGain(previousTrophies, data)
	if previousTrophies == nil or not data then
		return 0
	end

	local nextTrophies = tonumber(data.Trophies) or 0
	return math.max(0, nextTrophies - previousTrophies)
end

-- 从快照中读取当前奖杯数。
function DataAdapter.ReadTrophies(data)
	if not data then
		return nil
	end

	return tonumber(data.Trophies) or 0
end

return DataAdapter
