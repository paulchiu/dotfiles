---
model: sonnet
name: prepare-dad-money-report
description: "Prepare the monthly family money report for Paul's dad as phone-sized images to send over LINE."
---

# Prepare Dad Money Report

Prepare the monthly family finance report as phone-width PNG images that Paul sends to his dad in a LINE chat. Dad no longer reads email on a computer, so there is no Gmail draft, workbook, or email body by default. Treat this as sensitive personal finance work: read current values from local private sources, keep outputs out of git, and never send anything on Paul's behalf.

## Output

Three or more 1080px-wide light-mode PNGs, rendered by `scripts/build_line_images.py`:

- `1-summary.png`: credit card bill, savings left, deposits, spend breakdown bars (Home/Mom/Nicole), transactions over $100
- `2-all-transactions.png`, `3-all-transactions.png`, ...: every transaction, 20 per image, largest first, with the total and any exclusion note on the last image

Each transaction shows the merchant, amount, a coloured Home/Mom/Nicole tag, the date, and whose card it was. Paul attaches the images to LINE himself.

## Sources

- Current credit card export: look in `~/Downloads`, usually `anz.txt`.
- Converter: `/Users/paul/dev-misc/paul-tools`, command:

```bash
cd /Users/paul/dev-misc/paul-tools && npm start -- anz:csv /Users/paul/Downloads/anz.txt <output.csv>
```

- Current balances and monthly notes: `/Users/paul/Library/Mobile Documents/iCloud~md~obsidian/Documents/Quartz/Area/Journal/YYYY-MM-DD.md`.
- Previous months' configs: `/Users/paul/dev/sandbox/outputs/archive/*/*/dad-money-report-*/report.json` (also older `build_report.mjs` files), for categorisation precedent.
- Working outputs: `/Users/paul/dev/sandbox/outputs/dad-money-report-YYYY-MM/` (gitignored).

Do not hardcode bank account numbers, balances, or current-month deposit details in this skill. Read balances and monthly notes from the journal each month. Never put bank account numbers or BSB details in the images.

## Workflow

### 1. Gather current files

Inspect `~/Downloads` for the current ANZ text export. Read today's journal note for:

- credit card closing balance
- savings balance (shown as "Savings left")
- deposit notes (who deposited how much this month)

Create a fresh output directory: `/Users/paul/dev/sandbox/outputs/dad-money-report-YYYY-MM/`.

### 2. Convert and clean transactions

Run the `paul-tools` converter into the output directory as `anz.csv`. The credit card payment line, usually `AUTOREPAYMENT - THANK YOU`, must be excluded from report totals.

Watch for mis-signed refund/credit rows. The converter reads every amount as a positive debit, but the raw ANZ export puts refunds and credits in a separate (second) amount column. A row whose amount sits in that credit column is a refund, not spend, and must be excluded before totalling. A reconciliation that is off by exactly one transaction amount (for example a round `$44.00`) is the usual tell. Confirm by checking the raw export column position for that row before deciding.

Keep statement-period rows from the export unless Paul explicitly asks for strict calendar-month filtering. The report uses the statement period, not only the named month.

### 3. Categorise

Each row is spent on `Home`, `Mom`, or `Nicole`. The script maps card `1864` to Mom and `7703` to Nicole, and uses the card holder unless a `home` rule matches.

Home-use heuristics:

- classify council bills, water, and electricity/energy as `Home`
- match utilities on specific retailer/biller names (Origin Energy, AGL, Alinta, Unitywater, Seqwater, Allconnex, Urban Utilities, City Council), not on bare substrings like `WATER`. Gold Coast suburb names such as Biggera Waters, Helensvale, and Pacific Pines appear in ordinary merchant lines and will false-match a loose `WATER`/utility keyword, wrongly pulling chemist and grocery spend into `Home`
- classify home insurance as `Home`
- RACQ can be either home insurance or car insurance; use judgement rather than classifying all RACQ as Home. Home insurance tends to be steadier and monthly, while car insurance or motoring costs vary more; use amount, regularity, card, and prior configs to decide, and pin the decision with `card` and `amount` on the rule
- if unsure after checking prior configs, choose the most likely category and mention it to Paul

### 4. Write the config and render

Write `report.json` in the output directory:

```json
{
  "month": "September 2026",
  "period": "31 Aug to 28 Sep 2026",
  "closing_balance": 4860.45,
  "savings": 402.46,
  "deposits": [{"who": "Nicole", "amount": 200}, {"who": "Paul", "amount": 100}],
  "exclude": [{"match": "AUTOREPAYMENT", "label": "The automatic repayment of last month's bill"}],
  "home": [
    {"match": "GOLD COAST CITY COUN"},
    {"match": "AGL "},
    {"match": "RACQ", "card": "1864", "amount": 337.55}
  ]
}
```

- `period`: the earliest to latest transaction date in the export, unless the statement says otherwise
- `deposits`: omit or leave empty when the journal has no deposit notes; the summary then shows savings only
- `exclude` and `home` rules match on a description substring, optionally narrowed by exact `card` and `amount`; give each `exclude` rule a plain-English `label` (for example "A refund from Coles") because it is printed in the report

Render:

```bash
python3 -I ~/.config/opencode/skills/personal/nested/prepare-dad-money-report/scripts/build_line_images.py \
  <out_dir>/anz.csv <out_dir>/report.json <out_dir>
```

The script prints the excluded rows and the per-category totals, and exits non-zero if the cleaned total does not match `closing_balance`. Stop and investigate a mismatch rather than adjusting the config to force it.

### 5. Verify and report

Before finishing:

- confirm the payment row (and any refunds) appear in the script's `excluded:` line
- confirm the total matched the journal closing balance (the script exits 0)
- Read each PNG and check it is legible, nothing is cut off, and every transaction is present

In the final response, give the absolute path of the output directory and list the images, with the headline numbers (bill, savings, spend breakdown) and any categorisation judgement calls. Do not paste bank account numbers.

## Optional formats

Only when Paul asks: an A4 PDF of the same report, an Excel workbook (`Statement` and `Spend On` sheets, built with the Spreadsheets skill), or an email draft (subject `Family finances for <Month>, <Year>`, recipients copied from the most recent prior thread of that name in Gmail; never send it).
