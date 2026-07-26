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
    <h2 id="technical-skills">기술 스택</h2>
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
      <h3>MatchSimulation — 매칭 서비스 백엔드</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>교체 가능한 경계</span><span>전략 패턴 매칭 엔진</span><span>AI 연동 접점 설계</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 추천 엔진·DB·인증을 나중에 교체할 수 있도록 경계를 먼저 설계한 매칭 백엔드 구현</li>
        <li><strong>담당</strong> 2026.06– 진행 중 · 개인 설계·개발 · 7개 기능 모듈과 MatchingEngine 설정 기반 전환 구조 구성</li>
        <li><strong>검증</strong> 가입→추천→매칭 수락 전이 · QnA·알림·관리자 통계까지 전체 API 스모크 확인</li>
      </ul>
      <span class="portfolio-stack">Java 21 · Spring Boot 4 · Spring Data JPA · H2 · Gradle</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/1/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>DelayNoMore</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>Spring Boot 백엔드</span><span>회고 기반 추천</span><span>AI 토큰 최적화</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 계획 수정이 미루기를 만든다는 가설을 Immutable Lock 서비스로 구현</li>
        <li><strong>담당</strong> 2026.04–2026.06 · 기획·설계·개발·배포 단독 수행 · 계층형 백엔드 설계와 단일 컨테이너 배포</li>
        <li><strong>성과</strong> 회고→다음 계획 피드백 루프 · PostgreSQL 동시성 설계 · SSE 스트리밍 · AI 요청당 대부분 $0.001 미만</li>
      </ul>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · OpenRouter</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso-backend/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>Gateway 단일 진입점 인증/인가 검증</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>단일 진입점</span><span>공개·보호 라우트 분리</span><span>JWT 분산 검증</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 단일 진입점 뒤에서 공개·보호·내부 경로가 각각 다른 응답을 보장하는지 검증</li>
        <li><strong>담당</strong> 2026.01–2026.03 · 개인 설계·개발 · Gateway 단일 공개와 JWT 중앙 발급·JWKS 분산 검증 구성</li>
        <li><strong>검증</strong> 공개 라우트 접근 · 무토큰 401 · Admin 경유 양측 인가 · 내부 경로 404 확인</li>
      </ul>
      <span class="portfolio-stack">Kotlin · Spring Boot · Spring Security · Gateway · Docker Compose</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
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
      <h3>개방DB 관리 시스템</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>Generic API</span><span>메타데이터</span><span>레거시 개선</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 요구사항마다 조회 API를 반복 개발하던 하드코딩 레거시 구조를, 신규 인력이 파악하기 쉬운 형태로 재설계</li>
        <li><strong>담당</strong> 2024.09–2025.01 · <strong>설계 및 프로토타입</strong> · 스키마 추상화, Generic SQL 엔진, 버전 관리 설계</li>
        <li><strong>검증 범위</strong> 로컬 환경에서 관리자 설정만으로 조회 API가 생성되는 동작 확인</li>
        <li><strong>한계</strong> 운영 반영 전 퇴사. 실 트래픽·동시성 검증 미수행</li>
      </ul>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · MariaDB</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/process-management-solution/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>공정 관리 솔루션(PMS)</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>CI/CD</span><span>Docker</span><span>운영 표준화</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 담당자에게 의존하던 수동 배포와 장애 대응 프로세스 표준화</li>
        <li><strong>담당</strong> 2022.11–2024.12 · Docker 격리, GitLab CI/CD, 장애 패턴 분석</li>
        <li><strong>성과</strong> 배포 인적 오류 제거 · 대응 매뉴얼 도입 후 반복 운영 문의 감소</li>
      </ul>
      <span class="portfolio-stack">Java · Spring Boot · Docker · GitLab CI</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/gov-document-ai-data-service/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">06</span>
      </div>
      <h3>정부 공문서 AI 조회 서비스</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>폐쇄망</span><span>Java–Python 연동</span><span>업무 자동화</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 외부 통신이 차단된 폐쇄망에서 정부 HWP 문서 파싱 자동화</li>
        <li><strong>담당</strong> 2023.08–2024.02 · ProcessBuilder 기반 Java–Python 브릿지 설계</li>
        <li><strong>성과</strong> 보안 규제를 준수하며 문서 정제·등록을 자동화해 시범 사업 완수</li>
      </ul>
      <span class="portfolio-stack">Java · Spring MVC · Python · MariaDB</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/learning-management-system/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">07</span>
      </div>
      <h3>사내 교육 플랫폼(LMS)</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>SSO · RBAC</span><span>데이터 정합성</span><span>보안</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 다부서 교육 플랫폼의 비인가 접근과 첨부파일 유실 위험 해결</li>
        <li><strong>담당</strong> 2020.12–2021.03 · SSO 연동 RBAC, 공통 권한 검증, BLOB 저장 구현</li>
        <li><strong>성과</strong> API 접근 보안 강화 · 파일과 업무 데이터를 단일 트랜잭션으로 관리</li>
      </ul>
      <span class="portfolio-stack">Java · Spring Boot · JPA · Oracle</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>
  </div>
</section>
