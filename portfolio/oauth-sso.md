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
- **담당** 6개 모듈(Auth·Gateway·Matching·Task·Preview·Admin)의 인증 구조 설계부터 토큰 발급·검증, Gateway 라우팅, Docker Compose 통합까지 혼자 구성했습니다.
- **검증 방식** 주장이 아니라 Compose로 띄운 모듈에 직접 요청해 확인했고, 매칭 도메인의 동시 경쟁은 10스레드 테스트로 매칭이 정확히 1건만 생성됨을 확인했습니다.
- **기록** 선택하지 않은 대안과 선택이 가져온 비용까지 같은 문서에 적어, 문서 56건을 저장소에 공개했습니다.

<nav class="project-page-nav" aria-label="Gateway 인증/인가 검증 프로젝트 목차">
  <a href="#process">
    <span>만든 방식</span>
    <small>코드보다 문서가 먼저</small>
  </a>
  <a href="#distributed-auth">
    <span>01. Stateless JWT</span>
    <small>얻은 것과 감수한 것</small>
  </a>
  <a href="#gateway-auth">
    <span>02. 경계별 책임</span>
    <small>Gateway는 통과, 서비스는 재검증</small>
  </a>
  <a href="#bug">
    <span>03. 버그 하나의 가치</span>
    <small>개인키로 검증하던 디코더</small>
  </a>
  <a href="#concurrency">
    <span>04. 동시성 락</span>
    <small>작은 ID부터 잠근다</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>확인 결과·다음 과제</small>
  </a>
</nav>

## 만든 방식 — 코드보다 문서가 먼저 {#process}

기능 하나를 만드는 순서를 고정해 두고 반복했습니다.

- **1. 문제 정의** 왜 만드는지 한 문장으로 적습니다.
- **2. 대안 비교** 접근법 A/B/C를 비교하고 선택하지 않은 이유까지 남깁니다.
- **3. 설계 문서** API와 아키텍처를 먼저 문서로 확정합니다.
- **4. TDD** 실패하는 테스트부터 씁니다.
- **5. 버그 리포트** 버그가 나면 현상·원인·수정·회귀 테스트를 기록합니다.
- **6. 시나리오 정리** 완료 후 검증 시나리오를 정리합니다.

이 사이클은 [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md)로 문서화했습니다. 설계 결정마다 대안을 최소 둘 함께 적고, **왜 그것을 고르지 않았는지까지 같은 문서에 남깁니다.** 인증 상태 저장 방식이 그 예입니다.

{% include diagrams/oauth-token-decision.svg %}

- **문서와 코드의 일치** 선택하지 않은 것은 코드에서도 걷어냈습니다. 초기 검토 흔적으로 남아 있던 미사용 Redis 연동 의존성을 제거해(-60줄) 비교표의 결론과 실제 의존 그래프를 맞췄습니다.
- **AI 협업** 설계 문서와 계획을 먼저 쓰고 구현을 위임한 뒤, 테스트와 실제 요청으로 검증하는 분업입니다. 상세는 [claude-code-workflow.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/claude-code-workflow.md)와 [AI를 어떻게 쓰는가](/ai/)에 정리했습니다.

## 01. Stateless JWT — 얻은 것과 감수한 것 {#distributed-auth}

- **발급** Auth가 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 제공합니다.
- **검증** 각 서비스가 공개키로 서명과 만료를 직접 검증하므로, 일반 요청마다 인증 서버에 다시 문의하지 않습니다.

![로그인부터 API 응답까지 — Gateway를 거쳐 각 서비스가 JWKS 공개키로 JWT를 직접 검증하는 흐름](/assets/images/portfolio/oauth-request-flow.svg){:.portfolio-diagram}

- **Refresh Token** 재발급 시 기존 토큰을 교체하는 Rotation 흐름입니다. 다만 현재 저장소가 `ConcurrentHashMap` 인메모리라 **재시작 시 초기화되고 다중 인스턴스 상태를 공유하지 못합니다.** 인터페이스는 유지해 외부 저장소 구현으로 교체할 수 있게 뒀습니다.
- **기록** 전문은 [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)에 있으며, "아직 검증하지 않은 것"(동시 처리량, 인스턴스 증가에 따른 변화, Auth·DB 장애 시 사용자 흐름)도 성과와 구분해 같은 문서에 적었습니다.

## 02. 경계별 책임 — Gateway는 통과, 서비스는 재검증 {#gateway-auth}

- **공개 포트** Compose 환경에서 호스트에 연 포트는 Gateway의 8000 하나뿐입니다.
- **Gateway 역할** Spring Cloud Gateway(WebFlux) 기반 논블로킹 필터 체인으로 라우팅과 Cookie→Bearer 변환만 담당합니다.
- **서비스 역할** JWT 서명과 역할 정책은 각 Resource Server가 자신의 규칙으로 다시 판단합니다.
- **이렇게 나눈 이유** Gateway만 검사하고 내부를 신뢰하면 진입점이 뚫리는 순간 전부 뚫리기 때문입니다.

이 역할 분담이 성립하는지를 네 가지 시나리오의 **실제 요청**으로 확인했습니다.

| 시나리오 | 보장해야 하는 동작 | 확인 결과 |
| :--- | :--- | :--- |
| **공개 경로** | 로그인 화면·JWKS·OIDC metadata는 토큰 없이 접근됩니다. | Gateway 경유 접근을 확인했습니다. |
| **보호 경로 · 토큰 없음** | 보호 API 호출 시 401을 반환합니다. | Task·Admin API에서 확인했습니다. |
| **Admin 경유 인가** | Admin → Matching 호출에서 양쪽 서비스가 각각 JWT와 관리자 권한을 검증합니다. | 양측 검증을 확인했습니다. |
| **내부 경로 직접 접근** | Gateway에 `/internal/**` 라우트가 없어 외부에서는 404가 납니다. | `/internal/admin/users` 404를 확인했습니다. |

![Gateway 인증/인가 분기 — 공개·보호·관리자·내부 경로가 서로 다른 응답을 보장](/assets/images/portfolio/oauth-architecture.svg){:.portfolio-diagram}

- **모듈 구성의 의미** 6개 모듈은 시나리오를 재현하기 위한 테스트 베드입니다. 각 모듈의 업무 기능이 아니라 "공개 라우트를 가진 서비스·보호 API를 가진 서비스·내부 API만 가진 서비스"라는 역할 구분이 핵심입니다.

## 03. 버그 하나가 모델을 이해시켰다 {#bug}

| 구분 | 내용 |
| :--- | :--- |
| **증상** | 초기 스모크 테스트에서 정상 JWT가 보호 API에서 401을 받았습니다. |
| **원인** | `JwtProvider`가 토큰 검증에도 RSA 개인키를 쓰고 있었습니다. |
| **드러난 시점** | 발급자와 검증자가 같은 코드였을 때는 숨어 있다가, 검증을 각 서비스로 분산하자 바로 깨졌습니다. |
| **조치** | 디코더가 공개키를 사용하도록 수정하고 스모크 테스트를 다시 수행했습니다. |

- **배운 것** "개인키는 발급 주체만, 공개키는 검증 주체 누구나"라는 비대칭 키 모델의 책임 분리를 설정 문법이 아니라 실제 요청 흐름으로 이해했습니다.
- **규칙의 값어치** 버그를 고치기 전에 현상·원인·수정·회귀 테스트를 기록하는 것이 이 프로젝트의 규칙이었고, 이 사례가 그 규칙이 값을 한 순간입니다.
- **같은 규칙으로 고정한 다른 버그** 노출 설정 변경이 관리자 차단 상태를 덮어쓰던 BUG-001도 지금은 리그레션 테스트가 지키고 있습니다.

## 04. 동시성 — 작은 ID부터 잠근다 {#concurrency}

| 구분 | 내용 |
| :--- | :--- |
| **문제 1** | 두 사용자가 서로를 동시에 선택하면 매칭이 누락되거나(Lost Match) 중복 생성될(Double Matching) 수 있습니다. |
| **문제 2** | 사용자 쌍마다 락을 잡으면 서로 반대 순서로 락을 획득하다 데드락이 됩니다. |
| **설계** | 구현 전에 시나리오를 분석하고 항상 작은 ID부터 락을 획득하는 Ordered Locking 원칙을 설계 문서로 먼저 세웠습니다. |
| **근거** | 락 순서가 전역적으로 일정하면 순환 대기가 성립하지 않아 데드락이 구조적으로 불가능해집니다. |
| **검증** | 10개 스레드가 두 사용자를 동시에 상호 선택하는 테스트에서 매칭이 정확히 1건만 생성되는 것을 확인했습니다. |

- **마무리 리팩토링** 락 해제를 try-finally로 보장하고 락 범위를 상태 변경 구간으로만 최소화했습니다.
- **기록** 설계 문서와 일자별 기록은 [concurrency design](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-21-matching-concurrency-design.md)에 있습니다.

## 검증 결과와 한계 {#verification}

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| 경계별 시나리오 4건 | 실제 요청으로 전부 확인했습니다. (02 표 참조) |
| 모듈별 빌드 | 6개 애플리케이션 모듈 빌드와 전체 테스트가 통과했습니다. |
| 통합 실행 | 6개 애플리케이션과 PostgreSQL을 Compose로 기동하고 health를 확인했습니다. |
| 동시 매칭 경쟁 | Ordered Lock 적용 후 10스레드 동시 상호 선택 테스트에서 매칭 1건 생성을 확인했습니다. |

직접 구현해 본 결론은 역설적입니다. JWT 발급과 검증 자체는 구현할 수 있었지만, 키 관리·Refresh Token 보안·표준 준수까지 고려하면 인증 서버의 책임이 빠르게 복잡해졌습니다. **실제 서비스에서 검증된 인증 솔루션을 써야 하는 이유**와 도입 시 확인해야 할 지점(키 순환, 토큰 폐기, 경계별 재검증)을 몸으로 이해한 것이 이 실험의 가장 큰 수확입니다.

### 한계와 다음 검증 과제

- 상용 인증 서버 수준의 보안성을 검증한 것은 아닙니다.
- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화되며, 키 교체·폐기 시나리오는 검증하지 못했습니다.
- Refresh Token 탈취·재사용 대응은 검증하지 못했습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다. client credentials·토큰 교환·mTLS를 다음 과제로 두었습니다.

<span class="section-note">실제 팀 프로젝트에 적용해 지표를 측정한 결과가 아니라, 단일 진입점 뒤에서 인증/인가 시나리오가 성립하는지를 실제 요청으로 확인한 아키텍처 실험입니다.</span>

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization) — 소스 코드
- [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md) — 기능 하나를 만드는 실제 순서
- [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md) · [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
