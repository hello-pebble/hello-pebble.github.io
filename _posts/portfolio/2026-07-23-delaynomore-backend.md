---
layout: default
title: "DelayNoMore — 백엔드 설계"
permalink: /portfolio/1/backend/
category: portfolio
tags: [SpringBoot, Java, API, Concurrency, Portfolio]
---

# 백엔드 설계 — 어떻게, 왜 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> **Spring Boot 4 · Java 21** 기반으로, 규칙과 검증의 **단일 진실 공급원(source of truth)을 서버**에 두는 것을 설계 원칙으로 삼았습니다. 프론트가 아무리 막아도 API는 `curl`로 직접 호출될 수 있으므로, **서버가 최종 방어선**이 되도록 계층과 계약을 설계했습니다.

![백엔드 계층 구조 — 요청 생애주기](/assets/images/portfolio/delaynomore-backend.svg)

---

## 1. 계층 분리 — 왜 나눴나

초기에는 하나의 컨트롤러(약 1,000줄)에 프롬프트 조립·응답 정제·HTTP 호출·검증이 뒤섞여 있었습니다. 이를 책임별로 분리해 **테스트 가능성과 변경 용이성**을 확보했습니다.

- **`domain/{ai, plan}` + `global/{response, error, config}`** 구조로 도메인과 공통 관심사를 분리.
- **Controller** — `@Valid` 검증과 서비스 호출만 담당(얇게 유지).
- **Service** — 도메인 규칙, 프롬프트 조립(`AiPromptBuilder`), 응답 정제(`AiResponseParser`), SSE 릴레이를 소유.
- **`OpenRouterClient`** — 외부 LLM HTTP 호출을 격리. Boot 4 규칙에 맞춰 `RestTemplate` → **`RestClient`** 전환.
- 서비스 계층 단위 테스트(`AiServiceTest`, `AiResponseParserTest`)로 회귀를 방어.

---

## 2. API 계약 — 예측 가능한 응답

- **버저닝 + 공통 래퍼**: 모든 응답을 `/api/v1` 아래 `{ success, data, error }`(`ApiResponse`)로 통일. 검증 실패는 `error.fieldErrors`(필드→사유), 오류 분기는 `error.code`(`ErrorCode`)로 판별해 클라이언트 분기를 단순화했습니다.
- **선언적 검증**: 수동 `Map<String,Object>` 파싱을 **Bean Validation**(`@NotBlank`/`@Min`/`@Max`)으로 교체.
- **예외 일원화**: `BusinessException(ErrorCode)` + `GlobalExceptionHandler` 한 곳으로 모아 오류 응답 형식을 고정.
- **문서화**: springdoc(Swagger)로 `@Tag`/`@Operation`을 붙여 `/swagger-ui.html` 제공.

---

## 3. 서버가 지키는 규칙 — 최종 방어선

프론트의 낙관적 UI와 무관하게, 규칙 위반은 서버에서 걸러집니다.

- **입력 형식 검증**: 커스텀 제약 `@ValidPlanTasks`(날짜 키 `YYYY-MM-DD`, 항목 `{id, content, completed?}` 형태)와 status `@Pattern(DRAFT|CONFIRMED)`. 위반 시 400 + `fieldErrors`.
- **AI 응답 정규화**: LLM이 출력 계약을 어겨도(최상위 배열, "Day N" 키, `{plan:[...]}` 래퍼) 서버가 시작일부터 실제 날짜 키로 매핑(`normalizeDraftPlan`). 프론트 폴백이 만들던 비정상 키를 원인 지점에서 제거.
- **계산의 일관성**: 진행률과 회고 완료 개수가 같은 도메인 메서드(`Plan.countTasksOn`/`countAllTasks`)를 공유해 화면마다 값이 어긋나지 않게 했습니다.

---

## 4. Immutable Lock — 원자적 잠금 가드

계획을 확정(CONFIRMED)하면 **완료 토글과 no-op만 허용**되고, 구조·내용 변경은 거부됩니다. 핵심은 이 검사가 **저장소의 원자 구간 안**에서 일어난다는 점입니다.

![Immutable Lock — 서버 원자 가드](/assets/images/portfolio/delaynomore-lock.svg)

- 가드를 `computeIfPresent` 람다(키 단위 원자 구간)에서 실행해 **조회·검사·교체 사이에 다른 쓰기가 끼어들 수 없습니다**(check-then-act 레이스 제거). 거부 시 저장소는 변경되지 않고 감사 이벤트도 발행되지 않습니다.
- 생성 시 소유자당 한도 검사는 `synchronized`로 두 검사와 저장을 원자로 묶어 TOCTOU를 막습니다. 단일 서버 데모 범위에서의 의도된 선택이며, 다중 서버 확장은 별도 마일스톤으로 명시해 두었습니다.

---

> **💬 면접에서 더 깊게 이야기할 수 있는 주제**
> - 왜 규칙의 단일 진실 공급원을 서버에 두었는가 — 프론트 검증만으로 부족한 이유
> - `computeIfPresent` 원자 구간과 DB의 `SELECT … FOR UPDATE`는 어떻게 같은 보장을 주는가
> - LLM처럼 계약을 어기는 외부 응답을 서버에서 어떻게 검증·정규화했는가
> - 단일 서버 `synchronized` 가드의 한계와 다중 서버 환경에서의 대안

---

<span class="section-note">관련: [시스템 아키텍처 & 배포]({{ '/portfolio/1/architecture/' | relative_url }}) · [데이터 & 동시성]({{ '/portfolio/1/persistence/' | relative_url }}) · [AI 통합 & 토큰 절약]({{ '/portfolio/1/ai-engineering/' | relative_url }})</span>
