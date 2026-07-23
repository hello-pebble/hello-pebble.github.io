---
layout: default
title: "DelayNoMore — AI 통합 & 토큰 절약"
permalink: /portfolio/1/ai-engineering/
category: portfolio
tags: [OpenRouter, SSE, Optimization, Portfolio]
---

# AI 통합 &amp; 토큰 절약 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> 대형 LLM을 쓰면서도 **비용과 체감 대기**를 잡아야 했습니다. 모델 품질은 유지한 채 **전송량(토큰)만 줄여** 요청당 비용을 구조적으로 낮추고, SSE 스트리밍으로 긴 대기를 조립 과정으로 바꿨습니다.

---

## 1. 토큰 절약 — 요청당 대부분 $0.001 미만

![AI 토큰 절약](/assets/images/portfolio/delaynomore-token.svg)

같은 대화 경험을 유지하면서 요청당 전송량을 여러 지점에서 줄였습니다.

- **patch 전송**: 계획을 통째로 재전송하던 것을 **변경된 날짜만 담는 patch**로 전환(수정=해당 날짜만, 연장=새 날짜만, 단축=`null`). 출력 토큰을 크게 절감했습니다.
- **compact 포맷**: 모델과 주고받는 계획에서 `id`·`completed` 보일러플레이트를 제거하고 "날짜 → 문자열 배열" 형태로 통일. 프론트가 `id`·상태를 복원합니다.
- **대화 이력 축소**: 이력 전송을 최근 **12턴 → 6턴**으로 축소.
- **추론 모드 OFF**: 추론 모델이 요청당 약 **95초·reasoning 4천 토큰**을 소모하던 것을 `reasoning:{enabled:false}`로 제거.
- **`max_tokens` 상한**: 폭주 생성 비용을 방어(추론이 꺼져 정상 응답은 잘리지 않음).
- **결과(실사용 증빙)**: OpenRouter 기록상 요청당 입력 **364–1,645 토큰**, 비용 **$0.0002–$0.0022**로 대부분 **$0.001 미만**입니다.

> 부수적으로 **한국어 출력 순도**도 백엔드에서 확정적으로 보장했습니다. 모델이 섞어 내던 한자/가나·군더더기 마크다운 기호를 **후처리로 제거**(한글·영문·숫자·기호는 보존)해, 프롬프트만으로는 새는 문제를 원인 지점에서 없앴습니다.

---

## 2. 실시간 스트리밍 — 대기를 "조립 과정"으로

![실시간 스트리밍(SSE)](/assets/images/portfolio/delaynomore-streaming.svg)

하루 단위 계획 설계에 20~30초 이상 걸려 유저가 먹통으로 오인·이탈하는 병목이 있었습니다.

- **SSE 토큰 스트리밍**: 응답이 도착하는 대로 단어 단위로 흘려보내, 유저가 계획 조립 과정을 실시간으로 관찰하게 만들어 체감 대기를 단축했습니다.
- **Day별 순차 생성**: 초안을 "하루 = 한 줄(NDJSON)"로 생성해, 한 줄이 완성될 때마다 `day` 이벤트로 흘려 체크리스트가 **Day1부터 하나씩** 채워집니다.
- **깨진 JSON 방어**: 응답을 "산문 → `===PLAN===` 구분자 → 계획 JSON"으로 분리해 사람이 읽는 텍스트만 스트리밍하고 JSON은 끝에서 한 번에 반영합니다. 스트림 실패 시 비스트리밍 → mock 순으로 폴백합니다.

---

## 3. 초기 로딩 — 번들 최적화

![Vite 번들 최적화 — Manual Chunking](/assets/images/portfolio/delaynomore-bundle.svg)

AI SDK·라이브러리 도입으로 빌드가 500kB를 넘어 Vite 경고가 발생했습니다. `rollupOptions`를 튜닝해 `node_modules`를 `vendor.js`로 격리 분할하고, 메인 앱 소스를 **44.53kB로 축소**해 초기 파싱 속도를 확보했습니다.

---

## 4. AI 분량 추천 — 회고를 다음 계획으로

![AI 분량 추천 피드백 루프](/assets/images/portfolio/delaynomore-recommendation.svg)

쌓인 회고를 되먹여 다음 계획 분량을 추천하는 피드백 루프입니다.

- **서버가 계산·규칙 소유**: 완료율은 미래 날짜를 제외한 관찰 창에서만 계산하고, 규칙(완료율 50% 미만 −1 · 85%+이며 여유 회고 다수면 +1 등)으로 다음 분량을 결정합니다. 안전 범위 1~5개, 한 번에 최대 ±1(클램프).
- **AI는 이유만 설명**: AI는 이유 문장만 생성하고 **숫자는 못 바꿉니다**. 키 미설정·오류 시 서버 템플릿으로 폴백해 이유가 항상 존재합니다.
- **사용자 승인 필수**: 추천 → 미리보기 → 저장 승인을 거쳐야만 저장되고 원본은 바뀌지 않습니다. 표본이 작으면 완료율이 튀어, **같은 목표 최근 3건을 합산**해 안정화했습니다.

---

> **💬 면접에서 더 깊게 이야기할 수 있는 주제**
> - 토큰 사용량을 어떻게 측정하고, 어느 지점에서 줄였는가(patch·compact·이력·추론)
> - 스트리밍 중 JSON이 깨지는 문제를 구조적으로 어떻게 막았는가
> - AI 응답을 신뢰하지 않기 위해 서버가 검증·정규화·폴백을 어떻게 배치했는가
> - LLM에는 계산을 맡기지 않고 "이유 설명"만 맡긴 설계 판단

---

<span class="section-note">관련: [백엔드 설계]({{ '/portfolio/1/backend/' | relative_url }}) · [배포 & 인프라]({{ '/portfolio/1/architecture/' | relative_url }}) · [데이터 & 동시성]({{ '/portfolio/1/persistence/' | relative_url }})</span>
