--!strict
--!optimize 2

local Snap = require(script.Parent.Parent.Snap)

type SnapAny = any

export type ChannelEntry = {
	signals: { [string]: SnapAny },
	methods: { [string]: SnapAny },
	properties: { [string]: SnapAny },
}

local SIGNAL = "Signal"
local METHOD = "Method"
local PROPERTY = "Property"
local PROPERTY_PREFIX = "_p_"

local function isMarker(value: any): boolean
	return type(value) == "table" and value._nexusType ~= nil
end

local Bridge = {}

function Bridge.sortedServiceNames(serviceSchemas: { [string]: any }): { string }
	local names: { string } = {}
	for serviceName in serviceSchemas do
		table.insert(names, serviceName)
	end
	table.sort(names)
	return names
end

function Bridge.buildChannel(serviceName: string, markers: { [string]: any }): ChannelEntry
	local entry: ChannelEntry = {
		signals = {},
		methods = {},
		properties = {},
	}

	local defs: { [string]: any } = {}
	for name, marker in markers do
		if not isMarker(marker) then
			continue
		end

		if marker._nexusType == SIGNAL then
			defs[name] = Snap.event(marker._dataType, marker._reliability)
		elseif marker._nexusType == METHOD then
			defs[name] = Snap.request(marker._requestType, marker._responseType)
		elseif marker._nexusType == PROPERTY then
			defs[PROPERTY_PREFIX .. name] = Snap.event(marker._dataType, "Reliable")
		end
	end

	local ns = (Snap :: any).channel(serviceName, defs)

	for name, marker in markers do
		if not isMarker(marker) then
			continue
		end

		if marker._nexusType == SIGNAL then
			entry.signals[name] = (ns :: any)[name]
		elseif marker._nexusType == METHOD then
			entry.methods[name] = (ns :: any)[name]
		elseif marker._nexusType == PROPERTY then
			entry.properties[name] = (ns :: any)[PROPERTY_PREFIX .. name]
		end
	end

	return entry
end

function Bridge.build(serviceSchemas: { [string]: { [string]: any } }): { [string]: ChannelEntry }
	local result: { [string]: ChannelEntry } = {}
	for _, serviceName in Bridge.sortedServiceNames(serviceSchemas) do
		local markers = serviceSchemas[serviceName]
		result[serviceName] = Bridge.buildChannel(serviceName, markers)
	end
	return result
end

return table.freeze(Bridge)
