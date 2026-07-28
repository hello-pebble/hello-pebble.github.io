---
layout: default
title: "Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험"
permalink: /portfolio/oauth-sso/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

<span class="project-context">개인 프로젝트 · 2026.01 — 2026.03 · 기술 검증 프로젝트</span>

# Gateway 단일 진입점에서의 인증/인가 검증 — 공개·보호 라우트 분리와 JWT 분산 검증 실험

- 인증 서버가 토큰을 발급하고 Gateway와 Resource Server가 각자 권한을 검증하는 흐름을 직접 구성해, 경로별 접근 제어와 구성 요소별 책임을 실제 요청으로 확인했습니다.

<dl class="project-summary-grid">
  <div>
    <dt>무엇을</dt>
    <dd>Auth가 JWT를 중앙 발급하고 Gateway·Resource Server가 JWKS로 분산 검증하는 구조를 6개 모듈 테스트 베드로 구성</dd>
  </div>
  <div>
    <dt>왜</dt>
    <dd>Spring Security 설정을 사용하는 데서 그치지 않고, 인증 서버·Gateway·Resource Server가 각각 어떤 책임을 가져야 하는지 실제 요청으로 확인하기 위해</dd>
  </div>
  <div>
    <dt>담당 범위</dt>
    <dd>인증 구조 설계 · JWT/Refresh Token 발급 · JWKS 기반 검증 · Gateway 라우팅 · Resource Server 권한 검증 · Docker Compose 통합 구성</dd>
  </div>
  <div>
    <dt>검증한 것</dt>
    <dd>공개 경로 접근 · 무토큰 401 · Admin→Matching 양측 권한 검증 · 내부 경로 404 · 6개 모듈 Compose 통합 기동</dd>
  </div>
</dl>

<nav class="project-page-nav" aria-label="Gateway 인증/인가 검증 프로젝트 목차">
  <a href="#scenarios">
    <span>Overview</span>
    <small>4가지 시나리오와 6개 모듈</small>
  </a>
  <a href="#distributed-auth">
    <span>01. 중앙 발급·분산 검증</span>
    <small>JWT·JWKS 흐름</small>
  </a>
  <a href="#gateway-auth">
    <span>02. 경계별 책임</span>
    <small>Gateway와 Resource Server</small>
  </a>
  <a href="#conclusion">
    <span>03. 구현 후 결론</span>
    <small>직접 만들며 이해한 것</small>
  </a>
  <a href="#verification">
    <span>검증과 한계</span>
    <small>확인 결과·다음 과제</small>
  </a>
</nav>

## Overview — 검증한 4가지 시나리오 {#scenarios}

이 실험의 주인공은 개별 기능이 아니라 **인증/인가 시나리오**입니다. 단일 진입점 뒤에 여러 서비스가 있을 때 요청의 성격에 따라 서버가 보장해야 하는 응답을 네 가지로 정의하고, 실제 요청으로 확인했습니다.

| 시나리오 | 보장해야 하는 동작 |
| :--- | :--- |
| **① 공개 경로** | 로그인 화면·JWKS·OIDC metadata는 토큰 없이 접근 가능 |
| **② 보호 경로 · 토큰 없음** | 보호 API 호출 시 `401` 반환 |
| **③ Admin 경유 인가** | Admin → Matching 호출에서 **양쪽 서비스가 각각** JWT와 관리자 권한 검증 |
| **④ 내부 경로 직접 접근** | Gateway에 `/internal/**` 라우트가 없어 외부에서는 `404` |

![Gateway 인증/인가 분기 — 공개·보호·관리자·내부 경로가 서로 다른 응답을 보장](/assets/images/portfolio/oauth-architecture.svg){:.portfolio-diagram}

6개 모듈은 이 시나리오를 재현하기 위한 **테스트 베드**입니다. 각 모듈의 업무 기능이 아니라 "공개 라우트를 가진 서비스 · 보호 API를 가진 서비스 · 내부 API만 가진 서비스"라는 역할 구분이 핵심입니다.

| 모듈 | 시나리오에서의 역할 |
| :--- | :--- |
| **Auth** | 로그인 · JWT 발급 · JWKS 제공 — ①의 출처 |
| **Gateway** | 유일한 외부 진입점 · 라우팅 · Cookie→Bearer 변환 — ④의 차단 지점 |
| **Matching** | 보호 API와 관리자용 내부 API 보유 — ②·③·④의 대상 |
| **Task** | 사용자 작업 보호 API — ②의 대상 |
| **Preview** | 로그인·인가 흐름을 눈으로 확인하는 화면 |
| **Admin** | 관리자 API · Matching 내부 API 호출 — ③의 시작점 |

## 01. 중앙 발급 · 분산 검증 {#distributed-auth}

Auth는 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 제공합니다. 각 서비스는 공개키로 서명과 만료를 **직접** 검증하므로, 일반 요청마다 인증 서버에 다시 문의하지 않아 요청 경로의 원격 의존을 줄였습니다. 대신 서명 키가 전체 신뢰의 뿌리가 되므로, 이 구조에서는 키 보관·순환 같은 키 관리가 중요해집니다.

![로그인부터 API 응답까지 — Gateway를 거쳐 각 서비스가 JWKS 공개키로 JWT를 직접 검증하는 흐름](/assets/images/portfolio/oauth-request-flow.svg){:.portfolio-diagram}

## 02. Gateway와 Resource Server의 책임 {#gateway-auth}

Compose 환경에서 호스트에 공개한 포트는 Gateway의 `8000` 하나입니다. Gateway는 라우팅과 Cookie→Bearer 변환만 담당하고, JWT 서명과 역할 정책은 각 Resource Server가 자신의 규칙으로 판단합니다. Gateway만 검사하면 내부 서비스가 안전하다고 말할 수 없기 때문입니다.

| 경계 | 확인하는 것 |
| :--- | :--- |
| **Gateway** | 경로 라우팅 · `/internal/**` 라우트 미등록(외부 404) · Cookie→Bearer 변환 |
| **Admin** | JWT 서명·만료 + `ROLE_ADMIN` 검증 후 Matching 내부 API 호출 |
| **Matching** | 전달받은 JWT와 관리자 권한을 **다시** 검증 — 앞 서비스의 판단을 무조건 신뢰하지 않음 |

## 03. 직접 구현하며 얻은 결론 {#conclusion}

JWT 발급과 검증만 구현하는 것은 가능했지만, 키 관리·Refresh Token 보안·예외 처리와 표준 준수까지 고려하면 인증 서버의 책임이 빠르게 복잡해졌습니다. 직접 구현한 경험을 통해 실제 서비스에서는 검증된 인증 솔루션을 사용해야 하는 이유와, 적용 시 확인해야 할 지점(키 순환, 토큰 폐기, 경계별 재검증)을 이해하게 됐습니다.

## 검증 결과와 한계 {#verification}

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **① 공개 경로** | Gateway 경유로 로그인 화면·JWKS·OIDC metadata 접근 확인 |
| **② 무토큰 요청** | Task·Admin 보호 API에서 `401` 확인 |
| **③ 양측 인가 검증** | Admin이 JWT를 전달해 Matching 관리자 API를 호출하고 양쪽에서 권한 검증 |
| **④ 내부 경로 차단** | Gateway 경유 `/internal/admin/users` 접근 시 `404` 확인 |
| **모듈별 빌드** | 6개 애플리케이션 모듈 빌드와 전체 테스트 통과 |
| **통합 실행** | 6개 애플리케이션 + PostgreSQL을 Compose로 기동하고 health 확인 |

초기에는 정상 JWT가 보호 API에서 401을 받는 문제가 있었는데, `JwtProvider`가 검증에도 RSA 개인키를 쓰고 있던 것이 원인이었습니다. 디코더가 공개키를 사용하도록 수정하고 스모크 테스트를 다시 수행해, 발급 주체와 검증 주체가 분리된 비대칭 키 모델을 실제 요청으로 확인했습니다.

### 한계와 다음 검증 과제

- 상용 인증 서버 수준의 보안성을 검증한 것은 아닙니다.
- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화되며, 키 교체·폐기 시나리오는 검증하지 못했습니다.
- Refresh Token 탈취·재사용 대응은 검증하지 못했습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다 — client credentials·토큰 교환·mTLS가 다음 과제입니다.
- 실제 서비스라면 직접 구현 대신 검증된 인증 솔루션을 적용할 예정입니다.

<span class="section-note">실제 팀 프로젝트에 적용해 지표를 측정한 결과가 아니라, 단일 진입점 뒤에서 인증/인가 시나리오가 성립하는지를 실제 요청으로 확인한 아키텍처 실험입니다.</span>

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization) — 소스 코드
- [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
- [Architecture Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)
