# Nexus

Nexus is a high-performance Luau framework for Roblox.

It follows a service/controller architecture inspired by Knit-style workflows
and uses Snap for binary networking.

## Features

- Declarative service markers (`Signal`, `UnreliableSignal`, `Method`, `Property`)
- Typed serialization through `Nexus.t` (Snap data types)
- Quick method signature (`Nexus.Method(requestType, responseType, timeout?)`)
- Raw Snap access via `Nexus.Snap`
- Service and controller lifecycle (`NexusInit`, `NexusStart`)
- Global and per-service middleware (Inbound/Outbound)
- Deterministic `Order` execution
- Promise-based readiness helpers (`OnServiceReady`, `OnControllerReady`)
- Graceful shutdown via `Nexus.Stop()`

## Installation

```toml
[dependencies]
Nexus = "cometahn142/nexus@^0.3"
```

## Server

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ServerScriptService.Services)
Nexus.Start():andThen(function()
	print("[Nexus] Server ready")
end)
```

## Client

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ReplicatedStorage.SharedSchemas)
Nexus.AddControllers(PlayerScripts.Controllers)
Nexus.Start():andThen(function()
	print("[Nexus] Client ready")
end)
```

## Documentation

- [Installation](./docs/installation.md)
- [Usage Patterns](./docs/usage-patterns.md)
- [Nexus API](./docs/nexus.md)
- [Services and Controllers](./docs/services-and-controllers.md)
- [Middleware](./docs/middleware.md)

## License

MIT. See `LICENSE`.
