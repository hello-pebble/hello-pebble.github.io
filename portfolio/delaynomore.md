---
layout: default
title: "DelayNoMore - AI 계획 실행 서비스"
permalink: /portfolio/delaynomore/
category: portfolio
tags: [SpringBoot, Java, React, PostgreSQL, OpenRouter, Portfolio]
---

<span class="project-context">개인 프로젝트 · 2026.04 — 2026.06 · 기획부터 데모 배포까지 단독</span>

# DelayNoMore — AI 계획 실행 서비스

- 계획을 반복해서 수정하거나 실행을 미루는 흐름을 줄이기 위해, 확정 후에는 완료 체크와 이월만 허용하는 잠금 모델과 AI 코치를 설계했습니다.

**[▶ 실행해 보기](http://delaynomoreapp.duckdns.org/)**

<dl class="project-summary-grid">
  <div>
    <dt>무엇을</dt>
    <dd>AI와 대화해 하루 단위 계획을 만들고, 확정 후에는 완료 체크와 다음 날 이월만 허용하는 실행 중심 서비스</dd>
  </div>
  <div>
    <dt>왜</dt>
    <dd>계획을 세우는 것보다 계획을 계속 수정하는 과정이 실행을 늦춘다는 가설 — 수정을 제한하는 잠금 모델로 검증</dd>
  </div>
  <div>
    <dt>담당 범위</dt>
    <dd>서비스 기획 · 화면 흐름 · 데이터 모델링 · API 설계 · 프론트엔드/백엔드 구현 · OCI Docker 데모 배포</dd>
  </div>
  <div>
    <dt>검증한 것</dt>
    <dd>잠금 규칙의 서버 강제(409) · SSE 스트리밍 표시와 폴백 · PostgreSQL 재시작 복원 · 데모 배포 후 접속·실행</dd>
  </div>
</dl>

<nav class="project-page-nav" aria-label="DelayNoMore 프로젝트 목차">
  <a href="#overview">
    <span>Overview</span>
    <small>가설과 핵심 사용자 흐름</small>
  </a>
  <a href="#state-integrity">
    <span>01. 잠금 모델</span>
    <small>상태 머신·트랜잭션 강제</small>
  </a>
  <a href="#ai-streaming">
    <span>02. AI 응답 스트리밍</span>
    <small>SSE·patch·폴백</small>
  </a>
  <a href="#adaptive-recommendation">
    <span>03. 다음 계획 추천</span>
    <small>규칙이 숫자, AI는 이유</small>
  </a>
  <a href="#deployment">
    <span>데모 배포</span>
    <small>1GB VM·단일 컨테이너</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>확인한 범위·다음 과제</small>
  </a>
</nav>

## Overview {#overview}

계획을 세우는 것보다 계획을 계속 수정하는 과정이 실행을 늦춘다고 가정했습니다. 그래서 핵심 흐름을 **계획 생성 → 확정(잠금) → 실행 → 회고 → 다음 계획 추천**으로 고정하고, 확정 이후의 수정은 서버가 거부하게 했습니다.

<div class="shot-labels"><span>① 계획 생성</span><span>② 오늘 할 일</span><span>③ 실행 추적</span></div>

![DelayNoMore 실제 서비스 화면 — 왼쪽 AI 코치와의 대화로 계획을 만들고, 가운데에 오늘 할 일이 모이며, 오른쪽 체크리스트에서 실행을 추적한다](/assets/images/portfolio/delaynomore-app.png){:.portfolio-hero-shot}

---

## 01. 잠금 모델 — 계획 수정 제한을 서버가 강제 {#state-integrity}

"확정된 계획은 수정할 수 없다"는 규칙을 화면에서만 막으면 API 직접 호출로 우회할 수 있습니다. 상태 집합과 허용 전이를 `PlanStatus` 전이표 하나로 모으고, 상태 변경을 `confirm·complete·cancel` 도메인 명령으로만 허용했습니다.

![계획 상태 전이도 — DRAFT에서 CONFIRMED로 잠기고, 잠금 이후의 수정과 전이표에 없는 전이는 409로 거부된다](/assets/images/portfolio/delaynomore-state-machine.svg){:.portfolio-diagram}

| 상태 | 허용 동작 |
| :--- | :--- |
| **DRAFT** | 계획 구조·내용 수정, 확정, 중단 |
| **CONFIRMED** | 완료 체크, 서버가 통제하는 오늘→내일 이월, 완료, 중단 |
| **COMPLETED / CANCELLED** | 모든 변경 차단 — 기록 조회만 유지 |

전이는 트랜잭션과 `SELECT … FOR UPDATE` 행 잠금 안에서 원자적으로 실행됩니다. 두 세션이 동시에 완료를 요청하면 첫 요청만 성공하고 뒤 요청은 409를 받으며, 프론트는 이 응답에서 서버 상태로 화면을 다시 맞춥니다.

![Immutable Lock — 확정 계획을 서버와 트랜잭션에서 잠금](/assets/images/portfolio/delaynomore-lock.svg){:.portfolio-diagram}

저장소는 Repository 인터페이스를 유지한 채 인메모리에서 PostgreSQL로 이전해, 서비스 규칙 변경 없이 재시작 후에도 상태가 복원되게 했습니다. 4×4 전이 매트릭스, 종결 상태의 수정 차단, 재시작 복원을 Testcontainers 기반 테스트로 고정했습니다.

![데이터 스키마 — 목적에 따라 선택한 저장 전략](/assets/images/portfolio/delaynomore-schema.svg){:.portfolio-diagram}

---

## 02. AI 응답 대기를 진행 경험으로 {#ai-streaming}

테스트 환경에서 고품질 계획 생성에 20~30초가 걸렸고, 완료까지 빈 화면을 보여주는 방식은 처리 여부를 알 수 없다는 문제가 있었습니다. 응답을 스트리밍으로 바꿔 생성 과정을 바로 표시했습니다.

![AI 응답 전달 방식 전후 비교 — 빈 화면 대기에서 SSE 순차 표시와 patch 교환으로](/assets/images/portfolio/delaynomore-streaming-compare.svg){:.portfolio-diagram}

![AI 응답 최적화 — patch와 SSE로 전송량과 체감 대기를 줄임](/assets/images/portfolio/delaynomore-ai.svg){:.portfolio-diagram}

확인한 범위는 다음으로 제한합니다.

- 스트리밍 응답이 순차적으로 표시되는 것을 확인했습니다.
- 스트림 실패 시 비스트리밍, 다시 실패하면 mock으로 전환되는 폴백을 확인했습니다.
- 요청당 입력 364–1,645 토큰, 비용 $0.0002–$0.0022 범위를 실측했습니다.

---

## 03. 다음 계획 추천 — 규칙이 숫자를, AI가 이유를 {#adaptive-recommendation}

회고에서 저장한 완료율·체감 난이도가 다음 계획의 하루 분량 추천으로 이어집니다. 회고 데이터가 적은 초기에 LLM에 분량 결정을 맡기면 같은 기록에도 추천이 달라지고 외부 API 장애가 곧 기능 장애가 되므로, **숫자는 재현 가능한 서버 규칙이 계산하고 AI는 이유 설명만** 맡겼습니다.

![AI 분량 추천 피드백 루프 — 회고 기록을 서버 규칙이 계산하고 AI는 이유를 설명한다](/assets/images/portfolio/delaynomore-recommendation.svg){:.portfolio-diagram}

![오늘 마무리 화면 — 완료율과 체감 난이도, 이유를 기록한다](/assets/images/portfolio/delaynomore-reflect.png){:.portfolio-detail-shot}

AI가 만든 새 계획은 미리보기에만 존재하고, `confirm` 승인이 있어야 별도 계획으로 저장되며 원본 계획과 회고는 변경되지 않습니다.

| 검증 대상 | 확인한 내용 |
| :--- | :--- |
| **결정 규칙** | 완료율 경계, 관찰 기간 부족, 1~5개·±1 제한 등 분기를 단위 테스트로 검증 |
| **승인 경계** | 초안 단계에서는 계획 수가 늘지 않고, 승인 후에만 새 계획 생성·원본 불변 |
| **장애 폴백** | AI 실패 시에도 선택한 개수의 서버 템플릿 초안 생성 |
| **추적성** | 추천 조회·채택·변경, 추천 기반 생성을 감사 이력으로 기록 |

다음 단계는 같은 AI 호출 안에서 숫자·이유·신뢰도를 함께 받되, 서버가 범위를 재검증하고 실패 시 현재 규칙으로 즉시 폴백하는 고도화입니다.

![다음 계획 추천 고도화 — 규칙 기반 기준선 위에 AI 맞춤 판단과 서버 검증을 추가한다](/assets/images/portfolio/delaynomore-recommendation-evolution.svg){:.portfolio-diagram}

---

## 데모 배포 — 1GB 무료 VM 제약 안에서 {#deployment}

운영 경험이 아니라 **데모 배포 환경 구축과 실행 확인**입니다. 프론트엔드·백엔드·AI 프록시를 하나의 Docker 컨테이너로 묶어 배포 단순성과 장애 지점 축소를 우선했고, OpenRouter 키는 서버에만 보관했습니다.

![시스템 아키텍처 — 단일 컨테이너 안의 Controller·Service·Repository](/assets/images/portfolio/delaynomore-architecture.svg){:.portfolio-diagram}

![배포 파이프라인 — VM은 빌드하지 않고 이미지를 Pull한다](/assets/images/portfolio/delaynomore-deploy.svg){:.portfolio-diagram}

GitHub Actions가 이미지를 빌드해 GHCR에 올리고, Oracle Cloud 무료 VM은 이미지를 Pull만 해서 실행합니다. 저사양 VM에서 빌드가 자원을 점유하는 문제를 피하고 JVM 힙 상한으로 OOM을 방어했으며, 배포 후 데모 접속과 핵심 시나리오 실행을 확인했습니다.

---

## 검증 범위와 한계 {#verification}

| 검증 시나리오 | 확인 결과 |
| :--- | :--- |
| 계획 생성 → 확정 → 실행 → 회고 | 화면과 자동 테스트에서 전체 흐름 확인 |
| 잠금 상태에서 수정 요청 | 서버가 `409 PLAN_LOCKED`로 거부, 저장소·감사 이력 불변 |
| 허용되지 않은 상태 전이·동시 완료 요청 | `409 INVALID_STATUS_TRANSITION`, 행 잠금으로 첫 요청만 성공 |
| AI 스트리밍 응답 | 순차 표시, 스트림 실패 시 비스트리밍→mock 폴백 |
| 재시작 후 상태 복원 | Testcontainers의 PostgreSQL 17에서 재조회 검증 |
| OCI Docker 데모 배포 | 배포 후 데모 접속·핵심 시나리오 실행 확인 |

### 한계와 다음 검증 과제

- 실제 사용자 대상 효과는 측정하지 못했고, 유지율·이탈률 같은 KPI가 없습니다.
- 데모 환경이므로 운영 트래픽과 장애 대응은 검증하지 못했습니다.
- 게스트 ID가 데이터 접근 키라서 다른 브라우저에서 기존 데이터에 다시 연결할 수 없습니다.
- 생성 한도 가드가 `synchronized` 기반이라 다중 서버에서는 한도가 최대 1건 초과될 수 있습니다.
- 실제 서비스로 전환한다면 행동 이벤트와 완료율 수집부터 시작하고, 로그인과 분산 동시성을 다음 마일스톤으로 진행할 예정입니다.

## Source

- [DelayNoMore Release](https://github.com/hello-pebble/DelayNoMore_Release) — 소스 코드·API·배포 스크립트
- [CHANGELOG](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/CHANGELOG.md) — 13개 릴리스의 변경 이력과 설계 결정
- [데모](http://delaynomoreapp.duckdns.org/) · [원본 프로토타입](https://github.com/hello-pebble/DelayNoMore)
