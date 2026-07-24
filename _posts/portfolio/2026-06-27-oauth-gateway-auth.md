---
layout: default
title: "Gateway 통합 접근과 분산 인증"
permalink: /portfolio/oauth-sso-backend/02-gateway-auth/
category: portfolio
tags: [SpringCloudGateway, SpringSecurity, OAuth2, JWT, JWKS]
---

<span class="project-context">변경 경계로 나눈 MSA · 02</span>

# Gateway 통합 접근과 분산 인증

- 분리된 서비스의 외부 접근 경로를 Gateway 하나로 통합
- 기존 계정 API 조회 대신 Auth의 JWT 발급과 Resource Server별 공개키 검증 적용

{% include oauth-project-nav.html %}

## 배경

기능을 독립 서비스로 나누면 주소와 포트도 함께 늘어납니다. 클라이언트가 각 서비스의 위치를 직접 알게 하면 내부 구조가 외부 계약에 노출되고, 서비스를 추가할 때마다 접근 방식이 달라집니다.

PMS의 신규 기능은 사용자 확인을 위해 기존 계정 API를 호출했습니다. 기능이 늘어날수록 요청 경로가 계정 서비스의 가용성과 응답 시간에 함께 종속될 수 있는 구조였습니다.

## Gateway는 통합 진입점으로 제한했다

Compose 환경에서는 Gateway의 `8000` 포트만 호스트에 공개했습니다. Gateway는 다음 두 가지만 담당합니다.

- URL 경로에 따라 Auth, Matching, Task, Preview, Admin으로 요청 라우팅
- 브라우저의 Access Token Cookie를 `Authorization: Bearer` 헤더로 변환

JWT 서명과 역할 정책은 Gateway가 대신 판단하지 않습니다. 각 Resource Server가 자신의 API 접근 규칙을 소유하게 해 통합 접근과 서비스별 정책 분리를 함께 유지했습니다.

## 중앙 발급·분산 검증

Auth는 RSA 개인키로 JWT를 서명하고 공개키를 JWKS 엔드포인트로 제공합니다. Matching·Task·Admin은 공개키로 토큰의 서명과 만료 시간을 직접 검증합니다.

일반 API 요청마다 Auth의 계정 API를 다시 호출하지 않으므로, 토큰 발급 책임은 중앙에 두면서도 리소스 요청 경로의 원격 의존을 줄였습니다.

![Gateway부터 서비스 간 호출까지의 인증 흐름](/assets/images/portfolio/oauth-request-flow.svg)

## 서비스 간 호출도 다시 검증했다

관리자 요청은 두 서비스 경계를 통과합니다.

1. Admin이 JWT와 `ROLE_ADMIN`을 검증합니다.
2. Admin이 Matching의 `/internal/admin/**` API에 같은 JWT를 전달합니다.
3. Matching이 JWT와 관리자 권한을 다시 검증합니다.
4. Gateway에는 `/internal/**` 라우트를 두지 않아 외부 직접 접근 경로를 만들지 않습니다.

한 서비스의 판단을 다음 서비스가 무조건 신뢰하지 않도록 각 경계가 자신의 정책을 확인하게 했습니다.

## Trade-off

- Auth 재시작 시 RSA 키가 새로 생성되어 기존 JWT가 무효화됩니다.
- 이미 발급된 JWT를 만료 전에 즉시 폐기하는 기능은 구현하지 않았습니다.
- Admin → Matching 호출은 사용자 JWT를 전달하므로 서비스 자체의 신원은 증명하지 않습니다.
- 운영 환경에서는 영속 키 관리, 키 순환, client credentials·토큰 교환·mTLS를 검토해야 합니다.

## 다음 페이지

[03. 실행 검증과 현재 한계 →](/portfolio/oauth-sso-backend/03-verification/)
