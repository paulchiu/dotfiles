---
description: Check if branch changes conform to AGENTS.md standards
---

Review the changes in this branch compared to main and verify they conform to the standards defined in AGENTS.md.

## Process

1. First, identify the changes:
   - Run `git diff main...HEAD` to see all changes
   - Run `git log main..HEAD --oneline` to understand the commit history
   - Identify the files changed and their scope

2. Check if AGENTS.md exists in the project root. If not, report that no AGENTS.md file was found.

3. Read AGENTS.md and extract all guidelines, standards, and rules documented there.

4. Compare the branch changes against AGENTS.md requirements:
   - Check code style and formatting rules
   - Verify architectural patterns are followed
   - Validate naming conventions
   - Ensure testing requirements are met
   - Confirm documentation standards
   - Check any project-specific rules

5. For any violations found, report:
   - The specific AGENTS.md rule that was violated
   - The file and line number where the violation occurs
   - A clear explanation of what needs to be fixed

## Output Format

For each issue found, prefix with:

- `conform:` — change conforms to AGENTS.md
- `violation:` — change violates AGENTS.md (must be fixed)
- `question:` — unclear if change conforms, needs clarification

End with a summary:
1. **Conformity Status**: Pass / Fail / Partial
2. **Violations Count**: Number of issues found
3. **Action Items**: List of required fixes
