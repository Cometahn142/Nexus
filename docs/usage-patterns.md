# Usage Patterns

This page focuses on the way Nexus is typically used in real projects rather
than listing every function in isolation.

## Bootstrapping

On the server, load services and start Nexus:

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ServerScriptService.Services)
Nexus.Start()
```

On the client, load shared schemas and controllers:

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ReplicatedStorage.SharedSchemas)
Nexus.AddControllers(PlayerScripts.Controllers)
Nexus.Start()
```

> [!IMPORTANT]
> The client requires access to the server's `.Client` table declarations. Always map them via `Nexus.AddServices` on the client using shared scripts.

## Building services around contracts

The most important pattern in Nexus is defining the client-facing contract
through markers.

```luau
local InventoryService = Nexus.CreateService({
	Name = "InventoryService",
	Client = {
		ItemAdded = Nexus.Signal(Nexus.t.string),
		GetCount = Nexus.Method(Nexus.t.string, Nexus.t.uint32),
		Capacity = Nexus.Property(Nexus.t.uint32, 20),
	},
})
```

This makes the service boundary explicit and keeps networking close to the
feature it belongs to.

When needed, you can still use raw Snap APIs through `Nexus.Snap` without
adding another require path.

## Using controllers as client owners

Controllers are best used as the client-side owners of UI, local state, and
service consumption.

```luau
local InventoryController = Nexus.CreateController({
	Name = "InventoryController",
})
```

Keep rendering, local input, and presentation logic here.

## Middleware for cross-cutting rules

Use middleware when payload rules should not live inside every signal or method
handler.

Typical examples:

- validation
- tagging outgoing payloads
- tracing
- shared filtering rules

See the dedicated [Middleware](./middleware.md) page for details.

## Ordering and startup

Use `Order` when one service or controller should initialize before another.
Use `OnServiceReady` and `OnControllerReady` when asynchronous readiness is the
more natural dependency boundary.

## Practical Advice

- Keep service APIs small and explicit.
- Prefer shared schemas over duplicated remote definitions.
- Put view ownership in controllers, not services.
- Treat middleware as infrastructure, not business logic.

## Next

- [Installation](./installation.md)
- [Nexus API](./nexus.md)
- [Services and Controllers](./services-and-controllers.md)
- [Middleware](./middleware.md)

## License

MIT. See `LICENSE`.
