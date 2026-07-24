---
layout: default
title: "실행 검증과 현재 한계"
permalink: /portfolio/oauth-sso-backend/03-verification/
category: portfolio
tags: [DockerCompose, Testing, JWT, Troubleshooting, MSA]
---

<span class="project-context">기능별 변경 경계를 분리한 MSA · 03</span>

# 실행 검증과 현재 한계

- 문서·소스·Compose가 같은 6개 애플리케이션 구조를 설명하도록 정리
- 전체 빌드, 통합 기동, 보호·내부 경로의 실제 응답을 기준으로 검증

{% include oauth-project-nav.html %}

## 검증 결과

| 검증 항목 | 확인 결과 |
| :--- | :--- |
| **모듈별 빌드** | 6개 애플리케이션 모듈 빌드 및 전체 테스트 통과 |
| **통합 실행** | 6개 애플리케이션과 PostgreSQL을 Compose로 기동하고 health 확인 |
| **단일 진입점** | Gateway에서 로그인 화면, JWKS, OIDC metadata 접근 확인 |
| **서비스별 인증** | 토큰 없이 Task·Admin API 호출 시 `401` 확인 |
| **내부 경로 분리** | Gateway를 통한 `/internal/admin/users` 접근 시 `404` 확인 |
| **서비스 간 통신** | Admin이 JWT를 전달해 Matching 관리자 API를 호출하는 흐름 구성 |

## 정상 JWT가 Resource Server에서 401을 반환했다

RS256은 개인키로 서명하고 공개키로 검증해야 합니다. 초기 `JwtProvider`는 검증에도 개인키를 사용해 토큰 발급에는 성공하지만 보호 API에서는 정상 토큰이 거부됐습니다.

JWT 디코더가 RSA 공개키를 사용하도록 수정하고 Auth 테스트와 보호 API 스모크 테스트를 다시 수행했습니다. 이를 통해 발급 주체와 검증 주체가 분리된 비대칭 키 모델을 코드와 실제 요청으로 확인했습니다.

## 문서와 실행 환경의 구성이 달랐다

README와 Compose에는 일부 모듈만 기재돼 있었고 실제로 사용하지 않는 Redis 설명과 의존성이 남아 있었습니다. 코드에는 6개 애플리케이션이 있지만 문서대로는 같은 구성을 실행할 수 없었습니다.

다음 항목을 코드 기준으로 정리했습니다.

- 6개 애플리케이션의 역할·포트·라우트
- 모든 애플리케이션을 포함한 Compose 구성
- Gateway만 외부에 공개하는 포트 정책
- 사용하지 않는 Redis·Redisson 의존성과 테스트 대역 제거

소스 코드, 문서, 실행 환경이 동일한 모듈 경계를 설명하도록 맞추고 전체 구성을 다시 기동했습니다.

## 현재 한계

- 하나의 저장소를 사용하므로 모듈별 소스 접근 권한은 분리되지 않습니다.
- 모듈별 독립 배포 파이프라인과 버전 정책은 구성하지 않았습니다.
- Matching 상태, Refresh Token, 대기 상태가 메모리에 있어 재시작 시 사라지고 여러 인스턴스가 공유할 수 없습니다.
- 대기실은 실제 순번 큐가 아니라 즉시 `ALLOWED` 상태를 기록하는 기능 검증 수준입니다.
- 서비스 간 timeout·재시도·오류 매핑과 분산 추적을 구현하지 않았습니다.
- 팀 프로젝트에 적용해 Merge Conflict 감소율, 배포 시간, 원복 시간을 측정하지 않았습니다.

## 다음 단계

1. 모듈별 변경이 독립적인 빌드와 배포로 이어지도록 CI/CD 경계를 나눕니다.
2. 공유 상태가 필요한 기능부터 영속 저장소와 다중 인스턴스 검증을 추가합니다.
3. 사용자 권한과 서비스 신원을 분리하고 서비스 간 실패 전파와 관측 가능성을 보강합니다.

## Engineering Notes

- [Harness Engineering Note](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/engineering/2026-05-10-harness-engineering.md)
- [Architecture Decision Log](https://github.com/hello-pebble/oauth2-authorization/blob/main/docs/DECISION_LOG_WHY.md)
- [Source Code](https://github.com/hello-pebble/oauth2-authorization)
