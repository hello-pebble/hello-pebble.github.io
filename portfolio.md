---
layout: default
title: "포트폴리오"
permalink: /portfolio/
---

<header class="portfolio-index-header">
  <h1>Portfolio</h1>
  <p>문제를 기능으로 덮기보다 구조를 바꾸는 해법을 고민해 왔습니다. 개인 프로젝트와 실무 프로젝트에서 맡은 역할, 기술적 선택, 결과를 한눈에 확인해 보세요.</p>
</header>

<section class="portfolio-section" aria-labelledby="personal-projects">
  <div class="portfolio-section-heading">
    <h2 id="personal-projects">개인 프로젝트</h2>
    <span class="portfolio-count">2 projects</span>
  </div>
  <div class="portfolio-grid">
    <a class="portfolio-card" href="{{ '/portfolio/oauth-sso-backend/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="badge">개인 프로젝트</span>
        <span class="portfolio-card-number">01</span>
      </div>
      <h3>통합 인증(OAuth SSO) 시스템</h3>
      <p class="portfolio-summary">OAuth 2.0과 JWT를 기반으로 다중 서비스가 공유하는 무상태 인증 구조를 설계했습니다. Gateway 전역 검증, Refresh Token Rotation, Redis 블랙리스트를 적용해 확장성과 토큰 탈취 대응을 함께 확보했습니다.</p>
      <span class="portfolio-stack">Spring Boot · Spring Security · Gateway · Redis</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/1/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="badge">개인 프로젝트</span>
        <span class="portfolio-card-number">02</span>
      </div>
      <h3>DelayNoMore</h3>
      <p class="portfolio-summary">계획 확정 후 수정과 삭제를 막는 Immutable Lock으로 지연 행동을 줄이는 웹 서비스입니다. AI 계획 코치와 Firestore 영속화를 구현하고, 스트리밍 응답과 번들 분리로 체감 속도와 초기 로딩 성능을 개선했습니다.</p>
      <span class="portfolio-stack">React · Vite · Firebase · OpenRouter</span>
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
        <span class="badge outline">회사 프로젝트</span>
        <span class="portfolio-card-number">03</span>
      </div>
      <h3>개방DB 관리 시스템</h3>
      <p class="portfolio-summary">반복되는 조회 API 개발을 없애기 위해 데이터 스키마를 메타데이터로 추상화했습니다. 선택한 컬럼과 조건을 SQL로 변환하는 Generic API 엔진과 버전 관리 체계를 설계해 신규 요구사항을 설정만으로 수용하도록 개선했습니다.</p>
      <span class="portfolio-stack">Java · Spring MVC · MyBatis · MariaDB</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/process-management-solution/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="badge outline">회사 프로젝트</span>
        <span class="portfolio-card-number">04</span>
      </div>
      <h3>공정 관리 솔루션(PMS)</h3>
      <p class="portfolio-summary">담당자에게 의존하던 배포와 장애 대응을 표준화한 프로젝트입니다. Docker와 GitLab CI로 빌드·배포 파이프라인을 자동화하고, 장애 패턴 분석과 대응 매뉴얼을 통해 운영 공수와 인적 오류를 줄였습니다.</p>
      <span class="portfolio-stack">Java · Spring Boot · Docker · GitLab CI</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/gov-document-ai-data-service/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="badge outline">회사 프로젝트</span>
        <span class="portfolio-card-number">05</span>
      </div>
      <h3>정부 공문서 AI 조회 서비스</h3>
      <p class="portfolio-summary">외부 통신이 불가능한 폐쇄망에서 HWP 문서 파싱 문제를 해결했습니다. Java ProcessBuilder와 로컬 Python 환경을 연결하는 브릿지 파이프라인을 설계해 규제를 준수하면서 문서 정제·등록 과정을 자동화했습니다.</p>
      <span class="portfolio-stack">Java · Spring MVC · Python · MariaDB</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>

    <a class="portfolio-card" href="{{ '/portfolio/learning-management-system/' | relative_url }}">
      <div class="portfolio-card-top">
        <span class="badge outline">회사 프로젝트</span>
        <span class="portfolio-card-number">06</span>
      </div>
      <h3>사내 교육 플랫폼(LMS)</h3>
      <p class="portfolio-summary">여러 부서가 사용하는 교육 플랫폼의 접근 권한과 파일 정합성을 강화했습니다. SSO 연동 RBAC 검증을 공통화하고, 첨부파일을 Oracle BLOB에 저장해 비즈니스 데이터와 동일한 트랜잭션·백업 주기를 보장했습니다.</p>
      <span class="portfolio-stack">Java · Spring Boot · JPA · Oracle</span>
      <span class="portfolio-card-link">프로젝트 자세히 보기 →</span>
    </a>
  </div>
</section>
