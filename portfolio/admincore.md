---
layout: default
title: "AdminCore — 운영 관리자 콘솔 백엔드"
permalink: /portfolio/admincore/
category: portfolio
tags: [Java21, SpringBoot4, PostgreSQL, JPA, Flyway, SpringSecurity, JWT]
---

<span class="project-context">개인 프로젝트 · 2026.06 — 진행 중 · Java 21 · Spring Boot 4.1 · PostgreSQL · JPA · Flyway · Spring Security/JWT</span>

# AdminCore — 운영 관리자 콘솔 백엔드

- **서비스** 회원 관리, Q&A 답변, 알림 발송, 매칭 통계를 하나의 관리자 API와 콘솔로 제공하는 운영 관리자 전용 백엔드입니다.
- **범위** 사용자 대면 기능은 포함하지 않습니다. `admin`을 단일 API 진입점으로 두고 실제 규칙은 `user`·`qna`·`notification`·`matching` 모듈이 소유합니다.
- **검증 환경** PostgreSQL 17을 Docker로 실행하고, Flyway 마이그레이션과 `ddl-auto=validate`로 애플리케이션 모델과 스키마의 불일치를 확인합니다.

![AdminCore 관리자 콘솔의 매칭 현황 통계 — 전체·성사 건수와 성사율, 일별·성별·상태별 매칭 분포](/assets/images/portfolio/matchsimulation-admin-stats.png){:.portfolio-hero-shot}

| 기능 | 처리 |
| :--- | :--- |
| **회원 관리** | 페이징 목록 조회, `PENDING`·`ACTIVE`·`SUSPENDED` 상태 변경 |
| **Q&A 관리** | 전체·상태별 문의 조회, 관리자 답변과 답변 시각 기록 |
| **알림** | 전체 공지 또는 개별 회원 알림 생성, 발송 이력 조회 |
| **매칭 통계** | 상태·성별·일별 DB 집계, 전체·성사 건수와 성사율 계산 |
| **운영 배치** | 7일 무응답 매칭을 `EXPIRED`로 변경하고 요청자 알림 생성 |

## 01. 정지 계정의 기존 JWT도 다음 요청부터 차단 {#suspended}

JWT 서명과 만료 시각이 유효하더라도, 토큰 발급 후 계정이 정지될 수 있습니다. 로그인할 때만 상태를 확인하면 정지 전에 발급된 토큰은 만료될 때까지 보호 API를 계속 호출할 수 있습니다.

{% include diagrams/matchsim-suspended-decision.svg %}

- `JwtAuthFilter`가 토큰 서명을 검증한 뒤 현재 사용자 상태를 다시 조회합니다.
- 계정이 `SUSPENDED`이면 인증 객체를 만들지 않고 `401`로 차단합니다.
- 요청마다 사용자 조회가 추가되어 JWT의 stateless 장점을 일부 포기하지만, 관리자 정지가 다음 요청부터 실제로 적용되는 쪽을 선택했습니다.
- 관리자 API는 `/api/admin/** → hasRole('ADMIN')` 규칙으로 묶어 일반 회원 토큰을 `403`으로 거부합니다.

## 02. 상태 변경과 알림의 트랜잭션 경계 {#transaction}

회원을 승인하거나 정지하면 대상 회원에게 알림도 생성합니다. 두 변경을 하나의 트랜잭션으로 처리해 알림 저장이 실패하면 회원 상태 변경도 롤백되게 했습니다.

- 같은 상태를 다시 요청하면 알림을 중복 생성하지 않습니다.
- 현재는 DB 내부 알림이므로 강한 일관성을 선택했습니다.
- 메일·푸시 같은 외부 채널이 추가되면 외부 장애가 상태 변경을 막지 않도록 이벤트와 재시도 구조로 분리해야 합니다.

## 03. 통계 계산을 애플리케이션이 아닌 DB에 맡김 {#stats}

통계 조회 시 전체 행을 애플리케이션으로 가져오지 않고 PostgreSQL에서 집계합니다.

| 통계 | 처리 |
| :--- | :--- |
| **상태별** | `GROUP BY status` |
| **성별** | 요청자와 `LEFT JOIN` 후 `GROUP BY gender`; 삭제된 요청자는 `UNKNOWN` |
| **일별** | 생성 시각을 날짜로 변환해 `GROUP BY` |
| **전체·성사·성사율** | 상태별 집계 결과에서 파생해 추가 쿼리를 만들지 않음 |

- 통계 1회는 집계 쿼리 3개로 처리합니다.
- 반복 조회는 Caffeine의 60초 TTL 캐시로 줄입니다.
- 현재 매칭 상태를 변경하는 유일한 경로인 만료 배치 실행 시 캐시를 즉시 비웁니다.
- 인메모리 캐시이므로 다중 인스턴스에서는 노드별 값이 달라질 수 있습니다. 현재는 단일 인스턴스 전제입니다.

## 04. 운영 입력도 신뢰하지 않음 {#validation}

- 회원·문의 목록의 `size`는 최대 100으로 제한합니다.
- 허용하지 않은 정렬 필드는 `400`으로 거부합니다.
- 관리자 권한이 없으면 `/api/admin/**`에 진입할 수 없습니다.
- 정지 계정의 기존 토큰, 일반 회원의 관리자 API 접근, 알림 실패 시 롤백, 자동 만료 후 통계 반영을 테스트로 확인합니다.

## 한계와 다음 작업 {#limitations}

- 누가 언제 어떤 회원 상태를 바꿨는지 남기는 감사 로그가 없습니다.
- 관리자 역할이 `ADMIN` 하나라 회원 관리·문의 답변·공지 권한을 세분화하지 못합니다.
- 통계 캐시는 단일 인스턴스에만 유효하며 실행 계획과 쿼리 지연을 지속 관측하지 않습니다.
- 검증은 로컬 시드 데이터 기반이며 실제 운영 트래픽을 측정한 결과가 아닙니다.

## Source

- [github.com/hello-pebble/AdminCore](https://github.com/hello-pebble/AdminCore) — 소스 코드
- [docs/admin_mode.md](https://github.com/hello-pebble/AdminCore/blob/main/docs/admin_mode.md) — 기능·API·콘솔 시나리오
- [docs/architecture.md](https://github.com/hello-pebble/AdminCore/blob/main/docs/architecture.md) — 모듈 구조·통계 집계·인증 흐름
