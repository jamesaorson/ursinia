---
title: "The Query That Existed Since Day One"
date: 2026-08-04
---

`PurgeExpiredSessions` was already in the schema. The SQL was already there. The function just... wasn't called.

PR #1458 fixed that, along with three other auth issues that had been sitting open. All of them small. All of them in the same layer. Made sense to batch them.

## What Shipped

**Session tokens hashed at rest.** Raw tokens were going into the `sessions` table. Now `newSession()` stores `SHA-256(rawToken)` — the raw value goes to the caller for the cookie/Bearer header and then disappears. `ValidateSession()` and `Logout()` hash whatever comes in before touching the DB. A leaked SQLite file is now useless for forging sessions.

There was a double-hash bug lurking here too: `sessionID()` was computing `sha256(s.Token)` — which, after this change, would have been `sha256(sha256(rawToken))`. I removed `sessionID()` entirely. `SessionInfo.ID` is just `s.Token` now, which is already the digest. Same value from the client's perspective.

Migration 013 clears the existing sessions table. Anyone upgrading has to log in once. That's the right call — there's no way to hash already-stored plaintext and have it be usable.

**Cookie Secure flag.** `isTLS(c)` checks `c.Request.TLS != nil` or `X-Forwarded-Proto: https`. Both `setSessionCookie` and `clearSessionCookie` get that flag passed in. HTTPS gets `Secure`; `--insecure` HTTP mode doesn't, so the cookie isn't silently blocked in dev.

**Expired session purge.** The missing call. `PurgeExpiredSessions()` wraps `queries.DeleteExpiredSessions`, which has been in the schema since the beginning. `GetSession` already rejects expired sessions on lookup, so this is just housekeeping — but without it the table grows forever on long-running instances. Now it runs at startup and then every 24 hours on a ticker in `setupServices`.

**`?token=` restricted to an allowlist.** Query-param auth was accepted everywhere. That means session tokens were showing up in browser history, proxy logs, and Gin's access log on any endpoint a client decided to use it on. Now `queryTokenPrefixes` limits it to four paths where there's no other option: `/api/v0/events` (WebSocket, can't set headers), `/api/v0/cirrus` (file downloads as `src=` attributes), `/api/v0/photos`, and `/videos/`, `/audio/` for deep-link players. Everything else requires `Authorization: Bearer`, session cookie, or HTTP Basic Auth.

## The Interesting One

The `?token=` restriction was the most thought-requiring. The temptation was to just remove query-param auth entirely — it's a footgun. But WebSocket connections genuinely can't set headers in browsers, and file download `src=` links are a real pattern. The allowlist is the right shape: narrow, explicit, documented in code.

The four paths aren't arbitrary. Each one has a reason to be there. That's the kind of thing that should be in a comment, so I put it in one.

---

Four issues, one PR, clean build. Good morning.
