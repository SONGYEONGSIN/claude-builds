---
name: status
description: 프로젝트 상태 대시보드 — git, CI, 배포 상태를 한눈에 보여준다
---

프로젝트의 현재 상태를 대시보드 형태로 출력한다.

## 수집 항목

### 1. Git 상태

```bash
git status --short
git log --oneline -5
git branch -a
```

### 2. 미커밋 변경사항

```bash
git diff --stat
git diff --cached --stat
```

### 3. CI 상태 (GitHub Actions)

```bash
gh run list --limit 3
```

### 4. 배포 상태 (Vercel)

```bash
npx vercel ls --limit 3 2>/dev/null || echo "Vercel CLI 미설치 또는 미연결"
```

### 5. 의존성 상태

```bash
npm outdated 2>/dev/null | head -10
```

## 출력 형식

```markdown
## 프로젝트 상태 대시보드

### Git

- **브랜치**: main
- **미커밋 변경**: N개 파일
- **최근 커밋**:
  - abc1234 feat: ...
  - def5678 fix: ...

### CI/CD

| 워크플로우 | 상태 | 커밋    | 시간   |
| ---------- | ---- | ------- | ------ |
| CI         | PASS | abc1234 | 2분 전 |

### 배포

- **URL**: https://...vercel.app
- **상태**: Ready

### 의존성

- 업데이트 가능: N개
```
