# Nexus

This page summarizes the public API surface exposed by Nexus.

## Core constants

- `Nexus.Version`
- `Nexus.Player` (client only)
- `Nexus.Snap` (Snap module re-export)
- `Nexus.t`
- `Nexus.Middleware`

## Marker factories

- `Nexus.Signal(dataType, reliability?)`
- `Nexus.UnreliableSignal(dataType)`
- `Nexus.Method({ Request, Response, Timeout? })`
- `Nexus.Method(requestType, responseType, timeout?)`
- `Nexus.Property(dataType, initialValue)`
- `Nexus.DefineNamespace(namespaceName, builder)` (advanced Snap escape hatch)

These define the client-facing contract of a service.

## Registration and loading

- `Nexus.CreateService(serviceDef)`
- `Nexus.AddServices(folder)`
- `Nexus.GetService(serviceName)`
- `Nexus.OnServiceReady(serviceName)`

- `Nexus.CreateController(controllerDef)`
- `Nexus.AddControllers(folder)`
- `Nexus.GetController(controllerName)`
- `Nexus.OnControllerReady(controllerName)`

- `Nexus.AddModules(folder)`

## Lifecycle

- `Nexus.Start(options?)`
- `Nexus.Stop()`
- `Nexus.OnStart()`
- `Nexus.IsStarted()`

## Runtime remotes

### Server-side

- `RemoteSignal.FireTo(player, data)`
- `RemoteSignal.FireAll(data)`
- `RemoteSignal.FireAllExcept(player, data)`
- `RemoteSignal.FireList(players, data)`
- `RemoteSignal.Connect(callback)`
- `RemoteSignal.Wait()`

- `RemoteMethod.OnInvoke(handler)`
- `RemoteMethod.Invoke(player, data)`
- `RemoteMethod.TryInvoke(player, data)`

- `RemoteProperty.Set(value)`
- `RemoteProperty.SetFor(player, value)`
- `RemoteProperty.ClearFor(player)`
- `RemoteProperty.Get()`
- `RemoteProperty.GetFor(player)`

### Client-side

- `ClientSignal.Connect(callback)`
- `ClientSignal.Fire(data)`
- `ClientSignal.Wait()`

- `ClientMethod.Invoke(data)`
- `ClientMethod.TryInvoke(data)`

- `ClientProperty.Get()`
- `ClientProperty.Observe(callback)`
- `ClientProperty.OnChanged(callback)`

## Related Docs

- [Installation](./installation.md)
- [Usage Patterns](./usage-patterns.md)
- [Services and Controllers](./services-and-controllers.md)
- [Middleware](./middleware.md)

## License

MIT. See `LICENSE`.
