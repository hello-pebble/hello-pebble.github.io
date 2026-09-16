---
layout: default
title: "portfolio"
permalink: /portfolio/
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">portfolio</span>
</header>

<span class="section-note">프로젝트별 구현 범위와 검증한 범위를 구분해 공개합니다. 개인 프로젝트는 소스 코드와 의사결정 기록(Decision Log · 계획서/보고서 · CHANGELOG)을 함께 확인할 수 있습니다.</span>

<section class="portfolio-section" aria-labelledby="company-projects">
  <div class="portfolio-section-heading">
    <h2 id="company-projects">Work Experience</h2>
    <span class="portfolio-count">5 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/pms/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">01</span>
      </div>
      <h3>공정 관리 솔루션(PMS) <span class="portfolio-period">2022.11–2024.12</span></h3>
      <p class="portfolio-summary">AI 학습데이터 공정 관리 시스템을 26개월간 개발·운영하며 저장 유실 원인 3건을 분석·조치 · 화면별 매뉴얼·인계 절차를 정비해 사용자 문의를 월 20건에서 1~2건으로 개선</p>
      <span class="portfolio-stack">Java · Spring Boot · MyBatis · MariaDB · Docker · GitLab CI · Nginx</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/api-management/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>개방DB API관리 — 메타데이터 기반 조회 API 엔진 <span class="portfolio-period">2024.09–2025.01</span></h3>
      <p class="portfolio-summary">조회 API마다 파일 5~6개를 추가하던 구조를 메타데이터 등록 1건으로 바꾸는 엔진을 설계·개발 서버에 적용 · 핵심 설계는 개인 재구현 api-forge에서 H2·PostgreSQL 양쪽의 인젝션 차단 시나리오로 검증</p>
      <span class="portfolio-stack">Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero · jOOQ · Testcontainers</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/lms/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>사내 교육 플랫폼(LMS) <span class="portfolio-period">2020.12–2021.03</span></h3>
      <p class="portfolio-summary">화면별로 흩어진 권한 검증을 SSO 기반 RBAC와 공통 인터셉터로 통합해 엔드포인트 레벨에서 차단 · Oracle BLOB 파일 저장을 비즈니스 데이터와 같은 트랜잭션으로 구현</p>
      <span class="portfolio-stack">Java · Spring Boot · Spring Security · JPA · Oracle · SSO</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/gov-data-service/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">04</span>
      </div>
      <h3>정부 공문서 학습데이터 조회 서비스 <span class="portfolio-period">2023.08–2024.02</span></h3>
      <p class="portfolio-summary">폐쇄망에서 ProcessBuilder 기반 Java–Python 브릿지로 HWP 문서 파싱 자동화 · 파일 입력부터 DB 저장까지의 수동 등록 절차를 하나의 처리 흐름으로 묶어 시범 사업 납품 완료</p>
      <span class="portfolio-stack">Java · Spring MVC · Python · WildFly · MariaDB</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/port-fee/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>항만 시설 사용료 관리 시스템 <span class="portfolio-period">2019.05–2020.07</span></h3>
      <p class="portfolio-summary">여수광양항만공사 GIS 기반 시스템에서 연도별·임시 세율을 코드가 아닌 데이터로 분리해 관리 · 월 1회 현장 방문으로 서버를 점검하며 담당자 요청을 직접 받아 반영</p>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · Oracle</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="personal-projects">
  <div class="portfolio-section-heading">
    <h2 id="personal-projects">Personal Projects</h2>
    <span class="portfolio-count">4 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/delaynomore/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">06</span>
      </div>
      <h3>DelayNoMore <span class="portfolio-period">2026.04– 진행 중</span></h3>
      <p class="portfolio-summary">확정 계획의 수정 규칙을 프론트 차단 → 서버 가드 → 도구 권한으로 옮겨 우회 경로를 구조적으로 차단 · AI 응답 품질은 반복 실행 가능한 평가 하네스로 측정</p>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · SSE Streaming · Testcontainers</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">07</span>
      </div>
      <h3>Gateway 단일 진입점 인증/인가 검증 <span class="portfolio-period">2026.01–2026.03</span></h3>
      <p class="portfolio-summary">다중 모듈 인증 구조의 대안을 비교·결정하고, 무토큰 401·내부 경로 404·서비스별 권한 검증을 실제 요청으로 확인</p>
      <span class="portfolio-stack">Kotlin · Spring Boot · Spring Security · WebFlux Gateway · JWT · Docker Compose</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/admincore/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">08</span>
      </div>
      <h3>AdminCore — 운영 관리자 콘솔 백엔드 <span class="portfolio-period">2026.06– 진행 중</span></h3>
      <p class="portfolio-summary">회원·Q&A·알림·매칭 통계에 집중한 관리자 전용 백엔드 · 정지 계정의 기존 JWT를 다음 요청부터 차단하고 PostgreSQL 집계 결과를 캐시로 관리</p>
      <span class="portfolio-stack">Java 21 · Spring Boot 4 · PostgreSQL · JPA · Flyway · Spring Security/JWT</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/backoffice-ai/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">09</span>
      </div>
      <h3>Backoffice AI — 업무·콘텐츠 자동화 운영 플랫폼 <span class="portfolio-period">2026.08– 진행 중</span></h3>
      <p class="portfolio-summary">화면·API·자동화 워커를 분리 배포하고, 긴 작업을 요청 경로 밖으로 위임 · 단일 실행 잠금과 검토 전 발행 차단으로 자동화의 운영 경계를 설계</p>
      <span class="portfolio-stack">Kotlin · Spring Boot · Python · FastAPI · PostgreSQL/Supabase · Vercel · Railway · Docker</span>
    </a>

  </div>
</section>
