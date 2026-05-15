---
name: 다음 세션 시드 — 2026-05-15 (PR #98 미머지 / SharePoint 계약 epic + 대학 연락처 epic 대기)
description: PR #98 (services 검색 UX + chunk fetch + service_id 재부여) 미머지. 두 큰 epic 사용자 요청 대기 (SharePoint 계약서, 대학 연락처). hydration mismatch는 여전 백로그
type: project
originSessionId: 2026-05-15-services-search-renumber
---

## 종료 시점

2026-05-15 자정 부근 KST. branch `fix/services-search-renumber` (PR #98) 미머지. main HEAD `5df341f`.

## 이번 세션 결과

services PR-1 검증 트랙 이어가는 중 검색·정렬·시퀀스 3 이슈 발견 → fix PR로 정리.

### PR #98 변경 요약

| 영역 | 변경 |
|------|------|
| EditForm 대학명 검색 | 빈 query 표시 / 정확 일치 entry 포함 / justSelected state로 선택 후 close |
| page.tsx universityKeys | chunk fetch (Supabase 1000 limit + PostgREST partial response 회피, totalFetched ≥ total 종료) |
| page-meta-config | services 헤드라인 "서비스사이클 — 서비스" (다른 메뉴 derive 형식 일관) — outdated mockup test 1 fail 동시 해결 |
| 마이그레이션 20260522 | 학교키(앞 4자리) 유지 + 학교별 write_start_at asc 정렬 후 시퀀스 001부터 재부여. **prod 적용 완료** |

### 검증 흔적

- EditForm test 8건 PASS (RED→GREEN 신규 2건)
- 전체 unit test 844 PASS (이전 1 fail 동시 해결)
- typecheck 0 / lint 0 error
- prod에서 "경찰" 검색 시 dropdown 3건 모두 노출 확인 (사용자 visual 검증)
- service_id 재부여 마이그레이션 prod 적용 + 검증 SQL 확인 (사용자)

## 학습 (재사용 자산)

### 1. Supabase JS chunk fetch — PostgREST partial response 함정
`pageSize: 5000` 지정해도 PostgREST `Max-Rows` 기본 1000 cap. 또한 chunk fetch 시 *partial response* (range 1000 요청에 996 반환) 가능. 종료 조건은 `chunk.length < CHUNK`가 아니라 `totalFetched >= total` (listServices 반환의 `total` 활용).

### 2. Combobox 자기 자신 제외 로직 분리
filter에서 `u.value !== input value`로 자기 자신 제외하면 *검색 중 정확 일치 entry도 사라짐*. 표준 패턴은 `justSelected` state로 분리 — 선택 시 true, 입력 시 false. dropdown 표시 조건 `!justSelected && matches.length > 0`.

### 3. 헤드라인 derive 일관성
다른 메뉴(alerts/schedule/my-todo 등)는 `accent: 시점 표현 / title: 명세 표현`. 그러나 services는 사이드바 그룹·메뉴 라벨과 일치 형식으로 사용. 사용자 요청은 일관 자동 derive 형식. PR #98에서 정리.

### 4. service_id 재부여 마이그레이션 패턴
UNIQUE 컬럼 일괄 UPDATE 시 *2단계 처리* — 음수 임시값(`update set service_id = -service_id`)으로 충돌 회피 후 새 값 적용. CTE row_number() + partition by + order by로 정렬 기준 명시. `left(service_id::text, 4)::bigint`로 학교키 추출 (정수 division 아님 — 6/7자리 섞일 때 자릿수 일관 안 됨).

### 5. services-import.mjs 재실행 위험
import 스크립트가 CSV 원본 service_id를 그대로 사용. 마이그레이션 후 재import 시 원본 값으로 *덮어쓰여짐*. 재import 안 하거나, 재부여된 service_id로 CSV export 후 import. **[[feedback_services_import_overwrite_risk]] 학습 메모리 후보**

## 다음 세션 즉시 처리

### 1. PR #98 머지 + 후속
- prod main에 머지
- 사용자가 검증 잔여 진행 (필터/viewer 검증은 task #4, #5 pending)

### 2. SharePoint 계약서 → "계약" 메뉴 epic (큰 작업)
- 사용자 요청 (이번 세션 후반)
- env에 `SHAREPOINT_CONTRACTS_ITEM_ID=01TGOQVTS6Z2RN6CAAJREZVSUYWY762UNC` 설정 완료
- 사이드바 "계약" 메뉴(slug `contracts`) 이미 등록
- Microsoft Graph 인프라 재사용: `src/lib/microsoft/` + `src/features/receivables/queries.ts`가 SharePoint Excel workbook fetch 패턴 보유
- 시트 구조 (4년제~기타) 미상 — Graph API로 자동 분석 또는 사용자 명세 필요
- data flow 결정 필요: SharePoint 직접 read (receivables 패턴) vs Folio DB ETL (services 패턴) vs 하이브리드
- brainstorm 진입 권장

### 3. 대학 연락처 도메인 구성 (별도 epic)
- 사용자 요청 (이번 세션 초반)
- 사이드바 "대학 연락처" 메뉴 이미 등록 (src/app/dashboard/_data.ts:92)
- mockup 이미지 명세: 활성화/고객명/직함/대학명/소속부서/직책/관리등급(A~D)/관계등급/연락처(휴대폰·내선)/이메일
- DB 테이블 + RLS + list-variants 슬롯 신설
- 대학명 services 도메인 FK 연동 검토 가치

## 미해결 백로그 (시드 누적)

### Hydration mismatch (직전 세션부터 누적)
- PageTabs `OpenTabsProvider` localStorage SSR/CSR 차이 — useState(loadInitial) 패턴 mismatch
- ServicesTable `deadlineBadge`의 Date.now() (잠재적 mismatch — 표면화는 PageTabs가 먼저)
- 우리 fix 시도(useState+useEffect) → react-compiler ESLint 룰 위반 차단
- **권장 fix**: `dynamic({ ssr: false })` 패턴으로 PageTabs wrap (변경량 적음). 또는 `useSyncExternalStore` (정공법 — store 구조 변경)
- [[feedback_hydration_mismatch_lint_block]]

### 마이그레이션 prod 미적용
- backup 4 파일 (20260519~20260519d)
- backup-services-fk 3 파일 (20260521~20260521c)
- 이번 세션의 20260522는 prod 적용됨

### 기존 백로그 보존
- isoToLocalKst/localKstToIso 3 파일 중복 → `lib/datetime.ts` hoist
- 사이드바 services count "179" 하드코드 (실 import 후 2511로 동기 필요)
- receivables count hardcode 7건 (Excel 외부)

## 운영 상태

- branch: `fix/services-search-renumber` (PR #98 미머지)
- main HEAD: `5df341f`
- working tree clean
- 단위 테스트 844 PASS / 0 fail
- typecheck 0 / lint 0 error (12 warning 기존)
- list-variants 11 도메인 슬롯 완비
- services 도메인: 2511 row import 완료 + service_id 재부여 완료
