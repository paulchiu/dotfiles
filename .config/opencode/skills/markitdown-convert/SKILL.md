---
model: haiku
name: markitdown-convert
description: "Convert files to Markdown with MarkItDown. Use when asked to convert a PDF, Word, PowerPoint, Excel, image, audio, HTML, CSV, JSON, XML, ZIP, or EPUB to markdown, or save a source file as .md."
---

# MarkItDown Convert

Convert a source file to Markdown using the installed `markitdown` CLI. Follow the steps below in order. Do not skip steps.

## When To Use

Use this skill when the user wants to:

- convert a file to Markdown
- extract a document into Markdown
- turn a PDF, DOCX, PPTX, XLSX, XLS, HTML, CSV, JSON, XML, ZIP, EPUB, image, audio file, or Outlook message into `.md`
- preserve structure like headings, lists, tables, and links while converting

Do NOT use this skill when there is no source file or document to convert (for example, a request to reformat prose the user typed into chat). In that case, handle the request without this skill.

If the user asks to convert a YouTube URL: stop. Tell the user that this local install excludes the YouTube extra because the upstream dependency (`youtube-transcript-api~=1.0.0`) is currently not resolvable. Do not attempt the conversion and do not pretend support exists.

## Steps

### Step 1: Confirm the tool is available

Run:

```bash
markitdown --version
```

- If this prints a version string: continue to Step 2.
- If this fails with "command not found": try the known install path `/Users/paul/.local/bin/markitdown --version`. If that works, use the full path `/Users/paul/.local/bin/markitdown` in all later commands. If that also fails, stop and report to the user that `markitdown` is not installed. Do not write a custom parser as a substitute.

### Step 2: Identify input and output

Determine three things before running any conversion:

1. **Input path**: the file the user named. Verify it exists with `test -f /path/to/input && echo exists`. If it does not exist, stop and ask the user for the correct path.
2. **Output mode**: does the user want a saved `.md` file, or just the converted text shown in the reply?
   - If the user said "save", "write", "create a file", or gave an output path: they want a saved file.
   - If the user only said "convert" or "show me as markdown" with no mention of saving: they want a saved file too (converting a file implies producing one), unless they explicitly asked to see the output inline only.
3. **Output path**:
   - If the user gave an output path: use it exactly.
   - If the user did not give one: use the source path with its extension replaced by `.md`, in the same directory as the source. Example: `/Users/paul/docs/report.pdf` becomes `/Users/paul/docs/report.md`.

### Step 3: Run the conversion

To save to a file (the normal case):

```bash
markitdown /path/to/input.pdf -o /path/to/output.md
```

To print Markdown to stdout (only when the user explicitly wants inline output, no file):

```bash
markitdown /path/to/input.pdf
```

To read from stdin (only when the input arrives as a stream or pipe, not a named file):

```bash
cat /path/to/input.pdf | markitdown > /path/to/output.md
```

If the command exits non-zero or prints an error: stop, do not retry with different tools, and report the exact error message to the user. Only retry if the error indicates a fixable mistake you made (for example, a typo in the path).

If you need syntax help for an unusual case, run `markitdown --help` before improvising flags.

### Step 4: Verify the result

1. Confirm the command exited with status 0 (the previous step's output shows this).
2. If a file was written, confirm it exists and is non-empty: `test -s /path/to/output.md && echo ok`. If this prints nothing, stop and report that the output file is empty.
3. Read the first 20 to 30 lines of the generated Markdown (use the Read tool if available, otherwise `head -n 30 /path/to/output.md`).
4. Note any obvious degradation: missing tables, garbled text, image content reduced to placeholders, or empty sections.

### Step 5: Report to the user

Tell the user, in this order:

1. The absolute path of the Markdown file that was written (or state that output was printed inline).
2. Whether the conversion succeeded cleanly.
3. Any caveats you observed in Step 4, such as OCR limits, lost formatting, or unsupported embedded content. If there were none, say the output looks clean.

## Notes

- This environment has MarkItDown installed from the Microsoft GitHub repository, not the stale PyPI `0.0.2` release.
- The current upstream repo exposes an MCP server package (`markitdown-mcp`), but not a Codex/OpenCode skill.
- For every supported file type, use the installed CLI first. Do not hand-roll parsing or use other conversion libraries unless the CLI has already failed and the user has asked you to try something else.
