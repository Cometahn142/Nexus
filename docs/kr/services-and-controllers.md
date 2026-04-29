# 서비스와 컨트롤러 (Services and Controllers)

이 페이지는 Nexus가 서비스와 컨트롤러 간에 애플리케이션 로직을 분할하는 방법을 설명합니다.

## 서비스 (Services)

서비스는 `Nexus.CreateService`로 등록됩니다.

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

### 서비스 필드

- `Name` (필수)
- `Order` (선택 사항, 기본값 `0`)
- `Client` 마커 테이블 (선택 사항)
- `Middleware` (선택 사항)

### 서비스 생명주기

- `NexusInit(self)`  
  가장 먼저 실행됩니다. (Order에 따라 정렬됨)
- `NexusStart(self)`  
  초기화(Init) 단계 이후에 실행됩니다.
- 선택적 런타임 훅(Hooks):
  - `OnHeartbeat(self, dt)`
  - `OnStepped(self, time, dt)`
  - `OnPostSimulation(self, dt)`
  - `OnPlayerAdded(self, player)`
  - `OnPlayerRemoving(self, player)`

서비스는 공유 상태, 권한 있는(Authoritative) 로직 및 클라이언트용 계약을 작성하기에 적합한 곳입니다.

## 컨트롤러 (Controllers)

컨트롤러는 `Nexus.CreateController`로 등록됩니다.

```luau
local Controller = Nexus.CreateController({
	Name = "InventoryController",
	Order = 10,
})
```

### 컨트롤러 생명주기

- `NexusInit(self)`
- `NexusStart(self)`
- 선택적 훅:
  - `OnHeartbeat(self, dt)`
  - `OnRenderStepped(self, dt)`
  - `OnPostSimulation(self, dt)`

컨트롤러는 일반적으로 UI 상태, 로컬 입력 처리, 카메라 로직 및 기타 클라이언트 소유 동작을 작성하기에 적합한 곳입니다.

> [!IMPORTANT]
> 클라이언트에서 `Nexus.GetService`를 사용하려면 클라이언트 프레임워크가 해당 서비스의 계약을 알고 있어야 합니다. 서비스 정의(특히 `.Client` 스키마)를 클라이언트에 노출하고(예: `ReplicatedStorage`), 시작하기 전에 클라이언트에서 `Nexus.AddServices(SharedFolder)`를 호출해야 합니다.

## 접근 헬퍼

- `Nexus.GetService(name)`
- `Nexus.GetController(name)`
- `Nexus.OnServiceReady(name) -> Promise`
- `Nexus.OnControllerReady(name) -> Promise`

## 라이선스

MIT. `LICENSE` 파일을 참조하세요.
