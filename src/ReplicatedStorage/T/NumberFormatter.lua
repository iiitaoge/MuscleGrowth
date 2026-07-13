-- NumberFormatter
-- 将游戏中的原始数值转换成紧凑的 UI 显示文本。

local DEFAULT_DECIMALS = 2
local MAX_DECIMALS = 15
local GROUP_SIZE = 1000

local SUFFIXES = { "K", "M", "B", "T" }

for firstCode = string.byte("A"), string.byte("E") do
	for secondCode = string.byte("a"), string.byte("z") do
		table.insert(SUFFIXES, string.char(firstCode, secondCode))
	end
end

local NumberFormatter = {}

local function isFinite(value)
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function requireDecimals(decimals)
	if decimals == nil then
		return DEFAULT_DECIMALS
	end

	assert(type(decimals) == "number", "Number formatter decimals must be a number.")
	assert(isFinite(decimals), "Number formatter decimals must be finite.")
	assert(decimals == math.floor(decimals), "Number formatter decimals must be an integer.")
	assert(
		decimals >= 0 and decimals <= MAX_DECIMALS,
		("Number formatter decimals must be between 0 and %d."):format(MAX_DECIMALS)
	)

	return decimals
end

local function roundToDecimals(value, decimals)
	local scale = 10 ^ decimals
	return math.round(value * scale) / scale
end

local function formatCompactDecimal(value, decimals)
	local text = string.format("%." .. tostring(decimals) .. "f", value)
	if decimals == 0 then
		return text
	end

	text = string.gsub(text, "0+$", "")
	return string.gsub(text, "%.$", "")
end

local function getGroupIndex(magnitude)
	if magnitude < GROUP_SIZE then
		return 0
	end

	local groupIndex = math.floor(math.log10(magnitude) / 3)
	local divisor = GROUP_SIZE ^ groupIndex

	-- 修正浮点对数在整次幂边界附近可能产生的误差。
	while groupIndex > 0 and magnitude < divisor do
		groupIndex -= 1
		divisor /= GROUP_SIZE
	end

	while groupIndex < #SUFFIXES and magnitude >= divisor * GROUP_SIZE do
		groupIndex += 1
		divisor *= GROUP_SIZE
	end

	assert(groupIndex <= #SUFFIXES, "Number formatter suffix range exceeded.")
	return groupIndex
end

function NumberFormatter.Format(value: number, decimals: number?): string
	assert(type(value) == "number", "Number formatter value must be a number.")
	assert(isFinite(value), "Number formatter value must be finite.")

	local decimalPlaces = requireDecimals(decimals)
	local sign = value < 0 and "-" or ""
	local magnitude = math.abs(value)
	local groupIndex = getGroupIndex(magnitude)
	local divisor = GROUP_SIZE ^ groupIndex
	local roundedValue = roundToDecimals(magnitude / divisor, decimalPlaces)

	-- 例如 999999 保留两位小数后为 1000K，需要继续进位成 1M。
	if roundedValue >= GROUP_SIZE and groupIndex < #SUFFIXES then
		groupIndex += 1
		divisor *= GROUP_SIZE
		roundedValue = roundToDecimals(magnitude / divisor, decimalPlaces)
	end

	local suffix = groupIndex == 0 and "" or SUFFIXES[groupIndex]
	return sign .. formatCompactDecimal(roundedValue, decimalPlaces) .. suffix
end

return NumberFormatter
