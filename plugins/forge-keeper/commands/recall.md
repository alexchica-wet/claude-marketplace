---
description: Search past session logs in docs/sessions/ to recall what was done, why decisions were made, and what context was relevant. Use when the user asks "why did we do X?", "when did we change Y?", or needs context from a past session.
---

Search the session bitácora (`docs/sessions/`) to answer questions about
past work.

## Process

1. Read the user's question — what are they trying to recall?
2. Scan `docs/sessions/*.md` files for relevant content
3. Search by: keywords, date ranges, decision descriptions, file paths mentioned
4. Present findings with:
   - Which session(s) are relevant
   - The specific decision, change, or context they're looking for
   - Any related decisions from other sessions

If `docs/sessions/` doesn't exist or is empty, inform the user that no
session logs have been captured yet. Suggest running `/forge-keeper:sync`
after their next work session to start building the bitácora.

Keep responses concise — quote the relevant parts, don't dump entire sessions.
