# PocketSmith API reference

Server: `https://api.pocketsmith.com/v2` (production, OpenAPI 3.0.1, API version 2.0).
Docs index: <https://developers.pocketsmith.com/llms.txt>. Append `.md` to any docs page URL for its markdown source.

## Authentication

| Scheme | Header | Use |
|---|---|---|
| Developer key | `X-Developer-Key: <key>` | Single user, persistent, self-issued. Rotate regularly. |
| OAuth 2.0 | `Authorization: Bearer <token>` | Multi-user apps. |

Errors return `{"error": "message"}` with status 400, 403, 404, 409, or 422.

## Endpoint index

### Users
| Method | Path | Notes |
|---|---|---|
| GET | `/me` | The authorised user. Start here for the user ID. |
| GET | `/users/{id}` | Must be authorised as that user. |
| PUT | `/users/{id}` | Update user settings. |

### Accounts, institutions, transaction accounts
| Method | Path | Notes |
|---|---|---|
| GET | `/users/{id}/accounts` | Accounts with nested `transaction_accounts` and `scenarios`. |
| PUT | `/users/{id}/accounts` | Reorder by sending accounts in display order. |
| POST | `/users/{id}/accounts` | |
| GET/PUT/DELETE | `/accounts/{id}` | Delete can merge scenarios into another account. |
| GET | `/users/{id}/transaction_accounts` | The feed-level accounts that hold transactions. |
| GET/PUT | `/transaction_accounts/{id}` | |
| GET | `/institutions/{id}`, `/users/{id}/institutions` | |
| POST | `/users/{id}/institutions` | |
| PUT/DELETE | `/institutions/{id}` | Delete can merge into another institution. |

### Transactions
| Method | Path | Notes |
|---|---|---|
| GET | `/users/{id}/transactions` | Paginated. Full filter set below. |
| GET | `/accounts/{id}/transactions` | Same filters. |
| GET | `/transaction_accounts/{id}/transactions` | Same filters. |
| GET | `/categories/{id}/transactions` | `{id}` is a comma-separated list of category IDs. |
| GET | `/transactions/{id}` | |
| POST | `/transaction_accounts/{id}/transactions` | Create. 201 on success. |
| PUT | `/transactions/{id}` | Update, including splits. |
| DELETE | `/transactions/{id}` | |

### Categories and rules
| Method | Path | Notes |
|---|---|---|
| GET | `/users/{id}/categories` | Nested tree via `children`. |
| POST | `/users/{id}/categories` | `title` required. |
| GET/PUT | `/categories/{id}` | |
| DELETE | `/categories/{id}` | Deletes its budgets and uncategorises its transactions. |
| GET | `/users/{id}/category_rules` | |
| POST | `/categories/{id}/category_rules` | Returns 200, not 201. |

### Budgeting and analysis
| Method | Path | Required query params |
|---|---|---|
| GET | `/users/{id}/budget` | none (`roll_up` optional) |
| GET | `/users/{id}/budget_summary` | `period`, `interval`, `start_date`, `end_date` |
| GET | `/users/{id}/trend_analysis` | the four above plus `categories`, `scenarios` |
| DELETE | `/users/{id}/forecast_cache` | Forces forecast recalculation. |

### Events (budget events)
| Method | Path | Notes |
|---|---|---|
| GET | `/users/{id}/events` | `start_date` and `end_date` both required. |
| GET | `/scenarios/{id}/events` | |
| POST | `/scenarios/{id}/events` | `category_id`, `date`, `amount`, `repeat_type` required. |
| GET/PUT/DELETE | `/events/{id}` | ID form `<series_id>-<unix_ts>`. Affects the series. |

### Attachments, labels, saved searches, lookups
| Method | Path | Notes |
|---|---|---|
| GET/POST | `/users/{id}/attachments` | |
| GET/PUT/DELETE | `/attachments/{id}` | |
| GET | `/transactions/{id}/attachments` | |
| POST | `/transactions/{id}/attachments` | Assign an existing attachment. |
| DELETE | `/transactions/{tid}/attachments/{aid}` | Unassign only, does not delete. |
| GET | `/users/{id}/labels` | Array of label strings in use. |
| GET | `/users/{id}/saved_searches` | `{id, title, created_at, updated_at}`. |
| GET | `/currencies`, `/currencies/{id}`, `/time-zones` | |

## Transaction list filters

| Param | Type | Notes |
|---|---|---|
| `start_date` | date | Required if `end_date` given. Defaults to the subscription's earliest date. |
| `end_date` | date | Required if `start_date` given. Defaults to today. |
| `updated_since` | ISO 8601 timestamp | e.g. `2026-08-14T09:20:33+13:00`. Best filter for incremental sync. |
| `uncategorised` | integer | `1` to limit to uncategorised. |
| `needs_review` | integer | `1` to limit to the review queue. |
| `type` | enum | `debit` or `credit`. |
| `search` | string | Matches amount, account name, payee, category title, note, labels, ISO date. |
| `page` | integer | 1-based. |
| `per_page` | integer | 10 to 1000, default 30. |

Pagination response headers: `Total`, `Per-Page`, `Link` (RFC 5988, with `first`/`prev`/`next`/`last`).

## Schemas

### Transaction (read)
| Field | Type | Notes |
|---|---|---|
| `id` | integer | |
| `date` | date | When it took place. |
| `payee` | string | Cleaned merchant. |
| `original_payee` | string | Raw text the transaction was created with. |
| `amount` | number | Magnitude; pair with `type`. |
| `amount_in_base_currency` | number | Use this when summing across currencies. |
| `type` | enum | `debit` or `credit`. |
| `status` | enum | `pending` or `posted`. Pending rows are later superseded. |
| `needs_review` | boolean | |
| `is_transfer` | boolean | |
| `category` | Category | Null when uncategorised. |
| `labels` | string[] | Array on read, comma string on write. |
| `note`, `memo`, `cheque_number` | string | |
| `closing_balance` | number | Account balance at this transaction. |
| `upload_source` | string | e.g. `file`. |
| `transaction_account` | TransactionAccount | |
| `created_at`, `updated_at` | timestamp | |

### Create transaction: `POST /transaction_accounts/{id}/transactions`
Required: `payee`, `amount` (signed, negative = debit), `date`.
Optional: `category_id`, `labels` (comma string), `note`, `memo`, `cheque_number`, `is_transfer`, `needs_review`.

### Update transaction: `PUT /transactions/{id}`
All optional: `payee`, `amount` (signed), `date`, `category_id` (empty string uncategorises), `labels` (comma string, replaces set), `note`, `memo`, `cheque_number`, `is_transfer`, `needs_review`, `splits`.

`splits[]`: `amount` required; `payee`, `category_id`, `is_transfer`, `date` inherit from the parent when omitted. The parent must retain the correct remainder (`amount - sum(split amounts)`). Validation is atomic. When splits are sent, the 200 response is `{transaction, split_transactions[]}` instead of a bare transaction.

### Category
| Field | Type | Notes |
|---|---|---|
| `id`, `title`, `colour` | | `colour` is a CSS hex triplet. |
| `parent_id` | integer | Null at top level. |
| `children` | Category[] | Nested tree. |
| `is_transfer` | boolean | Excluded from budget summaries. |
| `is_bill` | boolean | Lump-sum spend, included in bill reminders. |
| `roll_up` | boolean | Budget folds into the parent. |
| `refund_behaviour` | enum/null | `credits_are_refunds`, `debits_are_deductions`, or null. |
| `created_at`, `updated_at` | timestamp | |

`POST /users/{id}/categories` takes the same writable fields; only `title` is required.

### CategoryRule
Read: `{id, payee_matches, category, created_at, updated_at}`.
Create body: `category_id` and `payee_matches` required (send `category_id` even though it is in the path), plus `apply_to_uncategorised` and `apply_to_all` booleans. `apply_to_all` overwrites existing categorisations.

### BudgetAnalysisPackage
```
{ category, is_transfer, expense: BudgetAnalysis, income: BudgetAnalysis }
```

BudgetAnalysis: `start_date`, `end_date`, `currency_code`, `total_actual_amount`, `average_actual_amount`, `total_forecast_amount`, `average_forecast_amount`, `total_over_by`, `total_under_by`, `periods[]`.

Period: `start_date`, `end_date`, `currency_code`, `actual_amount`, `forecast_amount`, `refund_amount`, `current`, `over_budget`, `under_budget`, `over_by`, `under_by`, `percentage_used`.

`refund_amount` tracks credits netted off an always-expense category (or debits off an always-income category), driven by `refund_behaviour`.

### Event
Read: `id` (`<series_id>-<unix_ts>`), `category`, `scenario`, `amount`, `amount_in_base_currency`, `currency_code`, `date`, `colour`, `note`, `repeat_type`, `repeat_interval`, `series_id`, `series_start_id`, `infinite_series`.

Create body (`POST /scenarios/{id}/events`): `category_id`, `date`, `amount` (signed), `repeat_type` (`once`, `daily`, `weekly`, `fortnightly`, `monthly`, `yearly`, `each weekday`) required; `repeat_interval` (default 1) and `note` optional. 409 on conflict, 422 on validation failure.

### Scenario
`id`, `title`, `description`, `type` (`no-interest`, `savings`, `debt`), `interest_rate`, `interest_rate_repeat_id` (0 none, 2 weekly, 3 fortnightly, 4 monthly, 5 yearly, 7 quarterly), `starting_balance(_date)`, `current_balance(_date)`, `closing_balance(_date)`, `safe_balance`, `achieve_date`, `minimum-value`, `maximum-value`.

Scenario IDs come from `GET /users/{id}/accounts` (`primary_scenario.id` and `scenarios[].id`); there is no standalone list-scenarios endpoint.

### TransactionAccount
`id`, `name`, `number`, `type` (`bank`, `credits`, `cash`, `stocks`, `mortgage`, `loans`, `vehicle`, `property`, `insurance`, `other_asset`, `other_liability`), `currency_code`, `current_balance(_date)`, `current_balance_in_base_currency`, `current_balance_exchange_rate`, `safe_balance`, `starting_balance(_date)`, `institution`.

### User (`GET /me`)
`id`, `login`, `name`, `email`, `avatar_url`, `beta_user`, `time_zone`, `week_start_day` (0 Sunday to 6 Saturday), `base_currency_code`, `available_accounts`, `available_budgets`, `forecast_last_updated_at`, `forecast_start_date`, `forecast_end_date`, `last_logged_in_at`, `created_at`, `updated_at`.

## Worked examples

### Monthly spend by category, from raw transactions
```bash
curl -s -G "https://api.pocketsmith.com/v2/users/$UID/transactions" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" \
  -d start_date=2026-08-01 -d end_date=2026-08-31 -d per_page=1000 \
| jq -r '
    map(select(.status != "pending" and (.category.is_transfer | not)))
  | group_by(.category.title // "Uncategorised")
  | map({category: .[0].category.title // "Uncategorised",
         spend: (map(select(.type == "debit") | .amount_in_base_currency // .amount) | add // 0),
         count: length})
  | sort_by(-.spend)[] | [.category, (.spend | . * 100 | round / 100), .count] | @tsv'
```

### Top payees among uncategorised rows (rule candidates)
```bash
curl -s -G "https://api.pocketsmith.com/v2/users/$UID/transactions" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" \
  -d uncategorised=1 -d start_date=2026-08-01 -d end_date=2026-08-31 -d per_page=1000 \
| jq -r 'group_by(.payee) | map({payee: .[0].payee, n: length}) | sort_by(-.n)[]
         | select(.n >= 3) | [.n, .payee] | @tsv'
```

### Budget variance for the month
```bash
curl -s -G "https://api.pocketsmith.com/v2/users/$UID/budget_summary" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" \
  -d period=months -d interval=1 -d start_date=2026-08-01 -d end_date=2026-08-31 \
| jq -r '.[] | select(.expense.total_forecast_amount != 0)
  | [.category.title,
     .expense.total_actual_amount,
     .expense.total_forecast_amount,
     (.expense.total_over_by  // 0),
     (.expense.total_under_by // 0)] | @tsv'
```

### Set a monthly grocery budget of 650 from September
```bash
curl -s -X POST "https://api.pocketsmith.com/v2/scenarios/$SCENARIO_ID/events" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" -H "Content-Type: application/json" \
  -d '{"category_id": 1438154, "date": "2026-09-01", "amount": -650,
       "repeat_type": "monthly", "repeat_interval": 1, "note": "Groceries"}'

curl -s -X DELETE "https://api.pocketsmith.com/v2/users/$UID/forecast_cache" \
  -H "X-Developer-Key: $POCKETSMITH_KEY"
```

### Incremental sync since the last run
```bash
curl -s -G "https://api.pocketsmith.com/v2/users/$UID/transactions" \
  -H "X-Developer-Key: $POCKETSMITH_KEY" \
  -d updated_since="$LAST_SYNC_ISO" -d per_page=1000
```
