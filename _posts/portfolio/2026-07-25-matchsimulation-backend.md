---
layout: default
title: "교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 규칙 기반 엔진에서 외부 AI로의 전환 접점 실험"
permalink: /portfolio/matchsimulation-backend/
category: portfolio
tags: [Java21, SpringBoot4, JPA, H2, Gradle, StrategyPattern]
---

<span class="project-context">개인 프로젝트 · 2026.07 — 진행 중</span>

# 교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 규칙 기반 엔진에서 외부 AI로의 전환 접점 실험

- AI 소개팅 서비스를 가정하고, 추천 엔진·DB·인증을 나중에 교체할 수 있도록 경계를 먼저 설계한 백엔드
- `matching.engine` 설정 하나로 규칙 기반 엔진과 외부 AI 서버 연동을 전환하는 구조를 단독 구현

<nav class="project-page-nav" aria-label="MatchSimulation 프로젝트 목차">
  <a href="#decisions">
    <span>Overview</span>
    <small>확보하려 한 3가지 교체 접점</small>
  </a>
  <a href="#structure">
    <span>01. 모듈 구조</span>
    <small>package-by-feature 7개 도메인</small>
  </a>
  <a href="#engine">
    <span>02. 매칭 엔진</span>
    <small>전략 패턴과 설정 기반 전환</small>
  </a>
  <a href="#simple-layers">
    <span>03. 단순한 계층</span>
    <small>의도적으로 미룬 것들</small>
  </a>
  <a href="#verification">
    <span>04. 검증과 다음 단계</span>
    <small>Phase 2 결과와 백엔드 로드맵</small>
  </a>
</nav>

## 확보하려 한 3가지 교체 접점 {#decisions}

이 프로젝트의 주인공은 개별 기능이 아니라 **교체 접점**입니다. AI 매칭 서비스를 만들 때 처음부터 AI 모델·운영 DB·표준 인증을 모두 갖추는 대신, "나중에 반드시 바뀔 부분"을 먼저 정의하고 그 경계 바깥의 코드가 교체에 영향받지 않는지를 확인했습니다.

| 교체 접점 | 지금의 구현 | 교체 시 바뀌는 범위 |
| :--- | :--- | :--- |
| **① 추천 엔진** | 규칙 기반 `LocalMatchingEngine` | `matching.engine` 설정값 하나 |
| **② 데이터베이스** | H2 In-Memory + JPA | datasource 설정 (JPA 코드 무변경) |
| **③ 인증** | UUID 더미 토큰 `TokenStore` | TokenStore 계층 (Controller 시그니처 유지) |

이 세 경계가 성립하면, MVP 단계의 단순한 구현을 유지하면서도 Phase 3 이후의 AI 연동·운영 전환을 코드 재작성 없이 진행할 수 있습니다.

![MatchSimulation 구조 — 7개 기능 모듈과 MatchingEngine 인터페이스의 설정 기반 분기](/assets/images/portfolio/matchsimulation-architecture.svg)

## 01. package-by-feature — 7개 도메인 모듈 {#structure}

계층(controller/service/…)이 아니라 **기능**을 최상위 기준으로 패키지를 나눴습니다. 각 모듈이 자신의 controller·service·repository·domain·dto를 내부에 소유합니다.

| 모듈 | 책임 |
| :--- | :--- |
| **user** | 회원가입(PENDING) · 로그인 · 내 정보 |
| **matching** | 추천 · 매칭 요청/수락/거절 · 엔진 연동 |
| **qna** | 1:1 문의 등록과 조회 |
| **notification** | 전체 공지 · 개별 알림 |
| **admin** | 회원 관리 · QnA 답변 · 알림 등록 · 매칭 통계 |
| **common** | 상태코드를 포함한 비즈니스 예외 · 통일된 에러 응답 |
| **config** | H2 시드 데이터 초기화 |

기능 단위로 나눈 이유는 두 가지입니다. 하나의 기능을 수정할 때 변경 범위가 한 패키지에 갇히고, 이후 Gradle 멀티모듈이나 서비스 분리가 필요해지면 패키지를 그대로 모듈로 승격시킬 수 있습니다. 모듈 간 참조는 수평 구조를 유지해 순환 의존이 생기지 않도록 했습니다.

사용자 기능과 관리자 기능은 같은 영속 계층을 공유하되 진입점을 분리했습니다. `AdminController`는 요청마다 Role=ADMIN을 검사해 아니면 403을 반환하므로, 권한 규칙이 화면이 아니라 서버 경계에서 적용됩니다.

### Trade-off

- 규모가 작은 현재는 계층형 구조보다 패키지 수가 많아 탐색 비용이 있습니다.
- 모듈 경계는 패키지 수준의 약속일 뿐, 컴파일 타임에 의존 방향을 강제하지는 못합니다. 강제가 필요해지는 시점이 멀티모듈 전환 시점이라고 판단했습니다.

## 02. MatchingEngine — 왜 처음부터 AI를 붙이지 않았는가 {#engine}

### 추천은 인터페이스 뒤에 숨겼다

추천 로직 전체를 `MatchingEngine` 인터페이스 하나로 감쌌습니다. 구현체는 두 개입니다.

- **LocalMatchingEngine** — 지역 일치·나이 차이(5세 이내 감점 완화)·직군 조합에 점수를 부여하는 규칙 기반 기본 구현
- **ExternalAiMatchingEngine** — RestClient로 외부 AI 서버에 후보 스코어링을 위임하는 어댑터

두 구현체는 `@ConditionalOnProperty`로 조건부 등록되어, `application.yml`의 `matching.engine` 값(`local` / `external-ai`)만 바꾸면 `MatchingService` 코드 수정 없이 전환됩니다.

### 규칙 기반을 먼저 만든 이유

AI 매칭이 목표인 서비스에서 규칙 기반 엔진을 먼저 만든 것은 우회가 아니라 순서의 문제였습니다.

1. AI 모델 없이도 추천→요청→수락 플로우 전체를 즉시 실행·검증할 수 있어야 나머지 백엔드를 만들 수 있습니다.
2. 외부 AI 서버와의 **요청/응답 계약**을 인터페이스로 먼저 고정해 두면, 이후 연동은 계약을 맞추는 어댑터 작업으로 좁혀집니다.
3. 추천 응답에 점수 사유를 포함시켜, 엔진이 바뀌어도 "왜 이 상대를 추천했는가"를 설명하는 API 형태는 유지됩니다.

### Trade-off

- 규칙 기반 점수는 추천 품질을 보장하지 않습니다. 지역·나이·직군 세 가지 신호는 실제 매칭 선호를 설명하기에 얕습니다.
- `ExternalAiMatchingEngine`은 어댑터 구조까지만 준비된 상태로, 실제 외부 AI 서버와의 연동·장애 처리(timeout·fallback)는 Phase 3 과제입니다.

## 03. 의도적으로 단순하게 남긴 계층 {#simple-layers}

빠르게 교체될 것을 알면서도 단순한 구현을 선택한 계층이 두 곳 있습니다. 기준은 "교체 시 바깥 코드가 몇 줄 바뀌는가"였습니다.

### H2 In-Memory + JPA

프로토타입 단계에서 로컬 어디서든 `./gradlew bootRun` 한 번으로 기동되는 환경을 우선했습니다. 재시작 시 데이터가 사라지는 대신, 접근을 전부 Spring Data JPA Repository로 추상화해 MySQL/PostgreSQL 전환이 datasource 설정 교체로 끝나도록 했습니다. 시드 데이터(관리자 1명 + 회원 20명, 매칭 30건, QnA 3건, 알림 2건)는 기동 시 자동 적재되어, 매 실행마다 동일한 검증 시나리오를 재현할 수 있습니다.

### UUID 더미 토큰

Spring Security 없이 `X-AUTH-TOKEN` 헤더의 UUID 토큰을 In-Memory `TokenStore`에서 조회하는 방식입니다. 표준 인증이 아니라는 것을 알면서 선택한 이유는, 인증 방식이 Controller와 Service로 새어 나가지 않게 격리하는 것이 이 단계의 목표였기 때문입니다. JWT/Spring Security 도입 시 TokenStore 계층만 교체하면 Controller 시그니처는 유지됩니다.

### 상태는 처음부터 명시적으로

반대로 상태 모델은 단순화하지 않았습니다.

- **MatchRecord**는 REQUESTED → ACCEPTED / REJECTED 세 상태로 제한된 상태 머신입니다. 상태 전이 지점이 명확해야, 이후 WebSocket 알림을 붙일 때 각 전이를 이벤트 발행 지점으로 쓸 수 있습니다.
- **User**는 role(USER/ADMIN) · status(PENDING/ACTIVE/SUSPENDED) · gender를 분리해, 권한·계정 생명주기·매칭 필터가 서로를 침범하지 않게 했습니다. 가입 직후는 PENDING이며 관리자 승인으로 ACTIVE가 됩니다.

### Trade-off

- 더미 토큰은 만료·서명 검증이 없어 로컬 실험 전용입니다. 이 상태로는 어떤 외부 노출도 불가합니다.
- In-Memory 토큰과 H2는 다중 인스턴스에서 공유될 수 없습니다. 수평 확장 검증은 영속 계층 전환 이후의 과제입니다.

## 04. 검증 결과와 다음 단계 {#verification}

### Phase 2 검증 결과

Java 21(Record DTO, Virtual Threads 활성화) + Spring Boot 4.1.0 + Gradle 9 기반으로, 빌드·테스트와 전체 API 스모크 테스트를 통과했습니다.

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **회원 흐름** | 신규 가입 시 PENDING 전환 · 회원/관리자 로그인 토큰 발급 확인 |
| **추천** | 지역·나이·직군 점수 기반 추천이 사유와 함께 반환되는지 확인 |
| **매칭 상태 전이** | 요청 → 수락 → ACCEPTED 전이 확인 |
| **QnA** | 문의 등록 → 관리자 답변 → ANSWERED 전이 확인 |
| **알림** | 전체 공지 배포와 개별 수신 확인 |
| **관리자** | 회원 정지(SUSPENDED) 처리 · 일별/성별/상태별 매칭 통계 조회 확인 |

### 현재 한계

- 인증이 더미 토큰이라 JWT 등 표준 방식이 적용되지 않았습니다.
- H2 인메모리 기반이라 재시작 시 데이터가 소실됩니다.
- 추천이 규칙 기반에 머물러 있고 AI 모델 통합은 미완료입니다.
- 매칭 성사 이후의 실시간 채팅 등 WebSocket 기능이 없습니다.

<span class="section-note">시드 데이터 기반의 로컬 스모크 테스트 결과이며, 실사용 트래픽이나 실제 사용자 대상의 추천 품질을 측정한 것은 아닙니다. 교체 접점이 설계대로 동작하는지를 확인한 구조 실험입니다.</span>

### 다음 단계 — 앞으로 추가할 백엔드 과제

각 과제는 지금까지 준비한 교체 접점 위에서 진행합니다.

1. **외부 AI 매칭 서버 연동 (Phase 3)** — `matching.engine=external-ai` 전환 후 `ExternalAiMatchingEngine`의 계약을 실제 AI 서버와 맞추고, LLM 기반 프로필 분석을 추천 신호에 추가합니다. timeout·fallback 등 외부 의존 장애 처리를 함께 다룹니다.
2. **운영 영속 계층 전환 (Phase 4)** — H2를 외부 RDBMS(MySQL/PostgreSQL)로 교체하고, JPA 코드 무변경이라는 설계 전제가 실제로 성립하는지 검증합니다.
3. **표준 인증 도입 (Phase 4)** — TokenStore를 JWT/Spring Security로 교체하고, Controller 시그니처가 유지되는지 확인합니다.
4. **실시간성 (Phase 4)** — MatchRecord 상태 전이(ACCEPTED 등)를 이벤트로 발행하고, WebSocket 기반 매칭 알림과 성사 후 대화방으로 확장합니다.

## Source

- [github.com/hello-pebble/MatchSimulation](https://github.com/hello-pebble/MatchSimulation) — 소스 코드
- [Architecture](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/architecture.md) · [Phase 2 Report](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/phase2_report.md)
