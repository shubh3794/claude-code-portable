# Testing Requirements

## Test-Driven Development

Preferred workflow for production code:
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

> **Language note**: Coverage targets, test frameworks, and spike/exploration exemptions are in language-specific overrides.
