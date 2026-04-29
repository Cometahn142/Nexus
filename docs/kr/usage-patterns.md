# 사용 패턴 (Usage Patterns)

이 페이지는 각 함수를 개별적으로 나열하기보다는 실제 프로젝트에서 Nexus가 일반적으로 사용되는 방식에 중점을 둡니다.

## 부트스트래핑 (Bootstrapping)

서버에서 서비스를 로드하고 Nexus를 시작합니다:

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ServerScriptService.Services)
Nexus.Start()
```

클라이언트에서 공유 스키마와 컨트롤러를 로드합니다:

```luau
local Nexus = require(Packages.Nexus)

Nexus.AddServices(ReplicatedStorage.SharedSchemas)
Nexus.AddControllers(PlayerScripts.Controllers)
Nexus.Start()
```

> [!IMPORTANT]
> 클라이언트는 서버의 `.Client` 테이블 선언에 접근할 수 있어야 합니다. 항상 공유 스크립트를 사용하여 클라이언트에서 `Nexus.AddServices`를 통해 매핑하세요.

## 계약(Contract) 중심의 서비스 구축

Nexus에서 가장 중요한 패턴은 마커를 통해 클라이언트용 계약을 정의하는 것입니다.

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

이를 통해 서비스 경계가 명확해지고 네트워킹 로직이 해당 기능과 가까운 곳에 유지됩니다.

필요한 경우, 다른 Require 경로를 추가하지 않고도 `Nexus.Snap`을 통해 원시 Snap API를 계속 사용할 수 있습니다.

## 컨트롤러를 클라이언트 소유자로 사용

컨트롤러는 UI, 로컬 상태 및 서비스 소비의 클라이언트 측 소유자로 사용하는 것이 가장 좋습니다.

```luau
local InventoryController = Nexus.CreateController({
	Name = "InventoryController",
})
```

렌더링, 로컬 입력 및 프레젠테이션 로직을 여기에 유지하세요.

## 횡단 관심사(Cross-cutting) 규칙을 위한 미들웨어

페이로드 규칙이 모든 신호나 메서드 핸들러 내에 존재해서는 안 될 때 미들웨어를 사용하세요.

일반적인 예시:
- 유효성 검사
- 송신 페이로드 태깅
- 추적 (Tracing)
- 공유 필터링 규칙

자세한 내용은 [미들웨어](./middleware.md) 전용 페이지를 참조하세요.

## 순서 지정 및 시작

한 서비스나 컨트롤러가 다른 것보다 먼저 초기화되어야 하는 경우 `Order`를 사용하세요.
비동기적 준비가 더 자연스러운 종속성 경계인 경우 `OnServiceReady` 및 `OnControllerReady`를 사용하세요.

## 실용적인 조언

- 서비스 API는 작고 명확하게 유지하세요.
- 중복된 원격 정의 대신 공유 스키마를 선호하세요.
- 뷰(View)의 소유권은 서비스가 아닌 컨트롤러에 두세요.
- 미들웨어는 비즈니스 로직이 아닌 인프라로 취급하세요.

## 다음 단계

- [설치 방법 (Installation)](./installation.md)
- [Nexus API](./nexus.md)
- [서비스와 컨트롤러 (Services and Controllers)](./services-and-controllers.md)
- [미들웨어 (Middleware)](./middleware.md)

## 라이선스

MIT. `LICENSE` 파일을 참조하세요.
