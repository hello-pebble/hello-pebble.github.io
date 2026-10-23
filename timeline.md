---
layout: default
title: "timeline"
permalink: /timeline/
---

<header class="portfolio-index-header">
  <span class="portfolio-eyebrow">timeline</span>
</header>

# {{ site.data.timeline.thesis }}

<span class="section-note">위 레인은 재직·교육, 아래 레인은 개인 프로젝트입니다. 표식 번호는 아래 목록 순서이고, 결과물이 없는 달은 비워 둡니다. 2026.10.23 기준.</span>

{% include diagrams/timeline.svg %}

<ol class="tl-legend">
{% for a in site.data.timeline.artifacts %}  <li>{% if a.href %}<a href="{{ a.href }}">{{ a.name }}</a>{% else %}{{ a.name }}{% endif %} <small>{{ a.month | replace: "-", "." }}</small></li>
{% endfor %}</ol>

## 같은 판단이 네 번 반복됐습니다

<div class="dg-wrap" markdown="1">

| 시기 | 규칙이 있던 곳 | 옮긴 곳 |
| :-- | :-- | :-- |
| 2019 [항만 사용료](/portfolio/port-fee/) | 개발자 코드 (감면 1건 = 개발 요청 1건) | 담당자 화면의 업체별 값 |
| 2024 [개방DB](/portfolio/api-management/) | API마다 파일 5~6개 | 메타데이터 엔진 1곳 (검증도 1곳) |
| 2026 [DelayNoMore](/portfolio/delaynomore/) | 프론트 잠금 버튼 | 서버 `409` → 도구 노출 권한 |
| 2026 [AdminCore](/portfolio/admincore/) | 로그인 시점 상태 검사 | 요청마다 재검사 (정지 토큰 차단) |

</div>

## 구간별로 남긴 것

<div class="dg-wrap" markdown="1">

| 구간 | 기간 | 남긴 것 |
| :-- | :-- | :-- |
| 항만 | 2019.05 – 2020.07 | 세율을 업체별 값으로 분리. 선임 부재 상황에서 시스템 전체를 독자 파악 |
| LMS | 2020.12 – 2021.03 | 회원·역할·운영관리 백엔드. 역할 변경은 전체 교체, 유형은 코드 ID 저장. 외부 저장과 DB 저장이 한 트랜잭션이 아님을 배움 |
| 교육·재학습 | 2021.04 – 2022.10 | K-Digital 중급 JAVA 웹 교육 → 2022.11 입사 |
| PMS·개방DB | 2022.11 – 2025.01 | PMS 26개월 운영(문의 월 20건 → 1~2건), 저장 유실 원인 3건, 메타데이터 조회 엔진, 폐쇄망 Java–Python 연동 |
| 재정비 | 2025.02 – 2025.12 | searchvibe(LangGraph·Gemini), springjava로 Redis·Kafka·WebSocket 실습, 정보처리기사 필기 |
| 개인 프로젝트 | 2026.01 – | 저장소 16개 · 커밋 약 1,500건 · 배포 2건([DelayNoMore](https://delaynomoreapp.duckdns.org/), [Backoffice AI](https://backoffice-ai-orpin.vercel.app/)) · [article-bot](https://app.notion.com/p/Learning-328982649c3f80829e01d23c6a12a785) 8개월째 매일 운영 |

</div>
