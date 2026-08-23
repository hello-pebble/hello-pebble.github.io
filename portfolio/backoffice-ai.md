---
layout: default
title: "Backoffice AI — 업무·콘텐츠 자동화 운영 플랫폼"
permalink: /portfolio/backoffice-ai/
category: portfolio
tags: [Kotlin, SpringBoot, Python, FastAPI, PostgreSQL, Supabase, Vercel, Railway, Docker]
---

<span class="project-context">개인 프로젝트 · 2026.08 — 진행 중 · 기획·구현·배포 구성 단독</span>

# Backoffice AI — 업무·콘텐츠 자동화 운영 플랫폼

- **서비스** 업무 현황, 승인, AI 뉴스 브리핑, Gmail 요약, 관심 종목, 콘텐츠 스튜디오와 블로그 자동화를 한 화면에서 다루는 개인 운영 대시보드입니다.
- **문제** 화면 요청 안에서 Python 자동화를 직접 실행하면 긴 작업이 웹 서버를 점유하고, 배포마다 컨테이너 파일이 초기화되면 OAuth 연결도 끊깁니다.
- **핵심 선택** 화면·API·자동화 워커를 각각 배포 가능한 단위로 분리했습니다. 브라우저 요청은 Kotlin API가 빠르게 판정하고, 시간이 걸리는 작업은 인증된 Python 워커로 위임합니다.
- **배포 기준** 정적 화면은 Vercel, Kotlin API와 Python 워커는 Railway, 운영 데이터와 Gmail OAuth 토큰은 Supabase PostgreSQL에 둡니다.

<nav class="project-page-nav" aria-label="Backoffice AI 프로젝트 목차">
  <a href="#architecture"><span>서비스 아키텍처</span><small>화면·API·워커 분리</small></a>
  <a href="#delivery"><span>배포 흐름</span><small>PR부터 운영 반영까지</small></a>
  <a href="#operations"><span>운영 경계</span><small>인증·실행 잠금·검토</small></a>
  <a href="#persistence"><span>재배포 이후</span><small>DB·OAuth 토큰 보존</small></a>
  <a href="#verification"><span>검증과 한계</span><small>확인한 범위</small></a>
</nav>

## 서비스 아키텍처 — 요청 경로와 작업 경로를 분리 {#architecture}

![Backoffice AI 서비스 아키텍처 — Vercel 화면이 Railway Kotlin API로 요청하고, API는 Supabase PostgreSQL 및 인증된 Railway Python 워커와 통신한다. 워커는 외부 AI·네이버 API를 사용하며 실제 발행은 검토 전 차단된다.](/assets/images/portfolio/backoffice-ai-architecture.svg){:.portfolio-diagram}

| 경로 | 책임 | 분리한 이유 |
| :--- | :--- | :--- |
| **Vercel 프런트엔드** | 단일 정적 대시보드와 `/api/*` 요청 전달 | 화면 배포를 API 릴리스와 독립시킵니다. |
| **Railway Kotlin API** | 업무·승인·외부 정보 API, API 키 검증, 워커 호출 | 브라우저의 짧은 요청과 도메인 규칙을 맡습니다. |
| **Supabase PostgreSQL** | 업무 데이터, 자동화 이력, Gmail OAuth 토큰 | 컨테이너 파일시스템에 남기지 않아 재배포에도 상태를 유지합니다. |
| **Railway Python 워커** | 키워드 수집·콘텐츠 생성·발행·스케줄러 | Selenium·AI 호출처럼 오래 걸리거나 실패 가능성이 큰 일을 웹 요청 경로에서 분리합니다. |

- 프런트엔드의 `/api/*`는 Vercel rewrite로 Kotlin API에 전달합니다. CORS는 정해진 Vercel 오리진만 허용합니다.
- API는 `X-API-Key`가 없거나 틀리면 `/api/health`, Gmail OAuth callback을 제외한 요청을 `401`로 거부합니다. 개인 운영 도구의 단일 사용자 경계로 두었고, 사용자별 권한이 필요해지면 별도 인증 체계로 바꿀 지점을 코드 주석으로 남겼습니다.
- API → 워커 호출도 별도 `X-Worker-API-Key`로 인증합니다. 워커는 공개 진입점이 아니라 API의 실행 위임 대상으로 둡니다.

## 배포 흐름 — 병합보다 먼저 검증하고, 런타임은 빌드하지 않음 {#delivery}

![Backoffice AI 배포 흐름 — 작업 브랜치와 PR에서 검증 후 develop 스테이징, main 운영으로 진행한다. Vercel은 정적 화면을, Railway는 Kotlin API와 Python 워커를 배포하며 Supabase는 영속 상태를 유지한다.](/assets/images/portfolio/backoffice-ai-delivery.svg){:.portfolio-diagram}

1. `develop`에서 `feature/`·`fix/`·`chore/` 작업 브랜치를 만들고 PR로 통합합니다. `main` 직접 푸시는 막고, 운영 반영은 `develop → main` PR로 한정했습니다.
2. GitHub Actions는 Kotlin 백엔드를 **컴파일+테스트**, Python은 **문법+import**, 프런트는 **JavaScript 문법**까지 각각 확인합니다. 한 영역의 변경이 다른 런타임을 조용히 깨뜨리지 않게 한 최소 검증입니다.
3. `develop`은 스테이징, `main`은 운영 배포 기준입니다. Vercel은 화면을, Railway는 API와 워커를 별도 서비스로 배포합니다.
4. 런타임 서비스는 환경 변수만 받고, API 키·OAuth 자격증명·DB 비밀번호는 저장소에 넣지 않습니다. API는 인증 키가 비어 있으면 의도적으로 기동하지 않습니다.

## 운영 경계 — 자동화의 편의가 무단 발행이 되지 않게 {#operations}

자동화는 "실행할 수 있음"과 "외부로 발행해도 됨"을 분리했습니다.

- **단일 실행 잠금**: 워커는 프로세스 잠금으로 동시에 두 작업이 시작되는 것을 막고, 이미 실행 중이면 `409`를 반환합니다. 동일 브라우저 프로필·파일을 공유하는 자동화가 서로 충돌하지 않게 하기 위한 현재 단일 워커 전제의 선택입니다.
- **시간 제한과 결과 회수**: 워커 실행에는 최대 시간이 있고, API는 성공 여부·종료 코드·마지막 출력만 운영 화면에 돌려줍니다. 긴 로그 전체를 브라우저 요청에 쌓지 않습니다.
- **검토 전 발행 차단**: 네이버 로그인/발행은 기본적으로 꺼져 있습니다. 콘텐츠 생성 실패 시의 자리표시자 발행, CAPTCHA·2단계 인증으로 인한 예측 불가능한 동작을 인지하고, 검토·승인 연결 전에는 실제 posting 모드를 운영 경로에서 열지 않는 기준을 문서화했습니다.
- **AI 실행 기록**: 새 AI 기능은 모델, 토큰·비용, 사용 도구, 결과·실패 이유를 AI 운영 센터에 남기도록 규칙화했습니다. 결과만 남기지 않고 다음 실행을 판단할 근거도 남기는 방식입니다.

## 재배포 이후에도 이어지는 상태 {#persistence}

컨테이너는 언제든 교체될 수 있다고 보고, 남아야 하는 상태를 파일에서 PostgreSQL로 옮겼습니다.

| 상태 | 이전 위험 | 현재 처리 |
| :--- | :--- | :--- |
| **Gmail OAuth 토큰** | 컨테이너 로컬 파일에 두면 재배포마다 재인증 | `app_documents`에 직렬화해 저장하고 기동 시 복원 |
| **업무·승인·자동화 이력** | 실행 환경에 묶이면 서비스 교체 시 유실 | Supabase PostgreSQL의 Flyway 마이그레이션 스키마로 관리 |
| **삭제된 업무 데이터** | 물리 삭제하면 복구·감사 근거 소실 | `lifecycle_state`, `removed_at` 기반 소프트 삭제 |

- Flyway는 운영 DB가 비어 있지 않은 경우도 기준점(`0`)을 남긴 뒤 마이그레이션을 적용하도록 구성했습니다. 기존 Supabase 시스템 항목을 지우지 않고 애플리케이션 스키마만 관리하기 위한 선택입니다.
- 헬스 체크는 단순 고정 응답이 아니라 DB에 `select 1`을 실행합니다. DB 연결 실패는 `503`으로 드러나므로, "프로세스는 떠 있지만 서비스는 쓸 수 없는" 상태를 배포 확인에서 구분할 수 있습니다.

## 검증 범위와 다음 과제 {#verification}

| 확인한 것 | 결과 |
| :--- | :--- |
| API 인증 | 운영 프로필에서 API 키가 없으면 기동을 막고, 잘못된 키는 `401`로 거부합니다. |
| Gmail 연결의 지속성 | OAuth 토큰을 PostgreSQL에 저장한 뒤 서버 재시작 후에도 재인증 없이 연결을 유지하는 것을 로컬에서 확인했습니다. |
| 배포 DB 연결 | Flyway PostgreSQL 모듈·기준점 설정을 적용해 PostgreSQL 17 연결/마이그레이션 실패 원인을 기록하고 수정했습니다. |
| 자동화 실행 | API가 원격 워커 호출 결과를 받으며, 워커의 중복 실행은 `409`로 거부합니다. |
| CI | 백엔드 build, Python import, 프런트 문법 검사를 분리 실행합니다. |

### 한계와 다음 작업

- 워커의 실행 잠금은 단일 프로세스 기준입니다. 워커를 여러 인스턴스로 늘릴 때는 DB 또는 Redis 기반 작업 큐와 분산 잠금으로 전환해야 합니다.
- API 키는 단일 운영자용 공유 키입니다. 여러 사용자·역할을 지원할 시점에는 사용자 인증과 권한 모델로 교체해야 합니다.
- 자동 발행은 아직 검토 흐름과 영속 큐가 완전히 연결되지 않았습니다. 발행 이력·승인 상태·재시도 정책을 DB 작업 큐로 묶는 것이 다음 단계입니다.
- 배포 대상은 변경 중인 개인 운영 환경이며, 운영 트래픽·가용성·장애 복구 시간은 측정하지 않았습니다.

## Source

- [backoffice-ai](https://github.com/hello-pebble/backoffice-ai) — 소스 코드·Docker 구성·CI
- [배포 전략](https://github.com/hello-pebble/backoffice-ai/blob/main/docs/BRANCH_STRATEGY.md) — 브랜치·스테이징·운영 배포 기준
- [배포 문제 해결 기록](https://github.com/hello-pebble/backoffice-ai/blob/main/docs/DEPLOYMENT_TROUBLESHOOTING.md) — Railway·Supabase·Flyway·인증 도입에서의 원인과 수정
- [데이터 모델](https://github.com/hello-pebble/backoffice-ai/blob/main/docs/DATA_MODEL.md) — PostgreSQL 데이터·소프트 삭제 정책
