---
name: 다음 세션 시드 — 2026-05-12 후속 (ListPattern Table refactor epic 머지 완료)
description: PR #83+#84 머지. ListPattern.tsx 1220 → 452 (-768, 63% 감소). 800줄 상한 압도적 달성
type: project
originSessionId: 2026-05-12-listpattern-table-refactor
---

## 종료 시점

2026-05-12 21:55 KST. main HEAD `fd9867d` (PR #84). working tree에 docs(.claude/plans/...md) 변경만 잔존 — 다음 세션에서 한 줄짜리 docs 커밋 또는 무시.

## 이번 세션 결과 — ListPattern Table refactor epic 완료

브레인스토밍: `.claude/memory/brainstorms/20260512-205059-listpattern-table-refactor.md`
플랜: `.claude/plans/20260512-211826-listpattern-table-refactor.md` (status: completed)

| Phase | 범위 | PR | 결과 |
|-------|------|-----|------|
| 1 | cohort 패턴 확립 (registry 슬롯 확장) | #83 머지 | ListPattern 1220 → 1106 |
| 2 | 7 variant 일괄 분리 (team/post/schedule/my-todo/receivables/ai-work/default) | #84 머지 | 1106 → **452** (-768, **63% 감소**) |

신규 디렉토리/파일 (17 신규):
- `inspector/list-variants/status.ts` — STATUS_LABEL/COLOR/RING 공통 상수
- `inspector/list-variants/{cohort,team,receivables,ai-work}/` — 기존 폴더에 Table.tsx + filters.ts 추가
- `inspector/list-variants/{post,schedule,my-todo,default}/` — 신규 디렉토리 + Table.tsx + filters.ts
- registry.ts에 9 variant 모두 등록 (Table/Filters/blank 슬롯 + View/EditForm은 inspector 4 variant만)

테스트: 720 unit GREEN 전수 유지 (통합 테스트 — variant 분리 시에도 dispatcher 라우팅으로 회귀 자동 감지)

## 머지 시 학습 (학습 패턴 추가)

1. **TDD hook strict + surgical refactor 충돌** — `.claude/settings.local.json`의 `CLAUDE_TDD_ENFORCE=strict`는 type-only 변경(types.ts)이나 cross-directory test layout(`inspector/__tests__/list-variants/`)을 인식 못 함. epic 동안 `warn`으로 잠시 변경 후 종료 시 원복 (이 세션에서 적용)
2. **JSX에서 `<obj[key].Comp />` 직접 사용 불가** — TypeScript JSX는 컴포넌트 이름이 PascalCase 변수여야 함. `const X = obj[key].Comp; return <X .../>` 패턴 필요 — registry dispatcher 작성 시 함정
3. **Registry union narrowing + optional slot** — `entry?.Slot`는 union 분기 narrow 실패. `"Slot" in entry && entry.Slot` 가드 패턴 필요. 일부 variant만 슬롯 보유 시 강제
4. **Post-feedback/post-notice 공유 컴포넌트** — variant prop 분기로 한 컴포넌트가 두 variant 처리. registry에 같은 컴포넌트 두 번 등록 (Filters만 다름)
5. **체크박스 state mutation 분리 (RSC 호환)** — my-todo Table은 `onToggleDone` prop만 받고 state mutation/persist는 dispatcher closure가 처리. 함수 prop이 closure로 RSC boundary 안에 머무름
6. **postStatusLabel/Keys 본거지 이동 시 import 갱신** — ListPattern에서 export하던 함수를 list-variants/post로 옮길 때 InspectorListBody import 경로 함께 변경 필수
7. **변경 라인 수 vs 절감 효과** — PR 1 (cohort 단일, -114줄) vs PR 2 (7 variant 일괄, -654줄). 패턴 확립 PR의 small footprint 후 일괄 PR이 큰 절감을 안전하게 가져옴

## 미진 / 백로그 (다음 epic 후보)

- **ListRow 타입 분리** — 26+ 파일이 `import type { ListRow } from "../patterns/ListPattern"`. 별도 mini-PR로 hoist 가능 (~1일)
- **variantRegistry 슬롯 타입 hoist** — 현재 inline `TableSlotProps`/`PostTableProps`/`MyTodoTableProps`. types.ts로 hoist
- **GuidePattern.tsx, DashPattern.tsx 등 다른 거대 컴포넌트 점검** — wc -l로 후보 발견. ListPattern과 동일 epic 패턴 적용 가능성
- **사이드바 mock 도메인 count hardcode 잔존** — DB 없는 도메인의 count 표기
- **receivables count hardcode 7건 (Excel 외부)** — 데이터 소스 미확정

## 운영 상태

- main HEAD `fd9867d`
- 모든 PR (#83~#84) 머지, 미머지 0
- working tree: `.claude/plans/...md` 한 줄 docs 변경 잔존 (PR #84 머지 결과 표 갱신). 다음 세션에서 단순 commit 또는 무시
- settings.local.json CLAUDE_TDD_ENFORCE 원복 완료 (warn → strict)
- lint clean (pre-existing _omit warning 11건만)
- 720 unit test GREEN, typecheck pass

## 부채 (장기)

- ListRow 타입이 ListPattern.tsx에 살아있음 (epic 외)
- ~~ListPattern 1220줄~~ → **452줄** (해결)
- 사이드바 mock 도메인 count hardcode 잔존
- receivables count hardcode 7건 (Excel 외부)
