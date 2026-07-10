local InstancePath = {}

local function unpackPath(pathSpec)
	if type(pathSpec) ~= "table" then
		return nil, nil
	end

	if pathSpec.Path ~= nil then
		return pathSpec.Path, pathSpec.RootKey
	end

	return pathSpec, nil
end

local function formatPath(path)
	local parts = {}
	for _, childName in ipairs(path or {}) do
		parts[#parts + 1] = tostring(childName)
	end
	return table.concat(parts, ".")
end

function InstancePath.Format(pathSpec)
	local path = unpackPath(pathSpec)
	return formatPath(path)
end

function InstancePath.Components(pathSpec)
	local path = unpackPath(pathSpec)
	if type(path) ~= "table" then
		return nil
	end
	return path
end

function InstancePath.Find(root, pathSpec)
	local path = unpackPath(pathSpec)
	if typeof(root) ~= "Instance" or type(path) ~= "table" then
		return nil
	end

	local current = root

	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

function InstancePath.Wait(root, pathSpec, timeout)
	local path = unpackPath(pathSpec)
	if typeof(root) ~= "Instance" or type(path) ~= "table" then
		return nil
	end

	local current = root
	local deadline = timeout and (os.clock() + math.max(timeout, 0)) or nil

	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		local remaining = deadline and math.max(deadline - os.clock(), 0) or nil
		current = remaining and current:WaitForChild(childName, remaining) or current:WaitForChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

function InstancePath.Require(root, pathSpec, context)
	local found = InstancePath.Find(root, pathSpec)
	if found then
		return found
	end

	local path, rootKey = unpackPath(pathSpec)
	local contextText = context and (" (" .. tostring(context) .. ")") or ""
	local rootText = rootKey and (" [RootKey=" .. tostring(rootKey) .. "]") or ""
	error("Missing instance path " .. formatPath(path) .. rootText .. contextText, 2)
end

function InstancePath.FindSpec(roots, pathSpec)
	if type(roots) ~= "table" or type(pathSpec) ~= "table" or type(pathSpec.RootKey) ~= "string" then
		return nil
	end
	return InstancePath.Find(roots[pathSpec.RootKey], pathSpec)
end

function InstancePath.WaitSpec(roots, pathSpec, timeout)
	if type(roots) ~= "table" or type(pathSpec) ~= "table" or type(pathSpec.RootKey) ~= "string" then
		return nil
	end
	return InstancePath.Wait(roots[pathSpec.RootKey], pathSpec, timeout)
end

function InstancePath.RequireSpec(roots, pathSpec, context)
	if type(roots) ~= "table" or type(pathSpec) ~= "table" or type(pathSpec.RootKey) ~= "string" then
		error("Invalid path specification" .. (context and (" (" .. tostring(context) .. ")") or ""), 2)
	end
	return InstancePath.Require(roots[pathSpec.RootKey], pathSpec, context)
end

return InstancePath
