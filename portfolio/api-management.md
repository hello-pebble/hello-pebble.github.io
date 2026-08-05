---
layout: default
title: "개방DB API관리 시스템 설계 및 프로토타입 개발"
permalink: /portfolio/api-management/
---

# 개방DB API관리 시스템 설계 및 프로토타입 개발

<span class="badge outline">회사 프로젝트</span>

> 조회 요구사항마다 유사한 엔드포인트를 추가하던 방식을 메타데이터 설정과 공통 SQL 변환 흐름으로 바꾼 프로젝트입니다. 회사 코드는 공개할 수 없어, 핵심 구조를 비식별화해 재구현한 저장소([api-forge](https://github.com/hello-pebble/api-forge))를 함께 제공합니다.

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
    <small>메타데이터·SQL·응답 예시</small>
  </a>
  <a href="#comparison">
    <span>기존 vs 변경</span>
    <small>API 추가 비용과 적용 여부</small>
  </a>
  <a href="#reimpl">
    <span>재구현 저장소</span>
    <small>api-forge · 테스트로 검증</small>
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
- **공개 재구현**: 회사 코드는 비공개이므로, 핵심 구조(메타데이터 기반 조회·화이트리스트 검증·동적 SQL)를 비식별화해 재구현한 [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge)에서 아래 예시를 발췌했습니다.

---

## Intent (설계 의도) {#intent}

조회 대상 테이블과 컬럼이 달라질 때마다 비슷한 Controller·Service·SQL을 추가하면 변경 지점이 계속 늘어납니다. 조회 기능의 공통 부분을 메타데이터와 SQL 변환 엔진으로 모으고, 업무별 차이는 설정으로 표현하는 것을 목표로 했습니다.

---

## Problem (문제 정의 및 원인 분석) {#problem}

- **문제**: 신규 조회 요구사항마다 테이블 스키마에 결합된 API와 SQL을 추가해야 했습니다.
- **비용**: 조회 API 1개를 추가하려면 Controller, Service, DAO 인터페이스, Mapper XML, 응답 DTO(필요 시 JSP 화면까지) 약 5~6개 파일을 만들거나 수정하고 재배포해야 했습니다.
- **원인**: 조회 대상, 조건, 정렬 규칙이 코드에 직접 들어가 있어 공통 처리와 업무별 차이를 분리하기 어려웠습니다.

---

## Solution (해결 과정) {#solution}

![Generic API 엔진 - 개발 방식의 구조적 전환](/assets/images/portfolio/dbms-generic-engine.svg){:.portfolio-diagram}

1. **데이터 스키마 추상화 관리 체계 수립**
   - 조회 가능한 테이블·컬럼·조건을 메타데이터로 관리하는 **스키마 추상화 레이어**를 도입했습니다.
2. **Generic API 엔진 설계 및 리플렉션 응용**
   - MyBatis의 동적 쿼리 생성과 Java Reflection API 개념을 응용했습니다.
   - UI에서 전달된 컬럼·조건 조합을 메타데이터와 대조하고 MyBatis 동적 SQL로 변환하는 **Generic API 엔진**을 구현했습니다.
3. **API 버전 관리 체계 구축**
   - 기존 조회 경로와 신규 조회 경로를 분리할 수 있도록 버전별 라우팅 구조를 적용했습니다.

### 왜 Reflection이었나 — MyBatis 동적 SQL만으로 부족했던 지점

- **MyBatis 동적 SQL은 "정해진 쿼리 골격 안의 분기"까지만 가능합니다.** `<if>`·`<choose>`는 Mapper XML에 미리 작성된 쿼리 안에서 조건을 켜고 끄는 도구라, 조회 대상 테이블과 컬럼 조합 자체가 런타임 메타데이터로 결정되는 구조에서는 골격을 미리 정의할 수 없었습니다.
- **결과 매핑을 정적으로 고정할 수 없었습니다.** 테이블마다 resultMap과 DTO를 만들면 다시 테이블 수만큼 코드가 늘어나므로, 조회 결과를 Map으로 받아 메타데이터에 정의된 컬럼·표시명 규칙에 따라 응답 구조로 변환하는 지점에 Reflection을 응용했습니다.
- **식별자는 바인드 파라미터로 처리할 수 없습니다.** 테이블·컬럼명은 `#{}` 바인딩이 불가능하고 `${}` 문자열 치환은 SQL Injection 표면이 됩니다. 그래서 식별자는 반드시 메타데이터 화이트리스트에 등록된 값만 SQL에 넣는 검증을 전제 조건으로 설계했습니다.

---

## Implementation Evidence (구현 근거) {#evidence}

아래 예시는 회사 코드가 아니라, 동일한 구조를 비식별화해 재구현한 [api-forge](https://github.com/hello-pebble/api-forge)에서 발췌했습니다. 데이터는 전부 가상 데이터입니다.

### 1. 메타데이터 구조와 예시

API 엔드포인트 하나가 메타데이터 테이블의 행 하나입니다. `DATASET`이 조회 대상 테이블과 URL 키를, `DATASET_COLUMN`이 노출 컬럼과 허용 필터·정렬을 정의합니다.

| 테이블 | 역할 | 핵심 필드 |
| :--- | :--- | :--- |
| **DATASET** | API 1개 정의 | `datasetKey`(URL 경로 키) · `sourceTable`(조회 대상 테이블) · `status`(DRAFT/PUBLISHED) |
| **DATASET_COLUMN** | 노출 컬럼 화이트리스트 | `sourceColumn` · `displayName` · `filterType` · `sortable` |

`bills`(가상 의안 정보) 데이터셋의 실제 등록 예시입니다. 여기 등록된 컬럼만 조회·필터·정렬에 쓸 수 있습니다.

| sourceColumn | displayName | filterType | sortable | 요청 예시 |
| :--- | :--- | :--- | :--- | :--- |
| **BILL_ID** | 의안번호 | EQUALS (=) | ✓ | `?BILL_ID=2200001` |
| **BILL_NM** | 의안명 | WORDS (LIKE) | ✗ | `?BILL_NM=데이터` |
| **PROPOSER** | 대표발의 | WORDS (LIKE) | ✗ | `?PROPOSER=김민준` |
| **COMMITTEE** | 소관위원회 | CHECK (IN) | ✓ | `?COMMITTEE=행정안전위원회,정무위원회` |
| **PROPOSE_DT** | 발의일자 | DATE (BETWEEN) | ✓ | `?PROPOSE_DT=2026-01-01,2026-06-30` |
| **BILL_STATUS** | 처리상태 | CHECK (IN) | ✓ | `?BILL_STATUS=위원회 심사` |

연산자는 클라이언트가 지정하는 것이 아니라 컬럼의 `filterType`이 결정합니다. `NONE`으로 등록된 컬럼은 결과에만 노출되고 필터가 거부되므로, 연산자를 주입할 수 있는 표면 자체가 없습니다.

### 2. 요청 → 검증 → 생성 SQL → 응답

**요청** — "행정안전위·정무위 소관, 2026년 상반기 발의 의안을 최신순으로":

```
GET /api/v1/datasets/bills?COMMITTEE=행정안전위원회,정무위원회&PROPOSE_DT=2026-01-01,2026-06-30&sort=PROPOSE_DT,desc&page=0&size=20
X-API-Key: demo-api-key-…
```

**검증** — 엔진은 SQL을 만들기 전에 요청을 메타데이터와 대조합니다.

1. `page`·`size`·`sort`·`format` 예약 파라미터를 분리하고, 나머지 파라미터명을 `DATASET_COLUMN`에서 조회 — 미등록이면 즉시 400
2. 컬럼의 `filterType`으로 연산자 결정 (`COMMITTEE`→IN, `PROPOSE_DT`→BETWEEN)
3. `sort` 대상 컬럼의 `sortable` 확인 — 허용되지 않으면 400
4. 요청 값은 전부 바인드 파라미터로 처리, SQL에 들어가는 식별자는 메타데이터에 저장된 컬럼명만 사용

**생성 SQL** — 문자열 연결로 조립되는 지점이 없습니다:

```sql
SELECT "BILL_ID", "BILL_NM", "PROPOSER", "COMMITTEE", "PROPOSE_DT", "BILL_STATUS"
FROM "NA_BILL"
WHERE "COMMITTEE" IN (?, ?)
  AND "PROPOSE_DT" BETWEEN ? AND ?
ORDER BY "PROPOSE_DT" DESC
LIMIT 20 OFFSET 0
-- 바인드 값: '행정안전위원회', '정무위원회', 2026-01-01, 2026-06-30
```

**응답**:

```json
{
  "datasetKey": "bills",
  "page": 0,
  "size": 20,
  "totalCount": 8,
  "data": [
    {
      "BILL_ID": "2200042",
      "BILL_NM": "데이터 이용 활성화에 관한 법률 일부개정안",
      "PROPOSER": "김민준",
      "COMMITTEE": "정무위원회",
      "PROPOSE_DT": "2026-06-12",
      "BILL_STATUS": "위원회 심사"
    }
  ]
}
```

### 3. 허용 목록 검증 실패 시 응답

등록되지 않은 컬럼으로 필터하면 SQL 생성 전에 거부됩니다.

```
GET /api/v1/datasets/bills?EVIL_COL=x
```

```json
{ "timestamp": "2026-08-05T12:34:56", "status": 400, "message": "지원하지 않는 필터 파라미터입니다: EVIL_COL" }
```

정렬이 허용되지 않은 컬럼(`sortable=false`)도 마찬가지입니다.

```
GET /api/v1/datasets/bills?sort=BILL_NM
```

```json
{ "timestamp": "2026-08-05T12:35:10", "status": 400, "message": "정렬이 허용되지 않은 칼럼입니다: BILL_NM" }
```

이를 막는 지점은 엔진 한 곳입니다. SQL에 들어가는 식별자는 요청 파라미터명이 아니라 메타데이터에 저장된 컬럼명이며, 요청 파라미터명은 조회 키로만 쓰이고 버려집니다.

```java
DatasetColumn col = dataset.findColumn(paramName)
        .orElseThrow(() -> new InvalidQueryException("지원하지 않는 필터 파라미터입니다: " + paramName));
if (col.getFilterType() == FilterType.NONE) {
    throw new InvalidQueryException("필터가 허용되지 않은 칼럼입니다: " + paramName);
}
Field<Object> field = DSL.field(DSL.name(col.getSourceColumn())); // SQL에는 메타데이터의 컬럼명만 들어간다
```

방어가 실제로 동작하는지는 재구현 저장소의 테스트로 확인할 수 있습니다. 전부 CI에서 통과합니다.

| 테스트 (@DisplayName) | 결과 |
| :--- | :--- |
| **등록되지 않은 칼럼으로 필터하면 거부한다 — 화이트리스트** | 400 거부 ✓ |
| **SQL 조각을 파라미터명으로 위장한 요청은 칼럼 조회 단계에서 거부된다** (`BILL_ID; DROP TABLE …`) | 400 거부 ✓ |
| **필터 값의 SQL 조각은 바인드 파라미터로 문자열 처리된다** (`' OR '1'='1`) | 문자열 리터럴 처리 ✓ |
| **SQL Injection 시도 값은 바인드 파라미터로 처리되어 0건 — PostgreSQL에서도 유효** | 200 · totalCount 0 ✓ |

마지막 시나리오는 H2와 PostgreSQL(Testcontainers) 양쪽 통합 테스트에 동일하게 존재합니다. 같은 메타데이터와 같은 엔진이 두 DB에서 그대로 검증됩니다.

---

## Comparison (기존 방식과 변경 방식) {#comparison}

| 항목 | 기존 방식 | 변경 방식 |
| :--- | :--- | :--- |
| **조회 API 1개 추가** | Controller·Service·DAO·Mapper XML·응답 DTO 등 5~6개 파일 작성/수정 | 메타데이터 1건 등록 (코드 수정 0줄) |
| **반영 방법** | 빌드·재배포 필요 | 설정 등록·발행 즉시 반영 |
| **입력 검증 위치** | API마다 개별 구현 (누락 위험) | 엔진 한 곳의 화이트리스트 + 바인드 처리 |
| **기존 API 영향** | 수정 시 회귀 위험 공유 | 버전 라우팅으로 기존 경로 그대로 유지 |

**실제 적용 여부**: 로컬 환경에서 관리자 설정만으로 조회 API가 생성되는 것까지 검증한 프로토타입 단계이며, 운영에는 반영되지 않았습니다. 운영 반영 전 퇴사한 것이 직접적인 사유이고, 반영을 위해서는 기존 API와의 호환성 검증과 실 트래픽 성능 검증이 남아 있었습니다. 미완으로 남은 검증을 대신 증명하기 위해 아래의 재구현 저장소를 만들었습니다.

---

## Reimplementation (재구현 저장소 api-forge) {#reimpl}

회사 코드는 공개할 수 없으므로, 이 프로젝트에서 설계한 핵심 구조를 비식별화해 처음부터 다시 구현한 저장소가 [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge)입니다. 관리자가 테이블·컬럼 메타데이터를 등록·발행하면 코드 수정 없이 필터·정렬·페이징·멀티포맷(JSON·CSV·XML·Excel·RDF) Open API가 생성되는, 같은 문제의식의 재구현입니다.

![api-forge 아키텍처 — 메타데이터 등록 흐름과 조회 흐름, SQL Injection 차단 지점](/assets/images/portfolio/apiforge-architecture.svg){:.portfolio-diagram}

원본과 같은 코드가 아니라 같은 설계를 현대 스택으로 다시 검증한 것이므로, 차이를 그대로 밝힙니다.

| | 회사 프로토타입 (원본) | api-forge (재구현) |
| :--- | :--- | :--- |
| **스택** | Java 8 · Spring MVC · MyBatis · MariaDB | Java 21 · Spring Boot 3 · jOOQ · H2/PostgreSQL |
| **동적 SQL** | MyBatis 동적 SQL + 화이트리스트 검증 | jOOQ DSL — 문자열 조립 없이 API로 쿼리 구성 |
| **결과 매핑** | Map + Reflection 응용 변환 | jOOQ `fetchMaps()` + 포맷별 Writer 전략 |
| **검증 수단** | 로컬 수동 확인 | 자동화 테스트 50건 + GitHub Actions CI |

재구현에서 방어와 동작을 테스트로 증명한 범위:

| 검증 항목 | 확인 방법 |
| :--- | :--- |
| **화이트리스트 차단** | 미등록 컬럼·비허용 필터·비허용 정렬 요청 → 400 (단위 테스트 12건) |
| **SQL Injection 방어** | 파라미터명 위장·값 주입 시나리오를 H2·PostgreSQL 양쪽에서 검증 |
| **등록→발행→조회 E2E** | 메타데이터 등록만으로 API가 열리는 전체 파이프라인 통합 테스트 (H2 18건) |
| **DB 이식성** | 동일 엔진이 PostgreSQL 16(Testcontainers)에서 그대로 동작 (12건) |
| **CI** | main push·PR마다 `mvnw verify` 전체 실행 (GitHub Actions) |

`./mvnw spring-boot:run` 한 줄로 실행되며, 시드된 가상 데이터셋과 데모 API 키로 위 요청 예시를 그대로 재현할 수 있습니다.

---

## Results (확인 가능한 변화) {#results}

- 로컬 환경에서 신규 조회 기능을 개별 엔드포인트 구현(5~6개 파일 수정) 대신 메타데이터 등록 1건으로 지원할 수 있는 구조임을 확인했습니다.
- 조회 요청 검증, SQL 생성, 결과 반환의 공통 흐름을 한 엔진에 모아, 허용 목록 검증과 바인드 처리가 누락될 수 있는 지점을 API 개수만큼에서 한 곳으로 줄였습니다.
- 기존 API를 유지한 상태에서 신규 조회 방식을 별도 버전으로 적용할 수 있게 했습니다.
- 재구현 저장소(api-forge)에서 같은 구조의 화이트리스트·인젝션 방어를 자동화 테스트 50건과 CI로 검증했습니다.

---

## Limitations (한계 및 후속 과제) {#limitations}

- 회사 프로토타입은 운영 반영 전 퇴사하여 실 트래픽·동시성 검증은 수행하지 못했습니다. 재구현 저장소의 검증도 기능·보안 테스트 수준이며 부하 테스트는 포함하지 않습니다.
- 컬럼 조합이 늘어날수록 쿼리 실행 계획을 예측하기 어려워집니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- 잘못된 메타데이터가 런타임 오류로 이어지는 문제는 재구현에서 등록 시 식별자 규칙 검증과 발행 전 소스 테이블 실존 확인으로 일부 보완했지만, 테스트 쿼리 실행까지 검증하는 기능은 후속 과제입니다.
- 데이터셋 버저닝·스키마 변경 감지, API 키별 rate limiting은 재구현 저장소의 로드맵에 남아 있는 미완 항목입니다.

---

## Source {#source}

- [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge) — 핵심 구조 비식별화 재구현 (Java 21 · Spring Boot 3 · jOOQ)
- [README](https://github.com/hello-pebble/api-forge/blob/main/README.md) — 레거시 대비 재설계 포인트 · 실행 방법 · [아키텍처 다이어그램](https://github.com/hello-pebble/api-forge/blob/main/docs/architecture.svg)
