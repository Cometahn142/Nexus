--!strict
--!optimize 2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local Janitor = require(script.Parent.Parent.Janitor)

local Bridge = require(script.Parent.Bridge)
local Loader = require(script.Parent.Loader)
local Middleware = require(script.Parent.Middleware)

type BridgeEntry = Bridge.ChannelEntry
type Janitor = Janitor.Janitor
type MiddlewareFn = Middleware.Middleware

export type ControllerDef = {
	Name: string,
	Order: number?,
	[string]: any,
}

export type Controller = ControllerDef & {
	NexusInit: ((self: Controller) -> any)?,
	NexusStart: ((self: Controller) -> any)?,
}

local controllers: { [string]: Controller } = {}
local controllersInInsertOrder: { Controller } = {}

local serviceSchemas: { [string]: { [string]: any } } = {}
local serviceProxies: { [string]: any } = {}
local serviceBridge: { [string]: BridgeEntry } = {}
local lazyProxies: { [string]: any } = {}

local started = false
local startedComplete = false
local onStartedComplete = Signal.new()
local onControllerRegistered = Signal.new()
local onServiceSchemaRegistered = Signal.new()

local rootJanitor: Janitor = Janitor.new()

local globalMiddleware = {
	Inbound = {} :: { MiddlewareFn },
	Outbound = {} :: { MiddlewareFn },
}

local function createClientSignal(packet: any): any
	local self = {}

	function self.listen(_: any, callback: (data: any) -> ()): any
		local connected = true
		local unlisten = packet:listen(function(data: any)
			if not connected then
				return
			end
			local ok, transformed = Middleware.runInbound(globalMiddleware.Inbound, nil, nil, data)
			if not ok then
				return
			end
			callback(transformed)
		end)

		local conn: any = { Connected = true }
		function conn.Disconnect(c: any)
			if not connected then
				return
			end
			connected = false
			c.Connected = false
			unlisten()
		end
		return conn
	end

	function self.send(_: any, data: any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, nil, nil, data)
		if not ok then
			return
		end
		packet:send(transformed)
	end

	function self.Wait(_: any): any
		local thread = coroutine.running()
		local received = false
		local unlisten: (() -> ())? = nil

		unlisten = packet:listen(function(data: any)
			if received then
				return
			end
			local ok, transformed = Middleware.runInbound(globalMiddleware.Inbound, nil, nil, data)
			if not ok then
				return
			end
			received = true
			if unlisten then
				unlisten()
			end
			task.spawn(thread, transformed)
		end)

		return coroutine.yield()
	end

	return table.freeze(self)
end

local function createClientMethod(snapInvoke: any): any
	local self = {}

	function self.request(_: any, data: any): any
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, nil, nil, data)
		if not ok then
			error("[Nexus] Outbound middleware rejected invoke", 2)
		end
		local success, result = snapInvoke:request(transformed)
		if not success then
			error(result, 2)
		end
		return result
	end

	function self.tryRequest(_: any, data: any): (boolean, any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, nil, nil, data)
		if not ok then
			return false, "outbound middleware rejected"
		end
		return snapInvoke:request(transformed)
	end

	return table.freeze(self)
end

local function createClientProperty(packet: any): any
	local value: any = nil
	local hasValue = false
	local observers: { (value: any) -> () } = {}
	local changeListeners: { (newValue: any, oldValue: any?) -> () } = {}

	packet:listen(function(data: any)
		local old = value
		value = data
		hasValue = true
		for _, fn in observers do
			task.spawn(fn, data)
		end
		for _, fn in changeListeners do
			task.spawn(fn, data, old)
		end
	end)

	local self = {}

	function self.Get(_: any): any
		return value
	end

	function self.Observe(_: any, callback: (value: any) -> ()): any
		table.insert(observers, callback)
		if hasValue then
			task.spawn(callback, value)
		end

		local conn: any = { Connected = true }
		function conn.Disconnect(c: any)
			if not c.Connected then
				return
			end
			c.Connected = false
			local idx = table.find(observers, callback)
			if idx then
				table.remove(observers, idx)
			end
		end
		return conn
	end

	function self.OnChanged(_: any, callback: (newValue: any, oldValue: any?) -> ()): any
		table.insert(changeListeners, callback)

		local conn: any = { Connected = true }
		function conn.Disconnect(c: any)
			if not c.Connected then
				return
			end
			c.Connected = false
			local idx = table.find(changeListeners, callback)
			if idx then
				table.remove(changeListeners, idx)
			end
		end
		return conn
	end

	return self
end

local function buildServiceProxy(nsEntry: BridgeEntry, markers: { [string]: any }): { [string]: any }
	local proxy: { [string]: any } = {}

	for name, marker in markers do
		if type(marker) ~= "table" or marker._nexusType == nil then
			continue
		end

		if marker._nexusType == "Signal" then
			proxy[name] = createClientSignal(nsEntry.signals[name])
		elseif marker._nexusType == "Method" then
			proxy[name] = createClientMethod(nsEntry.methods[name])
		elseif marker._nexusType == "Property" then
			proxy[name] = createClientProperty(nsEntry.properties[name])
		end
	end

	return proxy
end

--- Registers every Snap channel in the same order as the server (`Bridge.build`), so `wireId` lines up.
local function buildAllClientChannelsInOrder()
	for _, serviceName in Bridge.sortedServiceNames(serviceSchemas) do
		if serviceProxies[serviceName] then
			continue
		end
		local markers = serviceSchemas[serviceName]
		if not markers then
			continue
		end

		local nsEntry = Bridge.buildChannel(serviceName, markers)
		serviceBridge[serviceName] = nsEntry
		local realProxy = buildServiceProxy(nsEntry, markers)
		local lazyProxy = lazyProxies[serviceName]
		if lazyProxy then
			for k, v in realProxy do
				lazyProxy[k] = v
			end
			serviceProxies[serviceName] = lazyProxy
			lazyProxies[serviceName] = nil
		else
			serviceProxies[serviceName] = realProxy
		end
	end
end

local function ensureServiceBuilt(serviceName: string): { [string]: any }?
	local existing = serviceProxies[serviceName]
	if existing then
		return existing
	end

	local markers = serviceSchemas[serviceName]
	if not markers then
		return nil
	end

	if not started then
		return nil
	end

	local nsEntry = Bridge.buildChannel(serviceName, markers)
	serviceBridge[serviceName] = nsEntry
	local proxy = buildServiceProxy(nsEntry, markers)
	serviceProxies[serviceName] = proxy
	return proxy
end

local function orderedControllers(): { Controller }
	local list: { Controller } = table.create(#controllersInInsertOrder)
	for i, controller in controllersInInsertOrder do
		list[i] = controller
	end
	table.sort(list, function(a, b)
		local ao = a.Order or 0
		local bo = b.Order or 0
		if ao == bo then
			return a.Name < b.Name
		end
		return ao < bo
	end)
	return list
end

local Nexus: { [string]: any } = {}
Nexus.Version = "0.2.1"
Nexus.Player = Players.LocalPlayer
Nexus.Middleware = globalMiddleware

function Nexus.CreateService(serviceDef: any): any
	assert(type(serviceDef) == "table", "[Nexus] Service must be a table")
	local name = serviceDef.Name
	assert(type(name) == "string" and #name > 0, "[Nexus] Service.Name must be a non-empty string")

	local markers = serviceDef.Client
	if type(markers) == "table" and next(markers) ~= nil then
		serviceSchemas[name] = markers

		-- Snap channels are created in `Nexus.Start` (sorted order) so wire ids match the server.

		onServiceSchemaRegistered:Fire(name)
	end

	return serviceDef
end

function Nexus.CreateController<T>(controllerDef: T): T & Controller
	assert(type(controllerDef) == "table", "[Nexus] Controller must be a table")
	assert(
		type(controllerDef.Name) == "string" and #controllerDef.Name > 0,
		"[Nexus] Controller.Name must be a non-empty string"
	)
	assert(not controllers[controllerDef.Name], `[Nexus] Controller "{controllerDef.Name}" already exists`)
	assert(not started, "[Nexus] Cannot create controllers after Start()")

	local controller = controllerDef :: Controller
	controllers[controller.Name] = controller
	table.insert(controllersInInsertOrder, controller)
	onControllerRegistered:Fire(controller.Name, controller)

	return controllerDef :: any
end

function Nexus.AddServices(folder: Instance): { any }
	assert(not started, "[Nexus] Cannot add services after Start()")
	return Loader.loadAll(folder)
end

function Nexus.AddControllers(folder: Instance): { Controller }
	assert(not started, "[Nexus] Cannot add controllers after Start()")
	local loaded = Loader.loadAll(folder)
	local out: { Controller } = {}
	for _, value: any in loaded do
		if type(value) == "table" and type(value.Name) == "string" and controllers[value.Name] == value then
			table.insert(out, value)
		end
	end
	return out
end

function Nexus.AddModules(folder: Instance): { any }
	return Loader.loadAll(folder)
end

function Nexus.GetService(serviceName: string): any
	local built = ensureServiceBuilt(serviceName)
	if built then
		return built
	end

	local existingLazy = lazyProxies[serviceName]
	if existingLazy then
		return existingLazy
	end

	local lazyProxy: { [string]: any } = {}
	lazyProxies[serviceName] = lazyProxy

	return setmetatable(lazyProxy, {
		__index = function(_, key)
			if startedComplete then
				error(`[Nexus] Service "{serviceName}" member "{key}" accessed but service was never registered.`, 2)
			end
			return nil
		end,
	})
end

function Nexus.OnServiceReady(serviceName: string): any
	return Promise.new(function(resolve)
		if serviceSchemas[serviceName] then
			resolve(Nexus.GetService(serviceName))
			return
		end
		local conn: any
		conn = onServiceSchemaRegistered:Connect(function(name)
			if name == serviceName then
				conn:Disconnect()
				resolve(Nexus.GetService(serviceName))
			end
		end)
	end)
end

function Nexus.GetController(controllerName: string): Controller
	local controller = controllers[controllerName]
	assert(controller, `[Nexus] Controller "{controllerName}" not found`)
	return controller
end

function Nexus.OnControllerReady(controllerName: string): any
	return Promise.new(function(resolve)
		local existing = controllers[controllerName]
		if existing then
			resolve(existing)
			return
		end
		local conn: any
		conn = onControllerRegistered:Connect(function(name, controller)
			if name == controllerName then
				conn:Disconnect()
				resolve(controller)
			end
		end)
	end)
end

function Nexus.IsStarted(): boolean
	return startedComplete
end

function Nexus.Start(_options: { [string]: any }?): any
	if started then
		return Promise.reject("[Nexus] Already started")
	end
	started = true

	return Promise.new(function(resolve: any, reject: any)
		buildAllClientChannelsInOrder()

		local ordered = orderedControllers()

		local initPromises: { any } = {}
		for _, controller in ordered do
			if type(controller.NexusInit) == "function" then
				local ok, result = pcall(controller.NexusInit :: any, controller)
				if not ok then
					reject(result)
					return
				end
				if Promise.is(result) then
					table.insert(initPromises, result)
				end
			end
		end

		if #initPromises > 0 then
			local success, err = (Promise.all(initPromises) :: any):await()
			if not success then
				reject(err)
				return
			end
		end

		for serviceName in serviceSchemas do
			ensureServiceBuilt(serviceName)
		end

		for _, controller in ordered do
			if type(controller.OnHeartbeat) == "function" then
				rootJanitor:Add(RunService.Heartbeat:Connect(function(dt: number)
					controller:OnHeartbeat(dt)
				end))
			end
			if type(controller.OnRenderStepped) == "function" then
				rootJanitor:Add(RunService.RenderStepped:Connect(function(dt: number)
					controller:OnRenderStepped(dt)
				end))
			end
			if type(controller.OnPostSimulation) == "function" then
				rootJanitor:Add(RunService.PostSimulation:Connect(function(dt: number)
					controller:OnPostSimulation(dt)
				end))
			end
		end

		for _, controller in ordered do
			if type(controller.NexusStart) == "function" then
				task.spawn(controller.NexusStart :: any, controller)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()
		resolve()
	end)
end

function Nexus.OnStart(): any
	if startedComplete then
		return Promise.resolve()
	end
	return Promise.new(function(resolve: any)
		local conn: any
		conn = onStartedComplete:Connect(function()
			conn:Disconnect()
			resolve()
		end)
	end)
end

function Nexus.Stop(): any
	return Promise.new(function(resolve: any)
		if not started then
			resolve()
			return
		end
		rootJanitor:Cleanup()
		table.clear(controllers)
		table.clear(controllersInInsertOrder)
		table.clear(serviceSchemas)
		table.clear(serviceProxies)
		table.clear(serviceBridge)
		table.clear(lazyProxies)
		started = false
		startedComplete = false
		resolve()
	end)
end

return Nexus
