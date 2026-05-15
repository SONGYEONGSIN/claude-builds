---
name: services-import-mjs-service-id
description: "import 스크립트가 CSV 원본 service_id를 그대로 사용하여 upsert(onConflict='service_id'). 마이그레이션으로 재부여한 service_id가 *재import 시 원본 값으로 덮어쓰여짐*. 재import 전 export 절차 필요"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8a18890a-c371-4590-bb5c-6cf1f23166ac
---

## 발견 시점

2026-05-15. services 도메인 service_id 재부여 마이그레이션(`20260522_services_service_id_renumber.sql`) 적용 후. 학교키(앞 4자리) 유지 + 학교별 write_start_at asc로 시퀀스 001부터 재부여.

## 위험

`scripts/services-import.mjs` 코드:

```js
service_id: Number(r["service_id"] ?? 0),
```

CSV의 `service_id` 컬럼을 그대로 사용. `upsert({ onConflict: 'service_id' })`로 동일 service_id row 갱신. 즉:

- 마이그레이션으로 재부여된 새 service_id 1002001~1002007 (가천대학교(대학원))
- 재import 시 CSV 원본 100266 / 1002005 등으로 `INSERT` 또는 `UPDATE`
- 결과: 재부여 효과 사라지고 원본 service_id 일부 row가 *새로 생기거나* 옛 값으로 *덮어쓰여짐*

## How to apply

### 옵션 A — 재import 안 함
가장 안전. services source-of-truth가 Folio DB가 됨 (Sheets는 더 이상 동기 안 함). 새 서비스는 신규 등록 UI로.

### 옵션 B — 재부여된 service_id로 CSV export 후 import
1. Supabase에서 services 전체를 export (CSV) — 새 service_id 반영된 상태
2. 그 CSV를 새 source로 사용. 다음 import는 이 CSV.
3. 원본 Sheets는 운영부 참조용으로만 (Folio와 동기 안 함)

### 옵션 C — services-import.mjs를 service_id 무시 mode로
- import 스크립트에 `--ignore-service-id` flag 추가
- 그 mode에서는 service_id를 *생성* (max+1 또는 학교키*1000+seq)
- `onConflict: 'university_name + service_name'` 등 다른 자연키로 변경

옵션 A가 가장 surgical. 사용자가 services를 Folio source-of-truth로 인정한 상태(`source: 'folio_create' | 'google_sheet_import'` 컬럼 의도)면 자연스러움.

## 관련

- [[project_next_session_seed]] — 다음 세션 시드에 SharePoint 계약 epic + 대학 연락처 epic 함께 명시
