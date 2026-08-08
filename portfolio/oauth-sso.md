---
layout: default
title: "Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험"
permalink: /portfolio/oauth-sso/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

<span class="project-context">개인 프로젝트 · 2026.01 — 2026.03 · 기술 검증 프로젝트</span>

# Gateway 단일 진입점에서의 인증/인가 검증

인증 서버가 JWT를 중앙 발급하고 Gateway와 각 Resource Server가 JWKS 공개키로 직접 검증하는 구조가 **실제로 성립하는지**를, 6개 모듈(Auth·Gateway·Matching·Task·Preview·Admin)을 직접 구성해 확인한 기술 검증 프로젝트입니다. 인증 구조 설계부터 토큰 발급·검증, Gateway 라우팅, Docker Compose 통합까지 혼자 구성했습니다.

검증은 주장이 아니라 실제 요청으로 했습니다 — 공개 경로는 토큰 없이 통과하는지, 보호 API는 무토큰 시 401을 주는지, Admin 경유 호출에서 양쪽 서비스가 각각 권한을 검증하는지, 외부에서 내부 경로에 접근하면 404가 나는지를 Compose로 띄운 6개 모듈에 직접 요청해 확인했고, 매칭 도메인의 동시 경쟁은 10스레드 동시성 테스트로 매칭이 정확히 1건만 생성됨을 확인했습니다.

진행 방식은 기능마다 문제 정의 → 접근법 A/B/C 비교 → 설계 문서 → TDD → 버그 리포트를 반복하는 사이클입니다. 결과보다 **결정의 근거를 남기는 것**이 목적이라, 선택하지 않은 대안과 선택이 가져온 비용까지 같은 문서에 적었고 그 문서 56건이 저장소에 공개돼 있습니다.

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

이 프로젝트에서 기능 하나를 만드는 순서는 고정돼 있었습니다. **왜 만드는지 한 문장으로 정의 → 접근법 A/B/C 비교(선택하지 않은 이유까지) → API·아키텍처 설계 문서 → 실패하는 테스트부터 쓰는 TDD → 버그가 나면 현상·원인·수정·회귀 테스트를 리포트로 → 완료 후 시나리오 정리.** 이 사이클 자체를 [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md)로 문서화했고, 일자별 설계·구현 기록이 [docs/how-i-work/](https://github.com/hello-pebble/oauth2-authorization/tree/main/docs/how-i-work)에 남아 있습니다.

이 사이클이 저장소에 남긴 문서는 56건입니다 — 기술 결정 기록(TDR, Technical Decision Record) 5건, [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md), 버그 리포트와 트러블슈팅 노트가 코드와 같은 저장소에서 함께 버전 관리됩니다. 예를 들어 인증 상태 저장 방식은 이렇게 비교하고 선택했습니다.

| 플랜 | 방식 | 선택 / 미선택 이유 |
| :--- | :--- | :--- |
| **A (선택)** | Stateless JWT | 일반 요청이 중앙 저장소 조회에 의존하지 않음 |
| B | Redis 세션 | 즉시 무효화가 가능하지만 Redis가 단일 장애점이 됨 |
| C | Opaque Token | 매 요청 introspection 호출로 레이턴시 증가 |

선택하지 않은 것은 코드에서도 걷어냈습니다 — 초기 검토 흔적으로 남아 있던 미사용 Redis 연동 의존성을 제거하는 리팩토링(-60줄)으로, 비교표의 결론과 실제 의존 그래프를 일치시켰습니다.

구현은 AI 코딩 도구와 협업했습니다. 설계 문서와 계획을 먼저 쓰고 구현을 위임한 뒤, 테스트와 실제 요청으로 검증하는 분업입니다. 어느 단계를 AI에 맡기고 어느 단계를 직접 판단했는지는 [claude-code-workflow.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/claude-code-workflow.md)에 있고, 전반적인 원칙은 [AI를 어떻게 쓰는가](/ai/)에 정리했습니다.

## 01. Stateless JWT — 얻은 것과 감수한 것 {#distributed-auth}

Auth는 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 제공합니다. 각 서비스는 공개키로 서명과 만료를 직접 검증하므로, 일반 요청마다 인증 서버에 다시 문의하지 않습니다.

![로그인부터 API 응답까지 — Gateway를 거쳐 각 서비스가 JWKS 공개키로 JWT를 직접 검증하는 흐름](/assets/images/portfolio/oauth-request-flow.svg){:.portfolio-diagram}

이 선택으로 얻은 것과 잃은 것을 함께 기록했습니다. 얻은 것은 요청 경로의 원격 의존 제거와 발급·인가 책임의 분리입니다. 감수한 것은 발급된 토큰을 만료 전에 중앙에서 회수하기 어렵다는 점, 권한 변경이 기존 토큰에 즉시 반영되지 않는다는 점, 그리고 서명 키가 전체 신뢰의 뿌리가 되면서 키 보관·순환이 새로운 핵심 과제가 된다는 점입니다. 전문은 [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)에 있으며, "아직 검증하지 않은 것"(동시 처리량, 장애 시 사용자 흐름)도 같은 문서에 성과와 구분해 적었습니다.

## 02. 경계별 책임 — Gateway는 통과, 서비스는 재검증 {#gateway-auth}

Compose 환경에서 호스트에 공개한 포트는 Gateway의 8000 하나입니다. Gateway는 Spring Cloud Gateway(WebFlux) 기반의 논블로킹(Non-blocking) 필터 체인으로 라우팅과 Cookie→Bearer 변환만 담당하고, JWT 서명과 역할 정책은 각 Resource Server가 자신의 규칙으로 다시 판단합니다. Gateway만 검사하고 내부를 신뢰하는 구조는 진입점이 뚫리는 순간 전부 뚫리기 때문입니다.

이 역할 분담이 실제로 성립하는지를 네 가지 시나리오의 **실제 요청**으로 확인했습니다.

| 시나리오 | 보장해야 하는 동작 | 확인 결과 |
| :--- | :--- | :--- |
| **공개 경로** | 로그인 화면·JWKS·OIDC metadata는 토큰 없이 접근 | Gateway 경유 접근 확인 |
| **보호 경로 · 토큰 없음** | 보호 API 호출 시 401 | Task·Admin API에서 확인 |
| **Admin 경유 인가** | Admin → Matching 호출에서 **양쪽 서비스가 각각** JWT와 관리자 권한 검증 | 양측 검증 확인 |
| **내부 경로 직접 접근** | Gateway에 `/internal/**` 라우트가 없어 외부에서는 404 | `/internal/admin/users` 404 확인 |

![Gateway 인증/인가 분기 — 공개·보호·관리자·내부 경로가 서로 다른 응답을 보장](/assets/images/portfolio/oauth-architecture.svg){:.portfolio-diagram}

6개 모듈(Auth·Gateway·Matching·Task·Preview·Admin)은 이 시나리오를 재현하기 위한 테스트 베드입니다. 각 모듈의 업무 기능이 아니라 "공개 라우트를 가진 서비스·보호 API를 가진 서비스·내부 API만 가진 서비스"라는 역할 구분이 핵심입니다.

## 03. 버그 하나가 모델을 이해시켰다 {#bug}

초기 스모크 테스트에서 정상 JWT가 보호 API에서 401을 받았습니다. 원인을 추적하니 `JwtProvider`가 토큰 **검증에도 RSA 개인키**를 쓰고 있었습니다 — 발급자와 검증자가 같은 코드였을 때는 드러나지 않다가, 검증을 각 서비스로 분산하자 바로 깨진 것입니다.

디코더가 공개키를 사용하도록 수정하고 스모크 테스트를 다시 수행했습니다. 이 버그를 고치면서 "개인키는 발급 주체만, 공개키는 검증 주체 누구나"라는 비대칭 키 모델의 책임 분리가 설정 문법이 아니라 실제 요청 흐름으로 이해됐습니다. 버그를 발견하면 고치기 전에 현상·원인·수정·회귀 테스트(Regression Test)를 기록하는 것이 이 프로젝트의 규칙이었고, 이 사례가 그 규칙이 값을 한 순간입니다. 같은 규칙으로 고정한 다른 버그 — 노출 설정 변경이 관리자 차단 상태를 덮어쓰던 BUG-001 — 도 지금은 리그레션 테스트가 지키고 있습니다.

## 04. 동시성 — 작은 ID부터 잠근다 {#concurrency}

인증 흐름 검증 위에 매칭 도메인을 올리면서 동시성 문제를 만났습니다. 두 사용자가 서로를 동시에 선택하면 매칭이 누락되거나(Lost Match) 중복 생성될(Double Matching) 수 있고, 사용자 쌍마다 락을 잡으면 서로 반대 순서로 락을 획득하다 데드락이 됩니다.

구현 전에 시나리오를 분석하고 **항상 작은 ID부터 락을 획득하는 Ordered Locking** 원칙을 설계 문서로 먼저 세웠습니다. 락 순서가 전역적으로 일정하면 순환 대기가 성립하지 않아 데드락이 구조적으로 불가능해집니다. 구현 후에는 10개 스레드가 두 사용자를 동시에 상호 선택하는 동시성 테스트로 매칭이 정확히 1건만 생성되는 것을 검증했고, 마무리 리팩토링에서 락 해제를 try-finally로 보장하며 락 범위를 상태 변경 구간으로만 최소화했습니다. 설계 문서와 일자별 기록은 [concurrency design](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-21-matching-concurrency-design.md)에 있습니다.

## 검증 결과와 한계 {#verification}

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| 경계별 시나리오 4건 | 실제 요청으로 전부 확인 (02 표 참조) |
| 모듈별 빌드 | 6개 애플리케이션 모듈 빌드와 전체 테스트 통과 |
| 통합 실행 | 6개 애플리케이션 + PostgreSQL을 Compose로 기동하고 health 확인 |
| 동시 매칭 경쟁 | Ordered Lock 적용 후 10스레드 동시 상호 선택 테스트에서 매칭 정확히 1건 생성 확인 |

직접 구현해 본 결론은 역설적입니다. JWT 발급과 검증 자체는 구현 가능했지만, 키 관리·Refresh Token 보안·표준 준수까지 고려하면 인증 서버의 책임은 빠르게 복잡해졌습니다. **실제 서비스에서 검증된 인증 솔루션을 써야 하는 이유**와, 도입 시 확인해야 할 지점(키 순환, 토큰 폐기, 경계별 재검증)을 몸으로 이해한 것이 이 실험의 가장 큰 수확입니다.

### 한계와 다음 검증 과제

- 상용 인증 서버 수준의 보안성을 검증한 것은 아닙니다.
- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화되며, 키 교체·폐기 시나리오는 검증하지 못했습니다.
- Refresh Token 탈취·재사용 대응은 검증하지 못했습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다 — client credentials·토큰 교환·mTLS가 다음 과제입니다.

<span class="section-note">실제 팀 프로젝트에 적용해 지표를 측정한 결과가 아니라, 단일 진입점 뒤에서 인증/인가 시나리오가 성립하는지를 실제 요청으로 확인한 아키텍처 실험입니다.</span>

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization) — 소스 코드
- [dev-cycle.md](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/how-i-work/dev-cycle.md) — 기능 하나를 만드는 실제 순서
- [Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md) · [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
