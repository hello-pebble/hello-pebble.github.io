---
layout: default
title: "포트폴리오"
permalink: /portfolio/
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">portfolio</span>
</header>

<section class="portfolio-section" aria-labelledby="technical-skills">
  <div class="portfolio-section-heading">
    <h2 id="technical-skills">Tech Stack</h2>
  </div>
  <div class="portfolio-skill-list">
    <div class="portfolio-skill-row">
      <strong>Backend</strong>
      <span>Java, Python · Spring Boot, Security, JPA, MyBatis, JUnit</span>
    </div>
    <div class="portfolio-skill-row">
      <strong>Data</strong>
      <span>MariaDB, Oracle</span>
    </div>
    <div class="portfolio-skill-row">
      <strong>Infra</strong>
      <span>Docker, GitLab CI/CD, Tomcat, WildFly</span>
    </div>
    <div class="portfolio-skill-row">
      <strong>Frontend & AI</strong>
      <span>JavaScript, React, Vite · OpenRouter API 연동 · <a href="{{ '/ai/' | relative_url }}">AI 활용 상세</a></span>
    </div>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="personal-projects">
  <div class="portfolio-section-heading">
    <h2 id="personal-projects">Personal Projects</h2>
    <span class="portfolio-count">3 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/matchsimulation-backend/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">01</span>
      </div>
      <h3>MatchSimulation — 매칭 서비스 백엔드 <span class="portfolio-period">2026.06– 진행 중</span></h3>
      <p class="portfolio-summary">추천 엔진·DB·인증을 나중에 교체할 수 있도록 경계를 먼저 설계 · 전체 API 스모크 확인</p>
      <span class="portfolio-stack">Java 21 · Spring Boot 4 · Spring Data JPA · H2 · Gradle</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/delaynomore/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>DelayNoMore <span class="portfolio-period">2026.04–2026.06</span></h3>
      <p class="portfolio-summary">계획 수정을 차단하는 잠금 모델과 AI 코치를 기획부터 배포까지 단독 구현 · SSE 스트리밍으로 20~30초 대기 이탈 구간 해소</p>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · OpenRouter</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso-backend/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>Gateway 단일 진입점 인증/인가 검증 <span class="portfolio-period">2026.01–2026.03</span></h3>
      <p class="portfolio-summary">단일 진입점 뒤 공개·보호·내부 경로의 응답 분리를 설계 · 무토큰 401과 내부 경로 404를 실제 요청으로 확인</p>
      <span class="portfolio-stack">Kotlin · Spring Boot · Spring Security · Gateway · Docker Compose</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="company-projects">
  <div class="portfolio-section-heading">
    <h2 id="company-projects">Work Experience</h2>
    <span class="portfolio-count">4 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/db-management-system/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">04</span>
      </div>
      <h3>개방DB 관리 시스템 <span class="portfolio-period">2024.09–2025.01</span></h3>
      <p class="portfolio-summary">요구사항마다 조회 API를 반복 개발하던 하드코딩 구조를 메타데이터 기반으로 재설계 · 로컬에서 설정만으로 조회 API 생성 확인 <em>(프로토타입 · 운영 반영 전)</em></p>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · MariaDB</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/process-management-solution/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>공정 관리 솔루션(PMS) <span class="portfolio-period">2022.11–2024.12</span></h3>
      <p class="portfolio-summary">담당자에게 의존하던 수동 배포·장애 대응을 Docker와 GitLab CI/CD로 표준화 · 배포 인적 오류 제거와 반복 운영 문의 감소</p>
      <span class="portfolio-stack">Java · Spring Boot · Docker · GitLab CI</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/gov-document-ai-data-service/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">06</span>
      </div>
      <h3>정부 공문서 AI 조회 서비스 <span class="portfolio-period">2023.08–2024.02</span></h3>
      <p class="portfolio-summary">폐쇄망에서 ProcessBuilder 기반 Java–Python 브릿지로 HWP 문서 파싱 자동화 · 시범 사업 납품 완수</p>
      <span class="portfolio-stack">Java · Spring MVC · Python · MariaDB</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/learning-management-system/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">07</span>
      </div>
      <h3>사내 교육 플랫폼(LMS) <span class="portfolio-period">2020.12–2021.03</span></h3>
      <p class="portfolio-summary">다부서 교육 플랫폼의 비인가 접근·첨부파일 유실 위험을 SSO 기반 RBAC와 BLOB 저장으로 해결 · 파일과 업무 데이터를 단일 트랜잭션으로 관리</p>
      <span class="portfolio-stack">Java · Spring Boot · JPA · Oracle</span>
    </a>
  </div>
</section>
