---
layout: default
title: "개방DB API관리 시스템 설계 및 프로토타입 개발"
permalink: /portfolio/api-management/
---

<span class="project-context">회사 프로젝트 · 2024.09 — 2025.01 · Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero</span>

# 개방DB API관리 시스템 — 반복 개발을 메타데이터로 바꾸기

- 조회 요구사항마다 유사한 엔드포인트를 추가하던 방식을 메타데이터 설정과 공통 SQL 변환 흐름으로 바꾼 프로젝트입니다. 운영 반영 전 이직해 미완으로 남은 검증은, 같은 구조를 현대 스택으로 재구현한 [api-forge](https://github.com/hello-pebble/api-forge)(테스트 50건·CI)로 대신 증명했습니다.

<nav class="project-page-nav" aria-label="개방DB 관리 시스템 프로젝트 목차">
  <a href="#problem">
    <span>문제</span>
    <small>조회 API 하나에 파일 5개</small>
  </a>
  <a href="#boundary">
    <span>핵심 결정</span>
    <small>어디까지 동적으로 만들 것인가</small>
  </a>
  <a href="#evidence">
    <span>요청에서 SQL까지</span>
    <small>검증·생성·차단 지점</small>
  </a>
  <a href="#reimpl">
    <span>재구현 검증</span>
    <small>api-forge · 계승과 대체</small>
  </a>
  <a href="#limitations">
    <span>결과와 한계</span>
    <small>프로토타입 · 운영 반영 전</small>
  </a>
</nav>

## 문제 — 조회 API 하나에 파일 5개 {#problem}

신규 조회 요구사항이 올 때마다 Controller·Service·ServiceImpl·DAO·SQL XML **5개 파일**(관리 화면 동반 시 JSP까지 6개)을 추가해야 했습니다. 조회 대상·조건·정렬 규칙이 코드에 직접 들어가 있어 공통 처리와 업무별 차이를 분리할 수 없었고, 파라미터는 VO 없이 Map으로 오가 컴파일 시점 검증도 되지 않았습니다.

조회 기능의 공통 부분을 메타데이터와 SQL 변환 엔진으로 모으고, 업무별 차이는 설정으로 표현하는 것을 목표로 잡았습니다. 담당 범위는 관리자 메타데이터 화면, Hub 요청 검증, 메타데이터 기반 SQL 조립 로직이었고, 함께 iBatis 매퍼를 MyBatis로 전환해 기존 프로젝트와 개발 방식을 통일했습니다.

![Generic API 엔진 - 개발 방식의 구조적 전환](/assets/images/portfolio/dbms-generic-engine.svg){:.portfolio-diagram}

## 핵심 결정 — 어디까지를 동적으로 만들 것인가 {#boundary}

조회 정의는 세 계층(데이터셋 스키마 · 외부 노출 형태 · 컬럼별 조회 조건)으로 분리해 각각 독립적으로 변경되게 했습니다. 그런데 진짜 어려운 결정은 따로 있었습니다. 고정 쿼리와 달리 **런타임에 조립되는 SQL은 컬럼·조건 조합마다 DB 방언 차이가 드러나고**, 운영 DB(Tibero)는 개발 단계에서 접근할 수 없어 MariaDB → Oracle → Tibero 순서로 검증 격차를 좁혀야 했습니다. 조합이 늘수록 검증 경로가 폭발하므로, 동적 영역의 경계를 먼저 정했습니다.

| 층 | 대상 | 처리 방식 |
| :--- | :--- | :--- |
| **바깥** | 페이징 | ROWNUM 기반 공통 래퍼를 XML에 고정, 값은 바인드 변수 |
| **중간** | DB 방언 | SQL 맵 세트를 디렉터리 단위로 분리하고 설정으로 전환 |
| **안쪽** | 조회 컬럼·조건 | 메타데이터 기반 동적 조립 |

페이징 구문까지 조립 대상에 넣으면 DB 종류와 조건 조합의 곱만큼 검증 경로가 늘어납니다. 그래서 페이징은 고정 래퍼로 감싸고, 방언 차이는 쿼리 내부 분기가 아니라 **파일 단위 교체**로 처리해, 동적 영역을 조회 컬럼과 조건에만 남겼습니다. 내부 사용자만 쓰는 관리 화면 목록은 대상 건수가 적어 방언에 의존하지 않는 ResultSet 스크롤을 적용해, 공개 API와 다른 전략을 썼습니다. 메타데이터 등록 직후 관리 화면에서 샘플 URL을 호출해 결과를 바로 확인하는 장치도 넣어, 잘못된 설정이 배포 후에 발견되는 것을 줄였습니다.

## 요청에서 SQL까지 {#evidence}

아래 예시는 회사 코드가 아니라 동일 구조를 비식별화해 재구현한 [api-forge](https://github.com/hello-pebble/api-forge)에서 발췌했으며, 데이터는 전부 가상입니다. API 엔드포인트 하나가 메타데이터 테이블의 행 하나입니다 — `DATASET`이 조회 대상 테이블과 URL 키를, `DATASET_COLUMN`이 노출 컬럼과 허용 필터·정렬을 정의하고, **여기 등록된 컬럼만** 조회·필터·정렬에 쓸 수 있습니다.

| sourceColumn | displayName | filterType | sortable | 요청 예시 |
| :--- | :--- | :--- | :--- | :--- |
| **BILL_ID** | 의안번호 | EQUALS (=) | ✓ | `?BILL_ID=2200001` |
| **BILL_NM** | 의안명 | WORDS (LIKE) | ✗ | `?BILL_NM=데이터` |
| **COMMITTEE** | 소관위원회 | CHECK (IN) | ✓ | `?COMMITTEE=행정안전위원회,정무위원회` |
| **PROPOSE_DT** | 발의일자 | DATE (BETWEEN) | ✓ | `?PROPOSE_DT=2026-01-01,2026-06-30` |

연산자는 클라이언트가 아니라 컬럼의 `filterType`이 결정합니다. 요청이 오면 엔진은 SQL을 만들기 전에 파라미터명을 메타데이터에서 조회하고(미등록이면 400), 정렬 허용 여부를 확인하고, 값은 전부 바인드 파라미터로 처리합니다.

```
GET /api/v1/datasets/bills?COMMITTEE=행정안전위원회,정무위원회&PROPOSE_DT=2026-01-01,2026-06-30&sort=PROPOSE_DT,desc&page=0&size=20
```

```sql
SELECT "BILL_ID", "BILL_NM", "PROPOSER", "COMMITTEE", "PROPOSE_DT", "BILL_STATUS"
FROM "NA_BILL"
WHERE "COMMITTEE" IN (?, ?)
  AND "PROPOSE_DT" BETWEEN ? AND ?
ORDER BY "PROPOSE_DT" DESC
LIMIT 20 OFFSET 0
-- 바인드 값: '행정안전위원회', '정무위원회', 2026-01-01, 2026-06-30
```

인젝션을 막는 지점은 엔진 한 곳입니다. SQL에 들어가는 식별자는 요청 파라미터명이 아니라 **메타데이터에 저장된 컬럼명**이며, 요청 파라미터명은 조회 키로만 쓰이고 버려집니다.

```java
DatasetColumn col = dataset.findColumn(paramName)
        .orElseThrow(() -> new InvalidQueryException("지원하지 않는 필터 파라미터입니다: " + paramName));
if (col.getFilterType() == FilterType.NONE) {
    throw new InvalidQueryException("필터가 허용되지 않은 칼럼입니다: " + paramName);
}
Field<Object> field = DSL.field(DSL.name(col.getSourceColumn())); // SQL에는 메타데이터의 컬럼명만 들어간다
```

이 방어가 실제로 동작하는지는 재구현 저장소의 테스트가 CI에서 증명합니다 — 미등록 컬럼 필터 400, `BILL_ID; DROP TABLE …` 같은 파라미터명 위장 400, `' OR '1'='1` 값 주입은 문자열 리터럴 처리. 마지막 시나리오는 H2와 PostgreSQL(Testcontainers) 양쪽 통합 테스트에 동일하게 존재합니다.

## 미완의 검증을 재구현으로 — api-forge {#reimpl}

회사 프로토타입은 개발 서버까지 적용된 상태에서 이직해, 실트래픽·동시성 검증이 미완으로 남았습니다. 그 검증을 대신하기 위해 핵심 구조(메타데이터 기반 조회·화이트리스트 검증·동적 SQL)를 클린룸으로 재구현한 것이 **[api-forge](https://github.com/hello-pebble/api-forge)** (Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers)입니다. 단순 복제가 아니라, 레거시에서 배운 것을 기준으로 계승·대체·보류를 항목마다 판단했습니다.

![api-forge 아키텍처 — 메타데이터 등록 흐름과 조회 흐름, SQL Injection 차단 지점](/assets/images/portfolio/apiforge-architecture.svg){:.portfolio-diagram}

| 레거시 | api-forge | 판단 |
| :--- | :--- | :--- |
| 문자열 연결 SQL + 블랙리스트 필터 | jOOQ 타입 세이프 DSL + 식별자 화이트리스트 | 대체 — 가장 위험했던 지점 |
| DB별 SQL 맵 세트 디렉터리 교체 | jOOQ가 방언을 추상화 | 대체 — 맵 중복 제거 |
| 3종 DB를 단계별 수동 검증 | H2·PostgreSQL을 Testcontainers로 매 커밋 검증 | 검증 방식 전환 |
| Map 기반 파라미터 | DTO + Bean Validation | 대체 |
| 평문 인증키 | 해시 저장 + 상수 시간 검증 | 대체 |
| 데이터셋 버전 · 일일 호출 제한 | 미구현 | 보류 — 로드맵에 명시 |
| Sheet 출력 속성 (정렬·너비) | 미구현 | 제외 — 화면 표현은 API 응답의 책임이 아니라고 판단 |

두 가지 대체는 레거시 경험에서 직접 나왔습니다. 방언을 파일 교체로 처리하는 방식은 쿼리 내부 분기를 없애 주지만 지원 DB 수만큼 같은 쿼리를 유지해야 했고 — jOOQ 선택은 그 중복을 라이브러리에 위임한 것입니다. 방언 차이를 통합 시점에 몰아서 확인해야 했던 경험은, 서로 다른 DB를 컨테이너로 띄워 매 커밋마다 검증하는 CI로 이어졌습니다. `./mvnw spring-boot:run` 한 줄로 실행되며 시드된 가상 데이터셋으로 위 요청을 그대로 재현할 수 있습니다.

## 결과와 한계 {#limitations}

확인한 변화: 신규 조회 기능이 5~6개 파일 수정에서 **메타데이터 등록 1건**(빌드·재배포 없음)으로 바뀌는 구조를 로컬·개발 서버에서 확인했고, 검증·바인드 처리가 누락될 수 있는 지점을 API 개수만큼에서 엔진 한 곳으로 줄였습니다.

- 회사 프로토타입은 운영 반영 전 퇴사해 실트래픽·동시성 검증을 수행하지 못했고, 운영 DB(Tibero)에서 동작한 이력이 없습니다(검증은 MariaDB·Oracle까지). 재구현의 검증도 기능·보안 테스트 수준이며 부하 테스트는 포함하지 않습니다.
- 컬럼 조합이 늘수록 실행 계획 예측이 어려워집니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- 잘못된 메타데이터가 런타임 오류로 이어지는 문제는 재구현에서 등록 시 식별자 규칙 검증과 발행 전 소스 테이블 실존 확인으로 일부 보완했지만, 테스트 쿼리 실행 검증과 발행 후 스키마 변경 감지는 남은 과제입니다.

## Source {#source}

- [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge) — 핵심 구조 비식별화 재구현 (Java 21 · Spring Boot 3 · jOOQ)
- [README](https://github.com/hello-pebble/api-forge/blob/main/README.md) — 레거시 대비 재설계 포인트 · 실행 방법 · [아키텍처 다이어그램](https://github.com/hello-pebble/api-forge/blob/main/docs/architecture.svg)
