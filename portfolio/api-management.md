---
layout: default
title: "메타데이터 기반 조회 API 엔진 — api-forge"
permalink: /portfolio/api-management/
---

<span class="project-context">Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers · CI — 회사 프로토타입(2024.09—2025.01)의 재구현</span>

# 메타데이터 기반 조회 API 엔진 — api-forge

- **하는 일** 조회 API 하나를 메타데이터 테이블의 행 하나로 만듭니다.
- **바꾼 것** 신규 조회마다 Controller·Service·DAO·SQL XML 5개 파일을 추가하던 것을, 메타데이터 등록 1건으로 바꿨습니다. 빌드와 재배포가 필요 없습니다.
- **출발점** 회사 프로토타입(Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero)을 개발 서버까지 적용한 상태에서 이직해 검증이 미완으로 남았습니다.
- **현재** 핵심 구조를 클린룸으로 재구현한 **[api-forge](https://github.com/hello-pebble/api-forge)** 가 그 검증을 대신하며, 테스트 50건이 매 커밋 CI에서 실행됩니다.

<nav class="project-page-nav" aria-label="api-forge 프로젝트 목차">
  <a href="#engine">
    <span>01. 엔진이 하는 일</span>
    <small>메타데이터 행 하나 = API 하나</small>
  </a>
  <a href="#injection">
    <span>02. 인젝션 차단</span>
    <small>화이트리스트 한 지점</small>
  </a>
  <a href="#legacy">
    <span>03. 레거시에서 바꾼 것</span>
    <small>문자열 SQL → jOOQ</small>
  </a>
  <a href="#limitations">
    <span>한계</span>
    <small>남은 검증 과제</small>
  </a>
</nav>

## 01. 엔진이 하는 일 — 메타데이터 행 하나가 API 하나 {#engine}

- **`DATASET`** 조회 대상 테이블과 URL 키를 정의합니다.
- **`DATASET_COLUMN`** 노출 컬럼과 허용 필터·정렬을 정의하며, 여기 등록된 컬럼만 조회·필터·정렬에 쓸 수 있습니다.
- **연산자** 클라이언트가 아니라 컬럼의 `filterType`이 결정합니다. 아래 데이터는 전부 가상입니다.

| sourceColumn | displayName | filterType | sortable | 요청 예시 |
| :--- | :--- | :--- | :--- | :--- |
| **BILL_ID** | 의안번호 | EQUALS (=) | ✓ | `?BILL_ID=2200001` |
| **BILL_NM** | 의안명 | WORDS (LIKE) | ✗ | `?BILL_NM=데이터` |
| **COMMITTEE** | 소관위원회 | CHECK (IN) | ✓ | `?COMMITTEE=행정안전위원회,정무위원회` |
| **PROPOSE_DT** | 발의일자 | DATE (BETWEEN) | ✓ | `?PROPOSE_DT=2026-01-01,2026-06-30` |

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

![api-forge 아키텍처 — 메타데이터 등록 흐름과 조회 흐름, SQL Injection 차단 지점](/assets/images/portfolio/apiforge-architecture.svg){:.portfolio-diagram}

## 02. 인젝션 차단 — 방어 지점이 엔진 한 곳 {#injection}

- **SQL에 들어가는 식별자** 요청 파라미터명이 아니라 메타데이터에 저장된 컬럼명을 씁니다.
- **요청 파라미터명의 역할** 조회 키로만 쓰이고 버려집니다.
- **효과** 검증·바인드 누락이 생길 수 있는 지점이 API 개수만큼에서 엔진 한 곳으로 줄었습니다.

```java
DatasetColumn col = dataset.findColumn(paramName)
        .orElseThrow(() -> new InvalidQueryException("지원하지 않는 필터 파라미터입니다: " + paramName));
if (col.getFilterType() == FilterType.NONE) {
    throw new InvalidQueryException("필터가 허용되지 않은 칼럼입니다: " + paramName);
}
Field<Object> field = DSL.field(DSL.name(col.getSourceColumn())); // SQL에는 메타데이터의 컬럼명만 들어간다
```

이 방어의 동작은 테스트 50건이 매 커밋 CI에서 증명합니다.

| 공격 시나리오 | 결과 |
| :--- | :--- |
| 미등록 컬럼으로 필터 요청 | `400`으로 거부합니다. |
| `BILL_ID; DROP TABLE …` 파라미터명 위장 | `400`으로 거부합니다. |
| `' OR '1'='1` 값 주입 | 문자열 리터럴로 바인드 처리합니다. |

- **단위 테스트** SQL 조립기를 순수 단위 테스트로 검증합니다.
- **통합 테스트** 등록 → 발행 → 조회 파이프라인을 MockMvc로 검증합니다.
- **방언 교차 검증** 인젝션 시나리오를 H2와 PostgreSQL(Testcontainers) 양쪽에 동일하게 두어, DB 방언 차이까지 같은 엔진으로 확인합니다.

## 03. 레거시에서 바꾼 것 {#legacy}

| 레거시 | api-forge | 바꾼 이유 |
| :--- | :--- | :--- |
| 문자열 연결 SQL + 블랙리스트 필터 | jOOQ 타입 세이프 DSL + 식별자 화이트리스트 | 가장 위험했던 지점이었습니다. |
| DB별 SQL 맵 디렉터리 교체 | jOOQ가 방언을 추상화 | 지원 DB 수만큼 같은 쿼리를 유지해야 했던 중복을 라이브러리에 위임했습니다. |
| 3종 DB 단계별 수동 검증 | H2·PostgreSQL Testcontainers 매 커밋 검증 | 방언 차이를 통합 시점에 몰아서 확인해야 했습니다. |
| Map 기반 파라미터 · 평문 인증키 | DTO + Bean Validation · 해시 저장 + 상수 시간 검증 | 컴파일 시점 검증이 없고 자격증명이 노출됐습니다. |

- **디렉터리 교체 방식의 대가** 쿼리 내부 분기는 사라지지만, 지원 DB가 늘수록 같은 쿼리를 그 수만큼 유지해야 했습니다.
- **실행** `./mvnw spring-boot:run` 한 줄로 실행되며, 시드된 가상 데이터셋으로 위 요청을 그대로 재현할 수 있습니다.

## 한계 {#limitations}

- **검증 범위** 기능·보안 테스트 수준이며 부하 테스트는 포함하지 않았습니다. 회사 프로토타입도 운영 반영 전 이직해 실트래픽·동시성 검증 이력이 없습니다.
- **성능 예측** 컬럼 조합이 늘수록 실행 계획을 예측하기 어렵습니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- **메타데이터 오류** 등록 시 식별자 규칙 검증과 발행 전 소스 테이블 실존 확인으로 일부 보완했지만, 테스트 쿼리 실행 검증과 발행 후 스키마 변경 감지는 과제로 남았습니다.
- **미구현** 데이터셋 버전과 일일 호출 제한은 로드맵으로 남겼고, Sheet 출력 속성은 화면 표현이 API 응답의 책임이 아니라고 판단해 제외했습니다.

## Source {#source}

- [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge) — Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers
- [README](https://github.com/hello-pebble/api-forge/blob/main/README.md) — 레거시 대비 재설계 포인트 · 실행 방법 · [아키텍처 다이어그램](https://github.com/hello-pebble/api-forge/blob/main/docs/architecture.svg)
