# Changelog

## [Unreleased]

## [1.0.0] - 2026-04-16

첫 안정 릴리즈. 62 커밋의 누적 작업물.

### 에이전트 (12개)
- 12개 전문 에이전트 시스템: planner, designer, developer, qa, security, feedback, grader, comparator, validator, skill-reviewer, moderator, retrospective
- 파일 기반 메시지 버스로 에이전트 간 비동기 통신
- 구조화된 토론 시스템 (자동 트리거 + moderator 중재)

### 스킬 (19개)
- 개발 흐름: `/commit`, `/pair`, `/scaffold`, `/worktree`
- 검증: `/verify`, `/test`, `/security`, `/review-pr`
- 디자인: `/design-sync` (URL/이미지/로컬 7단계), `/design-audit`
- 분석: `/feedback`, `/metrics`, `/status`, `/retrospective`
- 학습: `/learn`, `/discuss`
- 품질 진화: `/eval`, `/evolve` (Hermes Agent self-evolution 패턴)
- 릴리즈: `/release` (semver 자동 판단 + CHANGELOG 관리)

### 훅 (22개)
- PreToolUse 파이프라인: command-guard, smart-guard, tdd-enforce
- PostToolUse 파이프라인: prettier, eslint, typecheck, test-runner, metrics, pattern-check, design-lint, debate-trigger, readme-sync
- 에러 분류: 13-class error classifier (Hermes Agent 패턴)
- 컨텍스트 압축: context-prune (도구 출력 1줄 요약, 12KB 예산)
- 모델 라우팅: model-suggest (events.jsonl 패턴 분석 → 비차단 제안)
- 세션 관리: session-review, session-log, uncommitted-warn

### 인프라
- SQLite instinct store (Migration v1-v3, 13개 사전 쿼리)
- Dual-write: JSON + SQLite + JSONL 3중 기록
- 실시간 관측 스트림 (watch-events.sh + events-tail.js)
- setup.sh 원클릭 설치 + validate.sh 5단계 검증
- 오케스트레이터: Claude Squad (tmux) + Agent Orchestrator (CI/CD) + 대안 도구 안내

### 규칙 (6개)
- conventions, tdd, git, design, donts, debugging
- Memory context fencing (Hermes Agent 패턴)
- $ARGUMENTS 검증 공통 규칙

### 출처
- SQLite Store: [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- 관측 스트림: [disler/claude-code-hooks-multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability)
- TDD 강제화: [obra/superpowers](https://github.com/obra/superpowers)
- Pair Mode: [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery)
- Error Classifier, Context Compressor, Memory Fencing, Model Routing, Self-Evolution: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Release Skill: [Shpigford/chops](https://github.com/Shpigford/chops)
