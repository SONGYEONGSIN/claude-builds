---
name: commit
description: Conventional Commit 메시지를 자동 생성하고 커밋한다
---

Conventional Commit 메시지를 자동 생성하여 커밋한다.

## 절차

1. `git diff --cached --stat` 로 스테이징된 변경 확인
2. 스테이징된 파일이 없으면 `git diff --stat`으로 변경사항 확인 후 관련 파일 스테이징
3. `git diff --cached` 로 상세 diff 분석
4. 변경 내용에 맞는 Conventional Commit 메시지 생성:
   - `feat:` — 새 기능
   - `fix:` — 버그 수정
   - `refactor:` — 리팩토링
   - `test:` — 테스트 추가/수정
   - `chore:` — 설정, 의존성 등
   - `docs:` — 문서
5. 메시지를 사용자에게 보여주고 확인 후 커밋

## 규칙

- 메시지는 한국어로 작성
- 제목은 50자 이하
- 본문이 필요하면 빈 줄 후 상세 설명 추가
- `.env`, credentials 등 민감 파일은 커밋하지 않음
