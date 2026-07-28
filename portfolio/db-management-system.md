---
layout: default
title: "개방DB 관리 시스템 설계 및 프로토타입 개발"
permalink: /portfolio/db-management-system/
---

# 개방DB 관리 시스템 설계 및 프로토타입 개발

<span class="badge outline">회사 프로젝트</span>

> 조회 요구사항마다 유사한 엔드포인트를 추가하던 방식을 메타데이터 설정과 공통 SQL 변환 흐름으로 바꾼 프로젝트입니다.

<nav class="project-page-nav" aria-label="개방DB 관리 시스템 프로젝트 목차">
  <a href="#overview">
    <span>Overview</span>
    <small>기간·기술 스택·검증 범위</small>
  </a>
  <a href="#intent">
    <span>설계 의도</span>
    <small>공통 조회를 메타데이터로 모으기</small>
  </a>
  <a href="#problem">
    <span>문제 정의</span>
    <small>스키마에 결합된 API 반복 개발</small>
  </a>
  <a href="#solution">
    <span>해결 과정</span>
    <small>Generic SQL 변환 엔진과 버전 라우팅</small>
  </a>
  <a href="#evidence">
    <span>구현 근거</span>
    <small>설정만으로 조회 API 생성 확인</small>
  </a>
  <a href="#results">
    <span>결과</span>
    <small>확인 가능한 변화</small>
  </a>
  <a href="#limitations">
    <span>한계와 후속 과제</span>
    <small>프로토타입 · 운영 반영 전</small>
  </a>
</nav>

---

## Project Overview {#overview}

- **구분**: 회사 프로젝트
- **기간**: 2024.09 ~ 2025.01 (5개월)
- **기술 스택**: Java, JSP, Spring MVC, MyBatis, MariaDB, Apache Tomcat
- **핵심 역할**: 설계 기획, Generic SQL 변환 엔진 설계 및 버전 관리 로직 구현
- **검증 범위**: 로컬 환경에서 관리자 설정만으로 조회 API가 생성되는 동작 확인

---

## Intent (설계 의도) {#intent}

조회 대상 테이블과 컬럼이 달라질 때마다 비슷한 Controller·Service·SQL을 추가하면 변경 지점이 계속 늘어납니다. 조회 기능의 공통 부분을 메타데이터와 SQL 변환 엔진으로 모으고, 업무별 차이는 설정으로 표현하는 것을 목표로 했습니다.

---

## Problem (문제 정의 및 원인 분석) {#problem}

- **문제**: 신규 조회 요구사항마다 테이블 스키마에 결합된 API와 SQL을 추가해야 했습니다.
- **원인**: 조회 대상, 조건, 정렬 규칙이 코드에 직접 들어가 있어 공통 처리와 업무별 차이를 분리하기 어려웠습니다.

---

## Solution (해결 과정) {#solution}

![Generic API 엔진 - 개발 방식의 구조적 전환](/assets/images/portfolio/dbms-generic-engine.svg)

1. **데이터 스키마 추상화 관리 체계 수립**
   - 조회 가능한 테이블·컬럼·조건을 메타데이터로 관리하는 **스키마 추상화 레이어**를 도입했습니다.
2. **Generic API 엔진 설계 및 리플렉션 응용**
   - MyBatis의 동적 쿼리 생성과 Java Reflection API 개념을 응용했습니다.
   - UI에서 전달된 컬럼·조건 조합을 메타데이터와 대조하고 MyBatis 동적 SQL로 변환하는 **Generic API 엔진**을 구현했습니다.
3. **API 버전 관리 체계 구축**
   - 기존 조회 경로와 신규 조회 경로를 분리할 수 있도록 버전별 라우팅 구조를 적용했습니다.

---

## Implementation Evidence (구현 근거) {#evidence}

- 위 아키텍처 다이어그램에 `메타데이터 등록 → 요청 검증 → 동적 SQL 생성 → 결과 반환`의 처리 경계를 표시했습니다.
- 조회 대상과 조건을 코드가 아닌 메타데이터로 관리하도록 구성했습니다.
- 기존·신규 API를 함께 운영할 수 있도록 버전 라우팅 책임을 조회 엔진과 분리했습니다.

---

## Results (확인 가능한 변화) {#results}

- 로컬 환경에서 신규 조회 기능을 개별 엔드포인트 구현 대신 메타데이터 등록으로 지원할 수 있는 구조임을 확인했습니다.
- 조회 요청 검증, SQL 생성, 결과 반환의 공통 흐름을 한 엔진에서 처리하도록 책임을 모았습니다.
- 기존 API를 유지한 상태에서 신규 조회 방식을 별도 버전으로 적용할 수 있게 했습니다.

---

## Limitations (한계 및 후속 과제) {#limitations}

- 운영 반영 전 퇴사하여 실 트래픽·동시성 검증은 수행하지 못했습니다.
- 동적 SQL은 허용 컬럼과 연산자 검증이 약하면 보안 문제가 생길 수 있어, 메타데이터 화이트리스트와 입력 검증 규칙을 지속적으로 관리해야 합니다.
- 컬럼 조합이 늘어날수록 쿼리 실행 계획을 예측하기 어려워집니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- 잘못된 메타데이터가 런타임 오류로 이어질 수 있으므로, 설정 저장 시 스키마 존재 여부와 테스트 쿼리를 검증하는 기능이 후속 과제입니다.
