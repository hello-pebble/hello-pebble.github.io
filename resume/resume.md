---
layout: default
title: resume
permalink: /resume/
resume_name: 권다경
---

<div class="resume-print-page resume-print-page-first">
<div class="resume-header">
  <div class="resume-identity">
    <span class="resume-title">{{ page.resume_name }}</span>
    <span class="resume-tagline">운영 중인 시스템의 반복 비용을 줄이는 백엔드 개발자</span>
  </div>
  <div class="resume-contact-print">kwdk2323@gmail.com · github.com/hello-pebble · 경력기술서 hello-pebble.github.io/resume/career-description/</div>
</div>

<ul class="resume-skill-list resume-body-list">
  <li>Java·Spring 백엔드 실무 3년 10개월</li>
  <li>제조 공정·문서 처리 시스템을 개발하고, 배포와 장애 대응까지 담당</li>
</ul>

<p class="resume-summary">개방DB API관리 시스템을 앞으로 들어올 프로젝트에서 쓸 기본 틀로 다시 만들었습니다. 기존 코드는 리팩토링해 쓰지 않던 함수와 중복 모듈을 덜어냈고, DB 메타데이터로 쿼리를 조립하는 엔진을 새로 설계해 조회 API 추가를 파일 5~6개에서 데이터셋 등록 1건으로 바꿨습니다(개발 서버 적용). 파라미터 화이트리스트 검증과 바인드 처리도 엔진 한 곳에 모았습니다.</p>
<p class="resume-summary">공정 관리 솔루션(PMS)에서 저장한 작업물이 사라지던 장애를 재현해 원인 3가지(전송 범위, 건별 커밋, 미저장 종료 경로)를 분리하고, 전송 범위 축소와 멱등 저장으로 조치했습니다. 매뉴얼·배포 체크리스트·분기별 시연까지 붙였고, 배포 후 3~4개월 사이 사용 문의가 월 20건에서 1~2건으로 줄었습니다.</p>
<p class="resume-summary">네 프로젝트에서 같은 판단을 반복했습니다. 항만(2019)은 감면 1건마다 필요하던 개발 요청을 담당자 화면의 업체별 값으로, 개방DB(2024)는 API마다 파일 5~6개를 메타데이터 엔진 1곳으로, DelayNoMore(2026)는 프론트 잠금 버튼을 서버 <code>409</code>와 도구 노출 권한으로, AdminCore(2026)는 로그인 시점 상태 검사를 요청마다 재검사로 옮겼습니다. 규칙을 반복 비용이 드는 곳에서 한 곳으로 모으는 일입니다.</p>
<p class="resume-summary">2025년 여름부터는 개인 프로젝트로 Java 21, SSE 스트리밍, Testcontainers 기반 다중 방언 검증, AI 도구 호출 평가 하네스를 다뤘고, 각 판단을 계획서와 보고서로 남겼습니다.</p>
<ul class="resume-skill-list resume-body-list">
  <li>상세 근거와 설계 판단은 <a href="{{ '/resume/career-description/' | relative_url }}">경력기술서</a>와 각 <a href="{{ '/' | relative_url }}">포트폴리오</a>에서 확인할 수 있습니다.</li>
</ul>

<section class="resume-compact-section">
<h2 class="resume-section-heading">Core Skills</h2>
<ul class="resume-skill-list">
  <li><strong>웹·업무 시스템 개발</strong> Java 8/21, Spring Boot, Spring MVC, eGovFrame, JSP, HTML/CSS, JavaScript, jQuery, MyBatis — 메타데이터 기반 동적 쿼리 엔진으로 조회 API 추가 공수 파일 5~6개 → 데이터셋 등록 1건</li>
  <li><strong>인증·인가</strong> Spring Security, JWT, OAuth2, RBAC — 정지 계정의 유효 토큰 차단, Gateway 통과 후 서비스별 재검증</li>
  <li><strong>RDBMS·데이터 설계</strong> MariaDB, Oracle, Tibero, PostgreSQL, MyBatis, JPA, Flyway — 데이터 모델링, 트랜잭션 경계, <code>FOR UPDATE</code> 행 잠금, TOCTOU 대조군 테스트</li>
  <li><strong>WEB/WAS·운영·배포</strong> Tomcat, WildFly, Nginx, Docker, GitLab CI, GitHub Actions — 환경은 이미지로 고정하되 배포 실행은 확인 가능한 시점에만</li>
  <li><strong>검증</strong> JUnit 5, MockMvc, Testcontainers — 단위 / 통합 / 외부 의존 평가 3층 분리</li>
</ul>
</section>

<section class="resume-compact-section">
<h2 class="resume-section-heading">Work Experience</h2>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜미디어그룹사람과숲 · 백엔드 개발자</h3><span class="entry-date">2022.11 – 2025.01</span></div>
  <ul>
    <li><a class="resume-detail-link" href="/portfolio/pms/">공정 관리 솔루션(PMS)을 26개월간 개발·운영하며 저장 유실 장애의 원인 3건을 규명해 조치했고, 배포 후 3~4개월 사이 사용 문의가 월 20건에서 1~2건으로 줄었습니다.</a></li>
    <li><a class="resume-detail-link" href="/portfolio/api-management/">개방DB API관리 시스템을 앞으로 쓸 기본 틀로 리팩토링하며 메타데이터 기반 조회 엔진을 설계해, API마다 파일 5~6개를 추가하던 개발을 데이터셋 등록 1건으로 바꾸고(개발 서버 적용), 검증 누락 가능 지점을 엔진 1곳으로 모았습니다.</a></li>
    <li><a class="resume-detail-link" href="/portfolio/gov-data-service/">폐쇄망에 놓인 정부 공문서 서비스의 HWP 파싱을 Java–Python 서브프로세스로 구현해, 문서를 열어 옮겨 적던 등록 절차를 파일 업로드 1회로 바꿨습니다.</a></li>
  </ul>
</div>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜에이아이넷 · 백엔드 개발자</h3><span class="entry-date">2020.12 – 2021.03</span></div>
  <ul>
    <li><a class="resume-detail-link" href="/portfolio/lms/">화상 교육 플랫폼의 회원·역할·운영관리 백엔드를 개발하며 역할 변경을 전체 교체로, 분류 유형을 이름 대신 코드 ID로 저장하도록 설계했습니다.</a></li>
  </ul>
</div>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜엘에프아이티 · 백엔드 개발자</h3><span class="entry-date">2019.05 – 2020.07</span></div>
  <ul>
    <li><a class="resume-detail-link" href="/portfolio/port-fee/">GIS 기반 항만 시설 사용료 관리 시스템에서 세율을 업체별 값으로 분리해, 감면 1건마다 필요하던 개발 요청을 담당자 화면 조작으로 바꿨습니다.</a></li>
  </ul>
</div>
</section>
</div>

<div class="resume-print-page">
<section class="resume-compact-section resume-project-section">
<h2 class="resume-section-heading">Selected Projects</h2>
<div class="resume-project-list">
  <article>
    <div class="resume-project-heading">
      <h3><a href="/portfolio/delaynomore/">DelayNoMore</a></h3>
      <span>개인 프로젝트 · Java 21 · Spring Boot · PostgreSQL · AI</span>
    </div>
    <ul>
      <li>계획 상태 전이를 서버 규칙으로 옮기고, 허용되지 않은 수정은 <code>409</code>로 차단했습니다.</li>
      <li>20~30초의 AI 응답을 SSE로 스트리밍하고, 계획 전문 재전송을 변경분 교환으로 바꿔 전송량을 변경분에만 비례하게 했습니다.</li>
      <li>육안으로 확인하던 AI 응답 품질을 반복 실행 가능한 평가 하네스로 바꿔, 모델이 금지된 도구를 인접 도구로 우회하는 경로 1건을 찾아냈습니다.</li>
    </ul>
  </article>
  <article>
    <div class="resume-project-heading">
      <h3><a href="/portfolio/pms/">공정 관리 솔루션(PMS)</a></h3>
      <span>회사 프로젝트 · Java · Spring Boot · FastAPI · Docker · GitLab CI</span>
    </div>
    <ul>
      <li>3D·2D·PDF 라벨링을 수행하는 웹서비스의 API와 관리 기능을 개발했습니다.</li>
      <li>저장 유실과 3D 중복 저장을 재현해 저장 경로별 원인을 분리하고, 자동 저장·종료 확인과 코드 수정으로 대응했습니다.</li>
      <li>CI 이미지 빌드와 수동 승인 배포를 운영하고, 체크리스트·화면별 매뉴얼·분기별 시연으로 인계 기준을 고정했고, 배포 후 3~4개월 사이 문의가 월 20건에서 1~2건으로 줄었습니다.</li>
    </ul>
  </article>
  <article>
    <div class="resume-project-heading">
      <h3><a href="/portfolio/api-management/#reimplementation">api-forge</a></h3>
      <span>개인 프로젝트 · Java 21 · Spring Boot · jOOQ · Testcontainers</span>
    </div>
    <ul>
      <li>회사 개방DB 구현 중 쿼리를 조합하는 부분만 클린룸 재구현했습니다. 조회 API마다 5개 파일을 추가하던 구조를 데이터셋 등록 1건으로 바꾸는 엔진입니다.</li>
      <li>요청 식별자는 메타데이터 화이트리스트로 제한하고 값은 jOOQ 바인드 파라미터로 처리했습니다.</li>
      <li>미등록 컬럼·파라미터명 위장·값 인젝션은 단위 테스트로 검증하고, 미등록 컬럼·값 인젝션은 H2·PostgreSQL 통합 테스트로 추가 검증하며, <code>main</code> 푸시와 PR마다 CI에서 실행합니다.</li>
    </ul>
  </article>
</div>
<p class="resume-more-links"><strong>Other</strong><a href="/portfolio/admincore/">AdminCore</a><a href="/portfolio/oauth-sso/">Auth Gateway Platform</a><a href="https://github.com/hello-pebble/searchvibe" target="_blank" rel="noopener noreferrer">searchvibe</a></p>
</section>

<section class="resume-compact-section resume-bottom">
<h2 class="resume-section-heading">Education & Certifications</h2>
<p>국가평생교육진흥원 · 정보통신공학 &nbsp;·&nbsp; 동양미래대학교 · 정보통신공학 &nbsp;·&nbsp; 네트워크관리사 2급 &nbsp;·&nbsp; 리눅스마스터 2급</p>
</section>
</div>

<div class="career-print career-body" markdown="1">
{% include career-description.md %}
</div>
