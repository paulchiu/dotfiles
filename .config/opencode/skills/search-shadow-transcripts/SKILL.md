---
name: search-shadow-transcripts
description: Search and query Shadow.app meeting transcripts from the local SQLite database. Use when the user wants to (1) search for specific text in Shadow transcripts, (2) query meeting recordings by content, (3) find conversations containing keywords, (4) extract transcript data from Shadow.app
---

# Search Shadow Transcripts

Query and search meeting transcripts stored in Shadow.app's local SQLite database.

## Database Location

Shadow stores transcripts in:
```
~/Library/Application Support/com.taperlabs.shadow/shadow.db
```

## Key Tables

- `SHADOW_TRANSCRIPT` - Contains transcript segments with `transContent` (the text), `transStartedAt`, `transEndedAt`, `convIdx` (conversation ID)
- `SHADOW_CONVERSATION` - Conversation metadata
- `SHADOW_SPEAKER` - Speaker information

## Quick Search

Use the search script:

```bash
./scripts/search_transcripts.sh "search term"
```

**Default output now includes meeting metadata:**
- Meeting name (convTitle)
- Date and time (convStartedAt in local timezone)
- Transcript content

Options:
- `--conversation` - Include full conversation ID and timestamps
- `--count` - Count matches only
- `--recent` - Show only today's transcripts
- `--raw` - Output raw SQL results (without formatting)

## SQL Examples

**Search for specific text with meeting info:**
```sql
SELECT c.convTitle, c.convStartedAt, t.transContent 
FROM SHADOW_TRANSCRIPT t
JOIN SHADOW_CONVERSATION c ON t.convIdx = c.convIdx
WHERE t.transContent LIKE '%keyword%'
ORDER BY t.transStartedAt DESC;
```

**Find transcripts with timestamps:**
```sql
SELECT c.convTitle, c.convStartedAt, t.transContent 
FROM SHADOW_TRANSCRIPT t
JOIN SHADOW_CONVERSATION c ON t.convIdx = c.convIdx
WHERE t.transContent LIKE '%meeting%' 
ORDER BY t.transStartedAt DESC;
```

**Get all transcripts from a specific conversation:**
```sql
SELECT c.convTitle, c.convStartedAt, t.transContent 
FROM SHADOW_TRANSCRIPT t
JOIN SHADOW_CONVERSATION c ON t.convIdx = c.convIdx
WHERE t.convIdx = 123 
ORDER BY t.transIdx;
```

**Count transcript segments:**
```sql
SELECT COUNT(*) FROM SHADOW_TRANSCRIPT;
```

## Resources

### scripts/

- `search_transcripts.sh` - Bash script for searching transcripts with various options
