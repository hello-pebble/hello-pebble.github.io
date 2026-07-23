---
layout: default
title: "DelayNoMore — 데이터 & 동시성 설계"
permalink: /portfolio/1/persistence/
category: portfolio
tags: [PostgreSQL, Supabase, Concurrency, Portfolio]
---

# 데이터 &amp; 동시성 설계 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> 누적된 회고 데이터를 다음 계획에 되먹이려면 **재시작에도 살아남는 저장소**가 필요했습니다. **PostgreSQL(Supabase 관리형)** 을 택하고, 스키마·인덱스·격리·원자성을 각각의 이유를 가지고 설계했습니다.

---

## 스키마 설계 — 3 테이블

![데이터 스키마 — 3 테이블](/assets/images/portfolio/delaynomore-schema.svg)

- **유연한 본문, 평탄한 매핑**: `Plan.tasks`는 형태가 바뀌기 쉬워 **`JSONB`**로 보관하고, 나머지는 레코드와 컬럼을 1:1로 평탄하게 매핑했습니다. 날짜·시각은 프론트 ISO 문자열 왕복을 위해 `TEXT`, `saved_at`은 정렬 키라 epoch ms `BIGINT`.
- **조회 패턴 인덱스**: 실제 쿼리에 맞춰 `(owner, saved_at DESC, id DESC)`, `(plan_id, date DESC)` 등을 설계했습니다.
- **이력은 삭제를 견딘다**: `reflections`는 `plans`에 `ON DELETE CASCADE`로 묶어 고아를 막고, `audit_events`는 **FK 없이** 두어 계획이 삭제된 뒤에도 "언제 삭제됐는가"를 답할 수 있게 했습니다.
- **접근 통제**: Supabase 자동 REST 노출을 막기 위해 세 테이블에 **정책 없는 RLS를 켜고**, 앱은 특권 역할로 직접 접속합니다. 스키마는 Flyway(`V1__init.sql`)로 버전 관리합니다.

---

## 소유자 격리 — 인증 이전의 접근 키

로그인 도입 전 단계로, 브라우저가 만든 안정 UUID를 `X-Guest-Id`로 실어 **계획·회고·이력을 소유자별로 격리**했습니다.

- `Plan.owner`를 소유자 키로 삼아 목록은 `findAllByOwner`로만 조회하고, **다른 소유자의 계획은 조회·수정·삭제 모두 404**로 존재 자체를 은닉합니다.
- 저장 한도를 소유자당 10개 / 전역 200개로 분리해 개인 한도와 서버 메모리 보호를 구분했습니다.
- 개인 데이터가 프록시·브라우저 캐시에 남지 않도록 계획 API 응답에 `Cache-Control: no-store`를 적용했습니다.

---

## 동시성 · 원자성 보장

![동시성 · 원자성 보장](/assets/images/portfolio/delaynomore-concurrency.svg)

여러 방문자가 같은 데이터를 동시에 건드려도 깨지지 않도록, **조회·검사·교체를 한 트랜잭션의 행 잠금 안**에서 수행합니다.

| 무엇을 지키나 | 어떻게 (PostgreSQL) |
| :--- | :--- |
| 생성 한도 TOCTOU 방지 | `@Transactional` + 검사·저장을 한 커밋에 |
| 고정 계획 잠금 레이스 방지 | `SELECT … FOR UPDATE` 행 잠금 안에서 가드 |
| 1일 1 회고 업서트 | `INSERT`/`UPDATE` 업서트, `createdAt` 보존 |
| 계획 변경과 감사 이력 | 한 트랜잭션으로 원자 커밋(실패 시 함께 롤백) |

- **저장 계층 추상화**: 저장소를 인터페이스로 두고 구현을 프로필로 선택합니다(`postgres` = JDBC, 기본 = 인메모리 데모·단위 테스트). **서비스 코드는 변경 없이** 어느 저장소에서도 같은 원자 보장을 유지합니다.
- **재시작 복원 검증**: Testcontainers로 실제 PG17에 Flyway를 적용해 원자 가드·업서트 `createdAt` 보존·캐스케이드·감사 생존을 검증하고, **새 인스턴스로 다시 읽어 재시작 후 복원**을 증명했습니다(`PersistenceRestartIT`).

---

## 남은 한계 (정직하게)

DB 영속화는 *서버* 재시작에도 데이터가 사라지지 않게 할 뿐, 데이터 접근 키는 여전히 브라우저의 게스트 ID입니다. 브라우저 데이터를 지우거나 다른 기기로 접속하면 DB에 계획이 남아 있어도 재연결되지 않습니다. **로그인 도입(owner를 guestId→memberId로 재-key)** 전까지 남는 구조적 한계로, 로드맵에 명시해 두었습니다.

---

> **💬 면접에서 더 깊게 이야기할 수 있는 주제**
> - `tasks`를 `JSONB`로 둔 이유와, 정규화 컬럼 대비 트레이드오프
> - 인덱스를 그 조합으로 설계한 근거(조회 패턴)
> - `audit_events`를 FK 없이 둔 설계 의도(삭제 이력 보존)
> - RLS를 켜고도 앱은 우회 접속하는 이유
> - 재시작 후 데이터 복원을 어떻게 테스트로 증명했는가

---

<span class="section-note">관련: [백엔드 설계]({{ '/portfolio/1/backend/' | relative_url }}) · [배포 & 인프라]({{ '/portfolio/1/architecture/' | relative_url }}) · [AI 통합 & 토큰 절약]({{ '/portfolio/1/ai-engineering/' | relative_url }})</span>
