---
name: gog-gmail
description: "Manages Gmail via the gog CLI: search, read, send, reply, draft, label, and download attachments. Use when asked to check email, send email, search inbox, manage labels, or work with Gmail."
---

# gog Gmail Manager

Manage Gmail using the `gog` CLI (v0.9.0+). Authentication is pre-configured.

## Global Flags

Always add `--no-input` to prevent interactive prompts. Use `--json` when you need to parse output programmatically (e.g., extracting IDs). Use `--plain` for stable TSV output.

## Commands Reference

### Search Threads

Search using Gmail query syntax. Returns threads (grouped conversations).

```bash
gog gmail search "from:alice subject:invoice" --max=10 --no-input
```

- `--max=N` — max results (default 10)
- `--page=TOKEN` — pagination token
- `--oldest` — show first message date instead of last
- `-z TIMEZONE` — output timezone (IANA name)

**Gmail query examples:**
- `is:unread` — unread messages
- `from:user@example.com` — from specific sender
- `subject:report` — subject contains "report"
- `has:attachment` — has attachments
- `after:2026/01/01 before:2026/02/01` — date range
- `in:inbox` — inbox only
- `label:important` — specific label
- `is:starred` — starred messages
- `newer_than:7d` — last 7 days

### Search Messages

Search individual messages (not grouped by thread):

```bash
gog gmail messages search "is:unread" --max=5 --no-input
gog gmail messages search "from:boss" --include-body --json --no-input
```

- `--include-body` — include decoded message body

### Read a Message

```bash
gog gmail get <messageId> --no-input
gog gmail get <messageId> --format=full --no-input
gog gmail get <messageId> --json --no-input
```

- `--format=full|metadata|raw` — message format (default: full)
- `--headers=From,Subject` — specific headers (metadata format only)

### Read a Thread

Get all messages in a thread:

```bash
gog gmail thread get <threadId> --no-input
gog gmail thread get <threadId> --full --no-input
```

- `--full` — show full message bodies
- `--download` — download attachments
- `--out-dir=PATH` — attachment output directory

### Send Email

```bash
gog gmail send \
  --to="recipient@example.com" \
  --subject="Subject line" \
  --body="Email body text" \
  --no-input
```

**Flags:**
- `--to=ADDR` — recipients (comma-separated, required)
- `--cc=ADDR` — CC recipients
- `--bcc=ADDR` — BCC recipients
- `--subject=TEXT` — subject (required)
- `--body=TEXT` — plain text body (required unless --body-html)
- `--body-file=PATH` — body from file (`-` for stdin)
- `--body-html=HTML` — HTML body
- `--attach=PATH` — attachment (repeatable)
- `--from=ADDR` — send-as alias

### Reply to Email

Reply to a specific message or thread:

```bash
# Reply to a specific message
gog gmail send \
  --reply-to-message-id="<messageId>" \
  --body="Reply text" \
  --no-input

# Reply within a thread (uses latest message headers)
gog gmail send \
  --thread-id="<threadId>" \
  --to="recipient@example.com" \
  --subject="Re: Original subject" \
  --body="Reply text" \
  --no-input

# Reply-all (auto-populates recipients from original)
gog gmail send \
  --reply-to-message-id="<messageId>" \
  --reply-all \
  --body="Reply text" \
  --no-input
```

### Drafts

```bash
# List drafts
gog gmail drafts list --no-input

# Create a draft
gog gmail drafts create \
  --to="recipient@example.com" \
  --subject="Draft subject" \
  --body="Draft body" \
  --no-input

# Create a reply draft
gog gmail drafts create \
  --reply-to-message-id="<messageId>" \
  --body="Draft reply" \
  --no-input

# Get draft details
gog gmail drafts get <draftId> --no-input

# Send a draft
gog gmail drafts send <draftId> --no-input

# Update a draft
gog gmail drafts update <draftId> --body="Updated body" --no-input

# Delete a draft
gog gmail drafts delete <draftId> --no-input
```

### Labels

```bash
# List all labels
gog gmail labels list --no-input

# Get label details (including message counts)
gog gmail labels get "INBOX" --no-input

# Create a label
gog gmail labels create "My Label" --no-input

# Add/remove labels on threads
gog gmail labels modify <threadId> --add="Label1" --remove="Label2" --no-input

# Modify labels on a thread (alternative)
gog gmail thread modify <threadId> --add="STARRED" --remove="UNREAD" --no-input
```

### Attachments

```bash
# List attachments in a thread
gog gmail thread attachments <threadId> --no-input

# Download all attachments from a thread
gog gmail thread attachments <threadId> --download --out-dir=./downloads --no-input

# Download a specific attachment
gog gmail attachment <messageId> <attachmentId> --out=./file.pdf --no-input
```

### Batch Operations

```bash
# Modify labels on multiple messages
gog gmail batch modify <msgId1> <msgId2> --add="Label" --remove="UNREAD" --no-input

# Permanently delete messages (destructive!)
gog gmail batch delete <msgId1> <msgId2> --force --no-input
```

### Web URLs

Get Gmail web URLs for threads:

```bash
gog gmail url <threadId> --no-input
```

## Common Workflows

### Check Recent Unread Email

```bash
gog gmail search "is:unread" --max=10 --no-input
```

Then read a specific message:

```bash
gog gmail get <messageId> --no-input
```

### Search and Read a Thread

```bash
# Find it
gog gmail search "from:alice subject:project update" --json --no-input

# Read all messages in the thread
gog gmail thread get <threadId> --full --no-input
```

### Send with Attachment

```bash
gog gmail send \
  --to="team@example.com" \
  --subject="Report attached" \
  --body="Please find the report attached." \
  --attach=./report.pdf \
  --no-input
```

### Archive a Thread (remove from inbox)

```bash
gog gmail thread modify <threadId> --remove="INBOX" --no-input
```

### Mark as Read

```bash
gog gmail thread modify <threadId> --remove="UNREAD" --no-input
```

### Star a Thread

```bash
gog gmail thread modify <threadId> --add="STARRED" --no-input
```

## Important Notes

- Always use `--no-input` to prevent interactive prompts
- Use `--json` when you need to extract IDs or structured data from output
- Use `--force` with destructive operations (batch delete) to skip confirmations
- For reply-all, `--reply-all` auto-populates To/CC from the original message
- Thread IDs and message IDs are obtained from search results (use `--json` to parse)
- Gmail query syntax is the same as the Gmail web search bar
