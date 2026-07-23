---
layout: default
title: "포트폴리오"
permalink: /portfolio/
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">BACKEND DEVELOPER</span>
  <h1>문제를 구조로 해결한 경험</h1>
  <p>인증·데이터·배포·운영의 복잡한 문제를 구조적으로 개선해 온 백엔드 개발자입니다.</p>
</header>

<section class="portfolio-section" aria-labelledby="personal-projects">
  <div class="portfolio-section-heading">
    <h2 id="personal-projects">개인 프로젝트</h2>
    <span class="portfolio-count">2 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso-backend/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">01</span>
      </div>
      <h3>통합 인증(OAuth SSO) 시스템</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>MSA 통합 인증</span><span>OAuth 2.0</span><span>보안 설계</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> MSA 환경의 서비스별 중복 인증과 세션 확장성 문제 해결</li>
        <li><strong>담당</strong> 개인 설계·개발 · OAuth 2.0, Gateway, JWT, Redis 인증 아키텍처 구현</li>
        <li><strong>성과</strong> 중앙 인증 표준화 · RTR와 블랙리스트 기반 토큰 탈취 대응 체계 구축</li>
      </ul>
      <span class="portfolio-stack">Spring Boot · Spring Security · Gateway · Redis</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/1/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>DelayNoMore</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>풀스택 백엔드</span><span>서버 규칙 소유</span><span>데이터 영속화</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 계획 수정이 미루기를 만든다는 가설을 Immutable Lock 서비스로 구현</li>
        <li><strong>담당</strong> 기획·설계·개발·배포 단독 수행 · Spring Boot + React 풀스택 재구현</li>
        <li><strong>성과</strong> 13개 릴리스로 규칙·데이터 소유권을 서버로 이관 · PostgreSQL 영속화·SSE 스트리밍</li>
      </ul>
      <span class="portfolio-stack">Spring Boot · Java 21 · React · PostgreSQL · OpenRouter</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>
  </div>
</section>

<section class="portfolio-section" aria-labelledby="company-projects">
  <div class="portfolio-section-heading">
    <h2 id="company-projects">회사 프로젝트</h2>
    <span class="portfolio-count">4 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/db-management-system/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>개방DB 관리 시스템</h3>
      <div class="portfolio-keywords" aria-label="핵심 키워드">
        <span>Generic API</span><span>메타데이터</span><span>레거시 개선</span>
      </div>
      <ul class="portfolio-highlights">
        <li><strong>목표</strong> 조회 API를 요구사항마다 반복 개발하던 하드코딩 구조 개선</li>
        <li><strong>담당</strong> 2024.09–2025.01 · 스키마 추상화, Generic SQL 엔진, 버전 관리 설계</li>
        <li><strong>성과</strong> 신규 조회 요구사항을 코드 변경 없이 설정으로 수용 · 온보딩 부담 완화</li>
      </ul>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · MariaDB</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/process-management-solution/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="portfolio-card-number">04</span>
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
        <span class="portfolio-card-number">05</span>
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
        <span class="portfolio-card-number">06</span>
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
