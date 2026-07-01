---
model: sonnet
name: generate-engineering-on-call-report
description: "Use this when asked to generate the monthly me&u Engineering On Call report, usually from the monthly Slack reminder or the Engineering On Call Notion runbook. The skill runs the GitHub report workflow for the previous month, checks the CSV output, prepares an Excel attachment, and returns plain email copy for the requester to paste into Gmail or another email client."
---

# Generate Engineering On Call Report

Generate the monthly me&u Engineering On Call hours report. Trigger the GitHub report
workflow for the previous calendar month, validate the CSV it emits, build a clean Excel
attachment, and hand back plain email copy the requester can paste and send themselves.

## Core rules

- Do **not** send email unless the requester explicitly asks after reviewing the output.
- Do **not** reproduce or fabricate a personal email signature. Output plain email copy only.
- Do **not** paste the CSV table into the email body as a summary. Put a placeholder where
  the screenshot should go.
- Create an Excel attachment with visible column headers and the exact report columns.
- If the report looks incomplete, inconsistent, or missing expected people, **stop and flag
  the issue** before preparing final email copy.

## Inputs and defaults

- **Report period:** the previous calendar month (default).
- **Source workflow:** `manual-full-report.yml` ([Manual Full Report](https://github.com/mr-yum/pagerduty-on-call/actions/workflows/manual-full-report.yml)).
- **Branch:** `main`.
- **Repository:** `mr-yum/pagerduty-on-call`.
- **Recipient source:** prefer the most recent *sent* Gmail examples for current recipients
  and CCs. If Gmail is unavailable, fall back to the parent Notion runbook and ask the
  requester to confirm recipients.

## Workflow

1. **Confirm the triggering context.** If the request came from Slack, read the linked
   message or thread. It is usually just a reminder to run the monthly report.
2. **Fetch the parent Notion runbook if needed** ([How to generate on-call report](https://app.notion.com/p/9d452771628049ce9b2ee2725a815039))
   and follow the GitHub workflow link from there.
3. **Trigger the workflow** on `main`:
   ```bash
   gh workflow run manual-full-report.yml --repo mr-yum/pagerduty-on-call --ref main
   ```
   If the workflow takes month/year inputs, pass the previous calendar month. Otherwise the
   workflow defaults to the previous month.
4. **Wait for the run to complete.** Find the run and watch it:
   ```bash
   gh run list --repo mr-yum/pagerduty-on-call --workflow manual-full-report.yml --limit 1
   gh run watch <run-id> --repo mr-yum/pagerduty-on-call
   ```
   If it fails, fetch the logs (`gh run view <run-id> --repo mr-yum/pagerduty-on-call --log-failed`)
   and report the failure instead of drafting an email.
5. **Extract the CSV.** Fetch the successful run log and pull the report CSV from the
   `---ALLQUIET---` section. Ignore setup logs, dependency downloads, and post-job cleanup.
   ```bash
   gh run view <run-id> --repo mr-yum/pagerduty-on-call --log
   ```
6. **Verify the CSV:**
   - every row has `Total Hours = Weekday + Weekend + Public Holiday`;
   - totals are plausible for the reporting month after excluded business hours.
7. **Build the `.xlsx` attachment** named `oncall-<month>-<year>.xlsx` with one sheet named
   `oncall-<month>-<year>`. Write to the scratchpad or `outputs/` unless the requester
   specifies a path.
8. **Use these columns exactly:** `Name`, `Location`, `Weekday`, `Weekend`,
   `Public Holiday`, `Total Hours`.
9. **Verify the workbook after export:**
   - headers are present and visibly rendered;
   - header text is **not** white on a blank or transparent fill;
   - all values match the CSV;
   - the file opens as a valid Excel workbook.
10. **Return the attachment path and plain email copy.** Only create a Gmail draft if the
    requester explicitly asked for a draft.

## Building the `.xlsx`

Use Python with `openpyxl`. Keep headers visibly styled (bold, on a filled cell), never white
text on a transparent/blank fill.

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

wb = Workbook()
ws = wb.active
ws.title = "oncall-<month>-<year>"

columns = ["Name", "Location", "Weekday", "Weekend", "Public Holiday", "Total Hours"]
ws.append(columns)

header_fill = PatternFill("solid", fgColor="D9E1F2")
header_font = Font(bold=True, color="000000")
for cell in ws[1]:
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center")

# rows parsed from the ---ALLQUIET--- CSV
for row in rows:
    ws.append(row)

wb.save("oncall-<month>-<year>.xlsx")
```

After saving, reopen the file and confirm the header row and values match the CSV before
handing it back.

## Plain email copy

Use this format. Do not add a signature.

```plain text
Subject: me&u Engineering On Call Report for <Month>, <Year>
To: <current payroll recipient>
Cc: <current CC recipients, if any>

Hi,

Please see below and attached for the engineering on call hours served report.

[insert screenshot of the report table here]

[attach Excel version of the table]
```

## Gmail behaviour

If the requester asks for a Gmail draft, create a **draft only** — never send it. Keep the
body plain; do not reproduce the user's signature, formatting, images, or social links.
If a draft with an old attachment already exists, create a replacement draft with the
corrected attachment and clearly tell the requester which draft is the newest one.

## Output to requester

Report back with:

- the workflow run URL or run ID;
- whether the CSV checks passed;
- the `.xlsx` path or attachment name;
- the current plain email copy or Gmail draft ID;
- any caveats, especially missing people, implausible totals, failed workflow runs, or
  duplicate drafts.
