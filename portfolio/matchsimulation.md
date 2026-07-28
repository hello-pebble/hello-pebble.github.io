---
layout: default
title: "교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 규칙 기반 엔진에서 외부 AI로의 전환 접점 실험"
permalink: /portfolio/matchsimulation/
category: portfolio
tags: [Java21, SpringBoot4, JPA, H2, Gradle, StrategyPattern]
---

<span class="project-context">개인 프로젝트 · 2026.06 — 진행 중</span>

# 교체 가능한 경계를 먼저 설계한 매칭 서비스 백엔드 — 규칙 기반 엔진에서 외부 AI로의 전환 접점 실험

- 추천 방식이 변경되더라도 가입·추천·매칭 수락 같은 핵심 흐름의 수정을 줄일 수 있도록 경계를 나누고, 구현체 전환과 주요 API 시나리오를 검증하고 있습니다.

<dl class="project-summary-grid">
  <div>
    <dt>무엇을</dt>
    <dd>AI 소개팅 서비스를 가정한 매칭 백엔드 — 가입·추천·수락 흐름과 `matching.engine` 설정 하나로 전환되는 추천 엔진 경계</dd>
  </div>
  <div>
    <dt>왜</dt>
    <dd>초기 추천 규칙이 점수 기반·외부 추천 엔진으로 바뀔 때, 핵심 매칭 흐름까지 함께 수정되는 범위를 줄일 수 있는지 검토하기 위해</dd>
  </div>
  <div>
    <dt>담당 범위</dt>
    <dd>요구사항 정의 · 도메인 경계 설계 · API 구현 · MatchingEngine 전략 구성 · 상태 전이와 통합 시나리오 검증 (진행 중)</dd>
  </div>
  <div>
    <dt>검증한 것</dt>
    <dd>설정 변경에 따른 엔진 구현체 전환 · 가입→추천→수락 상태 전이 · QnA·알림·관리자 통계 포함 전체 API 스모크 테스트</dd>
  </div>
</dl>

<nav class="project-page-nav" aria-label="MatchSimulation 프로젝트 목차">
  <a href="#decisions">
    <span>Overview</span>
    <small>확보하려 한 3가지 교체 접점</small>
  </a>
  <a href="#engine">
    <span>01. 매칭 엔진 경계</span>
    <small>설정 기반 구현체 전환</small>
  </a>
  <a href="#states">
    <span>02. 매칭 상태 전이</span>
    <small>가입 승인부터 수락·거절까지</small>
  </a>
  <a href="#structure">
    <span>03. 모듈 분리 기준</span>
    <small>package-by-feature</small>
  </a>
  <a href="#verification">
    <span>검증과 다음 단계</span>
    <small>Phase 2 결과와 로드맵</small>
  </a>
</nav>

## Overview — 확보하려 한 3가지 교체 접점 {#decisions}

매칭 서비스에서는 초기 추천 규칙이 이후 점수 기반·외부 추천 엔진으로 변경될 가능성이 있다고 보았습니다. "나중에 반드시 바뀔 부분"을 먼저 정의하고, 그 경계 바깥의 코드가 교체에 영향받지 않는지를 확인하는 것이 이 프로젝트의 목적입니다.

| 교체 접점 | 지금의 구현 | 교체 시 바뀌는 범위 |
| :--- | :--- | :--- |
| **① 추천 엔진** | 규칙 기반 `LocalMatchingEngine` | `matching.engine` 설정값 하나 |
| **② 데이터베이스** | H2 In-Memory + JPA | datasource 설정 (JPA 코드 무변경 — 실제 교체 검증은 Phase 4) |
| **③ 인증** | UUID 더미 토큰 `TokenStore` | TokenStore 계층 (Controller 시그니처 유지 — 실제 교체 검증은 Phase 4) |

![MatchSimulation 구조 — 7개 기능 모듈과 MatchingEngine 인터페이스의 설정 기반 분기](/assets/images/portfolio/matchsimulation-architecture.svg){:.portfolio-diagram}

## 01. MatchingEngine 경계 — 왜 처음부터 AI를 붙이지 않았는가 {#engine}

추천 로직이 서비스 흐름에 직접 결합되면 추천 방식이 바뀔 때마다 핵심 흐름도 함께 수정됩니다. 그래서 추천 전체를 `MatchingEngine` 인터페이스 하나로 감싸고, 규칙 기반 `LocalMatchingEngine`과 외부 AI 어댑터 `ExternalAiMatchingEngine`을 `@ConditionalOnProperty`로 조건부 등록해 **`matching.engine` 설정값만으로 전환**되는 것을 확인했습니다.

규칙 기반을 먼저 만든 것은 우회가 아니라 순서의 문제입니다. AI 모델 없이도 추천→요청→수락 플로우 전체를 즉시 실행·검증할 수 있고, 외부 AI와의 요청/응답 계약을 인터페이스로 먼저 고정하면 이후 연동은 어댑터 작업으로 좁혀집니다.

- 규칙 기반 점수(지역·나이·직군)는 추천 품질을 보장하지 않습니다.
- `ExternalAiMatchingEngine`은 어댑터 구조까지만 준비된 상태로, 실제 연동과 timeout·fallback은 Phase 3 과제입니다.

## 02. 매칭 상태 전이 — 잘못된 상태 변경을 규칙에서 차단 {#states}

계정 생명주기(User)와 매칭 요청(MatchRecord)을 각각 제한된 상태 머신으로 관리합니다. 수락·거절은 `REQUESTED` 상태에서만 허용되고 종결 상태는 재전이가 없어, 잘못된 상태 변경이 코드 여러 곳이 아니라 전이 규칙에서 막힙니다.

![매칭 상태 전이도 — 가입 승인부터 수락·거절까지, 전이 규칙과 불변 조건](/assets/images/portfolio/matchsimulation-match-state.svg){:.portfolio-diagram}

전이 지점을 명시적으로 남긴 이유는 확장 때문입니다. 이후 WebSocket 알림을 붙일 때 각 전이를 그대로 이벤트 발행 지점으로 사용할 수 있습니다. User의 role·status·gender를 분리한 것도 권한·계정 생명주기·매칭 필터가 서로를 침범하지 않게 하기 위해서입니다.

## 03. 모듈 분리의 기준 — 기능 단위 변경 범위 {#structure}

계층(controller/service)이 아니라 **함께 변경되는 기능**을 최상위 기준으로 패키지를 나눴습니다. 하나의 기능을 수정할 때 변경 범위가 한 패키지에 갇히고, 이후 분리가 필요해지면 패키지를 그대로 모듈로 승격할 수 있습니다. 모듈 간 참조는 수평 구조를 유지해 순환 의존이 생기지 않게 했습니다.

| 모듈 | 책임 |
| :--- | :--- |
| **user** | 회원가입(PENDING) · 로그인 · 내 정보 |
| **matching** | 추천 · 매칭 요청/수락/거절 · 엔진 연동 |
| **qna** | 1:1 문의 등록과 조회 |
| **notification** | 전체 공지 · 개별 알림 |
| **admin** | 회원 관리 · QnA 답변 · 매칭 통계 — 요청마다 Role=ADMIN 검사, 아니면 403 |
| **common / config** | 비즈니스 예외·통일된 에러 응답 · H2 시드 데이터 |

현재 규모에서는 계층형보다 패키지 수가 많아 탐색 비용이 있고, 모듈 경계는 패키지 수준의 약속일 뿐 컴파일 타임에 의존 방향을 강제하지 못합니다. 강제가 필요해지는 시점을 멀티모듈 전환 시점으로 판단했습니다.

## 검증 결과와 다음 단계 {#verification}

Java 21 + Spring Boot 4.1.0 + Gradle 9 기반으로, 시드 데이터(관리자 1명 + 회원 20명, 매칭 30건)를 기동 시 적재해 매 실행마다 동일한 시나리오를 재현합니다.

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **엔진 전환** | `matching.engine` 설정 변경으로 구현체 전환 · `MatchingService` 코드 무변경 |
| **회원 흐름** | 신규 가입 시 PENDING 전환 · 회원/관리자 로그인 토큰 발급 확인 |
| **추천** | 지역·나이·직군 점수 기반 추천이 사유와 함께 반환되는지 확인 |
| **매칭 상태 전이** | 요청 → 수락 → ACCEPTED 전이 확인 |
| **QnA · 알림 · 관리자** | 문의 답변(ANSWERED) · 공지 배포 · 회원 정지 · 매칭 통계 조회 확인 |
| **빌드·실행 경계** | 모듈별 빌드와 전체 API 스모크 테스트 통과 |

### 한계와 다음 검증 과제

- 실제 추천 품질은 검증하지 못했습니다 — 지역·나이·직군 세 신호는 실제 매칭 선호를 설명하기에 얕습니다.
- 대규모 트래픽이나 동시 수락 상황은 검증하지 못했습니다 — 동시성 테스트가 다음 과제입니다.
- DB·인증 교체는 설계 방향까지 준비된 상태이며, 실제 교체 검증(Phase 4)과는 구분합니다.
- 더미 토큰은 만료·서명 검증이 없어 로컬 실험 전용이며, H2·In-Memory 토큰은 다중 인스턴스에서 공유될 수 없습니다.
- 다음 단계: 외부 AI 연동과 구현체 계약 테스트(Phase 3) → RDBMS·JWT 교체 검증, 전이 이벤트 기반 WebSocket 알림(Phase 4)

<span class="section-note">시드 데이터 기반의 로컬 스모크 테스트 결과이며, 실사용 트래픽이나 실제 사용자 대상의 추천 품질을 측정한 것은 아닙니다. 교체 접점이 설계대로 동작하는지를 확인한 구조 실험입니다.</span>

## Source

- [github.com/hello-pebble/MatchSimulation](https://github.com/hello-pebble/MatchSimulation) — 소스 코드
- [Architecture](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/architecture.md) · [Phase 2 Report](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/phase2_report.md)
