---
name: gcal
description: View Google Calendar events, find meeting notes, and check schedule
---

# Google Calendar via gws CLI

Quick reference for using `gws` (Google Workspace CLI) to view calendar events and access meeting notes.

## Quick Start

```bash
# View today's events
gws calendar events list \
  --params '{"calendarId": "primary", "timeMin": "2026-03-16T00:00:00Z", "timeMax": "2026-03-17T00:00:00Z", "singleEvents": true, "orderBy": "startTime"}'

# Quick agenda view across all calendars
gws calendar +agenda
```

## When to Use This Skill

- User asks about their calendar or schedule
- User wants to see today's meetings or upcoming events
- User asks about meeting notes or Gemini notes from Google Meet
- User mentions a specific meeting and wants details
- User wants to find events related to a topic

## Authentication

```bash
npm install -g @googleworkspace/cli
gws auth setup
gws auth login -s drive,calendar,docs
```

## Common Operations

### List Events for a Date Range

```bash
gws calendar events list \
  --params '{
    "calendarId": "primary",
    "timeMin": "2026-03-16T00:00:00Z",
    "timeMax": "2026-03-17T00:00:00Z",
    "singleEvents": true,
    "orderBy": "startTime"
  }'
```

**Key parameters:**
- `calendarId`: Use `"primary"` for the user's main calendar
- `timeMin` / `timeMax`: ISO 8601 timestamps (use `date` command to get current date)
- `singleEvents: true`: Expands recurring events into individual instances
- `orderBy: "startTime"`: Requires `singleEvents: true`

### Find Events with Gemini Notes

```bash
gws calendar events list \
  --params '{
    "calendarId": "primary",
    "timeMin": "2026-03-16T00:00:00Z",
    "timeMax": "2026-03-17T00:00:00Z",
    "singleEvents": true,
    "orderBy": "startTime"
  }' 2>/dev/null \
  | jq -r '.items[]
    | select(.attachments != null)
    | select(.attachments[] | .title == "Notes by Gemini")
    | {summary, fileId: (.attachments[] | select(.title == "Notes by Gemini") | .fileId)}'
```

### Export Meeting Notes as Markdown

```bash
# Get the fileId from the event's attachments, then:
gws drive files export \
  --params '{"fileId": "YOUR_FILE_ID", "mimeType": "text/markdown"}' \
  -o notes.md
```

### Search for Events

The Calendar API doesn't have a direct search. Use `q` parameter for text search:

```bash
gws calendar events list \
  --params '{
    "calendarId": "primary",
    "q": "ANSTRAT-1567",
    "singleEvents": true,
    "orderBy": "startTime",
    "timeMin": "2026-01-01T00:00:00Z"
  }'
```

## Event Data Shape

Timed events have `start.dateTime` / `end.dateTime`:
```json
{
  "summary": "Meeting Title",
  "start": {"dateTime": "2026-03-16T09:30:00-04:00"},
  "end": {"dateTime": "2026-03-16T10:00:00-04:00"},
  "attachments": [
    {"title": "Notes by Gemini", "fileId": "...", "fileUrl": "..."}
  ],
  "description": "..."
}
```

All-day events have `start.date` / `end.date` instead.

## Supported Export Formats

| MIME type               | Use case   |
|-------------------------|------------|
| `text/markdown`         | Markdown   |
| `text/plain`            | Plain text |
| `application/pdf`       | PDF        |
| `text/html`             | HTML       |

## Tips

1. **Never use `--format table` for calendar events** — it renders `defaultReminders` (a root-level array) instead of the `items` array. Always use default JSON output and pipe through `jq` for readable results.
2. **Always redirect stderr when piping to `jq`** — `gws` prints `Using keyring backend: keyring` to stderr before the JSON, which breaks `jq`. Always use `2>/dev/null` before the pipe: `gws calendar events list --params '...' 2>/dev/null | jq ...`
3. **Use `jq` for filtering** — gws returns raw Google Calendar API JSON
4. **Always set `singleEvents: true`** — otherwise recurring events come as templates
5. **Timestamps are UTC** — use `Z` suffix or offset like `-04:00`
6. **Attachments include Gemini notes** — filter by `title == "Notes by Gemini"` to find AI meeting notes
7. **Export notes with Drive API** — use the `fileId` from attachments to export via `gws drive files export`
8. **Widen date ranges when searching** — "a couple weeks ago" can easily be 3+ weeks. When searching for past events by keyword, go back further than you think (e.g., 4 weeks) rather than missing the event.

---

*Last updated: 2026-03-25*
