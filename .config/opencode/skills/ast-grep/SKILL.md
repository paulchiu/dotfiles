---
model: sonnet
name: ast-grep
description: "Write and test ast-grep rules for structural code search using AST patterns. Use when asked to find code patterns, language constructs, or structural matches that text search or grep cannot express (e.g. \"find async functions without error handling\", \"find calls with a specific argument shape\", \"write an ast-grep rule\")."
---

# ast-grep Code Search

Translate natural language queries into ast-grep rules. ast-grep matches code by AST structure rather than text, so it can express queries like "async functions that lack try-catch" that grep cannot.

## When to Use

- Structural matching (e.g., "find all async functions that don't have error handling")
- Locating specific language constructs (e.g., "find all calls with specific parameters")
- Any search that depends on code structure rather than text

## Workflow

### 1. Understand the query

Pin down: the exact pattern or structure, the language, edge cases or variations, and what to exclude. Ask if ambiguous.

### 2. Create example code

Write a minimal snippet that should match, and save it to a temp file. You will validate the rule against this before touching the real codebase.

```javascript
// test_example.js
async function example() {
  const result = await fetchData();
  return result;
}
```

### 3. Write the rule

Start with the simplest rule that could work, then add complexity only as needed:

1. Try a `pattern` first (direct code matching, e.g. `console.log($ARG)`)
2. If that fails, match the node type with `kind`
3. Add relational rules (`has`, `inside`) for context ("function containing await")
4. Combine with composite rules (`all`, `any`, `not`) for logic ("has await but no try-catch")

**Always add `stopBy: end` to relational rules** (`inside`, `has`). Without it, the search stops at the first non-matching neighbor instead of traversing the whole subtree. This is the single most common cause of missed matches.

```yaml
# test_rule.yml
id: async-with-await
language: javascript
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end
```

See `references/rule_reference.md` for the full rule syntax: atomic rules (`pattern`, `kind`, `regex`, `nthChild`, `range`), relational rules, composite rules, and metavariable forms (`$VAR`, `$$VAR`, `$$$MULTI`, `$_NONCAPTURING`).

### 4. Test the rule against the example

**Option A: inline rule via stdin (quick iterations)**

```bash
echo "async function test() { await fetch(); }" | ast-grep scan --inline-rules "id: test
language: javascript
rule:
  kind: function_declaration
  has:
    pattern: await \$EXPR
    stopBy: end" --stdin
```

**Option B: rule file (recommended for complex rules)**

```bash
ast-grep scan --rule test_rule.yml test_example.js
```

Add `--json` to either for structured output.

**If nothing matches, debug in this order:**

1. Simplify: strip sub-rules until something matches, then re-add one at a time
2. Confirm every relational rule has `stopBy: end`
3. Dump the AST to see the real structure and node kinds:

```bash
# Structure of the target code (all nodes, incl. punctuation)
ast-grep run --pattern 'async function example() { await fetch(); }' \
  --lang javascript --debug-query=cst

# How ast-grep interprets your pattern (checks metavariable detection)
ast-grep run --pattern 'class $NAME { $$$BODY }' \
  --lang javascript --debug-query=pattern
```

Formats: `cst` (all nodes including punctuation), `ast` (named nodes only), `pattern` (pattern interpretation).

4. Verify `kind` values against the dumped tree; kinds come from the language's Tree-sitter grammar and vary by language
5. Check metavariables: a metavariable must be the entire text of its AST node (`obj.on$EVENT` and `"Hello $WORLD"` do not work)

### 5. Search the codebase

Only after the rule matches the example correctly.

```bash
# Simple single-node pattern: use run
ast-grep run --pattern 'console.log($ARG)' --lang javascript /path/to/project

# Complex rule (relational/composite): use scan
ast-grep scan --rule my_rule.yml /path/to/project

# Or scan with the inline rule, no file needed
ast-grep scan --inline-rules "id: my-rule
language: javascript
rule:
  kind: function_declaration
  has:
    pattern: await \$EXPR
    stopBy: end" /path/to/project
```

**run vs scan:** `run` takes a bare pattern, good for quick single-node matches. `scan` takes a full YAML rule, required for relational rules (`inside`, `has`, `precedes`, `follows`) and composite logic (`all`, `any`, `not`). Add `--json` to either for programmatic use.

## Shell Escaping for Inline Rules

The shell interprets `$` as a variable, so in double-quoted `--inline-rules` strings escape metavariables as `\$VAR`, or wrap the whole rule in single quotes:

```bash
# Escaped $ inside double quotes
ast-grep scan --inline-rules "id: log-call
language: javascript
rule:
  pattern: console.log(\$ARG)" .

# Or single quotes, no escaping needed
ast-grep scan --inline-rules 'id: log-call
language: javascript
rule:
  pattern: console.log($ARG)' .
```

Inline rules still require `id` and `language` keys, same as rule files.

## Common Recipes

Find async functions that use await:

```yaml
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
```

Find console.log inside class methods:

```yaml
rule:
  pattern: console.log($$$)
  inside:
    kind: method_definition
    stopBy: end
```

Find async functions without try-catch:

```yaml
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          pattern: try { $$$ } catch ($E) { $$$ }
          stopBy: end
```

## Resources

- `references/rule_reference.md`: full ast-grep rule documentation (atomic, relational, and composite rules, `stopBy`/`field` options, metavariables, troubleshooting). Load it when you need syntax detail beyond this file.
