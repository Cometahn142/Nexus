# Nexus

이 페이지는 Nexus가 제공하는 공개 API를 요약합니다.

## 핵심 상수

- `Nexus.Version`
- `Nexus.Player` (클라이언트 전용)
- `Nexus.Snap` (Snap 모듈 재내보내기)
- `Nexus.t`
- `Nexus.Middleware`

## 마커 팩토리 (Marker Factories)

- `Nexus.Signal(dataType, reliability?)`
- `Nexus.UnreliableSignal(dataType)`
- `Nexus.Method({ Request, Response, Timeout? })`
- `Nexus.Method(requestType, responseType, timeout?)`
- `Nexus.Property(dataType, initialValue)`

이것들은 서비스의 클라이언트용 계약(Contract)을 정의합니다.

## 등록 및 로드

- `Nexus.CreateService(serviceDef)`
- `Nexus.AddServices(folder)`
- `Nexus.GetService(serviceName)`
- `Nexus.OnServiceReady(serviceName)`

- `Nexus.CreateController(controllerDef)`
- `Nexus.AddControllers(folder)`
- `Nexus.GetController(controllerName)`
- `Nexus.OnControllerReady(controllerName)`

- `Nexus.AddModules(folder)`

## 생명주기

- `Nexus.Start(options?)`
- `Nexus.Stop()`
- `Nexus.OnStart()`
- `Nexus.IsStarted()`

## 런타임 원격 객체 (Remotes)

### 서버 측

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

### 클라이언트 측

- `ClientSignal.listen(callback)`
- `ClientSignal.send(data)`
- `ClientSignal.Wait()`

- `ClientMethod.request(data)`
- `ClientMethod.tryRequest(data)`

- `ClientProperty.Get()`
- `ClientProperty.Observe(callback)`
- `ClientProperty.OnChanged(callback)`

## 관련 문서

- [설치 방법 (Installation)](./installation.md)
- [사용 패턴 (Usage Patterns)](./usage-patterns.md)
- [서비스와 컨트롤러 (Services and Controllers)](./services-and-controllers.md)
- [미들웨어 (Middleware)](./middleware.md)

## 라이선스

MIT. `LICENSE` 파일을 참조하세요.
