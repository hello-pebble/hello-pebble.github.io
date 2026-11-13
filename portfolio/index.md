---
layout: default
title: "권다경, 백엔드 개발자"
permalink: /
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">portfolio</span>
  <h1>권다경, 백엔드 개발자</h1>
  <p>Java, Spring 실무 3년 10개월. 운영 중인 시스템의 반복 비용을 줄이는 일을 해 왔습니다. 프로젝트마다 구현한 범위, 검증한 범위, 확인하지 못한 범위를 구분해 적었습니다.</p>
  <p class="portfolio-links"><a href="{{ '/resume/' | relative_url }}">이력서</a><a href="{{ '/resume/career-description/' | relative_url }}">경력기술서</a><a href="https://github.com/hello-pebble" target="_blank" rel="noopener noreferrer">GitHub</a></p>
</header>

<section class="portfolio-section" aria-labelledby="lead-projects">
  <div class="portfolio-section-heading">
    <h2 id="lead-projects">대표 프로젝트</h2>
    <span class="portfolio-count">3 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card portfolio-card--lead" href="{{ '/portfolio/api-management/' | relative_url }}">
      <h3>개방DB API관리: 메타데이터 기반 조회 API 엔진 <span class="portfolio-period">회사 / 2024.09–2025.01</span></h3>
      <p class="portfolio-summary">앞으로 들어올 프로젝트에서 쓸 기본 틀로 리팩토링하고, 조회 API 엔진을 설계해 개발 서버에 적용했습니다. 쓰지 않던 함수와 중복 모듈을 덜어냈고, 파일 5~6개(작성자 경험 기준)를 쓰던 조회 API 추가는 데이터셋 등록으로 바뀝니다.</p>
      <p class="portfolio-meta">회사: 개발 서버까지, 운영 반영과 실트래픽은 미검증 / api-forge: 쿼리 조합 부분의 단위 및 통합 테스트와 CI</p>
      <span class="portfolio-stack">회사 Java 8, Spring MVC, eGovFrame, MyBatis, MariaDB / 재구현 Java 21, jOOQ, Testcontainers</span>
    </a>
    <a class="portfolio-card portfolio-card--lead" href="{{ '/portfolio/pms/' | relative_url }}">
      <h3>공정 관리 솔루션(PMS) <span class="portfolio-period">회사 / 2022.11–2024.12</span></h3>
      <p class="portfolio-summary">AI 학습데이터 공정 관리 시스템을 26개월간 개발하고 운영했습니다. 저장 유실 장애의 원인을 나눠 조치했고, 배포 후 3~4개월간 사용 문의가 월 20건에서 1~2건으로 줄었습니다.</p>
      <p class="portfolio-meta">근거: 문의 응대 기록(엑셀)의 평균, 운영 중 큰 에러 없음 / 한계: 배포 시간과 복구 시간은 측정하지 않음</p>
      <span class="portfolio-stack">Java, Spring Boot, MyBatis, MariaDB, Docker, GitLab CI</span>
    </a>
    <a class="portfolio-card portfolio-card--lead" href="{{ '/portfolio/delaynomore/' | relative_url }}">
      <h3>DelayNoMore: AI 계획 실행 서비스 <span class="portfolio-period">개인 / 2026.04– 진행 중</span></h3>
      <p class="portfolio-summary">확정한 계획을 고치지 못하게 하는 규칙을 화면에서 서버로 옮긴 서비스를 기획부터 배포까지 혼자 만들었습니다. 챌린지 정원 경쟁은 실제 PostgreSQL 테스트에서 정확히 1명만 통과하는 것을 확인했습니다.</p>
      <p class="portfolio-meta">검증: 서버 규칙과 동시성 자동 테스트, 에이전트 평가 하네스 / 한계: 데모 환경, 실트래픽 없음, v0.37.0 기준</p>
      <span class="portfolio-stack">Spring Boot, Java 21, React, PostgreSQL, Testcontainers</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="other-projects">
  <div class="portfolio-section-heading">
    <h2 id="other-projects">그 외 프로젝트</h2>
    <span class="portfolio-count">6 projects</span>
  </div>
  <ul class="portfolio-compact">
    <li><a href="{{ '/portfolio/gov-data-service/' | relative_url }}"><strong>정부 공문서 학습데이터 조회 서비스</strong><span>폐쇄망 HWP 파싱</span><small>회사 / 2023.08–2024.02</small></a></li>
    <li><a href="{{ '/portfolio/lms/' | relative_url }}"><strong>사내 교육 플랫폼(LMS)</strong><span>회원, 역할, 운영관리 백엔드</span><small>회사 / 2020.12–2021.03</small></a></li>
    <li><a href="{{ '/portfolio/port-fee/' | relative_url }}"><strong>항만 시설 사용료 관리 시스템</strong><span>세율을 데이터로 분리</span><small>회사 / 2019.05–2020.07</small></a></li>
    <li><a href="{{ '/portfolio/oauth-sso/' | relative_url }}"><strong>Gateway 단일 진입점 인증/인가 검증</strong><span>JWT, 서비스별 권한 검증</span><small>개인 / 2026.01–2026.03</small></a></li>
    <li><a href="{{ '/portfolio/admincore/' | relative_url }}"><strong>AdminCore</strong><span>운영 관리자 콘솔 백엔드</span><small>개인 / 2026.06– 진행 중</small></a></li>
    <li><a href="{{ '/portfolio/backoffice-ai/' | relative_url }}"><strong>Backoffice AI</strong><span>업무와 콘텐츠 자동화 플랫폼</span><small>개인 / 2026.08– 진행 중</small></a></li>
  </ul>
</section>
