---
layout: default
title: "OAuth2.0 및 JWT 기반 통합 인증(SSO) 시스템 설계 및 구현"
permalink: /portfolio/oauth-sso-backend/
---

# [Portfolio] OAuth2.0 및 JWT 기반 통합 인증(SSO) 시스템 설계 및 구현

> 한 번의 OAuth 인증으로 다중 마이크로서비스(MSA)에 접근 가능한 고성능 보안 인증 아키텍처 구축

---

## 📌 Project Overview
- **기간**: 2026.05 - 2026.06
- **기술 스택**: Spring Boot, Spring Security, Spring Cloud Gateway, OAuth2.0, JWT, Redis
- **핵심 목표**: 다수의 독립된 서비스들에 대해 단일 로그인(SSO) 환경을 제공하고, 표준 OAuth 2.0 프로토콜과 JWT를 도입하여 무상태(Stateless) 기반의 확장 가능한 보안 인프라 설계

---

## 🔍 Problem Discovery (문제 정의)
1. **중복된 인증 로직**: 신규 서비스 런칭 시마다 회원 테이블 관리 및 인증 처리 로직을 중복 개발해야 하는 비효율성 발생.
2. **세션 공유의 한계**: 다중 도메인 환경에서 WAS 간의 세션 클러스터링 구성은 메모리 부하와 확장성 측면에서 성능 한계를 보임.
3. **보안성 확보의 어려움**: API 간 통신 및 외부 노출 API에 대해 표준화된 보안 접근 제어 기법 부재.

---

## 💡 Solution: OAuth 2.0 & Gateway SSO
중앙 인증 서버(Authorization Server)를 구축하고, API 게이트웨이(Gateway)를 입구로 두어 무상태 통합 인증 인프라를 설계했습니다.

1. **OAuth 2.0 / OIDC 표준 준수**: RFC 6749 표준 사양을 준수하여 신뢰할 수 있는 Authorization Code Grant Flow 구현.
2. **JWT 기반의 무상태 인증**: 세션 상태를 서버에 저장하지 않는 Stateless 아키텍처로 설계하여 게이트웨이 영역에서 빠른 토큰 검증 처리.
3. **중앙 집중식 토큰 관리**: Redis를 활용하여 Refresh Token 및 블랙리스트 토큰을 고속 제어하고 데이터 일관성 보장.

---

## 🛠 Implementation Details (기술적 도전)

### 1. Spring Cloud Gateway 기반 전역 인증 필터 구현
모든 MSA 요청의 진입점인 게이트웨이에서 JWT 서명 및 유효기간을 1차적으로 검증하여 백엔드 서비스의 자원 낭비를 최소화하였습니다. 내부 서비스에는 복호화된 사용자 정보(User Context Header)를 전달하여 내부 모듈의 높은 독립성을 유지했습니다.

### 2. Refresh Token Rotation (RTR)을 통한 보안 고도화
사용자 편의성을 위해 긴 유효기간을 가진 Refresh Token의 보안 위험을 제거하고자, 새로운 Access Token 발급 시 Refresh Token도 무조건 재발급하는 RTR 기법을 설계했습니다. 
이미 사용된 Refresh Token이 다시 유입될 경우 탈취 상황으로 간주하고, Redis 내에 저장된 해당 유저의 모든 토큰 세션을 강제 무효화 처리하여 피해를 방지했습니다.

### 3. Redis 기반 분산 환경 토큰 블랙리스트 관리
사용자 로그아웃 시 기존에 발행된 JWT의 만료 전 접근을 원천 차단하기 위해, 로그아웃된 토큰의 남은 유효 시간 동안 Redis 내에 블랙리스트로 캐싱 및 대조하는 무효화 아키텍처를 구축했습니다.

---

## 📈 Results & Learnings
- **생산성 향상**: 개별 마이크로서비스 개발 단계에서 인증 로직 설계 비용을 100% 제거하여 비즈니스 로직에 집중 가능하게 됨.
- **성능 향상**: 게이트웨이의 무상태 검증 아키텍처로 개별 API 서버의 인증 관련 DB 쿼리 부하가 40% 이상 감소.
