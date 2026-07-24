---
layout: default
title: "인증에서 시작해 서비스 경계와 통신을 검증한 MSA 백엔드"
permalink: /portfolio/oauth-sso-backend/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

# 인증에서 시작해 서비스 경계와 통신을 검증한 MSA 백엔드

<span class="badge">개인 프로젝트</span>

> OAuth2 인증 구현으로 시작해 **6개 실행 모듈의 책임을 분리하고, Gateway 라우팅·JWKS 기반 분산 검증·서비스 간 권한 전파를 실제 통신으로 확인한 프로젝트**입니다.

---

## Project Overview

- **기간**: 2026.05 ~ 2026.07
- **역할**: 개인 설계·개발·테스트·실행 환경 구성
- **구성**: Auth, Gateway, Matching, Task, Preview, Admin — 6개 애플리케이션
- **기술 스택**: Kotlin, Java 21, Spring Boot 3.5, Spring Security, Spring Authorization Server, Spring Cloud Gateway, PostgreSQL, Docker Compose
- **GitHub**: [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization)

### 30초 요약

처음에는 OAuth2와 JWT의 동작 원리를 코드로 확인하는 인증 프로젝트였습니다. 이후 인증 서버 하나만으로는 MSA의 핵심 질문을 검증하기 어렵다고 판단했습니다.

- 토큰을 발급하는 곳과 검증하는 곳의 책임을 어떻게 나눌 것인가?
- Gateway는 인증까지 담당해야 하는가, 진입점과 라우팅에 집중해야 하는가?
- 서비스가 다른 서비스를 호출할 때 사용자 권한을 어떻게 전달하고 다시 검증할 것인가?
- 문서에 적힌 구성을 다른 개발자가 한 번에 실행해 확인할 수 있는가?

이 질문을 기준으로 리소스 서버와 관리 서비스를 추가하고, 전체 구성을 Docker Compose에서 함께 실행했습니다. 이 프로젝트의 결과물은 “완성된 상용 MSA”가 아니라 **서비스 분리 시 생기는 경계와 통신 문제를 직접 구현하고 검증한 실행 가능한 실험 환경**입니다.

---

## 인증 프로젝트를 MSA 실험으로 확장한 이유

인증 서버만 구현했을 때는 토큰 발급 성공 여부까지만 확인할 수 있었습니다. 실제 분산 환경에서는 발급 이후가 더 중요했습니다. 각 서비스가 인증 서버에 매번 물어보면 중앙 장애와 네트워크 비용에 종속되고, 반대로 모든 책임을 Gateway에 모으면 내부 서비스가 자신의 접근 정책을 표현하기 어려워집니다.

그래서 기능 수를 늘리는 대신 다음 순서로 **책임의 경계**를 확장했습니다.

1. **Auth**에서 OAuth2 로그인과 JWT 발급, 공개키 조회(JWKS)를 담당했습니다.
2. **Matching·Task·Admin**을 독립 Resource Server로 두고 JWT를 각자 검증하도록 했습니다.
3. **Gateway**는 외부 단일 진입점, 라우팅, 브라우저 쿠키의 Bearer 변환만 담당하도록 제한했습니다.
4. **Admin → Matching** 직접 호출을 추가해 사용자 JWT 전달과 양쪽 권한 검증을 확인했습니다.
5. **Preview**를 포함한 6개 애플리케이션과 PostgreSQL을 Compose로 묶어 실행 경로를 재현했습니다.

<span class="section-note">프로젝트 이름에는 OAuth2가 남아 있지만, 현재 포트폴리오의 초점은 인증 기능 자체보다 인증을 매개로 서비스 경계와 통신을 검증한 과정에 있습니다.</span>

---

## Architecture

![6개 모듈의 책임과 통신 구조](/assets/images/portfolio/oauth-architecture.svg)

| 모듈 | 책임 | 인증 관점 |
| :--- | :--- | :--- |
| **Gateway · :8000** | 외부 요청의 단일 진입점과 경로 라우팅 | 쿠키를 `Authorization: Bearer`로 변환하되 JWT를 직접 검증하지 않음 |
| **Auth · :8080** | OAuth2 로그인, JWT 발급, JWKS·OIDC 메타데이터 제공 | 개인키로 서명하고 공개키를 노출 |
| **Matching · :8081** | 매칭 프로필과 노출 상태 관리 | JWT 검증, 일반 API와 관리자용 내부 API 분리 |
| **Task · :8083** | 사용자 작업 API | JWT를 독립 검증 |
| **Preview · :8084** | 로그인·인가 흐름을 확인하는 화면 | Gateway를 통해 인증 흐름 진입 |
| **Admin · :8085** | 관리자 API와 Matching 연계 | `ROLE_ADMIN` 검증 후 사용자 JWT를 Matching에 전달 |

Compose 환경에서는 Gateway만 호스트에 공개하고 나머지 애플리케이션은 내부 네트워크에서 이름으로 통신합니다. 개발자가 개별 포트를 기억해 직접 호출하는 구조보다, 실제 운영 환경에 가까운 **단일 진입점 원칙**을 실행 환경에도 반영했습니다.

---

## 핵심 설계 판단

### 1. 토큰은 중앙에서 발급하고, 검증은 각 서비스가 수행한다

Auth가 RSA 개인키로 JWT를 서명하고 JWKS 엔드포인트로 공개키를 제공합니다. Matching·Task·Admin은 공개키로 서명과 만료 시간을 독립 검증합니다.

이 구조에서는 일반 API 요청마다 Auth에 원격 검증을 요청하지 않습니다. Auth가 토큰 발급의 기준점이면서도, 리소스 요청 경로의 단일 병목이 되지 않도록 역할을 나눴습니다.

**Trade-off**

- Auth가 재시작될 때 RSA 키가 새로 생성되므로 기존 JWT가 무효화됩니다.
- 발급된 JWT를 만료 전에 즉시 폐기하는 블랙리스트는 구현하지 않았습니다.
- 운영 단계라면 영속 키 관리와 키 순환 정책, 즉시 폐기 전략을 별도로 설계해야 합니다.

### 2. Gateway는 정책의 주인이 아니라 진입점으로 제한한다

Gateway의 보안 설정은 요청을 허용하고, 실제 인증·인가는 각 Resource Server가 수행합니다. Gateway는 브라우저가 보낸 액세스 토큰 쿠키를 Bearer 헤더로 바꿔 전달하고 경로를 올바른 서비스로 라우팅합니다.

처음부터 Gateway에서 모든 JWT와 역할을 검증하는 방식도 가능했습니다. 하지만 그렇게 하면 서비스별 정책이 Gateway 설정에 결합되고, 내부망에서 서비스를 직접 호출할 때 보호가 사라집니다. 각 서비스가 자신의 API 접근 규칙을 소유하도록 해 **라우팅 책임과 보안 정책 책임을 분리**했습니다.

### 3. 서비스 간 호출에서도 사용자 권한을 다시 검증한다

관리자 요청은 다음 두 경계를 통과합니다.

![Gateway부터 서비스 간 호출까지의 인증 흐름](/assets/images/portfolio/oauth-request-flow.svg)

1. Admin이 사용자 JWT를 검증하고 `ROLE_ADMIN`을 확인합니다.
2. Admin이 Matching의 `/internal/admin/**` API를 호출하면서 같은 JWT를 전달합니다.
3. Matching이 JWT와 관리자 권한을 다시 검증한 뒤 작업을 수행합니다.
4. Gateway에는 `/internal/**` 라우트를 두지 않아 외부 진입 경로와 내부 호출 경로를 구분합니다.

한 서비스의 판단을 다음 서비스가 무조건 신뢰하지 않도록 각 경계에서 검증했습니다. 다만 현재는 사용자 JWT를 그대로 전달하므로, 서비스 자체의 신원을 별도로 증명하지는 못합니다. 실제 운영 확장 시에는 client credentials, 토큰 교환 또는 mTLS를 검토할 수 있습니다.

---

## 대표 문제 해결

### Problem 1. 정상 발급된 JWT가 Resource Server에서 계속 401을 반환했다

**원인**

RS256은 개인키로 서명하고 공개키로 검증해야 합니다. 초기 `JwtProvider`는 검증 단계에도 개인키를 사용해, 발급에는 성공하지만 보호 API에서는 정상 토큰이 거부됐습니다.

**해결**

JWT 디코더가 RSA 공개키를 사용하도록 수정하고 Auth 테스트와 보호 API 스모크 테스트를 다시 수행했습니다.

**결과**

발급과 검증의 키 역할이 분리됐고, 토큰이 없는 요청은 `401`, 정상 토큰은 서비스 보안 체인을 통과하는 흐름을 확인했습니다. 단순히 “JWT를 사용했다”가 아니라 **서명 주체와 검증 주체가 분리되는 비대칭 키 모델**을 장애를 통해 이해했습니다.

### Problem 2. 노출 설정 변경이 차단 상태를 초기화했다

**원인**

Matching의 `updateExposure`가 기존 프로필을 수정하지 않고 새 객체로 교체했습니다. 그 과정에서 요청에 포함되지 않은 `isBlocked`가 기본값으로 돌아가, 한 필드의 변경이 다른 상태를 훼손했습니다.

**해결**

기존 프로필을 조회한 뒤 대상 필드만 변경하는 read-modify-write 방식으로 수정했습니다. `isBlocked = true`인 사용자의 노출 설정을 바꿔도 차단 상태가 유지되는 회귀 테스트를 추가했습니다.

**결과**

업데이트 API는 전달받은 필드만 바꿔야 한다는 불변식을 테스트로 고정했습니다. 모듈 분리뿐 아니라 **한 애그리게이트 안에서 상태 변경의 경계도 명시해야 한다**는 점을 확인했습니다.

### Problem 3. 문서의 아키텍처와 실제 실행 구성이 달랐다

**원인**

README와 Compose에는 일부 모듈만 기재돼 있었고, 사용하지 않는 Redis 설명과 의존성이 남아 있었습니다. 코드만 보면 6개 서비스지만 문서대로 실행하면 같은 구성을 재현할 수 없는 상태였습니다.

**해결**

- 6개 애플리케이션의 역할·포트·라우트를 코드 기준으로 다시 정리했습니다.
- 모든 애플리케이션을 Compose에 포함하고 Gateway만 외부 포트로 공개했습니다.
- 사용하지 않는 Redis·Redisson 의존성과 테스트 대역을 제거했습니다.
- 전체 빌드 후 컨테이너 헬스체크와 주요 공개·보호·내부 경로를 확인했습니다.

**결과**

저장소 설명, 빌드 구성, 실행 환경이 같은 시스템을 가리키게 됐습니다. 포트폴리오에서 아키텍처를 설명하는 것보다 먼저 **다른 사람이 그 설명을 실행으로 검증할 수 있게 만드는 작업**이 필요하다는 기준을 세웠습니다.

---

## Verification

기능 개수를 성과로 포장하지 않고, 현재 저장소에서 반복 확인할 수 있는 항목을 근거로 남겼습니다.

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| 전체 Gradle 빌드 | 6개 애플리케이션 모듈 빌드 및 테스트 통과 |
| Compose 실행 | 6개 애플리케이션과 PostgreSQL 기동, health 상태 확인 |
| Gateway 공개 경로 | `/actuator/health`, `/login.html`, `/oauth2/jwks`, OIDC metadata 응답 확인 |
| 보호 API | 토큰 없이 Task·Admin API 호출 시 `401` 확인 |
| 내부 API 차단 | Gateway를 통한 `/internal/admin/users` 접근 시 `404` 확인 |
| 회귀 테스트 | Matching 6개, Admin 5개 테스트 통과 |

<span class="section-note">위 결과는 기능·경계 검증이며 처리량이나 지연 시간 개선을 의미하지 않습니다. 부하 테스트를 수행하지 않았기 때문에 성능 수치는 포트폴리오 성과로 제시하지 않았습니다.</span>

---

## 현재 한계와 다음 단계

이 프로젝트에서 구현하지 않은 부분도 현재 구조의 일부로 명확히 구분했습니다.

- Matching 상태, Refresh Token, 대기 상태가 메모리에 있어 재시작 시 사라지고 다중 인스턴스가 공유할 수 없습니다.
- 대기실은 실제 순번 큐가 아니라 즉시 `ALLOWED` 상태를 기록하는 기능 검증 수준입니다.
- Auth 재시작 시 RSA 키가 바뀌어 기존 JWT가 무효화됩니다.
- Admin → Matching 호출은 사용자 JWT 전달 방식이며 서비스 전용 신원과 권한은 분리하지 않았습니다.
- 서비스 간 timeout·재시도·오류 매핑과 분산 추적을 구현하지 않았습니다.

다음 단계는 Redis를 “기술 스택에 넣기 위해” 추가하는 것이 아니라, 먼저 공유 상태가 필요한 Matching 또는 Refresh Token 저장소를 영속화하고 다중 인스턴스 테스트로 필요성을 증명하는 것입니다. 이후 서비스 간 인증을 사용자 권한과 서비스 신원으로 분리하고, 실패 전파와 관측 가능성을 보강할 계획입니다.

---

## 무엇을 배웠는가

처음에는 OAuth2 표준과 JWT 발급을 이해하는 것이 목표였습니다. 하지만 모듈이 늘어나면서 더 중요한 질문은 “어떤 기술을 썼는가”보다 **누가 발급하고, 누가 검증하며, 어느 경로를 외부에 공개하고, 실패를 어디서 책임지는가**였습니다.

이 프로젝트를 통해 다음 기준을 얻었습니다.

- 중앙화할 책임과 각 서비스가 소유할 정책을 구분한다.
- 내부 통신도 신뢰하지 않고 서비스 경계마다 권한을 검증한다.
- 문서·코드·실행 환경의 정합성을 기능 완성의 일부로 본다.
- 구현하지 않은 운영 요건과 검증하지 않은 성능을 성과처럼 표현하지 않는다.

---

## Source & Engineering Notes

- [Source Code](https://github.com/hello-pebble/oauth2-authorization)
- [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
- [BUG-001: updateExposure resets isBlocked](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/bug-reports/BUG-001-updateExposure-resets-isBlocked.md)
- [Architecture Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)
