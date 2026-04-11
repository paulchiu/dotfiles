---
name: markitdown-convert
description: "Convert files and document-like inputs to Markdown with MarkItDown. Use when asked to convert a PDF, Word doc, PowerPoint, Excel file, image, audio file, HTML, CSV, JSON, XML, ZIP, EPUB, or similar content to markdown, extract a document into markdown, or save a source file as .md."
---

# MarkItDown Convert

Use the installed `markitdown` CLI to convert supported files to Markdown.

## When To Use

Use this skill when the user wants to:

- convert a file to Markdown
- extract a document into Markdown
- turn a PDF, DOCX, PPTX, XLSX, XLS, HTML, CSV, JSON, XML, ZIP, EPUB, image, audio file, or Outlook message into `.md`
- preserve structure like headings, lists, tables, and links while converting

Do not use this skill for handwritten rewrites or prose-only formatting requests when there is no source file or document to convert.

## Tooling

- Prefer the installed CLI on `PATH`: `markitdown`
- Current install location: `/Users/paul/.local/bin/markitdown`
- If you need syntax help, run: `markitdown --help`

## Workflow

### 1. Identify the source

Determine:

- the input path or stream
- whether the user wants a saved `.md` file or just converted output
- the desired output path, if specified

If the user does not specify an output path and clearly wants a file created, default to the source basename with a `.md` extension next to the source file.

### 2. Convert with the CLI

Save to a file:

```bash
markitdown /path/to/input.pdf -o /path/to/output.md
```

Write Markdown to stdout:

```bash
markitdown /path/to/input.pdf
```

Read from stdin when needed:

```bash
cat /path/to/input.pdf | markitdown > output.md
```

### 3. Verify the result

After conversion:

- confirm the command exited successfully
- inspect the beginning of the generated Markdown
- mention any obvious degradation or unsupported content

### 4. Report clearly

Tell the user:

- where the Markdown was written
- whether conversion succeeded cleanly
- any notable caveats, such as OCR limits or unsupported embedded content

## Notes

- This environment has MarkItDown installed from the Microsoft GitHub repository, not the stale PyPI `0.0.2` release.
- The current upstream repo exposes an MCP server package (`markitdown-mcp`), but not a Codex/OpenCode skill.
- The upstream repo currently has a broken optional dependency for YouTube transcription (`youtube-transcript-api~=1.0.0`), so this local install excludes the YouTube extra. If the user asks to convert a YouTube URL, explain that the upstream dependency is currently not resolvable and do not pretend support exists.
- For other supported file types, use the installed CLI first before reaching for custom parsing.
