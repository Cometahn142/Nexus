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

type BridgeEntry = Bridge.NamespaceEntry
type Janitor = Janitor.Janitor
type MiddlewareFn = Middleware.Middleware

export type ServiceDef = {
	Name: string,
	Order: number?,
	Client: { [string]: any }?,
	Middleware: { Inbound: { MiddlewareFn }?, Outbound: { MiddlewareFn }? }?,
	[string]: any,
}

export type Service = ServiceDef & {
	NexusInit: ((self: Service) -> any)?,
	NexusStart: ((self: Service) -> any)?,
}

local services: { [string]: Service } = {}
local servicesInInsertOrder: { Service } = {}
local started = false
local startedComplete = false
local onStartedComplete = Signal.new()
local onServiceRegistered = Signal.new()

local rootJanitor: Janitor = Janitor.new()

type PropertyHandle = {
	packet: any,
	getForPlayer: (player: Player) -> any,
	clearPlayer: (player: Player) -> (),
}
local propertyHandles: { PropertyHandle } = {}

local globalMiddleware = {
	Inbound = {} :: { MiddlewareFn },
	Outbound = {} :: { MiddlewareFn },
}

local function createRemoteSignal(packet: any, serviceMw: { Inbound: { MiddlewareFn }?, Outbound: { MiddlewareFn }? }?): any
	local inbound = if serviceMw then serviceMw.Inbound else nil
	local outbound = if serviceMw then serviceMw.Outbound else nil

	local self = {}

	function self.FireTo(_: any, player: Player, data: any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, player, data)
		if not ok then
			return
		end
		packet:sendTo(player, transformed)
	end

	function self.FireAll(_: any, data: any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, nil, data)
		if not ok then
			return
		end
		packet:sendToAll(transformed)
	end

	function self.FireAllExcept(_: any, except: Player, data: any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, nil, data)
		if not ok then
			return
		end
		packet:sendToAllExcept(except, transformed)
	end

	function self.FireList(_: any, list: { Player }, data: any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, nil, data)
		if not ok then
			return
		end
		packet:sendToList(list, transformed)
	end

	function self.Connect(_: any, callback: (data: any, sender: Player) -> ()): any
		local connected = true
		local unlisten = packet:listen(function(sender: Player, data: any)
			if not connected then
				return
			end
			local ok, transformed = Middleware.runInbound(globalMiddleware.Inbound, inbound, sender, data)
			if not ok then
				return
			end
			callback(transformed, sender)
		end)

		local conn: any = { Connected = true }
		function conn:Disconnect()
			if not connected then
				return
			end
			connected = false
			self.Connected = false
			unlisten()
		end
		return conn
	end

	function self.Wait(_: any): (any, Player)
		local thread = coroutine.running()
		local received = false
		local unlisten: (() -> ())? = nil

		unlisten = packet:listen(function(sender: Player, data: any)
			if received then
				return
			end
			local ok, transformed = Middleware.runInbound(globalMiddleware.Inbound, inbound, sender, data)
			if not ok then
				return
			end
			received = true
			if unlisten then
				unlisten()
			end
			task.spawn(thread, transformed, sender)
		end)

		return coroutine.yield()
	end

	return table.freeze(self)
end

local function createRemoteMethod(snapInvoke: any, serviceMw: { Inbound: { MiddlewareFn }?, Outbound: { MiddlewareFn }? }?): any
	local inbound = if serviceMw then serviceMw.Inbound else nil
	local outbound = if serviceMw then serviceMw.Outbound else nil

	local self = {}

	function self.OnInvoke(_: any, handler: (player: Player, data: any) -> any)
		snapInvoke:handle(function(sender: Player, data: any): any
			local ok, transformed = Middleware.runInbound(globalMiddleware.Inbound, inbound, sender, data)
			if not ok then
				error("[Nexus] Inbound middleware rejected invoke", 0)
			end
			return handler(sender, transformed)
		end)
	end

	function self.Invoke(_: any, player: Player, data: any): any
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, player, data)
		if not ok then
			error("[Nexus] Outbound middleware rejected invoke", 2)
		end
		local success, result = snapInvoke:invoke(player, transformed)
		if not success then
			error(result, 2)
		end
		return result
	end

	function self.TryInvoke(_: any, player: Player, data: any): (boolean, any)
		local ok, transformed = Middleware.runOutbound(globalMiddleware.Outbound, outbound, player, data)
		if not ok then
			return false, "outbound middleware rejected"
		end
		return snapInvoke:invoke(player, transformed)
	end

	return table.freeze(self)
end

local function createRemoteProperty(packet: any, initialValue: any): any
	local value: any = initialValue
	local perPlayer: { [Player]: any } = {}

	local self = {}

	function self.Set(_: any, newValue: any)
		value = newValue
		if next(perPlayer) ~= nil then
			for _, player in Players:GetPlayers() do
				if perPlayer[player] == nil then
					packet:sendTo(player, newValue)
				end
			end
		else
			packet:sendToAll(newValue)
		end
	end

	function self.SetFor(_: any, player: Player, newValue: any)
		perPlayer[player] = newValue
		packet:sendTo(player, newValue)
	end

	function self.ClearFor(_: any, player: Player)
		if perPlayer[player] == nil then
			return
		end
		perPlayer[player] = nil
		packet:sendTo(player, value)
	end

	function self.Get(_: any): any
		return value
	end

	function self.GetFor(_: any, player: Player): any
		local override = perPlayer[player]
		if override ~= nil then
			return override
		end
		return value
	end

	table.insert(propertyHandles, {
		packet = packet,
		getForPlayer = function(player: Player): any
			local ov = perPlayer[player]
			return if ov ~= nil then ov else value
		end,
		clearPlayer = function(player: Player)
			perPlayer[player] = nil
		end,
	})

	return self
end

local function bindService(service: Service, nsEntry: BridgeEntry)
	local client = service.Client :: { [string]: any }
	local mw = service.Middleware

	for name, marker in client do
		if type(marker) ~= "table" or marker._nexusType == nil then
			continue
		end

		if marker._nexusType == "Signal" then
			client[name] = createRemoteSignal(nsEntry.signals[name], mw)
		elseif marker._nexusType == "Method" then
			client[name] = createRemoteMethod(nsEntry.methods[name], mw)
		elseif marker._nexusType == "Property" then
			client[name] = createRemoteProperty(nsEntry.properties[name], marker._initialValue)
		end
	end
end

local function collectSchemas(): { [string]: { [string]: any } }
	local schemas: { [string]: { [string]: any } } = {}
	for serviceName, service in services do
		local client = service.Client
		if client and next(client :: any) ~= nil then
			schemas[serviceName] = client :: any
		end
	end
	return schemas
end

local function syncPlayerProperties(player: Player)
	for _, handle in propertyHandles do
		handle.packet:sendTo(player, handle.getForPlayer(player))
	end
end

local function orderedServices(): { Service }
	local list: { Service } = table.create(#servicesInInsertOrder)
	for i, service in servicesInInsertOrder do
		list[i] = service
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
Nexus.PlayerAdded = Signal.new()
Nexus.PlayerLeaving = Signal.new()
Nexus.Middleware = globalMiddleware

function Nexus.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "[Nexus] Service must be a table")
	assert(
		type(serviceDef.Name) == "string" and #serviceDef.Name > 0,
		"[Nexus] Service.Name must be a non-empty string"
	)
	assert(not services[serviceDef.Name], `[Nexus] Service "{serviceDef.Name}" already exists`)
	assert(not started, "[Nexus] Cannot create services after Start()")

	local service = serviceDef :: Service
	if type(service.Client) ~= "table" then
		service.Client = {}
	end

	services[service.Name] = service
	table.insert(servicesInInsertOrder, service)
	onServiceRegistered:Fire(service.Name, service)
	return service
end

function Nexus.AddServices(folder: Instance): { Service }
	assert(not started, "[Nexus] Cannot add services after Start()")
	local loaded = Loader.loadAll(folder)
	local out: { Service } = {}
	for _, value in loaded do
		if type(value) == "table" and type(value.Name) == "string" and services[value.Name] == value then
			table.insert(out, value)
		end
	end
	return out
end

function Nexus.AddModules(folder: Instance): { any }
	return Loader.loadAll(folder)
end

function Nexus.GetService(serviceName: string): Service
	local service = services[serviceName]
	assert(service, `[Nexus] Service "{serviceName}" not found`)
	return service
end

function Nexus.OnServiceReady(serviceName: string): any
	return Promise.new(function(resolve)
		local existing = services[serviceName]
		if existing then
			resolve(existing)
			return
		end
		local conn: any
		conn = onServiceRegistered:Connect(function(name, service)
			if name == serviceName then
				conn:Disconnect()
				resolve(service)
			end
		end)
	end)
end

function Nexus.IsStarted(): boolean
	return startedComplete
end

function Nexus.CreateController(_: any): never
	error("[Nexus] CreateController can only be called on the client", 2)
end
function Nexus.AddControllers(_: any): never
	error("[Nexus] AddControllers can only be called on the client", 2)
end
function Nexus.GetController(_: any): never
	error("[Nexus] GetController can only be called on the client", 2)
end
function Nexus.OnControllerReady(_: any): never
	error("[Nexus] OnControllerReady can only be called on the client", 2)
end

function Nexus.Start(_options: { [string]: any }?): any
	if started then
		return Promise.reject("[Nexus] Already started")
	end
	started = true

	return Promise.new(function(resolve: any, reject: any)
		local schemas = collectSchemas()
		local namespaces = Bridge.build(schemas)

		for serviceName, nsEntry in namespaces do
			local service = services[serviceName]
			if service then
				bindService(service, nsEntry)
			end
		end

		local ordered = orderedServices()

		local initPromises: { any } = {}
		for _, service in ordered do
			if type(service.NexusInit) == "function" then
				local ok, result = pcall(service.NexusInit :: any, service)
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

		for _, service in ordered do
			if type(service.OnHeartbeat) == "function" then
				rootJanitor:Add(RunService.Heartbeat:Connect(function(dt: number)
					service:OnHeartbeat(dt)
				end))
			end
			if type(service.OnStepped) == "function" then
				rootJanitor:Add(RunService.Stepped:Connect(function(time: number, dt: number)
					service:OnStepped(time, dt)
				end))
			end
			if type(service.OnPostSimulation) == "function" then
				rootJanitor:Add(RunService.PostSimulation:Connect(function(dt: number)
					service:OnPostSimulation(dt)
				end))
			end
		end

		rootJanitor:Add(Players.PlayerAdded:Connect(function(player: Player)
			syncPlayerProperties(player)
			Nexus.PlayerAdded:Fire(player)
			for _, service in ordered do
				if type(service.OnPlayerAdded) == "function" then
					task.spawn(service.OnPlayerAdded :: any, service, player)
				end
			end
		end))
		rootJanitor:Add(Players.PlayerRemoving:Connect(function(player: Player)
			Nexus.PlayerLeaving:Fire(player)
			for _, service in ordered do
				if type(service.OnPlayerRemoving) == "function" then
					task.spawn(service.OnPlayerRemoving :: any, service, player)
				end
			end
			for _, handle in propertyHandles do
				handle.clearPlayer(player)
			end
		end))

		for _, player in Players:GetPlayers() do
			task.spawn(function()
				syncPlayerProperties(player)
				Nexus.PlayerAdded:Fire(player)
				for _, service in ordered do
					if type(service.OnPlayerAdded) == "function" then
						task.spawn(service.OnPlayerAdded :: any, service, player)
					end
				end
			end)
		end

		for _, service in ordered do
			if type(service.NexusStart) == "function" then
				task.spawn(service.NexusStart :: any, service)
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
		table.clear(services)
		table.clear(servicesInInsertOrder)
		table.clear(propertyHandles)
		started = false
		startedComplete = false
		resolve()
	end)
end

return Nexus
