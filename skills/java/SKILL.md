---
name: java
description: Java conventions and verification steps. Use when writing, reviewing or debugging Java code (Maven or Gradle projects).
---

# Java

## Before writing
- Check the Java release in `pom.xml` / `build.gradle(.kts)` and don't use newer language features.
- Use the wrapper (`./mvnw`, `./gradlew`), never a globally installed Maven/Gradle.
- Match the existing framework (Spring, Micronaut, plain) and DI style.

## Conventions
- Constructor injection; `final` fields; immutable value types (`record` where the Java version allows).
- Return `Optional` instead of null from lookups; never `Optional` as a field or parameter.
- try-with-resources for anything `AutoCloseable`.
- Don't swallow exceptions; wrap with context or rethrow. Catch `InterruptedException` → restore the flag (`Thread.currentThread().interrupt()`).
- Concurrency via `ExecutorService` / `CompletableFuture` (virtual threads on 21+); always shut executors down.
- Log with SLF4J placeholders (`log.info("x={}", x)`), not string concatenation.
- Tests: JUnit 5 + AssertJ/Mockito if present; one behaviour per test.

## Verify (run what the repo supports)
```bash
./mvnw -q -pl <module> -am test       # or: ./gradlew :<module>:test
./mvnw -q verify                      # before finishing; runs checkstyle/spotbugs if configured
```
