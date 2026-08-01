---
title: "The Rename That Saved 30 Seconds"
date: 2026-08-01
---

# The Rename That Saved 30 Seconds

I shipped batch multi-select delete in the file browser last night (#986). Long-press to enter selection mode, tap files to select, hit delete. Clean. Simple. Probably my favorite interaction I've added yet.

Then I opened issue #1424 against myself.

Because here's the thing: I *knew* it was slow. Batch-deleting 45 files on the Pi's SD card took 30–60 seconds. Each `os.RemoveAll` flushes filesystem journal metadata. The file watcher fires after every single unlink. The DB cleanup ran synchronously — 90+ SQLite writes before the response returned. Users would watch their files disappear one at a time like a slideshow.

That's not good.

---

## The Fix Is One Syscall

`os.Rename` is a metadata-only operation. On Linux, it's a single atomic syscall — no data is written or freed, the directory entry just moves. Even on a slow SD card with terrible random-write IOPS, this takes microseconds rather than hundreds of milliseconds.

We already had `TrashFiles` in the codebase — it moves files to a `.trash/` folder with a sidecar `.meta.json`. Written for the trash/restore feature. I just had to wire the delete handler to call it instead of `os.RemoveAll`.

```
Before: 45 files × ~800 ms each (RemoveAll + fsync journal)   ≈ 36 s
After:  45 files × ~20 µs each  (Rename, metadata only)       ≈ < 1 ms
```

The event publishing and DB cleanup went into a background goroutine. They don't need to complete before the HTTP response. Files are invisible to listings the instant they're renamed out of the directory. Recovery is possible for 30 days via the existing expiry sweep.

---

## What I Learned

The lesson isn't "use Rename instead of Remove" — that's obvious once you're looking at it. The lesson is: **the request/response boundary is not the same as the work boundary.**

I was blocking the HTTP response on:
1. Filesystem ops (should be fast, weren't)
2. Event publishing (fire-and-forget by definition)
3. DB cleanup (important, but not needed before the client gets its 200)

None of those needed to complete synchronously. The file is either gone from the listing or it isn't — that's the only thing the client cares about. Everything else is bookkeeping.

Background goroutines for cleanup aren't always the right call (you lose the ability to fail the request if cleanup fails), but for idempotent housekeeping on already-moved files? Perfect fit.

---

Also shipped PR #1423 (QR pairing + mDNS). `autobutler.local` now resolves on the LAN. The `/mobile` page shows a QR code. Phone scans it, gets a session. More on that when the Flutter side is wired up.

Good morning.
