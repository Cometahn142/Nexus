--!strict
--!optimize 2

local RunService = game:GetService("RunService")

local Snap = require(script.Parent.Snap)

type DataType<T> = Snap.DataType<T>

export type Reliability = "Reliable" | "Unreliable"

export type SignalMarker<T> = {
	_nexusType: "Signal",
	_dataType: DataType<T>,
	_reliability: Reliability,
}

export type MethodMarker<TReq, TRes> = {
	_nexusType: "Method",
	_requestType: DataType<TReq>,
	_responseType: DataType<TRes>,
	_timeout: number,
}

type MethodConfig<TReq, TRes> = {
	Request: DataType<TReq>,
	Response: DataType<TRes>,
	Timeout: number?,
}

export type PropertyMarker<T> = {
	_nexusType: "Property",
	_dataType: DataType<T>,
	_initialValue: T,
}

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}
export type RemoteSignal<T> = {
	listen: (self: RemoteSignal<T>, callback: (data: T, sender: Player) -> ()) -> Connection,
	sendTo: (self: RemoteSignal<T>, player: Player, data: T) -> (),
	sendToAll: (self: RemoteSignal<T>, data: T) -> (),
	sendToAllExcept: (self: RemoteSignal<T>, except: Player, data: T) -> (),
	sendToList: (self: RemoteSignal<T>, players: { Player }, data: T) -> (),
	Wait: (self: RemoteSignal<T>) -> (T, Player),
}

export type RemoteMethod<TReq, TRes> = {
	handle: (self: RemoteMethod<TReq, TRes>, handler: (player: Player, data: TReq) -> TRes) -> (),
	request: (self: RemoteMethod<TReq, TRes>, player: Player, data: TReq) -> TRes,
	tryRequest: (self: RemoteMethod<TReq, TRes>, player: Player, data: TReq) -> (boolean, any),
}

export type RemoteProperty<T> = {
	Set: (self: RemoteProperty<T>, value: T) -> (),
	SetFor: (self: RemoteProperty<T>, player: Player, value: T) -> (),
	ClearFor: (self: RemoteProperty<T>, player: Player) -> (),
	Get: (self: RemoteProperty<T>) -> T,
	GetFor: (self: RemoteProperty<T>, player: Player) -> T,
}

export type ClientSignal<T> = {
	listen: (self: ClientSignal<T>, callback: (data: T) -> ()) -> Connection,
	send: (self: ClientSignal<T>, data: T) -> (),
	Wait: (self: ClientSignal<T>) -> T,
}

export type ClientMethod<TReq, TRes> = {
	request: (self: ClientMethod<TReq, TRes>, data: TReq) -> TRes,
	tryRequest: (self: ClientMethod<TReq, TRes>, data: TReq) -> (boolean, any),
}

export type ClientProperty<T> = {
	Get: (self: ClientProperty<T>) -> T?,
	Observe: (self: ClientProperty<T>, callback: (value: T) -> ()) -> Connection,
	OnChanged: (self: ClientProperty<T>, callback: (newValue: T, oldValue: T?) -> ()) -> Connection,
}

export type MiddlewareFn = (player: Player?, data: any) -> (boolean, any?)

export type MiddlewarePipeline = {
	Inbound: { MiddlewareFn }?,
	Outbound: { MiddlewareFn }?,
}

export type ServiceDef = {
	Name: string,
	Order: number?,
	Client: { [string]: any }?,
	Middleware: MiddlewarePipeline?,
	[string]: any,
}

export type Service = {
	Name: string,
	Order: number?,
	Client: { [string]: any },
	Middleware: MiddlewarePipeline?,
	NexusInit: ((self: Service) -> any)?,
	NexusStart: ((self: Service) -> any)?,
	OnHeartbeat: ((self: Service, dt: number) -> ())?,
	OnStepped: ((self: Service, time: number, dt: number) -> ())?,
	OnPostSimulation: ((self: Service, dt: number) -> ())?,
	OnPlayerAdded: ((self: Service, player: Player) -> ())?,
	OnPlayerRemoving: ((self: Service, player: Player) -> ())?,
	[string]: any,
}

export type ControllerDef = {
	Name: string,
	Order: number?,
	[string]: any,
}

export type Controller = {
	Name: string,
	Order: number?,
	NexusInit: ((self: Controller) -> any)?,
	NexusStart: ((self: Controller) -> any)?,
	OnHeartbeat: ((self: Controller, dt: number) -> ())?,
	OnRenderStepped: ((self: Controller, dt: number) -> ())?,
	OnPostSimulation: ((self: Controller, dt: number) -> ())?,
	[string]: any,
}

export type DataTypes = {
	bool: DataType<boolean>,

	uint8: DataType<number>,
	uint16: DataType<number>,
	uint32: DataType<number>,
	int8: DataType<number>,
	int16: DataType<number>,
	int32: DataType<number>,
	uvarint: DataType<number>,
	varint: DataType<number>,
	float32: DataType<number>,
	float64: DataType<number>,

	char: DataType<string>,
	string: DataType<string>,

	null: DataType<nil>,
	nothing: DataType<nil>,
	auto: DataType<any>,
	unknown: DataType<unknown>,
	inst: DataType<Instance?>,

	vector3: DataType<Vector3>,
	vec3: DataType<Vector3>,
	vector3int16: DataType<Vector3int16>,
	vec3int16: DataType<Vector3int16>,
	color3: DataType<Color3>,
	color3b: DataType<Color3>,
	cframe: DataType<CFrame>,

	struct: (fields: { [string]: DataType<any> }) -> DataType<{ [string]: any }>,
	array: <T>(element: DataType<T>) -> DataType<{ T }>,
	map: <K, V>(key: DataType<K>, value: DataType<V>) -> DataType<{ [K]: V }>,
	optional: <T>(inner: DataType<T>) -> DataType<T?>,
	flags: (names: { string }) -> DataType<{ [string]: boolean }>,
}

local t: DataTypes = {
	bool = Snap.bool,

	uint8 = Snap.uint8,
	uint16 = Snap.uint16,
	uint32 = Snap.uint32,
	int8 = Snap.int8,
	int16 = Snap.int16,
	int32 = Snap.int32,
	uvarint = Snap.uvarint,
	varint = Snap.varint,
	float32 = Snap.float32,
	float64 = Snap.float64,

	char = Snap.char,
	string = Snap.string,

	null = Snap.null,
	nothing = Snap.null,
	auto = Snap.auto,
	unknown = Snap.unknown,
	inst = Snap.inst,

	vector3 = Snap.vector3,
	vec3 = Snap.vector3,
	vector3int16 = Snap.vector3int16,
	vec3int16 = Snap.vector3int16,
	color3 = Snap.color3,
	color3b = Snap.color3b,
	cframe = Snap.cframe,

	struct = Snap.struct,
	array = Snap.array,
	map = Snap.map,
	optional = Snap.optional,
	flags = Snap.flags,
} :: any

local function Signal<T>(dataType: DataType<T>, reliability: Reliability?): SignalMarker<T>
	return table.freeze({
		_nexusType = "Signal" :: "Signal",
		_dataType = dataType,
		_reliability = (reliability or "Reliable") :: Reliability,
	}) :: any
end

local function UnreliableSignal<T>(dataType: DataType<T>): SignalMarker<T>
	return Signal(dataType, "Unreliable")
end

local function Method<TReq, TRes>(
	configOrRequest: MethodConfig<TReq, TRes> | DataType<TReq>,
	responseType: DataType<TRes>?,
	timeout: number?
): MethodMarker<TReq, TRes>
	local config: MethodConfig<TReq, TRes>
	if type(configOrRequest) == "table" then
		config = configOrRequest
	else
		config = {
			Request = configOrRequest,
			Response = responseType :: DataType<TRes>,
			Timeout = timeout,
		}
	end

	assert(type(config) == "table", "[Nexus] Method config must be a table")
	assert(config.Request ~= nil, "[Nexus] Method config.Request is required")
	assert(config.Response ~= nil, "[Nexus] Method config.Response is required")

	return table.freeze({
		_nexusType = "Method" :: "Method",
		_requestType = config.Request,
		_responseType = config.Response,
		_timeout = config.Timeout or 10,
	}) :: any
end

local function Property<T>(dataType: DataType<T>, initialValue: T): PropertyMarker<T>
	return table.freeze({
		_nexusType = "Property" :: "Property",
		_dataType = dataType,
		_initialValue = initialValue,
	}) :: any
end

export type NexusAPI = {
	Version: string,
	Player: Player?,
	Snap: typeof(Snap),
	t: DataTypes,

	Middleware: MiddlewarePipeline,

	Signal: <T>(dataType: DataType<T>, reliability: Reliability?) -> SignalMarker<T>,
	UnreliableSignal: <T>(dataType: DataType<T>) -> SignalMarker<T>,
	Method: (<TReq, TRes>(config: MethodConfig<TReq, TRes>) -> MethodMarker<TReq, TRes>) & (<TReq, TRes>(
		requestType: DataType<TReq>,
		responseType: DataType<TRes>,
		timeout: number?
	) -> MethodMarker<TReq, TRes>),
	Property: <T>(dataType: DataType<T>, initialValue: T) -> PropertyMarker<T>,

	CreateService: <T>(serviceDef: T) -> T & Service,
	AddServices: (folder: Instance) -> { Service },
	GetService: (serviceName: string) -> any,
	OnServiceReady: (serviceName: string) -> any,

	CreateController: <T>(controllerDef: T) -> T & Controller,
	AddControllers: (folder: Instance) -> { Controller },
	GetController: (controllerName: string) -> Controller,
	OnControllerReady: (controllerName: string) -> any,

	AddModules: (folder: Instance) -> { any },

	IsStarted: () -> boolean,
	Start: (options: { [string]: any }?) -> any,
	Stop: () -> any,
	OnStart: () -> any,

	PlayerAdded: any,
	PlayerLeaving: any,
}

local impl: { [string]: any }

if RunService:IsServer() then
	impl = require(script.Server)
else
	impl = require(script.Client)
end

impl.Signal = Signal
impl.UnreliableSignal = UnreliableSignal
impl.Method = Method
impl.Property = Property
impl.Snap = Snap
impl.t = t

return (impl :: any) :: NexusAPI
