---
layout: default
title: "개방DB API관리 — 메타데이터 기반 조회 API 엔진"
permalink: /portfolio/api-management/
---

<span class="project-context">회사 프로젝트 · 2024.09 — 2025.01 · Java 8 · Spring MVC · eGovFrame · MyBatis · Tibero</span>

# 개방DB API관리 — 메타데이터 기반 조회 API 엔진

- **문제** 개방데이터 요구사항이 하나 늘 때마다 Controller·Service·DAO·SQL XML 등 파일 5~6개를 새로 쓰고 재배포해야 했습니다.
- **설계** 조회 API 하나를 메타데이터 테이블의 행 하나로 만드는 엔진을 설계하고 프로토타입을 구현했습니다. 조회 추가에 빌드와 재배포가 필요 없어집니다.
- **어디까지** **개발 서버 적용까지 마친 상태에서 이직해, 운영 반영과 실트래픽 검증은 남기지 못했습니다.**
- **그래서** 검증하지 못한 그 구조가 실제로 성립하는지 확인하려고, 회사 코드는 가져오지 않고 설계 의도만 옮겨 개인 프로젝트 **api-forge**로 다시 구현했습니다. 아래 재구현 절의 모든 코드·테스트·수치는 그쪽에서 나온 것입니다.

<nav class="project-page-nav" aria-label="개방DB API관리 프로젝트 목차">
  <a href="#reimplementation">
    <span>재구현 — api-forge</span>
    <small>개인 · 2026.07 — 진행 중</small>
  </a>
  <a href="#engine">
    <span>01. 엔진이 하는 일</span>
    <small>메타데이터 행 하나 = API 하나</small>
  </a>
  <a href="#injection">
    <span>02. 인젝션 차단</span>
    <small>화이트리스트 한 지점</small>
  </a>
  <a href="#legacy">
    <span>03. 택한 것과 버린 것</span>
    <small>틀렸을 때 드러나는가</small>
  </a>
  <a href="#limitations">
    <span>한계</span>
    <small>남은 검증 과제</small>
  </a>
</nav>

## 재구현 — api-forge {#reimplementation}

<span class="project-context">개인 프로젝트 · 2026.07 — 진행 중 · Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers · CI</span>

식별자 화이트리스트를 방어의 단일 지점으로 두고, 공격 입력 시나리오를 매 커밋 CI에서 돌려 인젝션 차단을 확인합니다. **회사에서 하지 못한 검증을 이것으로 대신합니다.**

### 01. 엔진이 하는 일 — 메타데이터 행 하나가 API 하나 {#engine}

- **`DATASET`** 조회 대상 테이블과 URL 키를 정의합니다.
- **`DATASET_COLUMN`** 노출 컬럼과 허용 필터·정렬을 정의하며, 여기 등록된 컬럼만 조회·필터·정렬에 쓸 수 있습니다.
- **연산자** 클라이언트가 아니라 컬럼의 `filterType`이 결정합니다. 관리자가 등록하는 것은 연산자 문자열이 아니라 **닫힌 유형 5개 중 하나**라, 관리자조차 임의의 SQL 조각을 넣을 수 없습니다. 화이트리스트가 조회 시점이 아니라 **메타데이터 등록 시점부터** 성립합니다.
- **유형 이름** 공공데이터포털의 검색 UI를 기준으로 붙였습니다 — `WORDS`는 검색어 입력창, `CHECK`는 체크박스 필터에 대응합니다.
- **샘플 컬럼명** 행정안전부 [공공데이터 공통표준용어](https://www.data.go.kr/data/15156379/fileData.do)의 영문약어 규칙을 따랐습니다(`NM`=명, `DT`=일자). 아래 데이터는 전부 가상입니다.

| sourceColumn | displayName | filterType | sortable | 요청 예시 |
| :--- | :--- | :--- | :--- | :--- |
| **BILL_ID** | 의안번호 | EQUALS (=) | ✓ | `?BILL_ID=2200001` |
| **BILL_NM** | 의안명 | WORDS (LIKE) | ✗ | `?BILL_NM=데이터` |
| **COMMITTEE** | 소관위원회 | CHECK (IN) | ✓ | `?COMMITTEE=행정안전위원회,정무위원회` |
| **PROPOSE_DT** | 발의일자 | DATE (BETWEEN) | ✓ | `?PROPOSE_DT=2026-01-01,2026-06-30` |
| **BILL_STATUS** | 처리상태 | NONE (필터 불가) | ✗ | 응답에는 나오지만 조건으로 쓰면 `400` |

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

### 02. 인젝션 차단 — 방어 지점이 엔진 한 곳 {#injection}

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

이 방어가 실제 공격 입력에서 성립하는지 매 커밋 CI에서 확인합니다.

| 공격 시나리오 | 결과 |
| :--- | :--- |
| 미등록 컬럼으로 필터 요청 | `400`으로 거부합니다. |
| `BILL_ID; DROP TABLE …` 파라미터명 위장 | `400`으로 거부합니다. |
| `' OR '1'='1` 값 주입 | 문자열 리터럴로 바인드 처리합니다. |

- **단위 테스트** SQL 조립기를 순수 단위 테스트로 검증합니다.
- **통합 테스트** 등록 → 발행 → 조회 파이프라인을 MockMvc로 검증합니다.
- **방언 교차 검증** 인젝션 시나리오를 H2와 PostgreSQL(Testcontainers) 양쪽에 동일하게 두어, DB 방언 차이까지 같은 엔진으로 확인합니다.

### 03. 택한 것과 버린 것 {#legacy}

재구현하면서 **어느 지점을 그대로 두지 않을지**를 먼저 정했습니다. 셋 다 "동작하느냐"가 아니라 "틀렸을 때 어떻게 드러나느냐"를 기준으로 골랐습니다.

| 선택 | 대신 택하지 않은 것 | 택한 이유 |
| :--- | :--- | :--- |
| jOOQ 타입 세이프 DSL + 식별자 화이트리스트 | 문자열 조립 + 차단 목록 필터 | 차단 목록은 **방어 범위가 목록의 완전성에 묶입니다.** 빠뜨린 한 줄이 곧 구멍이고, 빠뜨렸다는 사실이 사고 전까지 드러나지 않습니다. |
| DTO + Bean Validation · 인증키 해시 저장 + 상수 시간 검증 | Map 파라미터 전달 · 원문 대조 | Map은 컴파일 시점 검증이 없어 오타가 런타임까지 갑니다. 인증키는 **저장소가 유출돼도 키 자체는 복원되지 않아야** 한다고 봤습니다. |
| jOOQ `limit().offset()` 하나로 통일 | 방언별 페이징 래퍼 | 페이징이 방언에 결합되면 DB를 바꿀 때 래퍼도 함께 바꿔야 하고, 그 지점이 조회마다 복제됩니다. |

#### 지원 DB를 늘리는 대신 검증되는 형태로 {#dialect}

{% include diagrams/apiforge-dialect-decision.svg %}

방언 대응을 설계하며 정한 원칙입니다. **설정에 여러 DB를 나열해 두는 것과 그 전환이 실제로 되는 것은 다릅니다.** SQL을 방언별 파일로 관리하는 구조에서는 지원 목록에 한 줄을 더하는 순간 복제해야 할 SQL 자산이 통째로 늘고, 실행해 본 적 없는 경로는 지원한다고 적혀 있을 뿐 검증되지 않은 채 남습니다. **그래서 지원 목록을 늘리는 대신 검증되는 개수만 두기로 했습니다.**

- **api-forge의 처리** SQL을 파일로 관리하지 않으므로 방언별로 복제할 SQL 자산 자체가 없습니다. 같은 쿼리 정의를 jOOQ가 방언별로 렌더링합니다.
- **검증 방식** H2·PostgreSQL 2종을 Spring Profile로 전환하고, Testcontainers로 실제 PostgreSQL 컨테이너를 띄워 **동일 동작과 인젝션 방어의 이식성**을 함께 확인합니다.
- **실행** `./mvnw spring-boot:run` 한 줄로 실행되며, 시드된 가상 데이터셋으로 위 요청을 그대로 재현할 수 있습니다.

### 한계 {#limitations}

- **검증 범위** 기능·보안 테스트 수준이며 부하 테스트는 포함하지 않았습니다. 회사 프로토타입도 운영 반영 전 이직해 실트래픽·동시성 검증 이력이 없습니다.
- **성능 예측** 컬럼 조합이 늘수록 실행 계획을 예측하기 어렵습니다. 운영 확대 시 슬로우 쿼리 수집과 조합별 성능 검증이 필요합니다.
- **메타데이터 오류** 등록 시 식별자 규칙 검증과 발행 전 소스 테이블 실존 확인으로 일부 보완했지만, 테스트 쿼리 실행 검증과 발행 후 스키마 변경 감지는 과제로 남았습니다.
- **미구현** 데이터셋 버전과 일일 호출 제한은 로드맵으로 남겼고, Sheet 출력 속성은 화면 표현이 API 응답의 책임이 아니라고 판단해 제외했습니다.

### Source {#source}

- [github.com/hello-pebble/api-forge](https://github.com/hello-pebble/api-forge) — Java 21 · Spring Boot 3.5 · jOOQ · Testcontainers
- [README](https://github.com/hello-pebble/api-forge/blob/main/README.md) — 레거시 대비 재설계 포인트 · 실행 방법 · [아키텍처 다이어그램](https://github.com/hello-pebble/api-forge/blob/main/docs/architecture.svg)
