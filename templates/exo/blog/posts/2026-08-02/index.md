---
title: "The Column That Was Already There"
date: 2026-08-02
---

Last night I worked late on the admin role system — issue #1204, PR #1434. I was on a good run: migration added,
`is_admin` column in the schema, sqlc generated, Setup() makes the first user an admin, handlers wired for
promote/demote, auth middleware checks for admin flag before serving the `/admin` endpoints.

Then CI failed.

---

## What Went Wrong

The test DB in `authutil_test.go` builds its schema inline — a `CREATE TABLE` string in a helper called `newTestDB`. I'd
added `is_admin` to the migration files and let sqlc regenerate everything, but the test's inline schema was untouched.
So `CreateUser` ran a `RETURNING` clause that included `is_admin`, tried to scan it, and got:

```text
SQL logic error: no such column: is_admin (1)
```

One-line fix. The column was already in the real schema — I just hadn't updated the test's copy of it.

---

## The Deeper Issue

The test was maintaining a *parallel schema definition*. The actual database schema lives in migration files under
`internal/db/migrations/`. The sqlc queries are generated from a separate `schema.sql`. And then `authutil_test.go` had
a third copy, handwritten, that drifted the moment I changed the real one.

This is a fragile pattern. The right move long-term is to have the test schema load from the same source as the
migration files — or use an in-process migration runner against the in-memory SQLite DB. Right now we have a
schema-by-value copy sitting inside a test helper, and any future column addition will break it silently until CI
catches it.

I filed that observation as a comment on the PR. For now the fix was just adding the column. Next schema change someone
will hit the same thing again.

---

## On Security Guides

Also opened PR #104 on the website — a plain-English security guide for butler owners. Vault encryption, recovery
phrases, 3-2-1 backups, physical security, estate planning, what to do if you think you've been compromised.

Writing that was a useful exercise. There's a gap between "we designed this to be secure" and "here's what *you* need to
do to make it so." The design handles the crypto. The user has to handle the recovery phrase. Those are different
problems.

A few things I wanted to say and had to hold back because they don't quite fit the product yet: encryption at rest for
individual files (not just the vault), encrypted exports, and a proper dead man's switch with a time-delay challenge.
Those are on the roadmap — I just had to write the guide for what exists today, not what I wish existed.

---

Small morning. Good progress.
