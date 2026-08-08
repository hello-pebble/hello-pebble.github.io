---
layout: default
title: "교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 그리고 실제로 교체하며 검증한 기록"
permalink: /portfolio/matchsimulation/
category: portfolio
tags: [Java21, SpringBoot4, JPA, Flyway, SpringSecurity, JWT, WebSocket]
---

<span class="project-context">개인 프로젝트 · 2026.06 — 진행 중</span>

# 교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드

소개팅 서비스를 가정하고 가입, 추천, 매칭 수락, 1:1 채팅, 관리자 모드 흐름을 갖춘 프로젝트입니다.
이 프로젝트의 목적은 기능 완성이 아니라 나중에 바뀔 부분을 미리 알고, 실제로 교체해 보며 그 설계가 통하는지 확인하는 것입니다.

실제로 교체한 것은 세 곳입니다. 
1. 인증은 더미 토큰에서 Spring Security·JWT·BCrypt로 변경
2. DB 스키마는 Hibernate 자동 생성에서 Flyway 마이그레이션으로 변경
3. 채팅 수신은 ** 새로고침 → Polling → Long Polling → WebSocket ** 으로 각 단계의 비용을 실측한 뒤에 다음 단계로 넘어갔습니다. 교체할 때마다 회귀 테스트로 기존 동작이 깨지지 않았음을 확인했습니다.

진행 방식은 phase마다 계획서(엣지케이스 정의)를 먼저 쓰고, 구현 후 완료 보고서(실측 기록)를 남기는 사이클입니다.

![MatchSimulation 회원 콘솔 — 추천 받기부터 매칭 요청·채팅까지 전체 흐름을 실제 API 응답(추천 점수·이유 포함)과 함께 확인한다](/assets/images/portfolio/matchsimulation-console.png){:.portfolio-hero-shot}

<nav class="project-page-nav" aria-label="MatchSimulation 프로젝트 목차">
  <a href="#boundaries">
    <span>01. 경계 설계와 실제 교체</span>
    <small>인증·스키마·엔진</small>
  </a>
  <a href="#states">
    <span>02. 상태 전이와 동시성</span>
    <small>낙관적 락·트랜잭션 경계</small>
  </a>
  <a href="#chat">
    <span>03. 채팅 수신 4단계</span>
    <small>측정이 다음 단계를 정했다</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>확인한 범위·남은 과제</small>
  </a>
  <a href="#conclusion">
    <span>마무리</span>
    <small>기능 구현에서 교체 검증으로</small>
  </a>
  <a href="#process">
    <span>개발·검증 방식</span>
    <small>계획서와 보고서를 쌍으로</small>
  </a>
</nav>

## 01. 교체 가능한 경계 — 설계로 끝내지 않고 실제로 교체했다 {#boundaries}

"나중에 반드시 바뀔 부분" 세 곳의 경계를 먼저 긋고, 경계 바깥의 코드가 교체에 영향 받지 않는지를 확인했습니다. 
세 곳 중 두 곳은 이미 실제 교체로 답을 확인했습니다.

| 교체 접점 | 초기 구현 | 교체 결과 |
| :--- | :--- | :--- |
| **인증** | UUID 더미 토큰 `TokenStore` + 평문 비밀번호 | **교체 완료** — Spring Security + JWT(HS256) + BCrypt. 인증 헤더(`X-AUTH-TOKEN`)를 유지해 콘솔·API 계약 무변경, Controller는 `@AuthenticationPrincipal` 주입으로 전환 |
| **스키마 소유권** | Hibernate `ddl-auto: create-drop` | **교체 완료** — Flyway `V1__init.sql`로 이전, Hibernate는 `validate`로 강등해 엔티티-스키마 불일치 시 기동 실패가 안전장치가 되도록 |
| **추천 엔진** | 규칙 기반 `LocalMatchingEngine` | 인터페이스 유지 — `matching.engine` 설정만으로 구현체 전환 확인, 외부 AI 어댑터는 실연동 전 단계 |

![MatchSimulation 구조 — 기능 모듈과 MatchingEngine 인터페이스의 설정 기반 분기](/assets/images/portfolio/matchsimulation-architecture.svg){:.portfolio-diagram}

인증에서 처음부터 Spring Security를 사용하지 않고 더미 토큰으로 시작한 것은, 핵심 매칭 흐름을 먼저 완성해 회귀 테스트를 갖춘 뒤 표준 스택으로 갈아타기 위해서였습니다. 
실제 교체 시 위조 서명, 만료 토큰, 정지 계정의 유효 토큰 같은 엣지케이스를 계획서에 먼저 정의하고, 기존 에러 응답 포맷(`{status, message}`)까지 유지하며 전환했습니다. 
추천 엔진을 규칙 기반으로 먼저 만든 것도 같은 순서 규칙입니다.

추후 외부 AI와의 계약을 인터페이스로 고정해 두면 이후 연동은 어댑터 작업으로 좁혀집니다. 다만 규칙 기반 점수(지역, 나이, 직군)가 추천 품질을 보장하지 않는다는 한계는 그대로입니다.

## 02. 상태 전이와 동시성 — 잘못된 변경을 규칙에서 차단 {#states}

계정 생명주기(User)와 매칭 요청(MatchRecord)은 각각 제한된 상태 머신으로 관리합니다. 수락, 거절은 `REQUESTED` 상태에서만 허용되고 종결 상태는 재전이가 없습니다. 
여기에 동시성과 원자성을 명시적으로 얹었습니다.

![매칭 상태 전이도 — 가입 승인부터 수락·거절까지, 전이 규칙과 불변 조건](/assets/images/portfolio/matchsimulation-match-state.svg){:.portfolio-diagram}

- **동시 응답 경쟁** — 같은 매칭에 두 요청이 동시에 수락, 거절을 시도하면 `@Version` 낙관적 락으로 한쪽만 성공하고 다른 쪽은 409를 받습니다. 상태는 정확히 1회만 전이됩니다.
- **트랜잭션 경계** — 수락 시 상태 변경과 양측 알림 생성을 하나의 트랜잭션으로 묶어, 알림 저장이 실패하면 상태 변경도 롤백됩니다.
- **방치된 요청** — 7일 무응답 매칭은 스케줄러가 자동 만료시킵니다.

상태 전이 지점을 명시적으로 남긴 것은 확장을 위해서였고, 실제로 채팅 WebSocket 단계에서 "매칭이 ACCEPTED인 경우에만 연결 허용" 같은 규칙이 이 전이 지점을 그대로 재사용했습니다.

![관리자 콘솔의 매칭 현황 통계 — REQUESTED·ACCEPTED·EXPIRED·REJECTED 상태별 분포와 성사율을 실데이터로 집계한다](/assets/images/portfolio/matchsimulation-admin-stats.png){:.portfolio-detail-shot}

## 03. 채팅 수신의 4단계 진화 — 측정이 다음 단계를 정했다 {#chat}

매칭이 성사된 상대와의 1:1 채팅은 처음부터 WebSocket으로 가지 않았습니다. 
가장 단순한 구조부터 시작해 **각 단계의 비용을 숫자로 확인한 뒤** 다음 단계로 넘어갔고, 서버 API 계약(`afterId` 증분 조회)은 1단계에서 고정해 재사용했습니다.

| 단계 | 방식 | 이 단계가 남긴 것 |
| :--- | :--- | :--- |
| **새로고침** | 버튼 클릭 시 `afterId` 이후 메시지만 증분 조회 | 이후 모든 단계가 재사용하는 API 계약 |
| **Short Polling** | 3초 주기 자동 조회 | **실측: 30초에 1건 수신하는 동안 요청 10회·빈 응답 9회(90%)·전달 지연 최대 3초** — 낭비를 데이터로 기록 |
| **Long Polling** | `DeferredResult`로 서버가 대기, 새 메시지 발생 시 즉시 응답 | **같은 조건에서 요청 2회·빈 응답 0~1회·전달 지연 ≈ 0** |
| **WebSocket** | 연결 1개 유지, 양방향 push | **push 지연 9ms·핸드셰이크 13ms 실측** — 재요청 반복까지 제거 |

단계마다 설계 결정이 하나씩 있었습니다. 
Long Polling은 서블릿 스레드를 점유하지 않는 비동기 처리입니다 — `DeferredResult`를 반환하면 요청 스레드는 즉시 반납되고, 대기자는 `ConcurrentHashMap` 레지스트리가 보관하다가 `onTimeout`·`onCompletion` 콜백으로 제거해 누수를 막습니다. 비동기 디스패치에서 인증 필터가 다시 실행되는 서블릿 비동기 생명주기도 이 단계에서 명시적으로 다뤘습니다. 대기자 알림(publish)은 메시지 저장 트랜잭션 **커밋 이후**에 호출하도록 경계를 잡았습니다 — 트랜잭션 안에서 알리면 대기자가 커밋 전 데이터를 조회해 새 메시지를 놓칠 수 있기 때문입니다.

WebSocket에서는 STOMP를 **쓰지 않기로** 결정했습니다. 구독 대상이 matchId 하나뿐이라 브로커, 구독 프로토콜 계층이 과하고 핸드셰이크, 세션 관리, 브로드캐스트를 직접 다뤄 동작을 드러내는 쪽이 이 프로젝트의 목적에 맞았습니다. 인증은 `HandshakeInterceptor`에서 연결 수립 전에 JWT, 정지 계정, 매칭 참여자를 검증해 실패한 연결은 열리지도 않습니다.

실제 연결로 검증 항목
1. Long Polling은 MockMvc의 `asyncDispatch`로 비동기 응답 사이클을 확인
2. WebSocket은 `StandardWebSocketClient`로 랜덤 포트에 뜬 서버에 직접 접속해 핸드셰이크 거부, 세션 누수, REST 전송 -> WebSocket 수신 교차까지 확인

![WebSocket 단계의 1:1 채팅 — 연결 1개를 유지한 채 새 메시지가 push되어 폴링 요청 0회로 수신된다](/assets/images/portfolio/matchsimulation-chat-ws.png){:.portfolio-detail-shot}

## 검증 결과와 한계 {#verification}

Java 21 + Spring Boot 4.1.0 + Gradle 9 기반으로, 시드 데이터(관리자 1명 + 회원 20명, 매칭 30건)를 Flyway 스키마 위에 기동 시 적재해 매 실행마다 동일한 시나리오를 재현합니다.

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **인증 교체** | 더미 토큰 → JWT·BCrypt 전환 후 전체 회귀 테스트 통과 · 위조/만료/정지 계정 엣지케이스 확인 |
| **스키마 이전** | Flyway V1 적용 이력 검증 · `validate` 모드에서 전체 테스트 통과(스키마-엔티티 일치 증명) |
| **엔진 전환** | `matching.engine` 설정 변경으로 구현체 전환 · `MatchingService` 코드 무변경 |
| **매칭 동시성** | 동시 응답 시 1건만 성공(409) · 알림 실패 시 롤백 확인 |
| **채팅 4단계** | 단계별 엣지케이스(타임아웃 보정, 대기자 누수, 비참여자 차단 등) 계획서 정의 → 실측 확인 |
| **API 문서·회귀** | Swagger UI · JUnit 5 `@SpringBootTest` 기반 회귀 테스트(Regression Test) 51건을 phase마다 green 유지 |

### 한계와 다음 검증 과제

- 실제 추천 품질은 검증하지 못했습니다 — 지역, 나이, 직군 세 신호는 실제 매칭 선호를 설명하기에 얕습니다. 
- H2 인메모리 기반이라 대규모 트래픽·다중 인스턴스 상황은 검증 범위 밖입니다. -> DB연결은 예정
- AI 엔진은 어댑터 구조까지만 준비된 상태로, 실연동과 timeout·fallback이 남아 있습니다.

<span class="section-note">시드 데이터 기반의 로컬 검증 결과이며, 실사용 트래픽이나 실제 사용자 대상의 추천 품질을 측정한 것은 아닙니다. 교체 접점이 설계대로 동작하는지를 실제 교체로 확인해 가는 구조 실험입니다.</span>

## 마무리 — 기능 구현에서 교체 검증으로 {#conclusion}

이 프로젝트는 처음에는 H2, 더미 토큰, 단순 조회 방식으로 가입 -> 추천 -> 수락의 핵심 흐름을 먼저 검증했습니다.

이후 인증을 JWT·BCrypt로, 스키마 관리를 Flyway로 실제 교체했고, 채팅은 각 단계의 비용을 측정하며 WebSocket까지 발전시켰습니다.
동시 응답은 낙관적 락과 트랜잭션으로 보호해 상태가 한 번만 전이되도록 했습니다.

현재는 외부 AI 추천 엔진 실연동, 외부 RDBMS(PostgreSQL) 전환 — Flyway 이전은 이를 위한 포석입니다 — 운영 관측성(Actuator·메트릭)이 남아 있습니다. 

## 개발·검증 방식 — 계획서와 보고서를 쌍으로 {#process}

모든 phase는 같은 규칙으로 진행했습니다. 
시작 전에 **계획 문서**를 써서 배경·설계·엣지케이스(E1, E2, …)·테스트 계획을 고정하고, 구현 후에는 **완료 보고서**에 회귀 테스트 결과와 curl 실측을 기록합니다. 
예를 들어 Short Polling 계획서는 "구조적 비용(빈 요청)을 실측으로 기록해 다음 단계(Long Polling)의 필요성을 데이터로 남긴다"를 목표에 명시했고, 실제로 그 실측(빈 응답 90%)이 다음 phase의 첫 문장이 됐습니다. 이렇게 쌓인 plan→report가 [docs/](https://github.com/hello-pebble/MatchSimulation/tree/main/docs)에 기록돼 있습니다.

패키지는 초기 계층형 구조를 **함께 변경되는 기능 단위 모듈로 재편(refactoring)**한 결과입니다(user·matching·chat·qna·notification·admin). 변경 범위가 한 패키지에 갇히고, 필요해지면 패키지를 모듈로 승격할 수 있습니다. 현재 규모에서는 계층형보다 탐색 비용이 있고 의존 방향을 컴파일 타임에 강제하지 못한다는 비용도 함께 적어 둡니다.

구현은 Claude Code와 진행했습니다. phase 단위로 브랜치를 파서 PR로 머지하는 흐름이며, 계획서의 엣지케이스 표가 곧 AI에게 주는 명세이자 제가 결과를 검수하는 채점표입니다. 
계획서에 정의하지 않은 동작이 나오면 되돌립니다.

## Source

- [github.com/hello-pebble/MatchSimulation](https://github.com/hello-pebble/MatchSimulation) — 소스 코드
- [Architecture](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/architecture.md) · [docs/](https://github.com/hello-pebble/MatchSimulation/tree/main/docs) —  계획서, 완료 보고서
