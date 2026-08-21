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
      <strong>Frontend</strong>
      <span>JavaScript, React, Vite</span>
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
  <span class="section-note">개발 도구로 Claude Code·Codex를 사용합니다 — <a href="{{ '/ai/' | relative_url }}">활용 방식 보기</a></span>
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
      <p class="portfolio-summary">버전마다 문제 하나를 정해 v0.17.0까지 릴리스 · "확정 후 수정 불가" 규칙을 프론트 차단 → 서버 가드 → 도구 권한으로 옮겨 구조적으로 불가능하게 만듦 · 육안 판단을 평가 하네스로 바꿔 모델의 권한 우회 경로 발견</p>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · SSE Streaming · Testcontainers</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>Gateway 단일 진입점 인증/인가 검증 <span class="portfolio-period">2026.01–2026.03</span></h3>
      <p class="portfolio-summary">설계마다 대안 비교(A/B/C)와 결정 기록을 남기며 다중 모듈 인증 구조를 구성 · 무토큰 401과 내부 경로 404를 실제 요청으로 확인</p>
      <span class="portfolio-stack">Kotlin · Spring Boot · Spring Security · WebFlux Gateway · JWT · Docker Compose</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/admincore/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>AdminCore — 운영 관리자 콘솔 백엔드 <span class="portfolio-period">2026.06– 진행 중</span></h3>
      <p class="portfolio-summary">사용자 모드를 제거하고 회원·Q&A·알림·매칭 통계에 집중한 관리자 전용 백엔드로 재정의 · 정지 계정의 기존 JWT를 다음 요청부터 차단 · 통계는 PostgreSQL GROUP BY 집계와 60초 캐시, 만료 배치 시점 무효화를 적용</p>
      <span class="portfolio-stack">Java 21 · Spring Boot 4 · PostgreSQL · JPA · Flyway · Spring Security/JWT</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="company-projects">
  <div class="portfolio-section-heading">
    <h2 id="company-projects">Work Experience</h2>
    <span class="portfolio-count">5 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/api-management/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">04</span>
      </div>
      <h3>개방DB API관리 — 메타데이터 기반 조회 API 엔진 <span class="portfolio-period">2024.09–2025.01</span></h3>
      <p class="portfolio-summary">요구사항마다 파일 5~6개를 추가하던 조회 개발을 메타데이터 등록 1건으로 바꾸는 엔진을 설계 · 개발 서버 적용 후 이직해 <strong>검증하지 못한 구조를 개인 프로젝트 api-forge(2026.07–)로 클린룸 재구현</strong>해, 인젝션 차단이 DB 방언과 무관하게 성립하는지 매 커밋 CI로 확인</p>
      <span class="portfolio-stack">Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero → 재구현 Java 21 · jOOQ</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/pms/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>공정 관리 솔루션(PMS) <span class="portfolio-period">2022.11–2024.12</span></h3>
      <p class="portfolio-summary">라벨링 저장 유실을 개별 커밋으로 인한 부분 커밋으로 진단해 프레임 단위 저장으로 전환 · 3D 중복 저장은 2D와의 경로 비교로 누락된 정리 호출을 찾아 해소</p>
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
      <p class="portfolio-summary">화면 분기로 흩어진 권한 검증을 SSO 기반 RBAC와 공통 인터셉터로 모아 엔드포인트 레벨에서 차단 · 사내 보관 요건으로 BLOB 저장이 전제된 상태에서 파일 변경을 업무 데이터와 같은 트랜잭션에 묶어 구현</p>
      <span class="portfolio-stack">Java · Spring Boot · JPA · Oracle</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/port-fee/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">08</span>
      </div>
      <h3>항만 시설 사용료 관리 시스템 <span class="portfolio-period">2019.05–2020.07</span></h3>
      <p class="portfolio-summary">여수광양항만공사 GIS 기반 시스템에서 매년 개정되는 연도별·임시 세율을 코드가 아닌 데이터로 분리해 관리 · 월 1회 현장 방문으로 서버를 점검하며 담당자 요청을 직접 받아 반영</p>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · Oracle</span>
    </a>
  </div>
</section>
