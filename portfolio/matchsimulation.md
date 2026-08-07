---
layout: default
title: "교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 그리고 실제로 교체하며 검증한 기록"
permalink: /portfolio/matchsimulation/
category: portfolio
tags: [Java21, SpringBoot4, JPA, Flyway, SpringSecurity, JWT, WebSocket]
---

<span class="project-context">개인 프로젝트 · 2026.06 — 진행 중</span>

# 교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드

- "나중에 반드시 바뀔 부분"의 경계를 먼저 긋고, 실제로 그 경계를 따라 **더미 인증을 Spring Security + JWT로, Hibernate 자동 스키마를 Flyway로 교체**하며 설계가 통하는지 확인해 온 프로젝트입니다. 채팅 수신은 새로고침 → Short Polling → Long Polling → WebSocket 순서로, **각 단계의 비용을 실측한 뒤** 다음 단계로 넘어갔습니다.

<dl class="project-summary-grid">
  <div>
    <dt>무엇을</dt>
    <dd>AI 소개팅 서비스를 가정한 매칭 백엔드 — 가입·추천·수락·1:1 채팅·관리자 흐름과 설정 하나로 전환되는 추천 엔진 경계</dd>
  </div>
  <div>
    <dt>어떻게</dt>
    <dd>phase마다 계획서(엣지케이스 정의) → 구현 → 완료 보고서(실측 기록)를 쌍으로 남기는 사이클 — 문서 29건이 저장소에 공개</dd>
  </div>
  <div>
    <dt>담당 범위</dt>
    <dd>요구사항 정의 · 도메인 경계 설계 · API 구현 · 인증/스키마 교체 · 채팅 수신 구조 진화 · 상태 전이와 동시성 검증</dd>
  </div>
  <div>
    <dt>검증한 것</dt>
    <dd>더미 토큰 → JWT 실제 교체 · ddl-auto → Flyway 이전 · 동시 응답 낙관적 락 · Short Polling 빈 응답 90% 실측 · 전체 API 회귀 테스트</dd>
  </div>
</dl>

<nav class="project-page-nav" aria-label="MatchSimulation 프로젝트 목차">
  <a href="#process">
    <span>만든 방식</span>
    <small>계획서와 보고서를 쌍으로</small>
  </a>
  <a href="#boundaries">
    <span>01. 경계 설계와 실제 교체</span>
    <small>인증·스키마·엔진</small>
  </a>
  <a href="#chat">
    <span>02. 채팅 수신 4단계</span>
    <small>측정이 다음 단계를 정했다</small>
  </a>
  <a href="#states">
    <span>03. 상태 전이와 동시성</span>
    <small>낙관적 락·트랜잭션 경계</small>
  </a>
  <a href="#verification">
    <span>검증과 다음 단계</span>
    <small>확인한 범위·로드맵</small>
  </a>
</nav>

## 만든 방식 — phase마다 계획서와 보고서를 쌍으로 {#process}

모든 phase는 같은 리듬으로 진행했습니다. 시작 전에 **계획 문서**를 써서 배경·설계·엣지케이스(E1, E2, …)·테스트 계획을 고정하고, 구현 후에는 **완료 보고서**에 회귀 테스트 결과와 curl 실측을 기록합니다. 예를 들어 Short Polling 계획서는 "구조적 비용(빈 요청)을 실측으로 기록해 다음 단계(Long Polling)의 필요성을 데이터로 남긴다"를 목표에 명시했고, 실제로 그 실측(빈 응답 90%)이 다음 phase의 첫 문장이 됐습니다. 이렇게 쌓인 plan→report 쌍이 [docs/](https://github.com/hello-pebble/MatchSimulation/tree/main/docs)에 29건 공개돼 있습니다.

구현은 Claude Code와 협업했습니다. phase 단위로 브랜치를 파서 PR로 머지하는 흐름이며, 계획서의 엣지케이스 표가 곧 AI에게 주는 명세이자 제가 결과를 검수하는 채점표입니다. 계획서에 정의하지 않은 동작이 나오면 되돌립니다. 협업 원칙은 [AI를 어떻게 쓰는가](/ai/)에 정리했습니다.

## 01. 교체 가능한 경계 — 설계로 끝내지 않고 실제로 교체했다 {#boundaries}

시작할 때 "나중에 반드시 바뀔 부분" 세 곳의 경계를 먼저 그었습니다. 이 프로젝트의 핵심 질문은 **그 경계 바깥의 코드가 교체에 영향받지 않는가**였고, 세 곳 중 두 곳은 이미 실제 교체로 답을 확인했습니다.

| 교체 접점 | 초기 구현 | 교체 결과 |
| :--- | :--- | :--- |
| **① 인증** | UUID 더미 토큰 `TokenStore` + 평문 비밀번호 | **교체 완료** — Spring Security + JWT(HS256) + BCrypt. 인증 헤더(`X-AUTH-TOKEN`)를 유지해 콘솔·API 계약 무변경, Controller는 `@AuthenticationPrincipal` 주입으로 전환 |
| **② 스키마 소유권** | Hibernate `ddl-auto: create-drop` | **교체 완료** — Flyway `V1__init.sql`로 이전, Hibernate는 `validate`로 강등해 엔티티-스키마 불일치 시 기동 실패가 안전장치가 되도록 |
| **③ 추천 엔진** | 규칙 기반 `LocalMatchingEngine` | 인터페이스 유지 — `matching.engine` 설정만으로 구현체 전환 확인, 외부 AI 어댑터는 실연동 전 단계 |

![MatchSimulation 구조 — 기능 모듈과 MatchingEngine 인터페이스의 설정 기반 분기](/assets/images/portfolio/matchsimulation-architecture.svg){:.portfolio-diagram}

인증 교체가 특히 좋은 검증이었습니다. 처음부터 Spring Security를 깔지 않고 더미 토큰으로 시작한 것은, 핵심 매칭 흐름을 먼저 완성해 회귀 테스트를 갖춘 뒤 표준 스택으로 갈아타기 위해서였습니다. 실제 교체 시 위조 서명·만료 토큰·정지 계정의 유효 토큰 같은 엣지케이스를 계획서에 먼저 정의하고, 기존 에러 응답 포맷(`{status, message}`)까지 유지하며 전환했습니다. 추천 엔진을 규칙 기반으로 먼저 만든 것도 같은 순서 감각입니다 — 외부 AI와의 계약을 인터페이스로 고정해 두면 이후 연동은 어댑터 작업으로 좁혀집니다. 다만 규칙 기반 점수(지역·나이·직군)가 추천 품질을 보장하지 않는다는 한계는 그대로입니다.

패키지는 계층이 아니라 **함께 변경되는 기능** 단위로 나눴습니다(user·matching·chat·qna·notification·admin). 변경 범위가 한 패키지에 갇히고, 필요해지면 패키지를 모듈로 승격할 수 있습니다. 현재 규모에서는 계층형보다 탐색 비용이 있고 의존 방향을 컴파일 타임에 강제하지 못한다는 비용도 함께 적어 둡니다.

## 02. 채팅 수신의 4단계 진화 — 측정이 다음 단계를 정했다 {#chat}

매칭이 성사된 상대와의 1:1 채팅은 처음부터 WebSocket으로 가지 않았습니다. 가장 단순한 구조부터 시작해 **각 단계의 비용을 숫자로 확인한 뒤** 다음 단계로 넘어갔고, 서버 API 계약(`afterId` 증분 조회)은 1단계에서 고정해 재사용했습니다.

| 단계 | 방식 | 이 단계가 남긴 것 |
| :--- | :--- | :--- |
| **1. 새로고침** | 버튼 클릭 시 `afterId` 이후 메시지만 증분 조회 | 이후 모든 단계가 재사용하는 API 계약 |
| **2. Short Polling** | 3초 주기 자동 조회 | **실측 빈 응답 90%** — 낭비를 데이터로 기록 |
| **3. Long Polling** | `DeferredResult`로 서버가 대기, 새 메시지 발생 시 즉시 응답 | 전달 지연 ≈ 0, 빈 요청 제거 |
| **4. WebSocket** | 연결 1개 유지, 양방향 push | 재요청 반복까지 제거 |

단계마다 설계 결정이 하나씩 있었습니다. Long Polling에서는 대기자 알림(publish)을 메시지 저장 트랜잭션 **커밋 이후**에 호출하도록 경계를 잡았습니다 — 트랜잭션 안에서 알리면 대기자가 커밋 전 데이터를 조회해 새 메시지를 놓칠 수 있기 때문입니다. WebSocket에서는 STOMP를 **쓰지 않기로** 결정했습니다. 구독 대상이 matchId 하나뿐이라 브로커·구독 프로토콜 계층이 과하고, 핸드셰이크·세션 관리·브로드캐스트를 직접 다뤄 저수준 동작을 드러내는 쪽이 이 프로젝트의 목적에 맞았습니다. 인증은 `HandshakeInterceptor`에서 연결 수립 전에 JWT·정지 계정·매칭 참여자를 검증해, 실패한 연결은 열리지도 않습니다.

## 03. 상태 전이와 동시성 — 잘못된 변경을 규칙에서 차단 {#states}

계정 생명주기(User)와 매칭 요청(MatchRecord)은 각각 제한된 상태 머신으로 관리합니다. 수락·거절은 `REQUESTED` 상태에서만 허용되고 종결 상태는 재전이가 없습니다.

![매칭 상태 전이도 — 가입 승인부터 수락·거절까지, 전이 규칙과 불변 조건](/assets/images/portfolio/matchsimulation-match-state.svg){:.portfolio-diagram} 여기에 동시성과 원자성을 명시적으로 얹었습니다.

- **동시 응답 경쟁** — 같은 매칭에 두 요청이 동시에 수락·거절을 시도하면 `@Version` 낙관적 락으로 한쪽만 성공하고 다른 쪽은 409를 받습니다. 상태는 정확히 1회만 전이됩니다.
- **트랜잭션 경계** — 수락 시 상태 변경과 양측 알림 생성을 하나의 트랜잭션으로 묶어, 알림 저장이 실패하면 상태 변경도 롤백됩니다.
- **방치된 요청** — 7일 무응답 매칭은 스케줄러가 자동 만료시킵니다.

상태 전이 지점을 명시적으로 남긴 것은 확장을 위해서였고, 실제로 채팅 WebSocket 단계에서 "매칭이 ACCEPTED인 경우에만 연결 허용" 같은 규칙이 이 전이 지점을 그대로 재사용했습니다.

## 검증 결과와 다음 단계 {#verification}

Java 21 + Spring Boot 4.1.0 + Gradle 9 기반으로, 시드 데이터(관리자 1명 + 회원 20명, 매칭 30건)를 Flyway 스키마 위에 기동 시 적재해 매 실행마다 동일한 시나리오를 재현합니다.

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **인증 교체** | 더미 토큰 → JWT·BCrypt 전환 후 전체 회귀 테스트 통과 · 위조/만료/정지 계정 엣지케이스 확인 |
| **스키마 이전** | Flyway V1 적용 이력 검증 · `validate` 모드에서 전체 테스트 통과(스키마-엔티티 일치 증명) |
| **엔진 전환** | `matching.engine` 설정 변경으로 구현체 전환 · `MatchingService` 코드 무변경 |
| **매칭 동시성** | 동시 응답 시 1건만 성공(409) · 알림 실패 시 롤백 확인 |
| **채팅 4단계** | 단계별 엣지케이스(타임아웃 보정, 대기자 누수, 비참여자 차단 등) 계획서 정의 → 실측 확인 |
| **API 문서·회귀** | Swagger UI · phase마다 전체 회귀 테스트 green 유지 |

### 한계와 다음 검증 과제

- 실제 추천 품질은 검증하지 못했습니다 — 지역·나이·직군 세 신호는 실제 매칭 선호를 설명하기에 얕습니다.
- H2 인메모리 기반이라 대규모 트래픽·다중 인스턴스 상황은 검증 범위 밖입니다.
- 외부 AI 엔진은 어댑터 구조까지만 준비된 상태로, 실연동과 timeout·fallback이 남아 있습니다.
- 다음 단계: 외부 RDBMS(PostgreSQL) 전환 — Flyway 이전은 이를 위한 포석입니다 — 외부 AI 실연동, 운영 관측성(Actuator·메트릭).

<span class="section-note">시드 데이터 기반의 로컬 검증 결과이며, 실사용 트래픽이나 실제 사용자 대상의 추천 품질을 측정한 것은 아닙니다. 교체 접점이 설계대로 동작하는지를 실제 교체로 확인해 가는 구조 실험입니다.</span>

## Source

- [github.com/hello-pebble/MatchSimulation](https://github.com/hello-pebble/MatchSimulation) — 소스 코드
- [Architecture](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/architecture.md) · [docs/](https://github.com/hello-pebble/MatchSimulation/tree/main/docs) — phase별 계획서·완료 보고서 29건
