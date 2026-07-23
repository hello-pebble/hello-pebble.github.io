---
layout: default
title: "DelayNoMore — 데이터 영속화 & 동시성"
permalink: /portfolio/1/persistence/
category: portfolio
tags: [PostgreSQL, Supabase, Concurrency, Portfolio]
---

# 데이터 영속화 &amp; 동시성 <span class="badge outline">DelayNoMore</span>

<span class="section-note">← [DelayNoMore 개요로 돌아가기]({{ '/portfolio/1/' | relative_url }})</span>

> 저장 위치를 브라우저에서 서버로, 다시 인메모리에서 PostgreSQL로 옮기면서도 **같은 가드·업서트 의미를 보존**하는 것이 관건이었습니다. 저장 계층을 바꿔도 서비스 코드는 그대로 동작하도록 설계했습니다.

---

## 영속화의 진화

![데이터 영속화의 진화](/assets/images/portfolio/delaynomore-persistence.svg)

- **v0.1 · localStorage**: 브라우저에 저장 — 캐시 삭제·기기 변경 시 유실.
- **v0.4 · 서버 인메모리**: `ConcurrentHashMap` 기반 서버 보관함으로 옮겨 여러 계획을 만들고 목록에서 전환·삭제. 로그인/DB는 후속으로 미루되, Repository 시그니처는 DB 관례(`save`/`findAll`/`findById`/`update`/`deleteById`)를 미리 맞춰 교체를 대비했습니다.
- **v0.11 · 게스트ID 소유자 격리**: 브라우저가 만든 안정 UUID를 `X-Guest-Id`로 실어 계획·회고·이력을 **브라우저별로 격리**. 다른 소유자의 계획은 조회·수정·삭제 모두 404로 존재 자체를 은닉하고, 소유자당 10개/전역 200개 한도를 두었습니다.
- **v0.12 · PostgreSQL(Supabase)**: Flyway로 `plans`·`reflections`·`audit_events` 3개 테이블을 만들고, `tasks`는 `JSONB`로 보관. 이제 **서버를 재시작해도 데이터가 복원**되고 회고가 누적됩니다.

---

## 인메모리에서 트랜잭션으로 — 의미를 보존한 이식

![동시성 제어 — 인메모리에서 트랜잭션으로](/assets/images/portfolio/delaynomore-concurrency.svg)

인메모리 시절의 원자성 보장 장치를 PostgreSQL에서도 **같은 계약**으로 옮기는 것이 핵심이었습니다.

| 인메모리 (v0.4~0.11) | PostgreSQL (v0.12) |
| :--- | :--- |
| `computeIfPresent` 키 단위 원자 구간 | `@Transactional` + `SELECT … FOR UPDATE` |
| `synchronized`로 생성 한도 TOCTOU 가드 | 트랜잭션 안에서 검사·저장 |
| `compute` 업서트(1일 1 회고) | `INSERT`/`UPDATE` 업서트, `createdAt` 보존 |
| `update`가 이전 상태 반환 | `RETURNING id` / 교체 전 값 반환 |

- **인터페이스 + 프로필 분리**: 세 저장소를 인터페이스로 추출하고 구현을 프로필로 선택합니다. 기본은 인메모리(휘발성·롤백·단위 테스트), `postgres` 프로필은 JDBC 구현. **서비스 코드는 변경 없이** 그대로 동작합니다.
- **원자적 감사**: 계획 변경과 감사 append가 한 트랜잭션으로 커밋되어, 감사 실패 시 본 변경까지 롤백됩니다.
- **재시작 복원 증명**: Testcontainers로 실제 PG17에 Flyway를 적용해 저장·원자 가드·업서트 `createdAt` 보존·캐스케이드·감사 생존을 검증하고, **새 인스턴스로 다시 읽어 재시작 후 복원**을 증명했습니다.

---

## 스키마 설계 노트

- **평탄한 1:1 매핑**: 레코드와 컬럼을 1:1로 맞추고, 날짜·시각은 프론트 ISO 문자열 왕복을 위해 `TEXT`, `saved_at`은 epoch ms `BIGINT`로 저장.
- **조회 패턴 인덱스**: `(owner, saved_at DESC, id DESC)` 등 실제 조회 패턴에 맞춘 인덱스.
- **이력 생존**: `reflections`는 `plans`에 `ON DELETE CASCADE`, `audit_events`는 FK 없이 살아남아 삭제 이력을 보존.
- **직접 접속 보안**: Supabase 자동 API 노출을 막기 위해 세 테이블에 정책 없는 RLS를 켜고, 앱은 특권 역할로 직접 접속합니다. 백업은 대시보드 자동 백업 + `pg_dump`/`pg_restore` 스크립트를 병행합니다.

---

## 남은 한계 (정직하게)

DB 영속화는 *서버* 재시작에도 데이터가 사라지지 않게 할 뿐, 데이터 접근 키는 여전히 브라우저의 게스트 ID입니다. 브라우저 데이터를 지우거나 다른 기기로 접속하면 DB에 계획이 남아 있어도 재연결되지 않습니다. **로그인 도입(owner를 guestId→memberId로 재-key)** 전까지 남는 구조적 한계로, 로드맵에 명시해 두었습니다.

---

<span class="section-note">관련: [시스템 아키텍처 & 배포]({{ '/portfolio/1/architecture/' | relative_url }}) · [규칙의 소유권을 서버로]({{ '/portfolio/1/backend-ownership/' | relative_url }}) · [AI 통합]({{ '/portfolio/1/ai-engineering/' | relative_url }})</span>
