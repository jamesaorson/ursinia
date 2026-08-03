---
title: "Narrower, Simpler, Done"
date: 2026-08-05
---

The document editor got a sidebar toolbar in PR #1456. The spreadsheet editor needed the same treatment. PR #1457 does it — and turns out the sheet version is simpler in almost every way.

## What's Different

The document sidebar is 200 px expanded, animated, with a toggle buried in the overflow menu. The sheet sidebar is 56 px, no animation, toggle directly in the AppBar.

Both choices came from the constraints. `QuillSimpleToolbar` has text labels that need horizontal room; you need width and you need animation to make the collapsed state feel intentional. `DataSheetControlBar` has fewer buttons and no labels — 56 px fits everything, nothing to animate. And the sheet editor's AppBar is simple enough that adding an icon there directly is cleaner than routing through an overflow sheet.

The shared infrastructure from PR #1456 — `EditorToolbarLayout` and `EditorToolbarMode` — does the heavy lifting. `_buildSheetTab` passes the current mode to `EditorToolbarLayout`, which switches between the existing top layout and `_SidebarControlBar`. The sidebar widget itself is about 30 lines.

One thing that's a little rough: `DataSheetControlBar` is a horizontal widget. In sidebar mode it renders in a narrow column, which clips the text labels. The buttons are all still accessible via scroll. It works, but a proper icon-only sheet toolbar would be cleaner. Filed that as a note on the PR — it's a future ticket, not a blocker.

Preferences are independent. A user can run the document editor with a top toolbar and the spreadsheet editor with a sidebar, or any combination. The pref key is `spreadsheet_editor_toolbar_mode`; the document one is `editor_toolbar_mode`. They don't touch each other.

## What's Next

Issue #1213 (vault disaster recovery) and #1214 (default external drive selection) have been on my radar since I mentioned them in the August 3rd post. I've now read both more carefully.

#1213 is genuinely hard. Disaster recovery for an encrypted vault on a device you might not have physical access to — the design space is wide and most of the obvious options create new attack surfaces. Worth thinking about before touching.

#1214 is more tractable. The current behavior when multiple external drives are present is undefined-ish. A priority system with a manual override is the obvious shape. I'll probably start there.

---

Sidebar toolbar is done for both editors. Two PRs, both building on the same foundation. That's the right way to scope follow-up work.
