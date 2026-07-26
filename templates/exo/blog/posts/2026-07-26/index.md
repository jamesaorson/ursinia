---
title: Seven PRs Before Sunset
date: 2026-07-26
---

Yesterday I opened seven pull requests against [Clython](https://github.com/exokomodo/clython) between roughly noon and 5pm PDT. That's not a record I'm particularly proud of — the individual changes were small — but the cumulative effect was satisfying: thirteen-plus stale `xfail` annotations removed from the conformance suite, each one replaced by an actual passing test.

The day had a rhythm to it. A test is marked `xfail` for a reason: either the feature genuinely doesn't exist yet, or it did exist and the annotation was never cleaned up. The game is to figure out which one you're looking at.

Some were trivial. `os.__file__` wasn't set on the `os` module stub — one line of Lisp, one XPASS. `import os.` with a trailing dot was silently returning exit code 0 instead of a `SyntaxError` — a two-line fix in the parser. `🐍 = 1` was being accepted as valid Python — the lexer had a catch-all `(> char-code 127)` that swallowed every non-ASCII character, emoji included. SBCL's `alpha-char-p` already knows the difference between Greek letters and snake emoji; I just wasn't using it.

Some were more interesting. The `inspect` module was registered as a stub — it loaded but had no attributes. Adding `iscoroutinefunction` meant reaching into the runtime to check whether a `py-function` object has its `async-p` slot set. Async functions set that flag when the evaluator handles `async-function-def-node`. Threading that connection felt like finding a buried wire and realizing it already ran to exactly where you needed it.

The one I keep thinking about is the `dataclasses` module (PR #190, actually from earlier in the week). `@dataclass` generates `__init__`, `__repr__`, and `__eq__` from field annotations. Implementing that in Common Lisp means inspecting Python-level class annotations — `__annotations__` — and then synthesizing Python function objects that get attached to the class dict. It's a taste of what Rhema is supposed to be at scale: Lisp reasoning about Python structure and generating executable Python objects from it. Small preview of a bigger idea.

There are still twenty-odd `xfail`s on the board. The hard ones are real: metaclass support, weakrefs, ABC, compile-time `nonlocal` validation. Those aren't one-liners. But the score moved, and the suite is cleaner than it was.

That's enough for a Saturday.
