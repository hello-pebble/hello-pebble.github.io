---
layout: default
title: "DelayNoMore - AI 계획 실행 서비스"
permalink: /portfolio/delaynomore/
category: portfolio
tags: [SpringBoot, Java, React, PostgreSQL, OpenRouter, Portfolio]
---

<span class="project-context">개인 프로젝트 · 2026.04 — 2026.06 · 기획부터 데모 배포까지 단독</span>

# DelayNoMore — AI 계획 실행 서비스

- **가설** "계획을 세우는 것보다 계획을 계속 고치는 과정이 실행을 늦춘다"에서 출발했습니다.
- **서비스** AI와 대화해 하루 단위 계획을 만들고, 확정 후에는 완료 체크와 다음 날 이월만 허용합니다.
- **만든 방식** v0.1.0부터 v0.22.0까지 완성된 기능 목록을 향해 달리는 대신, 버전마다 직전 버전이 드러낸 문제 하나를 정해 풀었습니다.
- **대표 사례** 프론트 화면에만 있어 우회 가능하던 잠금 규칙을 서버 강제(409)로 옮기고, 20~30초의 AI 응답 대기를 SSE 스트리밍과 patch 교환으로 바꾸고, 육안으로 판단하던 에이전트 품질을 반복 측정 가능한 평가 하네스로 교체했습니다.
- **고정한 것** 잠금 규칙의 서버 강제·스트리밍 폴백·PostgreSQL 재시작 복원을 자동 테스트로 고정해, 규칙의 위치를 옮기는 동안 기존 동작이 깨지지 않게 했습니다.

**[▶ 실행해 보기](https://delaynomoreapp.duckdns.org/)**

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
    <small>반복 측정이 바꾼 결론</small>
  </a>
  <a href="#llm-troubleshoot">
    <span>05. 느린 원인</span>
    <small>모델이 아니라 추론 모드</small>
  </a>
  <a href="#challenge-concurrency">
    <span>06. 정원 5명에 9명</span>
    <small>판정을 쓰기 안으로</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>배포·확인한 범위</small>
  </a>
</nav>

## 만든 방식 — 버전마다 문제 하나 {#process}

- **출발** v0.1.0은 "대화로 투두리스트를 만든다"는 핵심 흐름 하나를 실제 클라우드에 배포하는 것이 전부였습니다.
- **이후 원칙** 모든 버전이 직전 버전이 드러낸 문제 하나를 골라 해결했습니다.
- **연쇄 사례** 계획을 여러 개 보관하게 되자 "오늘 뭘 하지?"가 흩어져 '오늘 할 일' 화면이 나왔고(v0.5.0), 프론트가 들고 있던 규칙이 우회 가능하다는 문제가 서버 이관 연작(v0.8~v0.9)으로 이어졌습니다.

<div class="shot-labels"><span>계획 생성</span><span>오늘 할 일</span><span>실행 추적</span></div>

![DelayNoMore 실제 서비스 화면 — 왼쪽 AI 코치와의 대화로 계획을 만들고, 가운데에 오늘 할 일이 모이며, 오른쪽 체크리스트에서 실행을 추적한다](/assets/images/portfolio/delaynomore-app.png){:.portfolio-hero-shot}

- **작업 리듬** 트렁크 기반으로 `main`을 항상 배포 가능한 상태로 두고, 기능마다 짧은 브랜치 → PR → 머지 → 버전 태그를 반복했습니다.
- **릴리스 기록** [CHANGELOG](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/CHANGELOG.md)에 "무엇을, 왜"를 남기고 QA 체크리스트 수행 결과를 `QA_RESULT_vX.Y.Z.md`로 기록했으며, 버전 사이의 인과는 [EVOLUTION.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/EVOLUTION.md)에 한 장의 그래프로 정리했습니다.
- **AI 협업** 릴리스 규칙과 작업 관례를 저장소의 `CLAUDE.md`에 고정해 매 세션이 같은 기준으로 움직이게 했고, 저는 버전마다 풀 문제를 정의하고 결과를 리뷰하고 QA 실측으로 검증하는 역할을 맡았습니다. AI가 만든 코드도 같은 QA 체크리스트를 통과해야 릴리스에 들어갑니다. 전체 원칙은 [AI를 어떻게 쓰는가](/ai/)에 정리했습니다.

테스트도 같은 리듬의 일부로, JUnit 5 기반 테스트를 세 층으로 나눠 둡니다.

| 층 | 대상 | 실행 조건 |
| :--- | :--- | :--- |
| **순수 단위 테스트** | 도메인 규칙·계산 로직 | 매 빌드에서 실행합니다. |
| **standalone MockMvc** | 전체 컨텍스트 없이 컨트롤러만 | 매 빌드에서 실행합니다. |
| **통합 테스트 (`*IT`)** | Testcontainers PostgreSQL | Docker가 없으면 스킵합니다. |
| **평가 (`@Tag("eval")`)** | 실제 모델 호출 | 일반 빌드에서 제외하고 `./gradlew evalAgent`로만 실행합니다. |

- **CI** 매 push마다 GitHub Actions가 프론트 lint·빌드와 백엔드 테스트를 돌립니다.

---

## 01. 규칙의 소유권을 서버로 — 잠금 모델의 세 단계 {#state-integrity}

"확정된 계획은 수정할 수 없다"는 이 서비스의 핵심 규칙입니다. 이 규칙이 **어디에 사는지**가 버전을 거치며 세 번 바뀌었습니다.

| 단계 | 버전 | 규칙의 위치와 한계 |
| :--- | :--- | :--- |
| **1. 프론트 차단** | v0.4.1 | 화면에서 수정 버튼을 막았습니다. 동작은 하지만 curl로 API를 직접 호출하면 그대로 뚫립니다. |
| **2. 서버 가드** | v0.8.0 | 잠긴 계획의 수정 요청을 서버가 `409 PLAN_LOCKED`로 거부합니다. 프론트는 안내만 하고 강제는 서버가 맡습니다. |
| **3. 전이표·도구 권한** | v0.14~v0.15 | 흩어진 if 체인을 `PlanStatus` 선언적 전이표로 모으고, 상태 변경을 명령 엔드포인트로만 허용했습니다. |

- **인정한 것** 화면의 규칙은 UX일 뿐 강제가 아니라는 점을 1단계에서 인정해야 했습니다.
- **역할 분담의 확장** 2단계를 시작으로 진행률 계산, 이월, 날짜 산출·검증, LLM patch 병합까지 프론트에 남아 있던 계산과 규칙을 v0.9.x에 걸쳐 버전마다 서버로 옮겼습니다.
- **설계의 결론** AI 코치를 도구 호출 에이전트로 전환할 때 전이표가 그대로 **도구 노출 권한**이 됐습니다. 잠긴 계획의 수정 차단이 "프롬프트로 타이르기"가 아니라 애초에 수정 도구를 주지 않는 구조적 불가능으로 바뀌었습니다.

![계획 상태 전이도 — DRAFT에서 CONFIRMED로 잠기고, 잠금 이후의 수정과 전이표에 없는 전이는 409로 거부된다](/assets/images/portfolio/delaynomore-state-machine.svg){:.portfolio-diagram}

| 상태 | 허용 동작 |
| :--- | :--- |
| **DRAFT** | 계획 구조·내용 수정, 확정, 중단이 가능합니다. |
| **CONFIRMED** | 완료 체크, 서버가 통제하는 오늘→내일 이월, 완료, 중단이 가능합니다. |
| **COMPLETED / CANCELLED** | 모든 변경을 차단하고 기록 조회만 유지합니다. |

- **원자성** 전이는 트랜잭션과 `SELECT … FOR UPDATE` 행 잠금 안에서 실행됩니다. 두 세션이 동시에 완료를 요청하면 첫 요청만 성공하고 뒤 요청은 409를 받습니다.
- **저장소 이전** Repository 인터페이스를 유지한 채 인메모리에서 PostgreSQL로 옮겼습니다(v0.12.0 · [BACKEND_MIGRATION.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/BACKEND_MIGRATION.md)).
- **고정한 검증** 4×4 전이 매트릭스는 전수 검증 테스트로, 소유자당 생성 한도 같은 동시 요청 경쟁은 20개 스레드가 `CountDownLatch` 이중 배리어로 같은 순간에 진입하는 TOCTOU 테스트로, 재시작 복원은 Testcontainers 통합 테스트로 각각 고정했습니다.

![Immutable Lock — 확정 계획을 서버와 트랜잭션에서 잠금](/assets/images/portfolio/delaynomore-lock.svg){:.portfolio-diagram}

---

## 02. 20~30초의 대기를 진행 경험으로 {#ai-streaming}

| 구분 | 내용 |
| :--- | :--- |
| **문제** | 테스트 환경에서 고품질 계획 생성에 20~30초가 걸렸습니다. |
| **선택하지 않은 것** | 모델 등급을 낮추는 방식은 품질을 깎으므로 배제했습니다. |
| **조치 1** | 응답을 SSE 기반 스트리밍으로 바꿔 생성 과정을 그대로 보여줍니다. |
| **조치 2** | 계획 전체를 매번 재전송하던 방식을 변경분(patch)만 주고받는 방식으로 바꿔 토큰을 줄였습니다. |

- **구현** Spring MVC의 `SseEmitter` 기반 비동기 처리입니다. 컨트롤러는 emitter를 즉시 반환하고, 전용 SSE 스레드 풀이 업스트림(OpenRouter)의 SSE 스트림을 파싱해 다운스트림으로 릴레이합니다.
- **테스트를 위한 분리** 에이전트 루프와 SSE 전송 사이에 `AgentEventSink` 함수형 인터페이스를 이음매로 뒀습니다. 루프는 "무슨 일이 일어났는지"만 알리고, 그걸 SSE로 보낼지 테스트용 리스트에 모을지는 호출부가 정합니다.
- **프론트** `EventSource`가 POST를 지원하지 않아 `fetch`와 `ReadableStream`으로 스트림을 직접 파싱합니다.

![AI 응답 전달 방식 전후 비교 — 빈 화면 대기에서 SSE 순차 표시와 patch 교환으로](/assets/images/portfolio/delaynomore-streaming-compare.svg){:.portfolio-diagram}

- **실측** patch 전환 후 요청당 입력 364–1,645 토큰, 비용 $0.0002–$0.0022 범위를 확인했습니다.
- **계측의 내재화** 처음에는 OpenRouter 대시보드를 눈으로 옮겨 적었지만, v0.15.2부터는 앱이 모든 LLM 호출의 사용량을 경로별로 직접 로깅합니다. "쓴 만큼을 세지 않으면 없는 셈이 된다"는 판단이었습니다.
- **폴백** 스트림이 실패하면 비스트리밍으로, 다시 실패하면 mock으로 넘어가는 경로를 실제로 끊어보며 확인했습니다.

---

## 03. 다음 계획 추천 — 숫자는 규칙이, 이유는 AI가 {#adaptive-recommendation}

- **연결** 회고에서 저장한 완료율과 체감 난이도가 다음 계획의 하루 분량 추천으로 이어집니다.
- **배제한 선택지** 분량 결정을 LLM에 맡기는 방식은, 같은 기록에 추천이 달라지면 신뢰를 줄 수 없고 외부 API 장애가 곧 기능 장애가 되기 때문에 배제했습니다.
- **역할 분담** 숫자는 재현 가능한 서버 규칙이 계산하고, AI는 이유 설명과 내용 생성만 맡습니다. AI가 실패해도 서버 템플릿으로 초안은 나옵니다.

![AI 분량 추천 피드백 루프 — 회고 기록을 서버 규칙이 계산하고 AI는 이유를 설명한다](/assets/images/portfolio/delaynomore-recommendation.svg){:.portfolio-diagram}

- **출시 직후 드러난 문제** 클릭한 계획 한 건의 기록만 쓰니 작은 표본에 추천이 튀었고, v0.13.1에서 같은 목표의 최근 계획 3건을 합산하는 방식으로 안정화했습니다.
- **안전장치** 새 계획은 미리보기에만 존재하다가 `confirm` 승인이 있어야 저장되며, 원본 계획과 회고는 변경되지 않습니다.
- **고정한 검증** 완료율 경계와 1~5개·±1 제한 같은 결정 분기는 단위 테스트로, 승인 경계와 폴백은 통합 테스트로 고정했습니다.

![오늘 마무리 화면 — 완료율과 체감 난이도, 이유를 기록한다](/assets/images/portfolio/delaynomore-reflect.png){:.portfolio-detail-shot}

---

## 04. 육안을 하네스로 — 에이전트 평가 {#eval}

- **새로 생긴 문제** AI 코치를 도구 호출 에이전트로 전환하자(v0.15.0), 프롬프트나 모델을 바꿨을 때 좋아졌는지 나빠졌는지 판단할 수단이 없었습니다.
- **판단 근거의 빈약함** v0.15.1의 버그도 "실기동해 보니 드러났다"가 전부였습니다.
- **조치** 기능 추가를 멈추고, 실제 모델로 상태별 도구 선택 정확도를 재는 평가 하네스를 먼저 만들었습니다(v0.16.0). 케이스 데이터셋(JSON), 순수 함수 채점기, 정확도와 토큰 비용을 한 표에 담는 리포트, `./gradlew evalAgent` 한 줄 실행으로 구성했습니다.

하네스를 실제 모델로 반복해 돌리는 동안 결론이 세 번 바뀌었습니다.

| 회차 | 처음 내린 결론 | 반복 실행이 바꾼 결론 |
| :--- | :--- | :--- |
| **1** | 특정 케이스가 실패한다고 봤습니다. | 실패가 케이스를 옮겨 다녔습니다. 한 번의 실행은 아무것도 증명하지 않았습니다. |
| **2** | 기저 실패율을 예상 수준으로 봤습니다. | 반복 횟수를 올리자 예상의 절반 수준으로 수렴했습니다. |
| **3** | 권한 모델이 구조로 막고 있다고 봤습니다. | 모델이 금지된 도구 대신 허용된 인접 도구로 우회하고 있었습니다. |

- **가장 중요한 발견** 반복 횟수를 충분히 올린 뒤에야 드러났습니다. 고정된 계획에 "마지막 날에 항목을 추가해줘"라고 하자, 수정 도구가 없는 모델이 **이월 도구로 계획을 실제로 바꿨습니다.** 이월은 그 상태에서 정상 노출되는 도구라 권한 모델이 뚫린 것이 아니고, 구조로는 막을 수 없는 층이라 측정 없이는 발견할 수 없었습니다.

{% include diagrams/delaynomore-avoidtools-decision.svg %}

- **후속 조치** 프롬프트 규칙과 `avoidTools` 채점 범주를 신설했고, 반복 실행을 감당하도록 축 선택 실행(`-Deval.only`)과 병렬화(`-Deval.threads`)로 하네스 자체도 개선해 80분을 20분으로 줄였습니다.
- **결과** 이 계기판 위에서 v0.17.0의 에이전트 프로필 전환(상태에 따라 시스템 프롬프트와 도구 집합을 함께 교체)을 올렸습니다. 마지막 검증 실행에서 남은 실패가 무엇인지 하나씩 확인한 뒤 배포했습니다.

---

## 05. 느린 원인은 모델이 아니라 추론 모드였습니다 {#llm-troubleshoot}

v0.1.0 라인을 배포하고 나니 계획 생성이 쓸 수 없을 만큼 느렸습니다. 모델을 바꾸기 전에 왜 느린지부터 봤습니다. OpenRouter의 generation 통계 한 줄이 답이었습니다.

| 지표 | 값 | 읽은 것 |
| :--- | :--- | :--- |
| `native_tokens_reasoning` | 4,017 | 답을 내기 **전에** 4천 토큰을 생각하는 데 씀 |
| `generation_time` | 95,251ms | 요청당 약 95초 |
| `finish_reason` | `stop` | 정상 종료 — 실패가 아니라 설계대로 느린 것 |

기본 모델이 추론 전용이었습니다. 게다가 사고 텍스트가 `content`에 섞여 JSON 파싱까지 방해하고 있었습니다. 조치는 요청에 `reasoning: { enabled: false }` 한 줄이었고, 응답은 실사용 가능한 수준으로 돌아왔습니다.

**"똑똑한 모델 = 좋은 선택"이 아니었습니다.** 정형 JSON을 빠르게 뽑는 작업에서는 추론이 지연과 비정형 출력만 만드는 독이 됩니다. 여기서 남은 20~30초를 경험으로 바꾼 것이 [02의 SSE 스트리밍](#ai-streaming)입니다.

### 화면이 하얗게 죽던 것은 출력이 아니라 계약 문제였습니다

같은 라운드에서 화이트스크린도 잡았습니다. 원인은 모델이 틀린 답을 준 게 아니라 **형태를 합의한 적이 없다는 것**이었습니다.

- **기대한 형태** `{ "tasks": { "2026-07-13": [...] } }` — 날짜를 키로 하는 맵
- **실제 받은 형태** `{ "plan": [ { "date": ..., "tasks": [...] } ] }` — 배열

프론트가 날짜 대신 `"plan"`을 키로 잡아 "Day 1 · plan"만 뜨거나, 파싱에 실패하면 `Object.entries(undefined)`로 앱 전체가 죽었습니다. 조치는 세 겹입니다. 백엔드 `sanitizeJson`이 코드펜스와 설명 텍스트를 걷어 중괄호 균형으로 최상위 객체만 추출하고, `coerceToDateMap`이 래퍼·배열·날짜맵을 모두 날짜맵으로 흡수하고, 렌더링이 `Array.isArray` 확인 후 그립니다. 실제로 받았던 응답 형태 4가지로 변환을 단위 검증했습니다.

- **여기서 얻은 규칙** 이번엔 `generation_time`과 `reasoning_tokens` 한 줄로 원인이 즉시 잡혔지만, 그건 운이었습니다. 당시 앱에는 지연도 토큰도 남기는 로그가 없었습니다. v0.15.2에서 모든 LLM 호출의 사용량을 경로별로 직접 로깅하게 만든 것이 이 회고의 결론입니다.
- **기록** 전문은 [DEPLOY_RETROSPECTIVE.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/archive/DEPLOY_RETROSPECTIVE.md)에 있습니다.

---

## 06. 정원 5명짜리 챌린지에 9명이 들어갔습니다 {#challenge-concurrency}

Goal Challenge(v0.21.0)에서 정원 5명·현재 4명인 챌린지에 다섯 명이 거의 동시에 참가를 요청하면 어떻게 되는가. 가장 자연스럽게 떠오르는 코드는 "세어 보고, 자리가 있으면 늘린다"입니다.

```java
int count = jdbc.queryForObject("SELECT participant_count FROM challenges WHERE id = ?", ...);
if (count < capacity) {                 // ← 판정
    jdbc.update("UPDATE challenges SET participant_count = participant_count + 1 WHERE id = ?", ...);
}
```

읽기와 쓰기가 두 문장으로 갈라져 있어, 판정의 근거였던 `count`는 UPDATE 시점에 이미 낡은 값입니다.

| 시각 | A | B | C | D | E | DB `participant_count` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| t1 | SELECT → 4 | SELECT → 4 | SELECT → 4 | SELECT → 4 | SELECT → 4 | 4 |
| t2 | `4 < 5` ✔ | `4 < 5` ✔ | `4 < 5` ✔ | `4 < 5` ✔ | `4 < 5` ✔ | 4 |
| t3 | UPDATE +1 | UPDATE +1 | UPDATE +1 | UPDATE +1 | UPDATE +1 | **9** |

**행 락은 이 문제를 못 막습니다.** 각자의 `+1`은 행 락으로 직렬화되므로 증가는 하나도 잃지 않습니다. 락이 보장하는 건 증가의 보존이지 판정의 정확성이 아닙니다.

### 해법은 판정을 쓰기 안으로 넣는 것이었습니다

읽기와 쓰기 사이에 틈이 있는 게 문제라면 틈을 없애면 됩니다.

```sql
UPDATE challenges
   SET participant_count = participant_count + 1
 WHERE id = :id AND participant_count < capacity
```

갱신된 행 수가 곧 결과입니다. `1`이면 자리를 얻은 것이고, `0`이면 그 사이 정원이 차서 `409 CHALLENGE_FULL`입니다. PostgreSQL 기본 격리 수준(READ COMMITTED)에서 두 번째 트랜잭션은 앞선 트랜잭션의 커밋을 기다린 뒤 **갱신된 최신 행으로 WHERE 조건을 다시 평가**(EvalPlanQual 재검사)하므로, 판정과 증가 사이에 다른 트랜잭션이 낄 물리적 틈이 없습니다.

그래서 `ChallengeService.join`에는 `if (full)` 같은 검사가 **없습니다.** 서비스가 미리 세어 보고 던지는 순간 위의 문제로 되돌아가기 때문에, 없는 것이 실수가 아니라 규칙입니다. 중복 참가는 복합 PK가, 잔액 부족은 `WHERE balance >= :fee`가 판정합니다. 판정 주체는 언제나 쓰기 그 자체입니다.

### 자리만 지켜서는 정합성이 아닙니다

정원을 지켜도 자리를 못 얻은 네 명의 포인트가 사라지면 깨진 것입니다. 참가 1회는 네 가지가 함께 성립하거나 함께 무효여야 하고, `@Transactional` 하나로 묶었습니다.

| 순서 | 판정하는 SQL 조각 | 0행일 때 |
| :--- | :--- | :--- |
| 1 | `INSERT ... ON CONFLICT DO NOTHING` | `409 CHALLENGE_ALREADY_JOINED` |
| 2 | `UPDATE point_wallets ... WHERE balance >= :fee` | `400 POINTS_INSUFFICIENT` |
| 3 | `UPDATE challenges ... WHERE participant_count < capacity` | `409 CHALLENGE_FULL` |

3번에서 예외가 나면 1번의 참가자 등록과 2번의 포인트 차감이 함께 롤백됩니다. 모든 스레드가 자기 행(참가자·지갑) → 경합 행(챌린지) 순으로 동일하게 진행하므로 순환 대기도 생기지 않습니다.

### 고려했지만 고르지 않은 것

| 방법 | 버린 이유 |
| :--- | :--- |
| `synchronized` 애플리케이션 락 | 서버를 2대로 늘리는 순간 무력화됩니다. 이 저장소의 `PlanService.create`가 그 선례이고, 주석이 스스로 한계를 적어 두고 있습니다. |
| `SELECT ... FOR UPDATE` 후 자바에서 검사 | 정확하지만 왕복이 2회이고 락을 더 오래 잡습니다. 카운터 하나의 비교-후-증가에는 과합니다. |
| 낙관적 락(`@Version`) | 충돌 시 재시도 루프가 필요한데, 정원 경쟁은 **충돌이 정상이고 흔한** 상황이라 낙관적 가정 자체가 맞지 않습니다. |

`CHECK (participant_count <= capacity)` 제약도 일부러 넣지 않았습니다. 제약을 걸면 틀린 구현이 정원을 넘길 때 오버부킹 대신 제약 위반 예외로 끝나서, **"틀린 구현은 실제로 정원을 넘는다"는 증거가 사라지기 때문입니다.**

### 틀린 구현을 테스트로 남겼습니다

주장 대신 대조군을 뒀습니다. `ChallengeJoinConcurrencyIT.naive_검사후쓰기는_동시요청에서_정원을_초과한다`가 Testcontainers의 실제 PostgreSQL 17에서 검사-후-쓰기 코드를 돌리고 `participant_count > capacity`를 assert합니다. 짝이 되는 `safe_조건부UPDATE는_동시요청에서도_정확히_1명만_받는다`가 성공 1건·나머지 409·탈락자 잔액 원복을 확인합니다.

- **naive 코드는 그 테스트 파일 안에만 있습니다.** 프로덕션에 시연용 분기를 남기지 않았습니다.
- **기록** 전문은 [CONCURRENCY.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/CONCURRENCY.md)에 있습니다.

---

## 검증 범위와 한계 {#verification}

- **배포의 성격** 운영이 아니라 데모 배포 환경 구축과 실행 확인입니다.
- **구성** 프론트·백엔드·AI 프록시를 단일 Docker 컨테이너로 묶고, GitHub Actions가 빌드해 GHCR에 올린 이미지를 Oracle Cloud 무료 VM(1GB)이 Pull만 해서 실행합니다.
- **이 구조를 택한 이유** 저사양 VM에서 빌드가 자원을 점유하지 않게 하기 위해서이며, JVM 힙 상한으로 OOM을 방어했습니다.
- **비밀 관리** OpenRouter 키는 서버에만 둡니다.

![배포 파이프라인 — VM은 빌드하지 않고 이미지를 Pull한다](/assets/images/portfolio/delaynomore-deploy.svg){:.portfolio-diagram}

| 검증 시나리오 | 확인 결과 |
| :--- | :--- |
| 계획 생성 → 확정 → 실행 → 회고 | 화면과 자동 테스트에서 전체 흐름을 확인했습니다. |
| 잠금 상태에서 수정 요청 | 서버가 `409 PLAN_LOCKED`로 거부하고 저장소·감사 이력이 유지됐습니다. |
| 허용되지 않은 전이·동시 완료 요청 | `409 INVALID_STATUS_TRANSITION`이 나고, 행 잠금으로 첫 요청만 성공했습니다. |
| AI 스트리밍 응답 | 순차 표시와 스트림 실패 시 비스트리밍→mock 폴백을 확인했습니다. |
| 재시작 후 상태 복원 | Testcontainers의 PostgreSQL 17에서 재조회로 검증했습니다. |
| 챌린지 정원 경쟁 | 실제 PostgreSQL에서 검사-후-쓰기는 정원을 넘고, 조건부 UPDATE는 정확히 1명만 통과하며 탈락자 잔액이 원복되는 것을 확인했습니다. |
| 에이전트 도구 선택 | 프롬프트를 바꿀 때마다 평가 하네스를 반복 실행해 기저 실패율과 비교했고, 남은 실패의 원인을 확인한 뒤 배포했습니다. |

### 한계와 다음 검증 과제

- 실제 사용자 대상 효과는 측정하지 못했고, 유지율·이탈률 같은 KPI가 없습니다.
- 데모 환경이므로 운영 트래픽과 장애 대응은 검증하지 못했습니다.
- 게스트 ID가 데이터 접근 키라서 다른 브라우저에서 기존 데이터에 다시 연결할 수 없습니다.
- 생성 한도 가드가 `synchronized` 기반이라 다중 서버에서는 한도가 최대 1건 초과될 수 있습니다. [06](#challenge-concurrency)에서 챌린지 참가는 조건부 UPDATE로 옮겼지만, 계획 생성 한도는 아직 이 방식입니다.
- 다음 단계로 전문 에이전트에 도메인 지식(검색/RAG)을 연결하는 것과 로그인·분산 동시성을 두었습니다.

## Source

- [DelayNoMore Release](https://github.com/hello-pebble/DelayNoMore_Release) — 소스 코드·API·배포 스크립트
- [EVOLUTION.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/EVOLUTION.md) — v0.1.0부터 v0.17.0까지 버전별 의도와 인과
- [CHANGELOG](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/CHANGELOG.md) — 릴리스별 변경 이력과 설계 결정
- [CONCURRENCY.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/CONCURRENCY.md) — 정원 경쟁에서 데이터 정합성을 지키는 방법과 고르지 않은 대안들
- [DEPLOY_RETROSPECTIVE.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/archive/DEPLOY_RETROSPECTIVE.md) — 95초 지연과 화이트스크린의 진단 기록
- [EVAL.md](https://github.com/hello-pebble/DelayNoMore_Release/blob/main/docs/EVAL.md) — "권한 모델이 말뿐인지 숫자로 확인하는 장치" · 반복 횟수와 검출 확률의 통계 논리
- [데모](https://delaynomoreapp.duckdns.org/)
