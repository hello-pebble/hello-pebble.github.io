---
layout: default
title: "DelayNoMore — 규칙의 소유권을 서버로"
permalink: /portfolio/1/backend-ownership/
category: portfolio
tags: [SpringBoot, Concurrency, API, Portfolio]
---

# 규칙의 소유권을 서버로 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> 초기에는 잠금·진행률·이월 같은 규칙을 **프론트가 계산**하고 서버는 값을 그대로 믿는 저장소였습니다. curl로 API를 직접 부르면 규칙을 우회할 수 있었죠. v0.8~0.9에서 이 규칙들의 **소유권을 서버로 옮겨**, 프론트는 UX(빠른 피드백)만 맡고 강제는 서버가 담당하도록 역할을 재정의했습니다.

---

## 무엇을 옮겼나

![규칙의 소유권을 프론트에서 백엔드로](/assets/images/portfolio/delaynomore-ownership.svg)

| 규칙 | 이전(프론트) | 이후(서버) |
| :--- | :--- | :--- |
| 고정 계획 잠금 | 화면에서만 버튼 숨김 | `PUT`을 서버가 검사, 위반 시 **409 `PLAN_LOCKED`** |
| 진행률·완료율 | 브라우저 계산 | `Plan` 도메인 메서드가 계산해 응답에 포함 |
| 미완료 이월 | 프론트가 계산 후 PUT | `POST /plans/{id}/carry-over` 도메인 액션 |
| 날짜 산출·검증 | 브라우저 로컬 날짜 | 서버가 `startDate`/`duration` 산출·검증 |
| LLM patch 병합 | 프론트가 병합 | `ChatPatchMerger`가 서버에서 병합 |
| 회고·이력 선택지 | 하드코딩 | 서버 enum 메타 API (프론트는 폴백 사본) |

**프론트는 소스가 아니라 폴백**입니다 — 서버 응답값을 채택하되, 서버 미가용 시에만 하드코딩 기본값으로 화면을 지킵니다.

---

## Immutable Lock — 서버 원자 가드

![Immutable Lock 서버 원자 가드](/assets/images/portfolio/delaynomore-lock.svg)

계획을 확정(CONFIRMED)하면 완료 토글과 no-op PUT만 허용되고, 스칼라·구조 변경·롤백은 모두 거부됩니다. 핵심은 이 검사가 **저장소의 원자 구간 안**에서 일어난다는 점입니다.

- **check-then-act 레이스 제거**: 가드를 `computeIfPresent` 람다(키 단위 원자 구간) 안에서 실행해, 조회·검사·교체 사이에 다른 쓰기가 끼어들 수 없습니다. 거부 시 저장소는 변경되지 않고 감사 이벤트도 발행되지 않습니다.
- **판정 기준 공유**: "구조 변경" 여부를 변경 이력과 같은 기준으로 판단하도록 diff 유틸(`PlanTaskDiff`)을 추출해 `AuditEventService`와 `PlanService`가 함께 씁니다.
- **불필요한 AI 호출 차단**: 고정 계획에 대한 확실한 수정 요청은 AI를 부르기 전에 안내로 차단하고, 질문은 그대로 통과시킵니다(오프라인 mock과 동일한 키워드 휴리스틱).

---

## 변경 감사(Audit) 이력 — "누가 · 언제 · 무엇을"

모든 방문자가 공유하는 보관함에서 계획별 변경 이력을 답할 수 있도록 감사 이벤트를 남깁니다.

- **서버 diff 판별**: 프론트의 모든 변경이 `PUT /plans/{id}` 전체 교체 하나로 오므로, 서버가 이전 상태와 비교해 이벤트 종류(`PLAN_CREATED`·`PLAN_CONFIRMED`·`TASK_COMPLETED`·`PLAN_DELETED` 등 7종)를 복원합니다. 클라이언트가 보낸 의미를 믿지 않습니다.
- **세션 귀속**: 브라우저 단위 익명 ID를 변이 요청에만 `X-Session-Id`로 실어, 이력 화면이 "이 브라우저/다른 세션"을 구분합니다. 인증이 아니라 표식입니다.
- **삭제 후에도 조회**: 계획을 지워도 이력은 캐스케이드하지 않습니다("언제 삭제됐는가"에 답해야 하므로). 모르는 planId는 404가 아니라 빈 목록으로 응답합니다.

---

## 이렇게 얻은 것

- **우회 불가능한 규칙**: API를 직접 호출해도 잠금·형식·날짜 규칙을 서버가 최종 방어선으로 강제합니다.
- **명확한 역할 분담**: 프론트=UX(낙관적 UI·빠른 피드백·폴백), 서버=규칙과 연산의 소유자.
- **일관된 계산**: 진행률·회고 완료 개수 등이 같은 도메인 메서드를 공유해 화면마다 값이 어긋나지 않습니다.

---

<span class="section-note">관련: [시스템 아키텍처 & 배포]({{ '/portfolio/1/architecture/' | relative_url }}) · [데이터 영속화 & 동시성]({{ '/portfolio/1/persistence/' | relative_url }}) · [AI 통합]({{ '/portfolio/1/ai-engineering/' | relative_url }})</span>
