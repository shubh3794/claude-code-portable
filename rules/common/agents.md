# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |
| rust-reviewer | Rust code review | Rust projects |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. After plan/research phase completes - Use **architect** agent to evaluate
3. Code just written/modified - Use **code-reviewer** agent
4. After execution phase completes - Use **code-reviewer** agent
5. Bug fix or new feature - Use **tdd-guide** agent
6. Build or compilation failure - Use **build-error-resolver** agent immediately

## Mandatory Workflow Gates

These gates apply globally across ALL workflows (GSD, TDD, ad-hoc):

| After Phase | Agent | Enforced By |
|-------------|-------|-------------|
| Research / Plan | **architect** | `gate-architect-after-plan.js` |
| Execution | **code-reviewer** | `gate-code-review-after-execute.js` |
| Before Commit | **security-reviewer** | `gate-security-before-commit.js` |
| Build failure (any time) | **build-error-resolver** | instruction (continuous) |

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
