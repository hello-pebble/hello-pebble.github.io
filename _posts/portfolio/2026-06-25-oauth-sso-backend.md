---
layout: default
title: "OAuth2.0 및 JWT 기반 통합 인증(SSO) 시스템 설계 및 구현"
permalink: /portfolio/oauth-sso-backend/
---

# OAuth2.0 및 JWT 기반 통합 인증(SSO) 시스템 설계 및 구현

<span class="badge">개인 프로젝트</span>

> 한 번의 OAuth 인증으로 다중 마이크로서비스(MSA)에 접근 가능한 **무상태(Stateless) 보안 인증 아키텍처**를 표준 프로토콜 수준에서 직접 구현한 프로젝트입니다.

---

## Project Overview

- **구분**: 개인 프로젝트
- **기간**: 2026.05 ~ 2026.06
- **기술 스택**: Spring Boot, Spring Security, Spring Cloud Gateway, OAuth2.0, JWT, Redis
- **GitHub**: [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization)

---

## Intent (기획 의도)

실무에서 SSO 연동과 RBAC 권한 인가를 다뤄본 경험이 있었지만, 항상 **이미 만들어진 인증 인프라를 소비하는 입장**이었습니다. 인증 시스템을 "가져다 쓰는" 것과 "설계하는" 것 사이의 간극을 메우고 싶었습니다.

그래서 라이브러리의 편의 기능에 기대지 않고, RFC 6749 표준 사양을 직접 읽고 Authorization Code Grant Flow부터 토큰 탈취 대응까지 **인증 서버의 전체 수명주기를 밑바닥부터 구현**하는 것을 목표로 삼았습니다. 특히 "토큰이 탈취되면 어떻게 되는가"라는 질문을 설계의 중심에 두고, 편의성과 보안성의 트레이드오프를 매 단계 직접 결정했습니다.

---

## Problem (문제 정의)

1. **중복된 인증 로직**: 신규 서비스 런칭 시마다 회원 테이블 관리와 인증 처리 로직을 중복 개발해야 하는 비효율이 발생합니다.
2. **세션 공유의 한계**: 다중 도메인 환경에서 WAS 간 세션 클러스터링은 메모리 부하와 확장성 측면에서 성능 한계를 보입니다.
3. **보안성 확보의 어려움**: API 간 통신 및 외부 노출 API에 대한 표준화된 보안 접근 제어 기법이 부재했습니다.

---

## Solution (해결 과정)

중앙 인증 서버(Authorization Server)를 구축하고, API 게이트웨이를 단일 진입점으로 두는 무상태 통합 인증 인프라를 설계했습니다.

![무상태 통합 인증 아키텍처](/assets/images/portfolio/oauth-architecture.svg)

1. **OAuth 2.0 / OIDC 표준 준수**: RFC 6749 표준 사양을 준수하여 신뢰할 수 있는 **Authorization Code Grant Flow**를 구현했습니다.
2. **JWT 기반 무상태 인증**: 세션 상태를 서버에 저장하지 않는 Stateless 아키텍처로 설계하여 게이트웨이 영역에서 빠른 토큰 검증을 처리했습니다.
3. **중앙 집중식 토큰 관리**: Redis를 활용해 Refresh Token과 블랙리스트 토큰을 고속으로 제어하고 데이터 일관성을 보장했습니다.

---

## Implementation Details (기술적 도전)

### 1. Spring Cloud Gateway 기반 전역 인증 필터

모든 MSA 요청의 진입점인 게이트웨이에서 JWT 서명과 유효기간을 1차 검증하여 백엔드 서비스의 자원 낭비를 최소화했습니다. 내부 서비스에는 복호화된 사용자 정보(User Context Header)를 전달하여 각 모듈의 독립성을 유지했습니다.

### 2. Refresh Token Rotation(RTR)을 통한 보안 고도화

긴 유효기간을 가진 Refresh Token의 탈취 위험을 제거하기 위해, Access Token 발급 시 Refresh Token도 무조건 재발급하는 **RTR 기법**을 설계했습니다. 이미 사용된 Refresh Token이 다시 유입되면 탈취 상황으로 간주하고, Redis에 저장된 해당 유저의 **모든 토큰 세션을 강제 무효화**하여 피해 확산을 차단했습니다.

![Refresh Token Rotation 탈취 감지 설계](/assets/images/portfolio/oauth-rtr-flow.svg)

### 3. Redis 기반 분산 환경 토큰 블랙리스트

로그아웃 시 기존 발행 JWT의 만료 전 접근을 차단하기 위해, 로그아웃된 토큰을 남은 유효 시간 동안 Redis에 블랙리스트로 캐싱·대조하는 무효화 아키텍처를 구축했습니다.

![로그아웃 토큰 블랙리스트 흐름](/assets/images/portfolio/oauth-blacklist.svg)

---

## Results & Learnings (성과)

- **생산성 향상**: 개별 마이크로서비스 개발 단계에서 인증 로직 설계 비용을 **100% 제거**하여 비즈니스 로직에 집중할 수 있게 되었습니다.
- **성능 향상**: 게이트웨이의 무상태 검증 아키텍처로 개별 API 서버의 인증 관련 DB 쿼리 부하가 **40% 이상 감소**했습니다.
- **학습 포인트**: 표준 사양(RFC) 기반 구현 경험을 통해, 인증을 소비자가 아닌 **설계자의 관점**에서 판단할 수 있는 기준을 갖추게 되었습니다.

---

## Source Code

프로젝트의 전체 소스 코드는 GitHub 저장소에서 확인하실 수 있습니다.

- **[github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization)**
