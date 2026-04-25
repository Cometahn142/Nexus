--!strict
--!optimize 2

export type Middleware = (player: Player?, data: any) -> (boolean, any?)

export type Pipeline = {
	Inbound: { Middleware }?,
	Outbound: { Middleware }?,
}

local Middleware = {}

local EMPTY: { Middleware } = table.freeze({})

local function runList(list: { Middleware }, player: Player?, data: any): (boolean, any)
	local current = data
	for _, fn in list do
		local ok, newData = fn(player, current)
		if not ok then
			return false, nil
		end
		if newData ~= nil then
			current = newData
		end
	end
	return true, current
end

function Middleware.runInbound(
	global: { Middleware }?,
	service: { Middleware }?,
	player: Player?,
	data: any
): (boolean, any)
	local globalList = global or EMPTY
	if #globalList > 0 then
		local ok, transformed = runList(globalList, player, data)
		if not ok then
			return false, nil
		end
		data = transformed
	end

	local serviceList = service or EMPTY
	if #serviceList > 0 then
		return runList(serviceList, player, data)
	end

	return true, data
end

function Middleware.runOutbound(
	global: { Middleware }?,
	service: { Middleware }?,
	player: Player?,
	data: any
): (boolean, any)
	local serviceList = service or EMPTY
	if #serviceList > 0 then
		local ok, transformed = runList(serviceList, player, data)
		if not ok then
			return false, nil
		end
		data = transformed
	end

	local globalList = global or EMPTY
	if #globalList > 0 then
		return runList(globalList, player, data)
	end

	return true, data
end

function Middleware.empty(): { Middleware }
	return EMPTY
end

return Middleware
