# Services and Controllers

This page explains how Nexus splits application logic between services and
controllers.

## Services

A service is registered with `Nexus.CreateService`.

```luau
local Service = Nexus.CreateService({
	Name = "InventoryService",
	Order = 10,
	Client = {
		ItemAdded = Nexus.Signal(Nexus.t.string),
		GetCount = Nexus.Method({
			Request = Nexus.t.string,
			Response = Nexus.t.uint32,
		}),
		Capacity = Nexus.Property(Nexus.t.uint32, 20),
	},
})
```

### Service fields

- `Name` (required)
- `Order` (optional, default `0`)
- `Client` marker table (optional)
- `Middleware` (optional)

### Service lifecycle

- `NexusInit(self)`  
  Runs first (ordered)
- `NexusStart(self)`  
  Runs after init phase
- Optional runtime hooks:
  - `OnHeartbeat(self, dt)`
  - `OnStepped(self, time, dt)`
  - `OnPostSimulation(self, dt)`
  - `OnPlayerAdded(self, player)`
  - `OnPlayerRemoving(self, player)`

Services are the right place for shared state, authoritative logic, and
client-facing contracts.

## Controllers

A controller is registered with `Nexus.CreateController`.

```luau
local Controller = Nexus.CreateController({
	Name = "InventoryController",
	Order = 10,
})
```

### Controller lifecycle

- `NexusInit(self)`
- `NexusStart(self)`
- Optional hooks:
  - `OnHeartbeat(self, dt)`
  - `OnRenderStepped(self, dt)`
  - `OnPostSimulation(self, dt)`

Controllers are usually the right home for UI state, local input handling,
camera logic, and other client-owned behavior.

> [!IMPORTANT]
> To use `Nexus.GetService` on the client, the client framework must know the service's contract. 
> You must expose the service definitions (specifically the `.Client` schemas) to the client (e.g. in `ReplicatedStorage`) and call `Nexus.AddServices(SharedFolder)` on the client before starting.

## Access helpers

- `Nexus.GetService(name)`
- `Nexus.GetController(name)`
- `Nexus.OnServiceReady(name) -> Promise`
- `Nexus.OnControllerReady(name) -> Promise`

## License

MIT. See `LICENSE`.
