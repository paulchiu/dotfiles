#!/usr/bin/env node

// Moved: release-reporter is now a Claude Code plugin.
//   repo:   ~/dev/claude-plugins/plugins/release-reporter
//   skill:  release-reporter (drives the CLI + Slack posting)
//
// It no longer uses BUILDKITE_API_TOKEN; it authenticates via the `bk` CLI
// (run `bk auth login` if needed). This shim forwards to the plugin CLI so
// existing invocations keep working.

const { spawnSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const CLI = path.join(
  process.env.HOME || require("os").homedir(),
  "dev/claude-plugins/plugins/release-reporter/bin/release-reporter.js"
);

if (!fs.existsSync(CLI)) {
  console.error(
    `release-reporter has moved to the claude-plugins repo but the CLI was not found at:\n  ${CLI}\nClone/locate the repo, then run that script directly.`
  );
  process.exit(1);
}

// Default to `run` so bare `release-reporter.js` behaves like the old script.
const args = process.argv.slice(2);
const forwarded = args.length > 0 ? args : ["run"];

const result = spawnSync("node", [CLI, ...forwarded], { stdio: "inherit" });
if (result.error) {
  console.error(`Failed to launch the release-reporter CLI: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status === null ? 1 : result.status);
