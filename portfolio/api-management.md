---
layout: default
title: "개방DB API관리 시스템 설계 및 프로토타입 개발"
permalink: /portfolio/api-management/
---

# 개방DB API관리 시스템 설계 및 프로토타입 개발

<span class="badge outline">회사 프로젝트</span>

> 조회 요구사항마다 유사한 엔드포인트를 추가하던 방식을 메타데이터 설정과 공통 SQL 변환 흐름으로 바꾼 프로젝트입니다.
> 운영 반영 전 이직했고, 같은 구조를 현대 스택으로 다시 구현해 [api-forge](https://github.com/hello-pebble/api-forge)로 공개했습니다.

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
    <small>메타데이터 3계층과 Generic SQL 변환</small>
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
    <span>재설계 검증</span>
    <small>api-forge · 계승·대체·보류 판단</small>
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

## 프로젝트 개요 {#overview}

- **구분**: 회사 프로젝트
- **기간**: 2024.09 ~ 2025.01 (5개월)
- **기술 스택**: Java 8, JSP, Spring MVC 4, 전자정부 표준프레임워크(eGovFrame), MyBatis, Apache Tomcat
- **DB 환경**: MariaDB(개발·테스트) → Oracle(통합 전 검증) → Tibero(운영)
- **핵심 역할**: 설계 기획, 메타데이터 기반 Generic SQL 변환 엔진 설계 및 구현
- **레거시 개선**: iBatis 기반 SQL 매퍼를 MyBatis로 전환
- **검증 범위**: 로컬·개발 환경에서 관리자 설정만으로 조회 API가 생성되는 동작 확인
- **공개 재구현**: 회사 코드는 비공개이므로, 핵심 구조(메타데이터 기반 조회·화이트리스트 검증·동적 SQL)를 비식별화해 재구현한 [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge)(테스트 50건, CI)에서 아래 예시를 발췌했습니다.

---

## 설계 의도 {#intent}

조회 대상 테이블과 컬럼이 달라질 때마다 비슷한 Controller·Service·SQL을 추가하면 변경 지점이 계속 늘어납니다. 조회 기능의 공통 부분을 메타데이터와 SQL 변환 엔진으로 모으고, 업무별 차이는 설정으로 표현하는 것을 목표로 했습니다.

---

## 문제 정의 및 원인 분석 {#problem}

- **문제**: 신규 조회 요구사항마다 테이블 스키마에 결합된 API와 SQL을 추가해야 했습니다.
- **원인**: 조회 대상, 조건, 정렬 규칙이 코드에 직접 들어가 있어 공통 처리와 업무별 차이를 분리하기 어려웠습니다.

조회 API 하나를 추가할 때 수정해야 하는 파일은 **5개**였습니다.

| # | 파일 | 역할 |
| :--- | :--- | :--- |
| **1** | `*Controller.java` | 요청 매핑 |
| **2** | `*Service.java` | 인터페이스 메서드 선언 |
| **3** | `*ServiceImpl.java` | 구현 |
| **4** | `*Dao.java` | 쿼리 ID 호출 |
| **5** | `*_SQL.xml` | SELECT 정의 |

관리 화면을 함께 제공하는 경우 JSP까지 6개였습니다. 파라미터와 결과는 VO 없이 Map 계열 객체로 주고받는 구조여서, 컬럼이 늘어날수록 컴파일 시점 검증이 되지 않는 문제도 함께 있었습니다.

---

## 해결 과정 {#solution}

![Generic API 엔진 - 개발 방식의 구조적 전환](/assets/images/portfolio/dbms-generic-engine.svg){:.portfolio-diagram}

### 1. 메타데이터 3계층 설계

조회 정의를 세 계층으로 분리해, 각 계층이 독립적으로 변경되도록 했습니다.

| 계층 | 관리 대상 | 주요 속성 |
| :--- | :--- | :--- |
| **데이터셋** | 소스 테이블의 스키마 | 컬럼ID, 컬럼형식, 길이, 필수 여부, 참조코드 |
| **API 서비스** | 외부에 노출할 형태 | 요청 주소, 출력 컬럼, 정렬 규칙, 일일 호출 제한 |
| **컬럼 옵션** | 조회 조건 | 필터 유형, 연산자, 데이터 제한 여부 |

### 2. Generic SQL 변환 엔진

UI에서 전달된 컬럼·조건 조합을 등록된 메타데이터와 대조하고, 통과한 것만 동적 SQL로 변환하도록 구성했습니다. 메타데이터에 없는 컬럼이나 허용되지 않은 연산자는 SQL 조립 단계에 진입하지 못합니다.

### 3. 환경별 DB 차이 대응

운영 DB는 Tibero였지만 개발 단계에서 직접 접근할 수 없었습니다. 일상 개발과 테스트는 MariaDB에서 진행하고, 통합 직전에 Oracle로 연동해 운영 환경에 가까운 조건에서 다시 검증하는 순서로 진행했습니다. Tibero가 Oracle 호환 인터페이스를 제공한다는 점을 이용해 검증 격차를 좁히려는 선택이었습니다.

고정 쿼리와 달리 런타임에 조립되는 SQL은 컬럼·조건 조합마다 방언 차이가 드러납니다. 조합이 늘어날수록 검증 경로가 급격히 늘기 때문에, **어디까지를 동적으로 만들 것인지 경계를 먼저 정했습니다.**

| 층 | 대상 | 처리 방식 |
| :--- | :--- | :--- |
| **바깥** | 페이징 | ROWNUM 기반 공통 래퍼를 XML에 고정, 값은 바인드 변수 |
| **중간** | DB 방언 | SQL 맵 세트를 디렉터리 단위로 분리하고 설정으로 전환 |
| **안쪽** | 조회 컬럼·조건 | 메타데이터 기반 동적 조립 |

페이징 구문을 조립 대상에 포함하면 DB 종류와 조건 조합의 곱만큼 경로가 늘어나 검증이 어려워집니다. 페이징은 고정 래퍼로 감싸고, 방언 차이는 쿼리 내부 분기가 아니라 파일 단위 교체로 처리해 동적 영역을 조회 컬럼과 조건에만 남겼습니다.

관리 화면의 목록 조회는 대상 건수가 적고 내부 사용자만 접근하므로, 방언에 의존하지 않는 ResultSet 스크롤을 기본값으로 두어 공개 조회 API와 다른 전략을 적용했습니다.

### 4. 관리 화면에서의 즉시 검증

메타데이터 등록 후 관리 화면에서 샘플 URL을 호출해 출력값과 처리 결과를 바로 확인할 수 있도록 설계했습니다. 잘못된 설정이 배포 이후에 발견되는 것을 줄이기 위한 장치입니다.

---

## 구현 근거 {#evidence}

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

## 기존 방식과 변경 방식 {#comparison}

| 항목 | 기존 방식 | 변경 방식 |
| :--- | :--- | :--- |
| **조회 API 1개 추가** | Controller·Service·ServiceImpl·DAO·SQL XML 5개 파일 (화면 동반 시 JSP 포함 6개) | 관리 화면에서 메타데이터 1건 등록 (코드 수정 0줄) |
| **반영 방법** | 빌드·재배포 필요 | 설정 등록·발행 즉시 반영 |
| **입력 검증 위치** | API마다 개별 구현 (누락 위험) | 엔진 한 곳의 화이트리스트 + 바인드 처리 |
| **기존 API 영향** | 수정 시 회귀 위험 공유 | 버전 라우팅으로 기존 경로 그대로 유지 |

**실제 적용 여부**: 로컬 환경에서 관리자 설정만으로 조회 API가 생성되는 것까지 검증한 프로토타입 단계이며, 운영에는 반영되지 않았습니다. 관리 화면에서 데이터셋 등록 → API 서비스 정의 → 테스트 호출까지 이어지는 흐름을 로컬 환경에서 확인했습니다. 운영 반영 전 퇴사한 것이 직접적인 사유이고, 반영을 위해서는 기존 API와의 호환성 검증과 실 트래픽 성능 검증이 남아 있었습니다. 미완으로 남은 검증을 대신 증명하기 위해 아래의 재구현 저장소를 만들었습니다.

---

## 재설계 검증 — api-forge {#reimpl}

운영 반영 전 이직해 실 검증을 하지 못했기 때문에, **같은 구조를 현대 스택으로 다시 구현해 동작과 안전성을 확인**했습니다.

**[api-forge](https://github.com/hello-pebble/api-forge)** — Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers

원 시스템의 소스는 비공개이며, 저장소는 아키텍처만 클린룸으로 재구현한 것입니다.

![api-forge 아키텍처 — 메타데이터 등록 흐름과 조회 흐름, SQL Injection 차단 지점](/assets/images/portfolio/apiforge-architecture.svg){:.portfolio-diagram}

| 레거시 | api-forge | 처리 |
| :--- | :--- | :--- |
| **필터 유형 + 연산자 조합** | `FilterType` 5종으로 고정 | 계승 (범위 축소) |
| **문자열 연결 SQL + 블랙리스트 필터** | jOOQ 타입 세이프 DSL + 식별자 화이트리스트 | 대체 |
| **Map 기반 파라미터** | DTO + Bean Validation | 대체 |
| **평문 인증키** | 해시 저장 + 상수 시간 검증 | 대체 |
| **개발·통합·운영 3종 DB를 단계별 수동 검증** | H2 · PostgreSQL을 Testcontainers로 CI 자동 검증 | 검증 방식 전환 |
| **DB별 SQL 맵 세트를 디렉터리 단위로 분리** | jOOQ가 방언을 추상화, 맵 중복 제거 | 대체 |
| **데이터셋 버전 · 일일 호출 제한** | 미구현 | 보류 |
| **Sheet 출력 속성 (정렬·너비)** | 미구현 | 제외 — 화면 표현은 API 응답의 책임이 아니라고 판단 |
| **관리 화면** | 미구현 (REST로 대체) | 제외 |

SQL 맵 세트를 통째로 교체하는 방식은 쿼리 내부에 분기를 두지 않는다는 장점이 있는 대신, 지원 DB가 늘어날수록 같은 쿼리를 여러 벌 유지해야 합니다. api-forge에서 jOOQ를 선택한 것은 방언 처리를 라이브러리에 위임해 이 중복을 없애기 위한 것입니다.

레거시에서 DB 방언 차이는 통합 시점에 몰아서 확인할 수밖에 없었습니다. api-forge에서 서로 다른 DB를 컨테이너로 띄워 매 커밋마다 동일 동작을 확인하도록 만든 것은 그 경험에서 나온 선택입니다.

레거시에서 가장 위험했던 지점은 요청 값이 문자열 조립으로 SQL에 들어가는 경로였습니다. api-forge는 식별자를 등록된 메타데이터로 제한하고 값은 예외 없이 바인드 파라미터로 처리하며, 인젝션 문자열이 단순 문자열 검색으로 처리되는 것을 통합 테스트로 확인합니다.

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

## 확인 가능한 변화 {#results}

- 로컬 환경에서 신규 조회 기능을 개별 엔드포인트 구현(5개, 화면 포함 6개 파일 수정) 대신 메타데이터 등록 1건으로 지원할 수 있는 구조임을 확인했습니다.
- 조회 요청 검증, SQL 생성, 결과 반환의 공통 흐름을 한 엔진에 모아, 허용 목록 검증과 바인드 처리가 누락될 수 있는 지점을 API 개수만큼에서 한 곳으로 줄였습니다.
- 조회 대상·조건이 코드에서 분리되면서, 스키마 변경의 영향 범위가 메타데이터로 좁혀졌습니다.
- 재구현 저장소(api-forge)에서 같은 구조의 화이트리스트·인젝션 방어를 자동화 테스트 50건과 CI로 검증했습니다.

---

## 한계 및 후속 과제 {#limitations}

- 회사 프로토타입은 운영 반영 전 퇴사하여 실 트래픽·동시성 검증은 수행하지 못했습니다. 위 수치는 로컬·개발 환경 기준입니다. 재구현 저장소의 검증도 기능·보안 테스트 수준이며 부하 테스트는 포함하지 않습니다.
- 메타데이터 엔진이 운영 DB(Tibero)에서 실제로 동작한 이력은 없습니다. 검증은 MariaDB와 Oracle까지였습니다.
- 컬럼 조합이 늘어날수록 쿼리 실행 계획을 예측하기 어려워집니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- 관리 화면의 ResultSet 스크롤 방식은 대상 건수가 커지면 메모리 사용이 늘어납니다. 데이터셋 수가 증가하면 공개 조회 API와 동일한 래퍼 기반 페이징으로 통일하는 편이 안전합니다.
- 잘못된 메타데이터가 런타임 오류로 이어지는 문제는 재구현에서 등록 시 식별자 규칙 검증과 발행 전 소스 테이블 실존 확인으로 일부 보완했지만, 테스트 쿼리 실행까지 검증하는 기능은 후속 과제입니다. 발행 이후의 스키마 변경 감지도 남아 있습니다.
- 데이터셋 버저닝·스키마 변경 감지, API 키별 rate limiting은 재구현 저장소의 로드맵에 남아 있는 미완 항목입니다.

---

## Source {#source}

- [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge) — 핵심 구조 비식별화 재구현 (Java 21 · Spring Boot 3 · jOOQ)
- [README](https://github.com/hello-pebble/api-forge/blob/main/README.md) — 레거시 대비 재설계 포인트 · 실행 방법 · [아키텍처 다이어그램](https://github.com/hello-pebble/api-forge/blob/main/docs/architecture.svg)
