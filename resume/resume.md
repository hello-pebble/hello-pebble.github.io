---
layout: default
title: resume
permalink: /
resume_name: 운영 효율과 서비스 안정성을 높이는 백엔드 개발자 권다경입니다.
---

<div class="resume-print-page resume-print-page-first">
<div class="resume-header">
  <div class="resume-identity">
    <span class="resume-title">{{ page.resume_name }}</span>
    <span class="resume-tagline">Java·Spring 백엔드 실무 3년 10개월/ 제조 공정·문서 처리 시스템을 개발하고, 배포와 장애 대응까지 담당</span>
  </div>
  <div class="resume-contact-print">kwdk2323@gmail.com · github.com/hello-pebble · 경력기술서 hello-pebble.github.io/resume/career-description/</div>
</div>

  <p class="resume-summary">복잡한 문제를 작은 단위로 나누어 빠르게 구현하고, 운영 결과를 바탕으로 개선합니다. 장애 발생 시에는 현상 해결에 그치지 않고 원인과 발생 흐름을 분석하며, 로그 확인 방법과 조치 순서를 문서화해 재발 대응 시간을 줄여왔습니다.</p>
<p class="resume-summary">요구사항과 사용자 흐름에 맞는 기술과 구조를 선택하고, 해결 과정과 시행착오를 동료와 공유해 반복 작업을 줄입니다. 빠른 실행력과 운영에 대한 책임감을 바탕으로, 관측 가능하고 운영하기 쉬운 시스템을 구축하는 데 기여하겠습니다.</p>
<p class="resume-summary"><li>상세 근거와 설계 판단은 <a href="{{ '/resume/career-description/' | relative_url }}">경력기술서</a>와 각 <a href="{{ '/portfolio/' | relative_url }}">포트폴리오</a>에서 확인할 수 있습니다. </li>
<li>개발 과정에서 Claude Code·Codex를 활용하고 있으며, 활용 방식을 정리해두었습니다 — <a href="{{ '/ai/' | relative_url }}">활용 방식 보기</a><li></p>

<section class="resume-compact-section">
<h2 class="resume-section-heading">Core Skills</h2>
<ul class="resume-skill-list">
  <li><strong>Backend</strong> Java, Spring Boot, Spring MVC, Spring Security, JPA, MyBatis, jOOQ</li>
  <li><strong>Data</strong> PostgreSQL, MariaDB, Oracle, Flyway</li>
  <li><strong>Operations</strong> Docker, GitLab CI, GitHub Actions, Tomcat, Nginx</li>
</ul>
</section>

<section class="resume-compact-section">
<h2 class="resume-section-heading">Work Experience</h2>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜미디어그룹사람과숲</h3><span class="entry-date">2022.11 – 2025.01</span></div>
  <ul>
    <li>최대 100명이 쓰는 공정 관리 솔루션(PMS)의 3D·2D 라벨링 API와 관리 기능을 개발하고, Docker 배포·GitLab CI 이미지 빌드와 로그 기반 장애 대응을 담당했습니다. <a class="resume-detail-link" href="/portfolio/pms/" aria-label="공정 관리 솔루션(PMS) 상세 보기">&rarr;</a></li>
    <li>개방DB API관리 시스템의 메타데이터 기반 조회 엔진을 설계해, API마다 파일 5~6개를 추가하던 개발을 등록 1건으로 바꿨습니다. <a class="resume-detail-link" href="/portfolio/api-management/" aria-label="메타데이터 기반 조회 API 엔진 상세 보기">&rarr;</a></li>
    <li>폐쇄망에 놓인 정부 공문서 AI 조회 서비스의 HWP 문서 파싱 기능을 Java–Python 브릿지로 구현했습니다. <a class="resume-detail-link" href="/portfolio/gov-data-service/" aria-label="정부 공문서 AI 조회 서비스 상세 보기">&rarr;</a></li>
  </ul>
</div>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜에이아이넷</h3><span class="entry-date">2020.12 – 2021.03</span></div>
  <ul>
    <li>사내 교육 플랫폼의 SSO 기반 권한 인가와 Oracle BLOB 파일 저장 기능을 개발했습니다. <a class="resume-detail-link" href="/portfolio/lms/" aria-label="사내 교육 플랫폼(LMS) 상세 보기">→</a></li>
  </ul>
</div>

<div class="resume-entry">
  <div class="entry-header"><h3>㈜엘에프아이티</h3><span class="entry-date">2019.05 – 2020.07</span></div>
  <ul>
    <li>GIS 기반 항만 시설 사용료 관리 시스템의 사용료 산정·업체 관리 기능을 개발하고 운영을 지원했습니다. <a class="resume-detail-link" href="/portfolio/port-fee/" aria-label="항만 시설 사용료 관리 상세 보기">→</a></li>
  </ul>
</div>
</section>
</div>

<div class="resume-print-page resume-print-page-second print-page-start">
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
      <li>20~30초의 AI 응답을 SSE로 스트리밍하고, 실패 시 비스트리밍·mock으로 이어지는 폴백을 구성했습니다.</li>
      <li>육안으로 확인하던 AI 응답 품질을 반복 실행 가능한 평가 하네스와 릴리스별 QA 기록으로 바꿨습니다.</li>
    </ul>
  </article>
  <article>
    <div class="resume-project-heading">
      <h3><a href="/portfolio/pms/">공정 관리 솔루션(PMS)</a></h3>
      <span>회사 프로젝트 · Java · Spring Boot · FastAPI · Docker · GitLab CI</span>
    </div>
    <ul>
      <li>최대 100명의 작업자가 3D·2D·PDF 라벨링을 수행하는 웹서비스의 API와 관리 기능을 개발했습니다.</li>
      <li>저장 유실과 3D 중복 저장을 재현해 저장 경로별 원인을 분리하고, 자동 저장·종료 확인과 코드 수정으로 대응했습니다.</li>
      <li>CI 이미지 빌드와 수동 승인 배포를 운영하고, 오류 문서·체크리스트·화면별 매뉴얼로 인계 기준을 고정했습니다.</li>
    </ul>
  </article>
  <article>
    <div class="resume-project-heading">
      <h3><a href="/portfolio/api-management/#reimplementation">api-forge</a></h3>
      <span>개인 프로젝트 · Java 21 · Spring Boot · jOOQ · Testcontainers</span>
    </div>
    <ul>
      <li>조회 API마다 5개 파일을 추가하던 구조를 메타데이터 등록 1건으로 바꾸는 엔진을 클린룸 재구현했습니다.</li>
      <li>요청 식별자는 메타데이터 화이트리스트로 제한하고 값은 jOOQ 바인드 파라미터로 처리했습니다.</li>
      <li>미등록 컬럼·파라미터명 위장·값 인젝션 시나리오를 H2와 PostgreSQL에서 반복 검증합니다.</li>
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
