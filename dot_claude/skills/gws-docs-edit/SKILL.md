---
name: gws-docs-edit
description: "Google Docs: Edit documents in place without losing comments or suggestions. Use when modifying an existing Google Doc that may have collaboration activity."
---

# Google Docs — Comment-Preserving Edits

Use the Docs API `batchUpdate` to make targeted edits that preserve comments and suggestions. **Never re-upload a doc via the Drive API if comments exist** — that destroys them.

## Step 1: Read the Document Structure

Get the document's content with paragraph indices and styles:

```bash
gws docs documents get --params '{"documentId": "DOC_ID"}' > /tmp/doc.json
```

Parse with Python to see the structure (save to file first — piping directly fails because the JSON contains lowercase `true`/`false`):

```python
import json

with open('/tmp/doc.json') as f:
    doc = json.load(f)

body = doc.get('body', {}).get('content', [])
for elem in body:
    if 'paragraph' in elem:
        p = elem['paragraph']
        text = ''.join([e.get('textRun', {}).get('content', '') for e in p.get('elements', [])])
        style = p.get('paragraphStyle', {}).get('namedStyleType', '')
        start = elem.get('startIndex', '')
        end = elem.get('endIndex', '')
        if text.strip():
            print(f'[{start}-{end}] ({style}) {text.strip()[:120]}')
```

For **table cells**, use recursive traversal:

```python
def show_tables(elements):
    for elem in elements:
        if 'table' in elem:
            for ri, row in enumerate(elem['table'].get('tableRows', [])):
                for ci, cell in enumerate(row.get('tableCells', [])):
                    for p in cell.get('content', []):
                        if 'paragraph' in p:
                            for e in p['paragraph'].get('elements', []):
                                content = e.get('textRun', {}).get('content', '')
                                start = e.get('startIndex', '')
                                end = e.get('endIndex', '')
                                if content.strip():
                                    print(f'  R{ri}C{ci} [{start}-{end}] {repr(content.rstrip())}')

show_tables(doc.get('body', {}).get('content', []))
```

## Step 2: Choose the Right Operation

| Goal | Operation | Notes |
|------|-----------|-------|
| Find & replace across whole doc | `replaceAllText` | Simplest. No index math needed. |
| Insert new content at a position | `insertText` | When doing multiple inserts, work from **highest index to lowest** so earlier inserts don't shift later indices. |
| Delete specific text | `deleteContentRange` | **Cannot include the trailing newline** at the end of a segment. Use `endIndex - 1`. |
| Change paragraph formatting | `updateParagraphStyle` | Must use **current** indices — if you just inserted text, re-read the doc or do styling in a separate call. |

## Operations Reference

### replaceAllText — Find & Replace

Best for bulk changes. No index calculation needed.

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "replaceAllText": {
        "containsText": {"text": "old text", "matchCase": true},
        "replaceText": "new text"
      }
    }]
  }'
```

### insertText — Add Content at a Position

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "insertText": {
        "location": {"index": 123},
        "text": "New paragraph text here.\n"
      }
    }]
  }'
```

### deleteContentRange — Remove Text

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "deleteContentRange": {
        "range": {"startIndex": 100, "endIndex": 110}
      }
    }]
  }'
```

### updateParagraphStyle — Format a Paragraph

Style types: `HEADING_1`, `HEADING_2`, `HEADING_3`, `HEADING_4`, `NORMAL_TEXT`, `TITLE`, `SUBTITLE`

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "updateParagraphStyle": {
        "range": {"startIndex": 100, "endIndex": 150},
        "paragraphStyle": {"namedStyleType": "HEADING_3"},
        "fields": "namedStyleType"
      }
    }]
  }'
```

### Batching Multiple Operations

Multiple operations can go in one request. Process **deletes before inserts** and work **bottom-up** (highest indices first) to avoid index shifting:

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [
      {"deleteContentRange": {"range": {"startIndex": 500, "endIndex": 510}}},
      {"deleteContentRange": {"range": {"startIndex": 200, "endIndex": 205}}},
      {"insertText": {"location": {"index": 300}, "text": "new content\n"}}
    ]
  }'
```

## Gotchas

- **Index shifting after inserts.** After `insertText`, every index after the insertion point shifts by the length of the inserted text. If you also need to style the inserted text, do it in a **separate `batchUpdate` call** using the new indices (re-read the doc or calculate the shift).

- **deleteContentRange trailing newline.** The API rejects deleting the final newline of a segment. Use `endIndex - 1` if you hit `"The range cannot include the newline character at the end of the segment."`.

- **insertText boundary.** The insertion index must be inside an existing paragraph. If you get `"The insertion index must be inside the bounds of an existing paragraph"`, the index is past the segment boundary — back up by 1.

- **Comments survive targeted edits.** `insertText`, `deleteContentRange`, `replaceAllText`, and `updateParagraphStyle` all preserve comments anchored to other text in the document. Only a full document re-upload via the Drive API destroys them.

- **Viewing comments.** Use `gcmd info --show-comments DOC_ID` or `gws drive comments list` to see existing comments and what text they're anchored to.

> [!CAUTION]
> This is a **write** skill — confirm with the user before executing edits.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-docs](../gws-docs/SKILL.md) — All Google Docs commands
- [gws-docs-write](../gws-docs-write/SKILL.md) — Simple text append
