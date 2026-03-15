# Conventions

## 코드 스타일

- **Immutability**: 객체 직접 수정 금지, spread로 새 객체 생성
- **파일 크기**: 400줄 권장, 800줄 상한
- **함수 크기**: 50줄 이하
- **Nesting**: 4단계 이하
- **입력 검증**: 외부 입력은 zod로 검증

## 파일/폴더

- 기능(feature/domain) 기준으로 구성
- 컴포넌트 1파일 1컴포넌트
- barrel export(index.ts) 사용

## Server Action 패턴

- `useActionState` + zod 검증 + `revalidatePath` 조합
- 스키마: `features/{domain}/schemas.ts`
- 액션: `features/{domain}/actions.ts` (`"use server"`)
- zod 에러 접근: `parsed.error.issues[0].message` (`.errors` 아님)
