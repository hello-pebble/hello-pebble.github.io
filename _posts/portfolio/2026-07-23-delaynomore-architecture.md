---
layout: default
title: "DelayNoMore — 배포 & 인프라"
permalink: /portfolio/1/architecture/
category: portfolio
tags: [SpringBoot, Docker, CI/CD, OracleCloud, Portfolio]
---

# 배포 &amp; 인프라 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> 프론트엔드·백엔드·AI 프록시를 **하나의 컨테이너**로 묶고, **빌드는 CI에서 한 번만** 수행해 VM은 이미지를 받아 실행만 하도록 설계했습니다. 저사양 무료 VM(Oracle Cloud Always Free)에서도 흔들리지 않고 돌아가게 만드는 것이 목표였습니다.

---

## 단일 컨테이너 풀스택 구성

![시스템 아키텍처](/assets/images/portfolio/delaynomore-architecture.svg)

- **단일 서빙**: Spring Boot가 빌드된 React(Vite) 정적 파일과 `/api/*`를 함께 서빙합니다. 루트 `Dockerfile` 하나로 컨테이너가 완성되어 프론트/백엔드를 따로 배포·정렬할 필요가 없습니다.
- **AI 프록시**: 브라우저는 OpenRouter를 직접 부르지 않습니다. 서버가 프록시로 중계해 **API 키를 서버에만 보관**하고, 프롬프트 조립·응답 정제·SSE 릴레이를 서버가 소유합니다.

---

## 배포 파이프라인 — 빌드 1회, 어디서든 Pull

![배포 파이프라인](/assets/images/portfolio/delaynomore-deploy.svg)

- **Pull 방식 배포**: `main` 푸시/`v*` 태그마다 GitHub Actions가 Docker 이미지를 빌드해 `ghcr.io`에 push하고, VM은 **빌드하지 않고 이미지를 받아 실행**만 합니다. 1GB Micro 같은 저사양 VM이 빌드로 마비되던 문제를 근본적으로 해결했습니다.
- **런타임 방어**: JVM 힙 상한(`-XX:MaxRAMPercentage=50`)을 걸어 작은 VM에서 OOM을 방지했습니다.
- **프로필 전환**: 같은 이미지가 환경변수만으로 **인메모리(휘발성)** 또는 **PostgreSQL(영속)** 모드로 기동합니다. `DB_URL`을 주면 `SPRING_PROFILES_ACTIVE=postgres`로 켜지고, 없으면 인메모리로 동작해 데모·롤백 경로가 유지됩니다.
- **키 관리**: 배포 스크립트가 `~/.delaynomore.env`(chmod 600)를 자동 로드해, API 키를 최초 1회만 파일로 저장하면 이후 배포에서 셸 히스토리에 키가 남지 않습니다.
- **DB 접속**: Supabase는 세션 풀러(포트 5432, `sslmode=require`) 문자열을 사용합니다(트랜잭션 풀러 6543은 Flyway 세션 기능 미지원이라 배제).

---

## 시간대(KST) 결함 해결

배포 컨테이너 JVM 기본 시간대(UTC)에서 `LocalDate.now()`를 쓰면 한국 사용자의 자정~오전 9시 요청이 **하루 이르게** 처리되는 결함이 있었습니다. `global/time/KstDates`를 신설해 프롬프트 대상 날짜·초안 시작 날짜·회고의 "오늘" 판정이 모두 **같은 `Asia/Seoul` 기준**을 공유하도록 통일했습니다.

---

## 스택 요약

| 레이어 | 기술 |
| :--- | :--- |
| 프론트엔드 | React · Vite (SPA, 단일 번들 44.53kB) |
| 백엔드 | Spring Boot 4 · Java 21 · REST `/api/v1` · SSE |
| AI | OpenRouter LLM 프록시 (키 서버 보관) |
| 데이터 | PostgreSQL (Supabase) · Flyway · JSONB |
| 인프라 | Docker 단일 컨테이너 · GitHub Actions · Oracle Cloud |

---

> **💬 면접에서 더 깊게 이야기할 수 있는 주제**
> - 왜 프론트·백엔드를 단일 컨테이너로 묶었는가 — 얻은 것과 잃은 것
> - VM에서 빌드하지 않고 이미지를 Pull하도록 바꾼 이유(저사양 환경 대응)
> - 같은 이미지를 프로필 전환으로 휘발/영속 두 모드로 운영해 얻은 이점
> - 무료 VM에서 JVM 메모리를 어떻게 방어했는가

---

<span class="section-note">관련: [백엔드 설계]({{ '/portfolio/1/backend/' | relative_url }}) · [데이터 & 동시성]({{ '/portfolio/1/persistence/' | relative_url }}) · [AI 통합 & 토큰 절약]({{ '/portfolio/1/ai-engineering/' | relative_url }})</span>
