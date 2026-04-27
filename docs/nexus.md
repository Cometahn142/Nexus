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
- `Nexus.Property(dataType, initialValue)`

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

- `RemoteSignal.listen(callback)`
- `RemoteSignal.sendTo(player, data)`
- `RemoteSignal.sendToAll(data)`
- `RemoteSignal.sendToAllExcept(player, data)`
- `RemoteSignal.sendToList(players, data)`
- `RemoteSignal.Wait()`

- `RemoteMethod.handle(handler)`
- `RemoteMethod.request(player, data)`
- `RemoteMethod.tryRequest(player, data)`

- `RemoteProperty.Set(value)`
- `RemoteProperty.SetFor(player, value)`
- `RemoteProperty.ClearFor(player)`
- `RemoteProperty.Get()`
- `RemoteProperty.GetFor(player)`

### Client-side

- `ClientSignal.listen(callback)`
- `ClientSignal.send(data)`
- `ClientSignal.Wait()`

- `ClientMethod.request(data)`
- `ClientMethod.tryRequest(data)`

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
