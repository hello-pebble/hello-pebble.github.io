---
layout: default
title: "Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험"
permalink: /portfolio/oauth-sso-backend/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

<span class="project-context">개인 프로젝트 · 2026.01 — 2026.03</span>

# Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험

- Gateway 하나만 외부에 공개하고, 공개·보호·내부 경로가 각각 다른 응답을 보장하는지 실제 요청으로 검증
- Auth가 JWT를 중앙 발급하고 각 서비스가 JWKS 공개키로 독립 검증하는 분산 인증 구조를 단독 구현

<nav class="project-page-nav" aria-label="Gateway 인증/인가 검증 프로젝트 목차">
  <a href="#scenarios">
    <span>Overview</span>
    <small>검증한 4가지 시나리오</small>
  </a>
  <a href="#testbed">
    <span>01. 테스트 베드</span>
    <small>전체 구조와 6개 모듈</small>
  </a>
  <a href="#gateway-auth">
    <span>02. 통합 인증</span>
    <small>Gateway와 JWT 분산 검증</small>
  </a>
  <a href="#verification">
    <span>03. 검증과 한계</span>
    <small>재현 결과와 다음 단계</small>
  </a>
</nav>

## 검증한 4가지 인증/인가 시나리오 {#scenarios}

이 실험의 주인공은 개별 기능이 아니라 **인증/인가 시나리오**입니다. 단일 진입점 뒤에 여러 서비스가 있을 때, 요청의 성격에 따라 서버가 어떤 응답을 보장해야 하는지를 다음 네 가지로 정의하고 실제 요청으로 확인했습니다.

| 시나리오 | 보장해야 하는 동작 |
| :--- | :--- |
| **① 비로그인 접근 허용 경로** | 로그인 화면·JWKS·OIDC metadata 등 공개 라우트는 토큰 없이 접근 가능 |
| **② 로그인 필수 경로** | 토큰 없이 보호 API를 호출하면 `401` 반환 |
| **③ Admin 경유 인가 검증** | Admin → Matching 호출에서 **양쪽 서비스가 각각** JWT와 관리자 권한을 검증 |
| **④ Gateway 우회 내부 접근 차단** | Gateway에 `/internal/**` 라우트를 두지 않아 외부에서는 `404` |

이 네 가지가 성립하면 "어떤 경로는 열려 있고, 어떤 경로는 인증이 필요하며, 내부 경로는 외부에서 보이지 않는다"는 접근 규칙을 화면이 아닌 서버 구성이 보장하게 됩니다.

![Gateway 인증/인가 분기 — 공개·보호·관리자·내부 경로가 서로 다른 응답을 보장](/assets/images/portfolio/oauth-architecture.svg)

## 01. 테스트 베드 — 전체 구조와 6개 모듈 {#testbed}

| 설계 판단 | 적용 방식 |
| :--- | :--- |
| **통합 접근** | Gateway만 외부에 공개하고 경로에 따라 내부 서비스로 라우팅 |
| **인증 책임 분리** | Auth가 JWT를 발급하고 Matching·Task·Admin이 JWKS 공개키로 검증 |
| **변경 경계 분리** | 각 모듈이 자신의 기능 코드와 정책을 소유 |
| **실행 재현** | 6개 애플리케이션과 PostgreSQL을 Docker Compose로 함께 기동 |

6개 모듈(Auth·Gateway·Matching·Task·Preview·Admin)은 위 인증 시나리오를 현실적으로 재현하기 위한 **테스트 베드**입니다. Matching·Task 같은 명칭은 추후 실제 서비스로 구현할 가능성을 고려한 **플레이스홀더**이며, 이 실험에서 중요한 것은 각 모듈의 업무 기능이 아니라 "공개 라우트를 가진 서비스, 보호 API를 가진 서비스, 내부 API만 가진 서비스"라는 역할 구분입니다.

| 모듈 | 시나리오에서의 역할 |
| :--- | :--- |
| **Auth** | 로그인·JWT 발급·JWKS 제공 — 공개 라우트(①)의 출처 |
| **Gateway** | 유일한 외부 진입점 · 라우팅 · Cookie→Bearer 변환 — ④의 차단 지점 |
| **Matching** | 보호 API와 관리자용 내부 API 보유 — ②·③·④의 대상 |
| **Task** | 사용자 작업 보호 API — ②의 대상 |
| **Preview** | 로그인·인가 흐름을 눈으로 확인하는 화면 |
| **Admin** | 관리자 API · Matching 내부 API 호출 — ③의 시작점 |

모듈 구조 자체는 PMS 운영에서 겪은 문제(기능 컨테이너가 코드·의존성·계정 API를 공유하며 변경 범위가 겹치던 경험)에서 출발했습니다. 함께 변경되는 기능과 정책 단위로 소스·빌드·실행을 나눴고, 각 애플리케이션은 별도 디렉터리와 빌드 설정을 가집니다. 다만 하나의 저장소를 쓰는 모노레포이므로 소스 열람 권한까지 분리되지는 않습니다.

## 02. Gateway 통합 접근과 분산 인증 {#gateway-auth}

### 단일 진입점은 Gateway 하나로 제한했다

Compose 환경에서 호스트에 공개한 포트는 Gateway의 `8000` 하나입니다. Gateway가 담당하는 것은 두 가지뿐입니다.

- URL 경로에 따라 Auth·Matching·Task·Preview·Admin으로 요청 라우팅
- 브라우저의 Access Token Cookie를 `Authorization: Bearer` 헤더로 변환

JWT 서명과 역할 정책은 Gateway가 대신 판단하지 않습니다. 각 Resource Server가 자신의 API 접근 규칙을 소유하게 해, 통합 접근과 서비스별 정책 분리를 함께 유지했습니다.

### 중앙 발급 · 분산 검증

Auth는 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 제공합니다. Matching·Task·Admin은 공개키로 토큰의 서명과 만료를 **직접** 검증합니다. 일반 API 요청마다 Auth의 계정 API를 다시 호출하지 않으므로, 발급 책임은 중앙에 두면서 요청 경로의 원격 의존은 줄였습니다.

![Gateway부터 서비스 간 호출까지의 인증 흐름](/assets/images/portfolio/oauth-request-flow.svg)

### 서비스 간 호출도 다시 검증했다

관리자 요청(시나리오 ③)은 두 서비스 경계를 통과합니다.

1. Admin이 JWT와 `ROLE_ADMIN`을 검증합니다.
2. Admin이 Matching의 `/internal/admin/**` API에 같은 JWT를 전달합니다.
3. Matching이 JWT와 관리자 권한을 **다시** 검증합니다.
4. Gateway에는 `/internal/**` 라우트가 없어 외부 직접 접근 경로가 생기지 않습니다(시나리오 ④).

한 서비스의 판단을 다음 서비스가 무조건 신뢰하지 않도록, 각 경계가 자신의 정책을 확인합니다.

### Trade-off

- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화됩니다.
- 이미 발급된 JWT를 만료 전에 즉시 폐기하는 기능은 구현하지 않았습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다.
- 운영 환경에서는 영속 키 관리, 키 순환, client credentials·토큰 교환·mTLS를 검토해야 합니다.

## 03. 실행 검증 결과와 한계 {#verification}

### 검증 결과

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **① 공개 라우트** | Gateway에서 로그인 화면, JWKS, OIDC metadata 접근 확인 |
| **② 보호 API 인증** | 토큰 없이 Task·Admin API 호출 시 `401` 확인 |
| **③ 양측 인가 검증** | Admin이 JWT를 전달해 Matching 관리자 API를 호출하고 양쪽에서 권한 검증 |
| **④ 내부 경로 차단** | Gateway를 통한 `/internal/admin/users` 접근 시 `404` 확인 |
| **모듈별 빌드** | 6개 애플리케이션 모듈 빌드 및 전체 테스트 통과 |
| **통합 실행** | 6개 애플리케이션과 PostgreSQL을 Compose로 기동하고 health 확인 |

### 정상 JWT가 401을 반환했던 문제

RS256은 개인키로 서명하고 공개키로 검증해야 합니다. 초기 `JwtProvider`는 검증에도 개인키를 사용해, 토큰 발급은 성공하는데 보호 API에서는 정상 토큰이 거부됐습니다. JWT 디코더가 RSA 공개키를 사용하도록 수정하고 보호 API 스모크 테스트를 다시 수행해, 발급 주체와 검증 주체가 분리된 비대칭 키 모델을 코드와 실제 요청으로 확인했습니다.

### 문서와 실행 환경의 불일치 정리

README·Compose에 일부 모듈만 기재돼 있었고 사용하지 않는 Redis 설명·의존성이 남아 있었습니다. 6개 애플리케이션의 역할·포트·라우트, 전체 Compose 구성, Gateway만 공개하는 포트 정책을 코드 기준으로 맞추고, 사용하지 않는 Redis·Redisson 의존성과 테스트 대역을 제거한 뒤 전체 구성을 다시 기동했습니다.

### 현재 한계

- 모노레포라서 모듈별 소스 접근 권한은 분리되지 않고, 모듈별 독립 CI/CD·버전 정책도 구성하지 않았습니다.
- Matching 상태·Refresh Token·대기 상태가 메모리에 있어 재시작 시 사라지고 다중 인스턴스가 공유할 수 없습니다.
- 대기실은 실제 순번 큐가 아니라 즉시 `ALLOWED`를 기록하는 기능 검증 수준입니다.
- 서비스 간 timeout·재시도·오류 매핑과 분산 추적은 구현하지 않았습니다.

<span class="section-note">실제 팀 프로젝트에 적용해 Merge Conflict 감소율이나 원복 시간 개선을 측정한 결과는 아닙니다. 단일 진입점 뒤에서 인증/인가 시나리오가 성립하는지를 실제 요청으로 확인한 아키텍처 실험입니다.</span>

### 다음 단계

1. 사용자 권한과 서비스 신원을 분리하고(client credentials·토큰 교환) 서비스 간 실패 전파를 다룹니다.
2. 공유 상태가 필요한 기능부터 영속 저장소와 다중 인스턴스 검증을 추가합니다.
3. 모듈별 변경이 독립 빌드·배포로 이어지도록 CI/CD 경계를 나눕니다.

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization) — 소스 코드
- [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
- [Architecture Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)
