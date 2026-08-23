---
name: pocketsmith
description: "Work with the PocketSmith API: pull transactions, categorise them (rules, splits, labels), read budget and trend reports, and set budgets via scenario events. Use when asked about PocketSmith, household budget data, savings rate, spending by category or payee, uncategorised transactions, or the budget vs actual variance for a month."
---

# PocketSmith API

Base URL: `https://api.pocketsmith.com/v2`. JSON in, JSON out.

## 1. Authenticate and find the user ID

Every path below is scoped by user ID, so the first call in any session is `/me`.

```bash
export POCKETSMITH_KEY="..."   # my.pocketsmith.com > Settings > Security & integrations > Developer keys

curl -s https://api.pocketsmith.com/v2/me \
  -H "X-Developer-Key: $POCKETSMITH_KEY" | jq '{id, login, base_currency_code, time_zone, week_start_day}'
```

`id` is the `{user_id}` in every `/users/{id}/...` path. Also note `base_currency_code`: any account in another currency reports both `amount` and `amount_in_base_currency`, and only the base-currency figure is safe to sum across accounts.

Developer keys are single-user and persistent. Rotate them regularly and never commit one. For anything multi-user, use OAuth 2.0 instead (`Authorization: Bearer <token>`).

Prefer a `$POCKETSMITH_KEY` env var read from the shell over writing the key into a script.

**Alternative to raw HTTP:** PocketSmith ships a hosted MCP server, which is usually the faster route for interactive analysis:

```bash
claude mcp add pocketsmith          --transport http https://mcp.pocketsmith.com/mcp            # full access, 57 tools
claude mcp add pocketsmith-readonly --transport http https://mcp-readonly.pocketsmith.com/mcp   # read-only, 38 tools
```

It authenticates via OAuth on first use and exposes composite tools (`financial_health_snapshot`, `month_end_review`, `spending_comparison`, `find_recurring_expenses`) that the REST API makes you assemble by hand. Use the REST API when you need scripted, repeatable, or bulk work; use MCP for ad hoc questions.

## 2. Pagination (applies to transactions above all)

Default page size is **30**, max is **1000**. Always set `per_page` on bulk pulls or you will silently analyse the first 30 rows.

- Request pages with `?page=N&per_page=1000`.
- Response headers: `Total` (record count), `Per-Page`, and an RFC 5988 `Link` header with `rel="next"`/`"last"`.
- Follow `Link: rel="next"` rather than incrementing blindly; the last page is short.

```bash
# Fetch every page of a date range into one JSON array
fetch_all() {  # $1 = url (no page params)
  page=1
  while :; do
    body=$(curl -s "$1&page=$page&per_page=1000" -H "X-Developer-Key: $POCKETSMITH_KEY")
    [ "$(echo "$body" | jq 'length')" -eq 0 ] && break
    echo "$body" | jq -c '.[]'
    page=$((page + 1))
  done | jq -s '.'
}
```

## 3. Getting transactions

```bash
UID=42
curl -s "https://api.pocketsmith.com/v2/users/$UID/transactions?start_date=2026-08-01&end_date=2026-08-31&per_page=1000" \
  -H "X-Developer-Key: $POCKETSMITH_KEY"
```

Filters on `GET /users/{id}/transactions`:

| Param                    | Notes                                                                                                                                   |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| `start_date`, `end_date` | ISO dates. **Pass both or neither.** One alone is a 400. Omitted, the range defaults to the subscription's earliest date through today. |
| `updated_since`          | ISO 8601 timestamp. The right filter for incremental syncs, since it catches back-dated edits a date range would miss.                  |
| `uncategorised`          | `1` (an integer, not `true`) to get only uncategorised rows.                                                                            |
| `needs_review`           | `1` for the review queue.                                                                                                               |
| `type`                   | `debit` or `credit`.                                                                                                                    |
| `search`                 | Matches amount, account name, payee, category title, note, labels, and ISO date.                                                        |
| `page`                   | See pagination above.                                                                                                                   |

Same filters apply to the narrower collections:

- `GET /accounts/{id}/transactions`
- `GET /transaction_accounts/{id}/transactions`
- `GET /categories/{id}/transactions` where `{id}` is a **comma-separated list** of category IDs
- `GET /transactions/{id}` for one

Reading a transaction: `amount` pairs with `type` (`debit`/`credit`), `payee` is the cleaned merchant while `original_payee` is what the bank sent, `category` is a nested object (null when uncategorised), `labels` is an array of strings, `closing_balance` is the account balance at that row, and `status` is `pending` or `posted`.

**Filter out `status: "pending"` before reporting.** Pending rows are temporary and are later superseded by their posted counterparts, so including both double-counts.

## 4. Classifying transactions

The category tree, one-off assignment, and rules are three separate mechanisms. Use all three.

### Category tree

`GET /users/{id}/categories` returns top-level categories with nested `children`, so flatten before matching:

```bash
curl -s "https://api.pocketsmith.com/v2/users/$UID/categories" -H "X-Developer-Key: $POCKETSMITH_KEY" \
  | jq -r '.. | objects | select(has("title") and has("colour")) | "\(.id)\t\(.title)\t\(.parent_id // "-")"'
```

Category flags that change how reports read:

- `is_transfer`: excluded from budget summaries. Set it on internal movements so they do not inflate income and expenses.
- `roll_up`: child budgets fold into the parent.
- `is_bill`: lump-sum spend rather than spread across the period, and included in bill reminders.
- `refund_behaviour`: `credits_are_refunds` (an expense category, so credits net off) or `debits_are_deductions` (an income category). Leaving this null is why a single refund can make a category look like income.

Create with `POST /users/{id}/categories` (`title` required; `colour`, `parent_id`, `is_transfer`, `is_bill`, `roll_up`, `refund_behaviour` optional).

### Assign one transaction

```bash
curl -s -X PUT "https://api.pocketsmith.com/v2/transactions/$TXN_ID" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" -H "Content-Type: application/json" \
  -d '{"category_id": 1438154, "needs_review": false, "labels": "groceries,weekly"}'
```

- `category_id: ""` (empty string) uncategorises.
- `labels` is a **comma-separated string on write** and an array on read, and it **replaces** the whole set. Read the current labels and re-send them plus the new one to add.
- Clear `needs_review` as you go so the queue drains.

### Category rules (do this for anything recurring)

```bash
curl -s -X POST "https://api.pocketsmith.com/v2/categories/$CATEGORY_ID/category_rules" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" -H "Content-Type: application/json" \
  -d '{"category_id": '"$CATEGORY_ID"', "payee_matches": "Countdown", "apply_to_uncategorised": true}'
```

Quirks worth knowing: the category is in the path but the documented body still requires `category_id`, so send both. `apply_to_uncategorised` backfills only untouched rows; `apply_to_all` overwrites existing categorisations, so treat it as destructive and confirm before using it. Rules match on payee text only, not amount or account. List existing rules first with `GET /users/{id}/category_rules` to avoid duplicates.

### Bulk categorisation workflow

1. `GET /users/{id}/transactions?uncategorised=1&start_date=...&end_date=...&per_page=1000`.
2. Group by `payee` and count. Anything appearing 3+ times is rule material.
3. For each repeat payee, find or create the category, then create a rule with `apply_to_uncategorised: true`.
4. Re-fetch the uncategorised list, then `PUT` the remaining one-offs individually.
5. Split mixed-purpose rows (see below) rather than forcing them into one category.

### Splits

`PUT /transactions/{id}` accepts a `splits` array. The parent keeps the remainder, so `parent.amount - sum(split amounts)` must be correct or the whole call is rejected. Splitting is atomic.

```json
{
  "splits": [
    { "amount": -30.0, "category_id": 101, "payee": "Restaurant ABC" },
    { "amount": -19.95, "category_id": 102, "payee": "Transport" }
  ]
}
```

## 5. Reporting

Three endpoints, all returning the same `BudgetAnalysisPackage` shape.

| Endpoint                         | Use for                                                                                                                                                                                |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /users/{id}/budget`         | Current budget, one package per category. Optional `roll_up=true` folds children into parents (children still appear separately). No date params: it reports the budget as configured. |
| `GET /users/{id}/budget_summary` | Actual vs budget over a date range. **All of `period`, `interval`, `start_date`, `end_date` are required.** Excludes transfer categories.                                              |
| `GET /users/{id}/trend_analysis` | Same analysis for a chosen set of categories and scenarios. Requires the four above plus `categories` and `scenarios` (comma-separated IDs).                                           |

`period` is `weeks`, `months`, or `years` (`event` exists but rarely aligns). `interval` multiplies it, so `period=weeks&interval=2` is fortnightly. Start and end dates are **bumped outward to whole periods**, so a 2026-08-05 to 2026-08-20 request with `period=months` returns the whole of August.

```bash
curl -s -G "https://api.pocketsmith.com/v2/users/$UID/budget_summary" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" \
  -d period=months -d interval=1 -d start_date=2026-08-01 -d end_date=2026-08-31
```

Response shape per package: `category`, `is_transfer`, and separate `expense` and `income` analyses. Each analysis carries `total_actual_amount`, `total_forecast_amount`, `average_*`, `total_over_by`, `total_under_by`, and a `periods[]` array. Each period has `actual_amount`, `forecast_amount`, `refund_amount`, `over_by`, `under_by`, `percentage_used`, plus `current`, `over_budget`, and `under_budget` booleans.

Variance table for a month:

```bash
curl -s -G ".../users/$UID/budget_summary" ... \
  | jq -r '.[] | select(.expense.total_forecast_amount != 0)
    | [.category.title, .expense.total_actual_amount, .expense.total_forecast_amount,
       (.expense.periods[0].percentage_used // 0)] | @tsv'
```

`percentage_used` mid-month is not a pace signal on its own. Compare it against elapsed days in the period before calling anything over budget.

**These endpoints are category-level only.** Payee-level breakdowns, top-merchant lists, recurring-charge detection, and savings rate all require pulling raw transactions and aggregating locally. Sum `amount_in_base_currency` when accounts span currencies, drop `is_transfer` categories and `status: "pending"` rows first.

## 6. Setting budgets

There is no "set the budget for this category" endpoint. A PocketSmith budget is the sum of **budget events**: repeating forecast events attached to a category inside a scenario.

Get a scenario ID from the account the spending sits in:

```bash
curl -s "https://api.pocketsmith.com/v2/users/$UID/accounts" -H "X-Developer-Key: $POCKETSMITH_KEY" \
  | jq -r '.[] | "\(.title)\tprimary_scenario=\(.primary_scenario.id)"'
```

Then create the event:

```bash
curl -s -X POST "https://api.pocketsmith.com/v2/scenarios/$SCENARIO_ID/events" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" -H "Content-Type: application/json" \
  -d '{"category_id": 1438154, "date": "2026-09-01", "amount": -650,
       "repeat_type": "monthly", "repeat_interval": 1, "note": "Groceries budget"}'
```

- `amount` is **signed**: negative for an expense budget, positive for income.
- `repeat_type`: `once`, `daily`, `weekly`, `fortnightly`, `monthly`, `yearly`, `each weekday`. `repeat_interval` defaults to 1, so `weekly` with interval 2 is fortnightly.
- Required: `category_id`, `date`, `amount`, `repeat_type`.

Reading and editing: `GET /users/{id}/events?start_date=...&end_date=...` (both required) returns occurrences, not series. Event IDs look like `42-1601942400`, which is `series_id` plus the occurrence timestamp, and `series_start_id` and `infinite_series` identify the series. `PUT`/`DELETE /events/{id}` affects the series the occurrence belongs to, so read the event back before deleting to confirm you are not wiping an infinite series.

To change a budget amount, update the existing event rather than adding a second one, or the two will sum. After bulk event changes, call `DELETE /users/{id}/forecast_cache` to force a recalculation.

## 7. Gotchas

- `start_date` and `end_date` on transactions must be sent as a pair.
- `uncategorised` and `needs_review` filters take `1`, not `true`.
- Amounts are **signed on write** (negative is a debit) but read back as `amount` plus a `type` field.
- `labels` writes as a comma-separated string and replaces the entire set.
- Default page size 30. Set `per_page` on every bulk read.
- Exclude `status: "pending"` and `is_transfer` categories before totalling anything.
- `apply_to_all` on a category rule overwrites existing categorisations. Confirm first.
- Budget and trend endpoints round the date range out to whole periods.
- Errors return `{"error": "..."}`; expect 400 (bad params), 403 (bad or missing key), 404, 409, 422 (validation).

## Reference

`references/api-reference.md` has the full endpoint index, request and response field tables, and worked examples.
