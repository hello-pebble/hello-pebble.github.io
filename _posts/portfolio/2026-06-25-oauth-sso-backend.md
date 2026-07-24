---
layout: default
title: "기능별 변경 경계를 분리하고 Gateway로 통합한 MSA 백엔드"
permalink: /portfolio/oauth-sso-backend/
category: portfolio
tags: [Kotlin, SpringBoot, SpringSecurity, OAuth2, JWT, MSA, DockerCompose]
---

<span class="project-context">개인 프로젝트 · 2026.05 — 2026.07</span>

# 기능별 변경 경계를 분리하고 Gateway로 통합한 MSA 백엔드

- PMS 운영에서 경험한 코드 혼재·변경 충돌·계정 API 결합 문제에서 출발
- 6개 실행 모듈과 Gateway 단일 진입점, JWT 중앙 발급·분산 검증 구조 구현

{% include oauth-project-nav.html %}

## 배경

PMS 서비스를 운영할 때 신규 기능을 Docker 컨테이너로 추가하고 기존 서비스의 API를 호출해 계정 정보를 확인했습니다. 초기에는 빠르게 기능을 붙일 수 있었지만, 기능이 누적될수록 컨테이너에 사용하지 않는 코드와 의존성이 함께 포함됐습니다.

팀원에게 기능을 나눠도 수정 지점이 겹쳐 Merge Conflict와 원복 부담이 커졌고, 기능 컨테이너는 계정 확인을 위해 기존 PMS API에 계속 의존했습니다.

> 컨테이너는 나뉘었지만 코드·변경·인증 책임의 경계는 나뉘지 않았습니다.

이 경험을 바탕으로 다음 구조를 검증했습니다.

- 함께 변경되는 기능을 독립 모듈로 제한
- 분리된 서비스는 Gateway에서 하나의 진입점으로 통합
- 사용자 신원은 Auth가 발급하고 각 서비스가 독립적으로 검증

## 전체 구조

![기능별 변경 경계와 통합 접근 구조](/assets/images/portfolio/oauth-architecture.svg)

| 설계 판단 | 적용 방식 |
| :--- | :--- |
| **변경 경계 분리** | Auth, Matching, Task, Preview, Admin이 자신의 기능 코드와 정책을 소유 |
| **통합 접근** | Gateway만 외부에 공개하고 경로에 따라 내부 서비스로 라우팅 |
| **인증 책임 분리** | Auth가 JWT를 발급하고 Matching·Task·Admin이 JWKS 공개키로 검증 |
| **실행 재현** | 6개 애플리케이션과 PostgreSQL을 Docker Compose로 함께 기동 |

## 확인한 결과

- 6개 애플리케이션을 모듈별로 빌드하고 하나의 Compose 환경에서 기동했습니다.
- 토큰 없이 보호 API를 호출하면 `401`, Gateway를 통한 내부 API 접근은 `404`가 반환되는 것을 확인했습니다.
- Admin이 사용자 JWT를 전달해 Matching의 관리자 API를 호출하고 양쪽 서비스가 권한을 검증하도록 구성했습니다.

<span class="section-note">실제 팀 프로젝트에 적용해 Merge Conflict 감소율이나 원복 시간 개선을 측정한 결과는 아닙니다. 변경·빌드·실행 경계를 분리하고 통합 접근할 수 있는지 확인한 아키텍처 실험입니다.</span>

## 상세 내용

아래 페이지에서 각 설계 질문과 검증 범위를 나눠 설명합니다.

- [01. 컨테이너 분리에서 변경 경계 분리로](/portfolio/oauth-sso-backend/01-module-boundaries/)
- [02. Gateway 통합 접근과 분산 인증](/portfolio/oauth-sso-backend/02-gateway-auth/)
- [03. 실행 검증과 현재 한계](/portfolio/oauth-sso-backend/03-verification/)

## Source

- [github.com/hello-pebble/oauth2-authorization](https://github.com/hello-pebble/oauth2-authorization)
