---
layout: default
title: "portfolio"
permalink: /portfolio/
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">portfolio</span>
</header>

<span class="section-note">모든 개인 프로젝트는 소스 코드와 함께 의사결정 기록(Decision Log · 계획서/보고서 · CHANGELOG)을 공개합니다.</span>

<section class="portfolio-section" aria-labelledby="technical-skills">
  <div class="portfolio-section-heading">
    <h2 id="technical-skills">Tech Stack</h2>
  </div>
  <div class="portfolio-skill-list">
    <div class="portfolio-skill-row">
      <strong>Backend</strong>
      <span>Java, Kotlin, Python, Spring Boot, Security, JPA, MyBatis, JUnit 5, Testcontainers</span>
    </div>
    <div class="portfolio-skill-row">
      <strong>Frontend & AI</strong>
      <span>JavaScript, React, Vite, ClaudeCode, Codex <a href="{{ '/ai/' | relative_url }}">AI 활용 </a></span>
    </div>    
    <div class="portfolio-skill-row">
      <strong>Data</strong>
      <span>MariaDB, Oracle, PostgreSQL</span>
    </div>
    <div class="portfolio-skill-row">
      <strong>Infra</strong>
      <span>Docker, Oracle Cloud Infrastructure(OCI), GitHub Actions, GitLab CI, Tomcat</span>
    </div>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="personal-projects">
  <div class="portfolio-section-heading">
    <h2 id="personal-projects">Personal Projects</h2>
    <span class="portfolio-count">3 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/delaynomore/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">01</span>
      </div>
      <h3>DelayNoMore <span class="portfolio-period">2026.04–2026.06</span></h3>
      <p class="portfolio-summary">버전마다 문제 하나를 정해 v0.17.0까지 릴리스 · 잠금 규칙의 소유권을 서버로 이관하고, 에이전트 도구 선택 정확도를 평가 하네스 676회 실측으로 검증 · 테스트 317건</p>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · SSE Streaming · Testcontainers</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>Gateway 단일 진입점 인증/인가 검증 <span class="portfolio-period">2026.01–2026.03</span></h3>
      <p class="portfolio-summary">설계마다 대안 비교(A/B/C)와 결정 기록을 남기며 6개 모듈 인증 구조를 구성 · 무토큰 401과 내부 경로 404를 실제 요청으로 확인</p>
      <span class="portfolio-stack">Kotlin · Spring Boot · Spring Security · WebFlux Gateway · JWT · Docker Compose</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/matchsimulation/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>MatchSimulation — 매칭 서비스 백엔드 <span class="portfolio-period">2026.06– 진행 중</span></h3>
      <p class="portfolio-summary">교체 가능한 경계를 먼저 설계하고 더미 인증→JWT, 자동 스키마→Flyway로 실제 교체 검증 · 채팅 수신을 폴링→WebSocket 4단계로 실측하며 진화(push 지연 9ms)</p>
      <span class="portfolio-stack">Java 21 · Spring Boot 4 · JPA · Flyway · Long Polling · WebSocket</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="company-projects">
  <div class="portfolio-section-heading">
    <h2 id="company-projects">Work Experience</h2>
    <span class="portfolio-count">4 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/api-management/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">04</span>
      </div>
      <h3>개방DB 관리 시스템 <span class="portfolio-period">2024.09–2025.01</span></h3>
      <p class="portfolio-summary">요구사항마다 조회 API를 반복 개발하던 하드코딩 구조를 메타데이터 기반으로 재설계 · 핵심 구조를 공개 저장소(api-forge)로 재구현해 테스트 50건으로 검증 <em>(프로토타입 · 운영 반영 전)</em></p>
      <span class="portfolio-stack">Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/pms/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>공정 관리 솔루션(PMS) <span class="portfolio-period">2022.11–2024.12</span></h3>
      <p class="portfolio-summary">AI 학습데이터 라벨링 작업의 원격 운영 환경 구성 · Docker Compose와 GitLab CI 이미지 빌드, 수동 배포·로그 기반 장애 대응 절차 문서화</p>
      <span class="portfolio-stack">Java · Spring Boot · Docker · GitLab CI</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/gov-data-service/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">06</span>
      </div>
      <h3>정부 공문서 AI 조회 서비스 <span class="portfolio-period">2023.08–2024.02</span></h3>
      <p class="portfolio-summary">폐쇄망에서 ProcessBuilder 기반 Java–Python 브릿지로 HWP 문서 파싱 자동화 · 시범 사업 납품 완수</p>
      <span class="portfolio-stack">Java · Spring MVC · Python · MariaDB</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/lms/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">07</span>
      </div>
      <h3>사내 교육 플랫폼(LMS) <span class="portfolio-period">2020.12–2021.03</span></h3>
      <p class="portfolio-summary">다부서 교육 플랫폼의 비인가 접근·첨부파일 유실 위험을 SSO 기반 RBAC와 BLOB 저장으로 해결 · 파일과 업무 데이터를 단일 트랜잭션으로 관리</p>
      <span class="portfolio-stack">Java · Spring Boot · JPA · Oracle</span>
    </a>
  </div>
</section>
