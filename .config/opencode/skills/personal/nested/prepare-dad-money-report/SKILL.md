---
name: prepare-dad-money-report
description: "Prepare Paul's monthly family money report email for his dad from ANZ credit card exports, the prior Excel format, and the current Obsidian journal account details. Use when asked to prepare Dad's monthly family finances, family money report, ANZ report, credit card bill email, or the recurring Gmail draft for Dad/Mom/Nicole."
---

# Prepare Dad Money Report

Prepare the monthly family finance report, workbook, screenshots, and Gmail draft. Treat this as sensitive personal finance work: read current values from local private sources, avoid committing raw outputs, and never send the email.

## Stable Email Context

Recipients are not stored in this skill. When you need them, look up the most recent prior `Family finances for <Month>, <Year>` thread in Gmail and reuse its To/Cc list verbatim. Do not hardcode or echo the addresses back to Paul in chat.

- Subject: `Family finances for <Month>, <Year>`
- Sender style: short, plain, direct, ending with `Kind regards,` and `Paul.`

Gmail or Firefox access is still needed when Paul asks to create the actual saved Gmail draft, place screenshots inline through the Gmail UI, or inspect a newer prior thread. Creating a draft is allowed when explicitly requested, but never send it.

## Access Boundary

Generate the report artifacts with CLI tools by default. Do not use desktop/browser access for transaction conversion, row filtering, categorisation, workbook creation, chart rendering, or screenshot generation.

Use:

- shell commands for file discovery, `paul-tools`, CSV inspection, and reconciliation
- the Spreadsheets skill plus bundled workspace dependencies for `.xlsx` creation and rendered PNG screenshots
- `email-draft.md` as a complete local draft when Gmail access is unavailable or not yet confirmed

Prefer the Gmail connector for creating a saved draft when it can attach the workbook/screenshots. Use Firefox/Computer Use only when connector support is insufficient for the desired draft formatting, especially inline image placement.

## Sources

- Current credit card export: look in `~/Downloads`, usually `anz.txt`.
- Converter: `/Users/paul/dev-misc/paul-tools`, command:

```bash
npm start -- anz:csv /Users/paul/Downloads/anz.txt <output.csv>
```

- Previous report workbook: latest relevant `~/Downloads/anz-*.xlsx`; use it for sheet shape and visual expectations, not for current values.
- Current balances and monthly notes: `/Users/paul/Library/Mobile Documents/iCloud~md~obsidian/Documents/Quartz/Area/Journal/YYYY-MM-DD.md`.
- Working outputs: `/Users/paul/dev/sandbox/outputs/dad-money-report-YYYY-MM/`.

Do not hardcode bank account numbers, balances, or current-month deposit details in this skill. Read balances and monthly notes from the journal each month. Do not include bank account numbers or BSB details in the email draft; Dad already knows them.

## Workflow

### 1. Gather current files

Inspect `~/Downloads` for the current ANZ text export and last month's Excel report. Read today's journal note for:

- credit card closing balance
- cash balance
- ANZ Access Advantage cash balance
- deposit notes or other monthly commentary

Create a fresh output directory under `outputs/`.

### 2. Convert and clean transactions

Run the `paul-tools` converter into the output directory. Inspect the CSV and remove the credit card payment line, usually `AUTOREPAYMENT - THANK YOU`, before calculating report totals.

Keep statement-period rows from the export unless Paul explicitly asks for strict calendar-month filtering. The prior report has used the statement period, not only the named month.

Reconcile the cleaned transaction total against the journal credit card closing balance. Stop and investigate if the totals do not match.

### 3. Build the workbook, table, and screenshot

Use the Spreadsheets skill and bundled workspace dependencies for workbook creation/editing. Preserve the prior workbook's two-sheet shape unless Paul asks for a redesign:

- `Statement`: date, description, card, card holder, for/category, amount
- `Spend On`: Home/Mom/Nicole breakdown with a visible grand total and chart

Use the prior report's categorisation pattern. Known recurring defaults:

- card `1864` is Mom
- card `7703` is Nicole
- otherwise, use the card holder as the spend category

Home-use heuristics:

- classify council bills, water, and electricity/energy as `Home`
- classify home insurance as `Home`
- RACQ can be either home insurance or car insurance; use judgement rather than classifying all RACQ as Home
- home insurance tends to be steadier and monthly, while car insurance or motoring costs may vary more; use amount, regularity, card, and prior reports to guess when the merchant text is ambiguous
- if unsure after checking prior reports, choose the most likely category and keep the workbook easy to edit

Sort statement rows by amount descending. For the email body, render transactions over $100 as a markdown table, not as a screenshot. Produce:

- `anz-<month>-<year>.xlsx`
- a markdown table of transactions over $100 inside `email-draft.md`
- `spend-breakdown.png`
- `email-draft.md`

### 4. Draft the email

Keep the draft close to this template:

```text
Hi Dad,

This month the credit card bill is $X. We still have $Y remaining in cash.

The over $100 transactions this month have been:

| Date | Description | Card | Card Holder | For | Amount |
| --- | --- | --- | --- | --- | ---: |
| ... | ... | ... | ... | ... | $... |

The spend breakdown is:

[insert spend-breakdown.png]

Kind regards,

Paul.
```

Add deposit notes only when the journal or Paul indicates they are needed for this month.

If creating a Gmail draft, attach the workbook and include the screenshots inline or as attachments according to what the Gmail tooling supports. If using Computer Use to type/upload sensitive financial data into Gmail, pause at the action-time confirmation required by the Computer Use policy.

### 5. Verify and report

Before finishing, verify:

- CSV conversion succeeded and the payment row was excluded
- cleaned total equals the journal credit card closing balance
- workbook opens/exports successfully
- workbook formula-error scan is clean
- screenshot images render legibly
- Gmail draft was created, or the task is explicitly paused awaiting confirmation

In the final response, link only the useful output files and state whether a Gmail draft exists. Do not paste bank account numbers, recipient addresses, or full email body unless Paul asks.
