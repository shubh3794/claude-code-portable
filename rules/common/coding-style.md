# Coding Style

## Immutability

Prefer immutable data where idiomatic. Immutable data prevents hidden side effects and enables safe concurrency.

> **Language note**: This rule may be overridden by language-specific rules where in-place mutation is idiomatic (e.g., PyTorch tensor ops, Go pointer receivers).

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Organize by feature/domain, not by type

## Error Handling

- Handle errors explicitly at every level
- Never silently swallow errors

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
