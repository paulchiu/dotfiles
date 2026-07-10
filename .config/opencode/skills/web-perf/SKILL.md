---
name: web-perf
description: Audit web performance via Chrome DevTools MCP — Core Web Vitals (LCP/INP/CLS), render-blocking resources, network chains, layout shifts, caching. Use to audit/profile/optimize page load, Lighthouse scores, or site speed.
---

# Web Performance Audit

Metric thresholds and tooling APIs drift. When citing specific numbers or recommendations, prefer retrieval over pre-training:

- Core Web Vitals thresholds/definitions: `https://web.dev/articles/vitals`
- DevTools trace analysis: `https://developer.chrome.com/docs/devtools/performance`
- Lighthouse score weights: `https://developer.chrome.com/docs/lighthouse/performance/performance-scoring`

## FIRST: Verify MCP Tools

Try `navigate_page` or `performance_start_trace`. If unavailable, STOP: the chrome-devtools MCP server isn't configured. Ask the user to add:

```json
"chrome-devtools": {
  "type": "local",
  "command": ["npx", "-y", "chrome-devtools-mcp@latest"]
}
```

## Guidelines

- Verify claims (network requests, DOM, codebase) then state findings definitively. Confirm something is unused before recommending removal.
- Quantify impact using the insights' estimated savings. If a flagged issue has 0ms estimated impact, note it but don't recommend action.
- Be specific: "compress hero.png (450KB) to WebP", not "optimize images".
- Prioritize ruthlessly. A site with 200ms LCP and 0 CLS is already excellent, say so.

## Workflow

Copy this checklist to track progress:

```
Audit Progress:
- [ ] Phase 1: Performance trace (navigate + record)
- [ ] Phase 2: Core Web Vitals analysis (includes CLS culprits)
- [ ] Phase 3: Network analysis
- [ ] Phase 4: Accessibility snapshot
- [ ] Phase 5: Codebase analysis (skip if third-party site)
```

### Phase 1: Performance Trace

```
navigate_page(url: "<target-url>")
performance_start_trace(autoStop: true, reload: true)
```

`reload: true` captures cold-load metrics. If the trace comes back empty, confirm the page actually loaded first.

### Phase 2: Core Web Vitals Analysis

Extract metrics with `performance_analyze_insight(insightSetId: "<id-from-trace>", insightName: "...")`.

Insight names vary across Chrome DevTools versions. If a name doesn't work, inspect the trace response to list the available insights. Common names:

| Insight Name | What to Look For |
|--------------|------------------|
| `LCPBreakdown` | LCP split into TTFB, resource load, render delay |
| `CLSCulprits` | Shifting elements (unsized images, injected content, font swaps) |
| `RenderBlocking` | CSS/JS blocking first paint |
| `DocumentLatency` | Server response time issues |
| `NetworkRequestsDepGraph` | Request chains delaying critical resources |

**Thresholds (good / needs-improvement / poor):**
- TTFB: < 800ms / < 1.8s / > 1.8s
- FCP: < 1.8s / < 3s / > 3s
- LCP: < 2.5s / < 4s / > 4s
- INP: < 200ms / < 500ms / > 500ms
- TBT: < 200ms / < 600ms / > 600ms
- CLS: < 0.1 / < 0.25 / > 0.25
- Speed Index: < 3.4s / < 5.8s / > 5.8s

### Phase 3: Network Analysis

```
list_network_requests(resourceTypes: ["Script", "Stylesheet", "Document", "Font", "Image"])
get_network_request(reqid: <id>)   # for details
```

Look for: render-blocking resources, late-discovered dependency chains (CSS imports, JS-loaded fonts), missing preloads for critical resources, weak/missing caching headers, oversized or uncompressed payloads.

**Unused-preconnect gotcha:** if a preconnect is flagged unused, check whether ANY requests went to that origin. Zero requests means definitively unused, recommend removal. If requests exist but loaded late, the preconnect may still be valuable.

### Phase 4: Accessibility Snapshot

```
take_snapshot(verbose: true)
```

Flag high-level gaps: missing/duplicate ARIA IDs, contrast below WCAG AA (4.5:1 normal text, 3:1 large), focus traps or missing focus indicators, interactive elements without accessible names.

### Phase 5: Codebase Analysis

**Skip if auditing a third-party site without codebase access.**

Detect the framework/bundler from config files and `package.json`, then check the usual suspects:

- **Tree-shaking / dead code**: Webpack `mode: 'production'` + `sideEffects`; barrel files; wholesale imports of lodash/moment
- **Unused JS/CSS**: CSS extraction strategy, PurgeCSS/Tailwind `content` config, dynamic vs eager imports
- **Polyfills**: `@babel/preset-env` targets and `useBuiltIns`, `core-js` imports, overly broad `browserslist`
- **Compression/minification**: terser/esbuild/swc, gzip/brotli in build or server config, source maps leaking into production bundles

## Output Format

1. **Core Web Vitals Summary**: table with metric, value, rating (good/needs-improvement/poor)
2. **Top Issues**: prioritized, with estimated impact (high/medium/low)
3. **Recommendations**: specific fixes with code snippets or config changes
4. **Codebase Findings**: framework/bundler detected, optimization opportunities (omit if no codebase access)
