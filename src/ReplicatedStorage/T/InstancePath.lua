local InstancePath = {}

local function formatPath(path)
	local parts = {}
	for _, childName in ipairs(path or {}) do
		parts[#parts + 1] = tostring(childName)
	end
	return table.concat(parts, ".")
end

local function getPathSpec(pathSpec, context)
	context = context or "InstancePath"
	assert(type(pathSpec) == "table", context .. " must be a path specification table.")
	assert(type(pathSpec.RootKey) == "string" and pathSpec.RootKey ~= "", context .. ".RootKey must be a non-empty string.")
	assert(type(pathSpec.Path) == "table" and #pathSpec.Path > 0, context .. ".Path must be a non-empty array.")

	for key in pairs(pathSpec.Path) do
		assert(
			type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #pathSpec.Path,
			context .. ".Path must be an array of strings."
		)
	end

	for index = 1, #pathSpec.Path do
		local childName = pathSpec.Path[index]
		assert(
			type(childName) == "string" and childName ~= "",
			("%s.Path[%d] must be a non-empty string."):format(context, index)
		)
	end

	return pathSpec.RootKey, pathSpec.Path
end

local function missingPathError(rootKey, path, context)
	local suffix = context and (" (" .. tostring(context) .. ")") or ""
	error(
		("Missing instance path [RootKey=%s] %s%s"):format(rootKey, formatPath(path), suffix),
		3
	)
end

function InstancePath.Format(pathSpec)
	local _, path = getPathSpec(pathSpec, "InstancePath.Format")
	return formatPath(path)
end

function InstancePath.Components(pathSpec)
	local _, path = getPathSpec(pathSpec, "InstancePath.Components")
	return path
end

function InstancePath.Find(root, pathSpec)
	local _, path = getPathSpec(pathSpec, "InstancePath.Find")
	assert(typeof(root) == "Instance", "InstancePath.Find root must be an Instance.")

	local current = root
	for _, childName in ipairs(path) do
		current = current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

function InstancePath.Wait(root, pathSpec, timeout)
	local _, path = getPathSpec(pathSpec, "InstancePath.Wait")
	assert(typeof(root) == "Instance", "InstancePath.Wait root must be an Instance.")

	local current = root
	local deadline = timeout and (os.clock() + math.max(tonumber(timeout) or 0, 0)) or nil

	for _, childName in ipairs(path) do
		local remaining = deadline and math.max(deadline - os.clock(), 0) or nil
		current = remaining and current:WaitForChild(childName, remaining) or current:WaitForChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

function InstancePath.Require(root, pathSpec, context)
	local rootKey, path = getPathSpec(pathSpec, context or "InstancePath.Require")
	local found = InstancePath.Find(root, pathSpec)
	if found then
		return found
	end

	missingPathError(rootKey, path, context)
end

function InstancePath.FindSpec(roots, pathSpec)
	local rootKey = getPathSpec(pathSpec, "InstancePath.FindSpec")
	assert(type(roots) == "table", "InstancePath.FindSpec roots must be a table.")

	local root = roots[rootKey]
	assert(root == nil or typeof(root) == "Instance", "InstancePath.FindSpec root mapping must contain Instances.")
	if not root then
		return nil
	end

	return InstancePath.Find(root, pathSpec)
end

function InstancePath.WaitSpec(roots, pathSpec, timeout)
	local rootKey = getPathSpec(pathSpec, "InstancePath.WaitSpec")
	assert(type(roots) == "table", "InstancePath.WaitSpec roots must be a table.")

	local root = roots[rootKey]
	assert(root == nil or typeof(root) == "Instance", "InstancePath.WaitSpec root mapping must contain Instances.")
	if not root then
		return nil
	end

	return InstancePath.Wait(root, pathSpec, timeout)
end

function InstancePath.RequireSpec(roots, pathSpec, context)
	local rootKey, path = getPathSpec(pathSpec, context or "InstancePath.RequireSpec")
	assert(type(roots) == "table", "InstancePath.RequireSpec roots must be a table.")

	local root = roots[rootKey]
	if root == nil then
		missingPathError(rootKey, path, context or "missing root mapping")
	end
	assert(typeof(root) == "Instance", "InstancePath.RequireSpec root mapping must contain Instances.")

	return InstancePath.Require(root, pathSpec, context)
end

return InstancePath
