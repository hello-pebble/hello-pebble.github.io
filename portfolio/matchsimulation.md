---
layout: default
title: "MatchSimulation — 관리자 모드로 계정과 매칭을 통제하고 관측하기"
permalink: /portfolio/matchsimulation/
category: portfolio
tags: [Java21, SpringBoot4, JPA, Flyway, SpringSecurity, JWT]
---

<span class="project-context">개인 프로젝트 · 2026.06 — 진행 중 · Java 21 · Spring Boot 4.1 · JPA · Flyway · Spring Security/JWT</span>

# MatchSimulation — 관리자 모드

- **서비스** 소개팅 서비스를 가정한 백엔드입니다. 가입·추천·매칭·1:1 채팅 위에 **계정과 매칭을 통제·관측하는 관리자 모드**를 얹었습니다.
- **관리자가 하는 일** 가입을 승인하고 문제 계정을 정지시키며, 문의에 답하고 공지를 보내고, 매칭이 어떻게 흘러가는지 봅니다.
- **이 페이지** 관리자 모드만 다룹니다. 사용자 기능은 [저장소 `docs/`](https://github.com/hello-pebble/MatchSimulation/tree/main/docs)에 phase별 계획서·완료 보고서로 기록돼 있습니다.

![관리자 콘솔의 매칭 현황 통계 — 전체·성사 건수와 성사율, 일별·성별·상태별 매칭 분포를 집계한다](/assets/images/portfolio/matchsimulation-admin-stats.png){:.portfolio-hero-shot}

| 기능 | 내용 |
| :--- | :--- |
| **회원 관리** | 전체 목록 조회(페이징), 상태 변경 — `PENDING`(가입 대기) / `ACTIVE`(승인) / `SUSPENDED`(정지) |
| **Q&A 관리** | 전체·상태별 문의 조회, 답변 작성(→ `ANSWERED`, 답변 시각 기록) |
| **알림 등록** | 전체 공지(대상 미지정) 또는 개별 회원 대상 알림 생성 |
| **매칭 통계** | 전체·성사 건수, 성사율, 일별·성별(요청자 기준)·상태별 분포 |

관리자 API는 전부 `/api/admin/**` → `hasRole('ADMIN')` 한 규칙으로 묶여 있고, 아니면 `403`입니다.

## 01. 정지시켰는데 토큰은 아직 살아 있다 {#suspended}

관리자 모드에서 가장 손이 많이 간 지점입니다.

{% include diagrams/matchsim-suspended-decision.svg %}

**JWT는 서버가 세션 상태를 들고 있지 않습니다.** 로그인 시점에만 정지 여부를 보면, 정지 이전에 발급된 토큰은 만료될 때까지 그대로 통과합니다. 정지 처리가 "지금부터 로그인 불가"까지만 의미하고 "지금 접속 중인 사람 차단"은 못 하는 상태가 됩니다.

| 검사 지점 | 정지 계정 처리 |
| :--- | :--- |
| **로그인** | `AuthService`에서 정지 계정의 로그인 자체를 거부합니다. |
| **매 요청** | `JwtAuthFilter`가 서명 검증 후 사용자를 조회해 **정지 상태면 인증 자체를 부여하지 않습니다.** 서명이 멀쩡해도 통과하지 못합니다. |

- **엣지케이스를 먼저 정의했다** 계획서에 "위조 서명 / 만료 토큰 / **정지 계정의 유효 토큰**" 세 가지를 적고 구현했습니다. 앞의 둘은 라이브러리가 잡아주고, 실제로 놓치기 쉬운 것은 세 번째였습니다.
- **여기서 배운 것** 인증(토큰이 진짜인가)과 인가(지금도 유효한 사용자인가)는 다른 질문입니다. JWT를 쓰면 후자는 자동으로 따라오지 않습니다.
- **이 선택의 조건** 차단은 진입점마다 잊지 않고 검사할 때만 성립합니다. 규칙이 아니라 습관에 기대는 구조라, 진입점이 늘면 빠뜨릴 자리도 같이 늘어납니다. 토큰 만료를 짧게 두고 갱신 시점에 거르는 방식이 대안이었습니다.

## 02. 상태 변경과 알림을 한 트랜잭션으로 {#transaction}

회원을 승인하거나 정지시키면 대상 회원에게 알림이 생성됩니다. 이 둘을 **하나의 트랜잭션으로 묶었습니다.**

```java
@Transactional
public UserResponse changeStatus(Long userId, UserStatus status) {
    User user = userRepository.findById(userId)
            .orElseThrow(() -> ApiException.notFound("사용자를 찾을 수 없습니다: " + userId));
    UserStatus before = user.getStatus();
    user.setStatus(status);
    if (before != status) {
        if (status == UserStatus.ACTIVE) {
            notificationService.notify(userId, "회원 승인 완료", "...");
        } else if (status == UserStatus.SUSPENDED) {
            notificationService.notify(userId, "계정 정지 안내", "...");
        }
    }
    return UserResponse.from(user);
}
```

- **왜 묶었나** 알림 저장이 실패하면 상태 변경도 롤백됩니다. **계정이 정지됐는데 당사자는 이유를 모르는 상태**가 생기지 않게 하기 위해서입니다.
- **`before != status` 가드** 같은 상태로 다시 저장하는 요청에 알림이 중복 발송되지 않게 막습니다.
- **다르게 볼 수 있는 지점** 알림을 비동기 이벤트로 뺐다면 상태 변경이 알림 실패에 발목 잡히지 않습니다. 이 규모에서는 "통지 없는 정지"를 막는 쪽이 중요하다고 봤지만, 알림 채널이 외부(메일·푸시)로 늘어나면 뒤집어야 할 판단입니다.

## 03. 통계는 무겁고, 관리자는 방금 바뀐 값을 본다 {#stats}

매칭 통계는 **전체 매칭과 전체 회원을 훑는 집계**입니다. 관리자가 새로고침할 때마다 전부 조회하면 낭비지만, 캐시만 걸면 방금 바꾼 상태가 반영되지 않습니다.

| | 처리 |
| :--- | :--- |
| **캐시** | `@Cacheable("matchStats")` 60초 TTL — 반복 조회 시 집계를 다시 돌지 않습니다. |
| **즉시 무효화** | 매칭 요청·응답(`MatchingService`)과 자동 만료(`MatchExpiryScheduler`)에서 `@CacheEvict`로 캐시를 비웁니다. |
| **결과** | 읽기는 캐시로 싸게, 쓰기가 일어나면 그 즉시 최신값. |

- **TTL만 뒀다면** 관리자가 회원을 정지시키고 통계를 봤을 때 최대 60초 낡은 숫자를 봅니다. 관측 도구가 방금 한 조작을 안 보여주면 신뢰를 잃습니다.
- **무효화만 뒀다면** 쓰기가 잦으면 캐시가 거의 안 먹습니다. 둘 다 둔 이유입니다.
- **한계** 인메모리 캐시라 다중 인스턴스에서는 자기 노드만 비웁니다. 단일 인스턴스 전제의 선택입니다.

## 04. 관측과 자동 정리 {#observability}

- **집계 내용** 전체·성사 건수와 성사율, 일별 추이, 성별(요청자 기준) 분포, 상태별 분포(`REQUESTED`·`ACCEPTED`·`REJECTED`·`EXPIRED`).
- **자동 만료** 7일 무응답 매칭은 스케줄러가 `EXPIRED`로 전이시킵니다. 관리자가 손대지 않아도 `REQUESTED`가 무한정 쌓이지 않고, 성사율 분모가 오염되지 않습니다.
- **페이징 방어** 회원·문의 목록은 `size`를 최대 100으로 강제(`PageRequests.clamp`)하고, 존재하지 않는 정렬 필드는 `400`으로 막습니다. 관리자 화면이라도 파라미터를 신뢰하지 않습니다.
- **성사율의 한계** 규칙 기반 추천(지역·나이·직군)이라 품질을 직접 잴 수단이 없어, 성사율을 대리 지표로 두었습니다. 시드 데이터 위의 숫자라 실제 선호를 설명하지는 못합니다.

## 05. 검증과 한계 {#verification}

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **정지 계정 차단** | 유효 서명을 가진 정지 계정 토큰이 인증 단계에서 차단되는 것을 확인했습니다. |
| **권한 분리** | ADMIN이 아닌 토큰의 `/api/admin/**` 접근이 `403`으로 거부되는 것을 확인했습니다. |
| **트랜잭션 경계** | 알림 저장 실패 시 상태 변경도 롤백되는 것을 확인했습니다. |
| **자동 만료** | 스케줄러 실행 후 대상 매칭이 `EXPIRED`로 전이되고 통계에 반영되는 것을 확인했습니다. |
| **회귀** | JUnit 5 `@SpringBootTest` 기반 회귀 테스트를 phase마다 green으로 유지했습니다. |

<span class="section-note">시드 데이터(관리자 1명 + 회원 20명 + 매칭 30여 건) 기반의 로컬 검증입니다. 실사용 트래픽이나 실제 사용자 대상의 추천 품질을 측정한 것은 아닙니다.</span>

### 남은 과제

- **관리자 조작 이력(누가 언제 누구를 정지시켰는가)을 남기지 않습니다.** 운영 시스템이라면 감사 로그가 이 기능들보다 먼저 필요합니다.
- 정지 반영이 진입점마다 검사하는 규율에 기대고 있습니다. 토큰 수명을 줄이고 갱신에서 거르는 구조가 더 안전합니다.
- 통계 캐시가 인메모리라 다중 인스턴스에서는 무효화가 자기 노드에만 적용됩니다.

## 개발·검증 방식 {#process}

- **계획서와 보고서를 쌍으로** 시작 전에 배경·설계·엣지케이스(E1, E2, …)·테스트 계획을 고정하고, 구현 후에 회귀 결과와 curl 실측을 기록합니다.
- **패키지 구조** 함께 변경되는 기능 단위 모듈(user·matching·chat·qna·notification·**admin**)로 재편해, 관리자 기능 변경이 한 패키지 안에 갇히게 했습니다.
- **AI 협업** phase 단위로 브랜치를 파서 PR로 머지하며, 계획서의 엣지케이스 표가 곧 명세이자 제가 결과를 검수하는 채점표입니다. 계획서에 정의하지 않은 동작이 나오면 되돌립니다.

## Source

- [github.com/hello-pebble/MatchSimulation](https://github.com/hello-pebble/MatchSimulation) — 소스 코드
- [docs/admin_mode.md](https://github.com/hello-pebble/MatchSimulation/blob/main/docs/admin_mode.md) — 관리자 모드 기능·API 명세
- [docs/](https://github.com/hello-pebble/MatchSimulation/tree/main/docs) — phase별 계획서·완료 보고서
