# 설치 방법

이 페이지에서는 Roblox 프로젝트에 Nexus를 추가하는 일반적인 방법을 설명합니다.

## 방법 1: Wally

프로젝트에서 이미 Wally를 사용하는 경우:

```toml
[dependencies]
Nexus = "cometahn142/nexus@^0.3"
```

Nexus는 Snap, Promise, Signal, Janitor와 같은 공유 패키지에 종속되어 있으므로, Wally를 사용하는 것이 모든 패키지의 버전을 함께 관리하는 가장 쉬운 방법입니다.

## 방법 2: 수동 설치 또는 소스 코드 포함

라이브러리를 직접 포함하는 경우:

1. Nexus를 공유 패키지 위치에 복사합니다.
2. 종속성 라이브러리들도 사용 가능한지 확인합니다.
3. 서버와 클라이언트 모두에서 동일한 위치에 패키지를 노출합니다.

Rojo 기반 프로젝트의 경우, Nexus를 전용 타사(Third-party) 또는 패키지 폴더에 보관하는 것이 가장 깔끔합니다.

## 검증

성공적으로 설치되면 서버와 클라이언트 모두에서 다음 코드를 실행할 수 있습니다.

```luau
local Nexus = require(Packages.Nexus)
print(Nexus.Version)
```

## 다음 단계

- [사용 패턴 (Usage Patterns)](./usage-patterns.md)
- [Nexus API](./nexus.md)
- [서비스와 컨트롤러 (Services and Controllers)](./services-and-controllers.md)

## 라이선스

MIT. `LICENSE` 파일을 참조하세요.
