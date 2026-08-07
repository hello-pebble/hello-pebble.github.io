---
layout: default
title: "DelayNoMore - AI 계획 실행 서비스"
permalink: /portfolio/delaynomore/
category: portfolio
tags: [SpringBoot, Java, React, PostgreSQL, OpenRouter, Portfolio]
---

<span class="project-context">개인 프로젝트 · 2026.04 — 2026.06 · 기획부터 데모 배포까지 단독</span>

# DelayNoMore — AI 계획 실행 서비스

- "계획을 세우는 것보다 계획을 계속 고치는 과정이 실행을 늦춘다"는 가설에서 출발해, 확정 후에는 완료 체크와 이월만 허용하는 잠금 모델과 AI 코치를 만들었습니다. v0.1.0부터 v0.17.0까지 **버전마다 문제 하나를 정해 풀어온 과정** 자체가 이 페이지의 주제입니다.

**[▶ 실행해 보기](http://delaynomoreapp.duckdns.org/)**

<dl class="project-summary-grid">
  <div>
    <dt>무엇을</dt>
    <dd>AI와 대화해 하루 단위 계획을 만들고, 확정 후에는 완료 체크와 다음 날 이월만 허용하는 실행 중심 서비스</dd>
  </div>
  <div>
    <dt>어떻게</dt>
    <dd>버전마다 문제 하나 — 릴리스 단위 CHANGELOG·QA 실측 · 규칙의 소유권을 프론트에서 서버로 단계적 이관 · 육안 확인을 평가 하네스로 교체</dd>
  </div>
  <div>
    <dt>담당 범위</dt>
    <dd>서비스 기획 · 데이터 모델링 · API 설계 · 프론트/백엔드 구현 · 평가 하네스 · OCI Docker 데모 배포</dd>
  </div>
  <div>
    <dt>검증한 것</dt>
    <dd>잠금 규칙의 서버 강제(409) · SSE 스트리밍과 폴백 · PostgreSQL 재시작 복원 · 에이전트 도구 선택 정확도 실측 676회</dd>
  </div>
</dl>

<nav class="project-page-nav" aria-label="DelayNoMore 프로젝트 목차">
  <a href="#process">
    <span>만든 방식</span>
    <small>버전마다 문제 하나</small>
  </a>
  <a href="#state-integrity">
    <span>01. 규칙의 소유권</span>
    <small>프론트 차단에서 도구 권한까지</small>
  </a>
  <a href="#ai-streaming">
    <span>02. 20~30초의 대기</span>
    <small>SSE·patch·계측</small>
  </a>
  <a href="#adaptive-recommendation">
    <span>03. 추천의 역할 분담</span>
    <small>숫자는 규칙, 이유는 AI</small>
  </a>
  <a href="#eval">
    <span>04. 육안을 하네스로</span>
    <small>676회 실측이 바꾼 결론</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>배포·확인한 범위</small>
  </a>
</nav>

## 만든 방식 — 버전마다 문제 하나 {#process}

이 프로젝트는 완성된 기능 목록을 향해 달리지 않았습니다. v0.1.0은 "대화로 투두리스트를 만든다"는 핵심 흐름 하나를 실제 클라우드에 배포하는 것이 전부였고, 이후 모든 버전은 **직전 버전이 드러낸 문제 하나**를 골라 해결했습니다. 계획을 여러 개 보관하게 되자 "오늘 뭘 하지?"가 흩어지는 문제가 생겨 '오늘 할 일' 화면이 나왔고(v0.5.0), 프론트가 들고 있던 규칙이 우회 가능하다는 문제가 서버 이관 연작(v0.8~v0.9)으로 이어지는 식입니다.

<div class="shot-labels"><span>① 계획 생성</span><span>② 오늘 할 일</span><span>③ 실행 추적</span></div>

![DelayNoMore 실제 서비스 화면 — 왼쪽 AI 코치와의 대화로 계획을 만들고, 가운데에 오늘 할 일이 모이며, 오른쪽 체크리스트에서 실행을 추적한다](/assets/images/portfolio/delaynomore-app.png){:.portfolio-hero-shot}

작업 리듬은 트렁크 기반입니다. `main`은 항상 배포 가능한 상태로 두고, 기능마다 짧은 브랜치 → PR → 머지 → 버전 태그를 반복했습니다. 릴리스마다 [CHANGELOG](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/CHANGELOG.md)에 "무엇을, 왜"를 남기고, QA 체크리스트를 실제로 수행한 결과를 `QA_RESULT_vX.Y.Z.md`로 기록했습니다. 버전 사이의 인과는 [EVOLUTION.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/EVOLUTION.md)에 한 장의 그래프로 정리돼 있습니다.

구현의 상당 부분은 Claude Code와 협업했습니다. 릴리스 규칙과 작업 관례를 저장소의 `CLAUDE.md`에 고정해 매 세션이 같은 기준으로 움직이게 했고, 저는 버전마다 풀 문제를 정의하고, 결과를 리뷰하고, QA 실측으로 검증하는 역할을 맡았습니다. AI가 만든 코드도 같은 QA 체크리스트를 통과해야 릴리스에 들어갑니다. 전체 원칙은 [AI를 어떻게 쓰는가](/ai/)에 따로 정리했습니다.

---

## 01. 규칙의 소유권을 서버로 — 잠금 모델의 세 단계 {#state-integrity}

"확정된 계획은 수정할 수 없다"는 이 서비스의 핵심 규칙입니다. 이 규칙이 **어디에 사는지**가 버전을 거치며 세 번 바뀌었습니다.

**1단계 — 프론트 차단 (v0.4.1).** 처음에는 화면에서 수정 버튼을 막았습니다. 동작은 하지만, curl로 API를 직접 호출하면 그대로 뚫립니다. 화면의 규칙은 UX일 뿐 강제가 아니라는 것을 인정해야 했습니다.

**2단계 — 서버 가드 (v0.8.0).** 잠긴 계획에 대한 수정 요청을 서버가 `409 PLAN_LOCKED`로 거부하게 했습니다. 이때부터 프론트는 안내만 하고, 강제는 서버가 맡습니다. 이 역할 분담을 시작으로 진행률 계산, 이월, 날짜 산출·검증, LLM patch 병합까지 프론트에 남아 있던 계산과 규칙을 버전마다 서버로 옮겼습니다(v0.9.x).

**3단계 — 전이표, 그리고 도구 권한 (v0.14~v0.15).** 흩어진 if 체인으로 남아 있던 "이 상태에서 뭘 할 수 있나"를 `PlanStatus` 하나의 선언적 전이표로 모으고, 상태 변경을 `confirm·complete·cancel` 명령 엔드포인트로만 허용했습니다. AI 코치를 도구 호출 에이전트로 전환할 때 이 표가 그대로 **도구 노출 권한**이 됐습니다 — 잠긴 계획의 수정 차단이 "프롬프트로 타이르기"가 아니라 **애초에 수정 도구를 주지 않는 구조적 불가능**으로 바뀐 것이 이 설계의 결론입니다.

![계획 상태 전이도 — DRAFT에서 CONFIRMED로 잠기고, 잠금 이후의 수정과 전이표에 없는 전이는 409로 거부된다](/assets/images/portfolio/delaynomore-state-machine.svg){:.portfolio-diagram}

| 상태 | 허용 동작 |
| :--- | :--- |
| **DRAFT** | 계획 구조·내용 수정, 확정, 중단 |
| **CONFIRMED** | 완료 체크, 서버가 통제하는 오늘→내일 이월, 완료, 중단 |
| **COMPLETED / CANCELLED** | 모든 변경 차단 — 기록 조회만 유지 |

전이는 트랜잭션과 `SELECT … FOR UPDATE` 행 잠금 안에서 원자적으로 실행됩니다. 두 세션이 동시에 완료를 요청하면 첫 요청만 성공하고 뒤 요청은 409를 받습니다. 저장소는 Repository 인터페이스를 유지한 채 인메모리에서 PostgreSQL로 이전했고(v0.12.0), 4×4 전이 매트릭스와 재시작 복원을 Testcontainers 기반 테스트로 고정했습니다.

![Immutable Lock — 확정 계획을 서버와 트랜잭션에서 잠금](/assets/images/portfolio/delaynomore-lock.svg){:.portfolio-diagram}

---

## 02. 20~30초의 대기를 진행 경험으로 {#ai-streaming}

테스트 환경에서 고품질 계획 생성에 20~30초가 걸렸습니다. 모델을 낮추는 대신 응답을 SSE 스트리밍으로 바꿔 생성 과정을 그대로 보여주고, 계획 전체를 매번 재전송하던 방식을 **변경분(patch)만 주고받는 방식**으로 바꿔 토큰을 줄였습니다.

![AI 응답 전달 방식 전후 비교 — 빈 화면 대기에서 SSE 순차 표시와 patch 교환으로](/assets/images/portfolio/delaynomore-streaming-compare.svg){:.portfolio-diagram}

절감은 주장이 아니라 실측으로 남겼습니다. patch 전환 후 요청당 입력 364–1,645 토큰, 비용 $0.0002–$0.0022 범위였고, 처음에는 OpenRouter 대시보드를 눈으로 옮겨 적었지만 v0.15.2부터는 앱이 모든 LLM 호출의 사용량을 경로별로 직접 로깅합니다 — "쓴 만큼을 세지 않으면 없는 셈이 된다"는 판단이었습니다. 스트림이 실패하면 비스트리밍으로, 다시 실패하면 mock으로 넘어가는 폴백도 실제로 끊어보며 확인했습니다.

---

## 03. 다음 계획 추천 — 숫자는 규칙이, 이유는 AI가 {#adaptive-recommendation}

회고에서 저장한 완료율·체감 난이도가 다음 계획의 하루 분량 추천으로 이어집니다. 분량 결정을 LLM에 맡기는 선택지도 있었지만 배제했습니다. 같은 기록에 추천이 달라지면 신뢰를 줄 수 없고, 외부 API 장애가 곧 기능 장애가 되기 때문입니다. 그래서 **숫자는 재현 가능한 서버 규칙이 계산하고, AI는 이유 설명과 내용 생성만** 맡습니다. AI가 실패해도 서버 템플릿으로 초안은 나옵니다.

![AI 분량 추천 피드백 루프 — 회고 기록을 서버 규칙이 계산하고 AI는 이유를 설명한다](/assets/images/portfolio/delaynomore-recommendation.svg){:.portfolio-diagram}

출시 직후 드러난 문제도 있었습니다. 클릭한 계획 한 건의 기록만 쓰니 작은 표본에 추천이 튀었고, 같은 목표의 최근 계획 3건을 합산하는 방식으로 안정화했습니다(v0.13.1). 새 계획은 미리보기에만 존재하다가 `confirm` 승인이 있어야 저장되며, 원본 계획과 회고는 변경되지 않습니다 — 완료율 경계, 1~5개·±1 제한 같은 결정 분기는 단위 테스트로, 승인 경계와 폴백은 통합 테스트로 고정했습니다.

![오늘 마무리 화면 — 완료율과 체감 난이도, 이유를 기록한다](/assets/images/portfolio/delaynomore-reflect.png){:.portfolio-detail-shot}

---

## 04. 육안을 하네스로 — 에이전트 평가 {#eval}

AI 코치를 도구 호출 에이전트로 전환하자(v0.15.0) 새 종류의 문제가 생겼습니다. 프롬프트나 모델을 바꿨을 때 **좋아졌는지 나빠졌는지 판단할 수단이 없었습니다.** v0.15.1의 버그도 "실기동해 보니 드러났다"가 전부였습니다. 그래서 기능 추가를 멈추고, 실제 모델로 상태별 도구 선택 정확도를 재는 평가 하네스를 먼저 만들었습니다(v0.16.0) — 케이스 데이터셋(JSON), 순수 함수 채점기, 정확도와 토큰 비용을 한 표에 담는 리포트, `./gradlew evalAgent` 한 줄 실행.

하네스를 실제 모델로 **676회** 돌리는 동안 결론이 세 번 바뀌었습니다.

1. 처음에는 특정 케이스가 실패한다고 봤는데, 반복 실행하니 **실패가 케이스를 옮겨 다녔습니다.** 한 번의 실행은 아무것도 증명하지 않았습니다.
2. 반복 횟수를 올리자 기저 실패율이 예상의 절반 수준으로 수렴했습니다.
3. 가장 중요한 발견 — 모델이 금지된 도구 대신 **허용된 인접 도구로 우회**하고 있었습니다. 잠긴 계획의 수정이 막히자 이월 도구로 같은 효과를 내는 식입니다. 권한 모델이 구조로 막을 수 없는 층이라, 측정 없이는 발견할 수 없었습니다.

이 발견으로 프롬프트 규칙과 `avoidTools` 채점 범주를 신설했고, 반복 실행을 감당하도록 하네스 자체도 개선했습니다(축 선택 실행, 병렬화로 80분 → 20분). 이 계기판 위에서 v0.17.0의 에이전트 프로필 전환(상태에 따라 시스템 프롬프트와 도구 집합을 함께 교체)을 올렸고, 릴리스 전 스모크 57회 통과율 100%를 실측으로 확인한 뒤 배포했습니다.

---

## 검증 범위와 한계 {#verification}

배포는 운영이 아니라 **데모 배포 환경 구축과 실행 확인**입니다. 프론트·백엔드·AI 프록시를 단일 Docker 컨테이너로 묶고, GitHub Actions가 빌드해 GHCR에 올린 이미지를 Oracle Cloud 무료 VM(1GB)이 Pull만 해서 실행합니다. 저사양 VM에서 빌드가 자원을 점유하지 않게 한 선택이고, JVM 힙 상한으로 OOM을 방어했습니다. OpenRouter 키는 서버에만 있습니다.

![배포 파이프라인 — VM은 빌드하지 않고 이미지를 Pull한다](/assets/images/portfolio/delaynomore-deploy.svg){:.portfolio-diagram}

| 검증 시나리오 | 확인 결과 |
| :--- | :--- |
| 계획 생성 → 확정 → 실행 → 회고 | 화면과 자동 테스트에서 전체 흐름 확인 |
| 잠금 상태에서 수정 요청 | 서버가 `409 PLAN_LOCKED`로 거부, 저장소·감사 이력 불변 |
| 허용되지 않은 전이·동시 완료 요청 | `409 INVALID_STATUS_TRANSITION`, 행 잠금으로 첫 요청만 성공 |
| AI 스트리밍 응답 | 순차 표시, 스트림 실패 시 비스트리밍→mock 폴백 |
| 재시작 후 상태 복원 | Testcontainers의 PostgreSQL 17에서 재조회 검증 |
| 에이전트 도구 선택 | 평가 하네스 676회 실측 · 릴리스 스모크 57회 통과율 100% |

### 한계와 다음 검증 과제

- 실제 사용자 대상 효과는 측정하지 못했고, 유지율·이탈률 같은 KPI가 없습니다.
- 데모 환경이므로 운영 트래픽과 장애 대응은 검증하지 못했습니다.
- 게스트 ID가 데이터 접근 키라서 다른 브라우저에서 기존 데이터에 다시 연결할 수 없습니다.
- 생성 한도 가드가 `synchronized` 기반이라 다중 서버에서는 한도가 최대 1건 초과될 수 있습니다.
- 다음 단계는 전문 에이전트에 도메인 지식(검색/RAG)을 연결하는 것과, 로그인·분산 동시성입니다.

## Source

- [DelayNoMore Release](https://github.com/hello-pebble/DelayNoMore_Release) — 소스 코드·API·배포 스크립트
- [EVOLUTION.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/EVOLUTION.md) — v0.1.0부터 v0.17.0까지 버전별 의도와 인과
- [CHANGELOG](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/CHANGELOG.md) — 릴리스별 변경 이력과 설계 결정
- [데모](http://delaynomoreapp.duckdns.org/) · [원본 프로토타입](https://github.com/hello-pebble/DelayNoMore)
