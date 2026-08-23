---
name: flutter-fullstack
description: Enforces zero-error discipline — mandatory self-testing before reporting done, no unverified assumptions, no scope creep on simple requests. Use for any Flutter widget, state management, backend/API integration, or Dart code in this repo.
license: MIT
---

# Flutter Fullstack — Precision Rules

## Answering style
- Yes/no question → start with "Yes"/"No" + one short plain-word reason. No preamble.
- Explanation question → plain words, as short as possible. No lecture, no unrelated background.
- Code task → match the scope asked. A one-line fix = one-line change, not a file-wide cleanup. Don't strip out needed error handling to look "minimal."
- Ambiguous request → ask ONE precise clarifying question, don't guess.

## Never guess
- Don't assume a method/class/package API — check the real file/dependency before using it.
- Don't edit a file from memory — read it first.
- If unsure, say so explicitly instead of proceeding as fact.

## Before marking anything "done"
- Run `dart analyze` and the relevant tests. No run = not verified — say so, don't claim it works.
- Fix failing tests, don't skip/comment them out.
- Confirm null, empty, and error states are handled — not just the happy path.
- Never report "done" with a known unhandled case.

## Code conventions
- **Structure:** feature-first — `lib/features/<name>/{data,domain,presentation}`. Shared code in `lib/core/`. No logic inside `build()`.
- **State:** Riverpod w/ codegen (`@riverpod`), one notifier per feature, widgets only `ref.watch`/`ref.read`, use `AsyncValue` not manual loading flags.
- **Errors:** no silent `catch`; repos return `Result<T>` (`Success`/`Failure`); network calls have timeouts.
- **Null safety:** immutable models (`final` + `copyWith`); no unjustified `!`; DTOs handle missing fields defensively.
- **Tests:** new screen → widget test; new repo/notifier → unit test w/ mocked dependency; paths mirror `lib/` → `test/`.
- **Style:** 2-space indent, no `print()`, `build()` under ~60 lines.

## Never do
- Guess an API and hope it compiles.
- Claim something's tested without running it.
- Add unrequested changes to a simple fix.
- Leave a silent `TODO`/half-implemented branch.
- Mark a task "done" with a known unhandled edge case.
