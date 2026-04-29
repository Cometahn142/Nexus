# 미들웨어 (Middleware)

Nexus는 두 가지 수준에서 미들웨어를 지원합니다:

- 전역(Global): `Nexus.Middleware`
- 서비스 로컬(Service-local): `Service.Middleware`

둘 다 다음을 지원합니다:

- `Inbound` (수신) 목록
- `Outbound` (송신) 목록

각 미들웨어 함수의 시그니처:

```luau
function(player: Player?, data: any): (boolean, any?)
```

- 페이로드를 거부/삭제하려면 `false`를 반환합니다.
- 변환된 페이로드를 전달하려면 `true, newData`를 반환합니다.
- 원본 페이로드를 그대로 전달하려면 `true, nil`을 반환합니다.

이를 통해 미들웨어는 모든 원격 핸들러에서 반복하지 않고 공유 유효성 검사, 페이로드 가공, 횡단 관심사(Cross-cutting concerns)를 처리하는 데 유용하게 사용됩니다.

## 예시

```luau
Nexus.Middleware.Outbound = {
	function(player, data)
		if type(data) ~= "table" then
			return false, nil
		end
		data._sentAt = os.clock()
		return true, data
	end,
}
```

## 순서

- Inbound: 전역(Global) -> 서비스(Service)
- Outbound: 서비스(Service) -> 전역(Global)

도메인별 규칙에는 서비스 미들웨어를 사용하고, 추적(Tracing), 속도 제한(Rate-limit) 태그 또는 공통 유효성 검사와 같은 횡단 관심사에는 전역 미들웨어를 사용하세요.

## 라이선스

MIT. `LICENSE` 파일을 참조하세요.
