---
layout: default
title: "Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험"
permalink: /portfolio/oauth-sso/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

<span class="project-context">개인 프로젝트 · 2026.01 — 2026.03 · 기술 검증 프로젝트</span>

# Gateway 단일 진입점에서의 인증/인가 검증

- **검증한 것** 인증 서버가 JWT를 중앙 발급하고 Gateway와 각 Resource Server가 JWKS 공개키로 직접 검증하는 구조가 실제로 성립하는지 확인했습니다.
- **담당** 다중 모듈(Auth·Gateway·Task·Preview·Admin)의 인증 구조 설계부터 토큰 발급, 검증, Gateway 라우팅, Docker Compose 통합으로 구성했습니다.
- **검증 방식** 주장이 아니라 Compose로 띄운 모듈에 직접 요청해, 경계별 네 시나리오의 응답 코드로 확인했습니다.
- **기록** 선택하지 않은 대안과 선택이 가져온 비용까지 같은 문서에 적어, 저장소에 공개했습니다.

<nav class="project-page-nav" aria-label="Gateway 인증/인가 검증 프로젝트 목차">
  <a href="#process">
    <span>만든 방식</span>
    <small>코드보다 문서가 먼저</small>
  </a>
  <a href="#distributed-auth">
    <span>01. 매 요청마다 묻지 않기</span>
    <small>그 대신 무엇을 감수했나</small>
  </a>
  <a href="#gateway-auth">
    <span>02. Gateway만 믿으면 안 됩니다</span>
    <small>진입점이 뚫리면 전부 뚫린다</small>
  </a>
  <a href="#bug">
    <span>03. 정상 토큰이 401을 받았다</span>
    <small>분산하자 드러난 버그</small>
  </a>
  <a href="#tradeoff">
    <span>고르지 않은 것</span>
    <small>세션 저장소를 걷어낸 이유</small>
  </a>
  <a href="#verification">
    <span>확인한 것과 못 한 것</span>
    <small>검증 결과·다음 과제</small>
  </a>
</nav>

## 코드보다 문서를 먼저 썼습니다 {#process}

기능 하나를 만드는 순서를 고정해 두고 반복했습니다. 문제를 한 문장으로 적는 것에서 시작해, 대안을 비교하고, 설계를 문서로 확정한 뒤에야 코드를 씁니다.

- **1. 문제 정의** 왜 만드는지 한 문장으로 적습니다.
- **2. 대안 비교** 접근법 A/B/C를 비교하고 선택하지 않은 이유까지 남깁니다.
- **3. 설계 문서** API와 아키텍처를 먼저 문서로 확정합니다.
- **4. TDD** 실패하는 테스트부터 씁니다.
- **5. 버그 리포트** 버그가 나면 현상-원인-수정-회귀 테스트를 기록합니다.
- **6. 시나리오 정리** 완료 후 검증 시나리오를 정리합니다.

이 사이클은 [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md)로 문서화했습니다. 설계 결정마다 대안을 최소 둘 함께 적고, **왜 그것을 고르지 않았는지까지 같은 문서에 남깁니다.** 이 프로젝트의 첫 결정이었던 인증 상태 저장 방식은 [고려했지만 고르지 않은 것](#tradeoff)에 정리했습니다.

- **AI 협업** 설계 문서와 계획을 먼저 쓰고 구현을 위임한 뒤, 테스트와 실제 요청으로 검증하는 분업입니다. 상세는 [claude-code-workflow.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/claude-code-workflow.md)와 [AI를 어떻게 쓰는가](/ai/)에 정리했습니다.

## 01. 매 요청마다 인증 서버에 묻지 않기로 했습니다 {#distributed-auth}

서비스가 여러개인데 요청마다 인증 서버에 토큰이 유효한지 물으면, 인증 서버가 모든 트래픽의 병목이자 단일 장애점이 됩니다. 그래서 검증 권한을 각 서비스로 내려보내기로 했습니다. Auth가 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 공개하면, 각 서비스는 그 공개키로 서명과 만료를 스스로 판단할 수 있습니다.

![로그인부터 API 응답까지 — Gateway를 거쳐 각 서비스가 JWKS 공개키로 JWT를 직접 검증하는 흐름](/assets/images/portfolio/oauth-request-flow.svg){:.portfolio-diagram}

문제는 이 선택이 공짜가 아니라는 것입니다. 서버가 토큰 상태를 들고 있지 않으니, 발급한 토큰을 중간에 무효화할 방법도 같이 사라집니다.

- **Refresh Token** 재발급 시 기존 토큰을 교체하는 Rotation 흐름으로 이 공백을 일부 메웠습니다. 다만 현재 저장소가 `ConcurrentHashMap` 인메모리라 **재시작 시 초기화되고 다중 인스턴스 상태를 공유하지 못합니다.** 인터페이스는 유지해 외부 저장소 구현으로 교체할 수 있게 뒀습니다.
- **기록** 전문은 [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)에 있으며, "아직 검증하지 않은 것"(동시 처리량, 인스턴스 증가에 따른 변화, Auth·DB 장애 시 사용자 흐름)도 성과와 구분해 같은 문서에 적었습니다.

## 02. Gateway만 믿으면, 뚫리는 순간 전부 뚫립니다 {#gateway-auth}

검증을 분산했으니 다음 질문은 "그럼 Gateway는 뭘 하나"입니다. 흔한 답은 Gateway에서 인증을 전부 처리하고 내부는 신뢰하는 것이지만, 그러면 진입점 하나가 뚫리는 순간 뒤의 서비스가 전부 같이 뚫립니다. 그래서 Gateway는 **통과만**, 판단은 **각 서비스가 다시** 하도록 나눴습니다.

- **공개 포트** Compose 환경에서 호스트에 연 포트는 Gateway의 8000 하나뿐입니다.
- **Gateway 역할** Spring Cloud Gateway(WebFlux) 기반 논블로킹 필터 체인으로 라우팅과 Cookie→Bearer 변환만 담당합니다.
- **서비스 역할** JWT 서명과 역할 정책은 각 Resource Server가 자신의 규칙으로 다시 판단합니다.

이 역할 분담이 말로만 성립하는 게 아니라는 것을, 네 가지 시나리오의 **실제 요청**으로 확인했습니다.

| 시나리오 | 보장해야 하는 동작 | 확인 결과 |
| :--- | :--- | :--- |
| **공개 경로** | 로그인 화면·JWKS·OIDC metadata는 토큰 없이 접근됩니다. | Gateway 경유 접근을 확인했습니다. |
| **보호 경로 · 토큰 없음** | 보호 API 호출 시 401을 반환합니다. | Task·Admin API에서 확인했습니다. |
| **Admin 경유 인가** | Admin → Matching 호출에서 양쪽 서비스가 각각 JWT와 관리자 권한을 검증합니다. | 양측 검증을 확인했습니다. |
| **내부 경로 직접 접근** | Gateway에 `/internal/**` 라우트가 없어 외부에서는 404가 납니다. | `/internal/admin/users` 404를 확인했습니다. |

![Gateway 인증/인가 분기 — 공개·보호·관리자·내부 경로가 서로 다른 응답을 보장](/assets/images/portfolio/oauth-architecture.svg){:.portfolio-diagram}

<ol class="diagram-callouts">
<li markdown="1">
**Gateway — 판단하지 않고 통과시킵니다.**
Spring Cloud Gateway(WebFlux)의 논블로킹 필터 체인에서 경로 라우팅과 Cookie→Bearer 변환만 수행합니다. 토큰이 유효한지, 권한이 되는지는 여기서 결정하지 않습니다. Gateway가 인가까지 책임지면 규칙이 한곳에 모여 편하지만, 그 한곳이 뚫릴 때 전부 뚫립니다.
</li>
<li markdown="1">
**보호 경로 — 검증 주체는 각 서비스입니다.**
Resource Server가 JWKS로 받아 둔 공개키로 서명과 만료를 직접 판단합니다. Auth에 다시 묻지 않으므로 인증 서버가 트래픽 경로에서 빠지고, 대신 각 서비스가 자기 규칙으로 인가를 한 번 더 결정합니다. Admin → Matching 호출에서 양쪽이 각각 `ROLE_ADMIN`을 확인하는 것이 이 구조 때문입니다.
</li>
<li markdown="1">
**내부 경로 — 막은 게 아니라 문을 안 냈습니다.**
`/internal/**`은 Gateway에 라우트 자체가 없습니다. 필터로 차단하면 설정 한 줄이 빠질 때 열리지만, 라우트가 없으면 외부에서 도달할 경로가 존재하지 않아 404가 납니다. 방어를 규칙이 아니라 구성으로 옮긴 지점입니다.
</li>
</ol>

모듈을 나눈 기준은 업무 기능이 아니라 이 시나리오를 재현할 수 있는가입니다. "공개 라우트를 가진 서비스 · 보호 API를 가진 서비스 · 내부 API만 가진 서비스"가 각각 하나씩 필요했고, 그만큼만 만들었습니다.

## 03. 검증을 분산하자 정상 토큰이 401을 받았습니다 {#bug}

01의 결정이 실제로 무엇을 바꿨는지는 버그가 알려줬습니다. 초기 스모크 테스트에서, 방금 정상 발급된 JWT가 보호 API에서 401을 받았습니다.

| 구분 | 내용 |
| :--- | :--- |
| **원인** | `JwtProvider`가 토큰 검증에도 RSA 개인키를 쓰고 있었습니다. |
| **드러난 시점** | 발급자와 검증자가 같은 코드였을 때는 숨어 있다가, 검증을 각 서비스로 분산하자 바로 깨졌습니다. |
| **조치** | 디코더가 공개키를 사용하도록 수정하고 스모크 테스트를 다시 수행했습니다. |

같은 프로세스 안에서는 개인키로 검증해도 아무 일이 없었습니다. 이 버그는 구조를 바꾸기 전까지는 존재하지도 않았던 셈입니다. **"개인키는 발급 주체만, 공개키는 검증 주체 누구나"** 라는 비대칭 키 모델의 책임 분리를, 설정 문법이 아니라 실제 요청 흐름으로 이해한 지점입니다.

- **규칙의 값어치** 버그를 고치기 전에 현상·원인·수정·회귀 테스트를 기록하는 것이 이 프로젝트의 규칙이었고, 이 사례가 그 규칙이 값을 한 순간입니다.
- **같은 규칙으로 고정한 다른 버그** 노출 설정 변경이 관리자 차단 상태를 덮어쓰던 BUG-001도 지금은 리그레션 테스트가 지키고 있습니다.

## 고려했지만 고르지 않은 것 {#tradeoff}

인증 상태를 어디에 둘 것인가가 이 프로젝트의 첫 결정이었습니다. 셋을 비교했습니다.

| 대안 | 얻는 것 | 버린 이유 |
| :--- | :--- | :--- |
| **A · Stateless JWT** *(선택)* | 일반 API 요청이 중앙 세션 조회에 의존하지 않고, 발급 책임과 인가 책임이 갈립니다. | — |
| B · Redis 세션 | 토큰을 즉시 무효화할 수 있습니다. | Redis가 단일 장애점이 됩니다. |
| C · Opaque Token | 서버가 토큰 상태를 쥐고 있습니다. | 매 요청 introspection 호출로 레이턴시가 늘어납니다. |

A를 고른 대가는 B가 주려던 것을 잃는 것입니다. 발급된 토큰을 만료 전에 회수하기 어렵고, 권한을 바꿔도 이미 나간 토큰에는 즉시 반영되지 않으며, 키 보관과 순환이 새 과제로 남습니다. 같은 축에서 반대로 고른 적도 있습니다. [AdminCore](/portfolio/admincore/)에서는 관리자의 정지가 즉시 들어야 한다는 요구가 우선이라 요청마다 계정 상태를 다시 봤습니다. **같은 트레이드오프라도 무엇을 지킬지가 다르면 답이 갈립니다.**

- **문서와 코드를 일치시킨 방식** 고르지 않은 것은 코드에서도 걷어냈습니다. 초기 검토 흔적으로 남아 있던 미사용 Redis 연동 의존성을 제거해(-60줄) 비교표의 결론과 실제 의존 그래프를 맞췄습니다. 비교표만 남고 코드에 흔적이 남아 있으면, 그 문서는 다음 사람에게 거짓말이 됩니다.

## 확인한 것과, 확인하지 못한 것 {#verification}

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| 경계별 시나리오 4건 | 실제 요청으로 전부 확인했습니다. (02 표 참조) |
| 모듈별 빌드 | 애플리케이션 모듈 빌드와 전체 테스트가 통과했습니다. |
| 통합 실행 | 애플리케이션과 PostgreSQL을 Compose로 기동하고 health를 확인했습니다. |

직접 구현해 본 결론은 역설적입니다. JWT 발급과 검증 자체는 구현할 수 있었지만, 키 관리·Refresh Token 보안·표준 준수까지 고려하면 인증 서버의 책임이 빠르게 복잡해졌습니다. **실제 서비스에서 검증된 인증 솔루션을 써야 하는 이유**와 도입 시 확인해야 할 지점(키 순환, 토큰 폐기, 경계별 재검증)을 몸으로 이해한 것이 이 실험의 가장 큰 수확입니다.

### 아직 못 푼 문제

- 상용 인증 서버 수준의 보안성을 검증한 것은 아닙니다.
- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화되며, 키 교체·폐기 시나리오는 검증하지 못했습니다.
- Refresh Token 탈취·재사용 대응은 검증하지 못했습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다. client credentials·토큰 교환·mTLS를 다음 과제로 두었습니다.

<span class="section-note">실제 팀 프로젝트에 적용해 지표를 측정한 결과가 아니라, 단일 진입점 뒤에서 인증/인가 시나리오가 성립하는지를 실제 요청으로 확인한 아키텍처 실험입니다.</span>

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization) — 소스 코드
- [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md) — 기능 하나를 만드는 실제 순서
- [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md) — 설계 결정마다 고르지 않은 대안과 그 이유
