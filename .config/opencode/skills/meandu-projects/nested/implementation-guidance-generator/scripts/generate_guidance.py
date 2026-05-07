#!/usr/bin/env python3
"""
Implementation Guidance Generator Script

This script generates implementation guidance documents following specific formatting standards.
It works with Linear issues retrieved via MCP and creates structured guidance with proper file
references and code locations.

Note: This script is now primarily used as a reference. The skill should use Linear MCP tools
directly to retrieve issue data and generate guidance within the Claude Code workflow.
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path


def extract_issue_details(issue_content):
    """Extract key details from issue content."""
    details = {
        'problem': '',
        'expected': '',
        'current': '',
        'files_mentioned': [],
        'functions_mentioned': []
    }

    # Look for common patterns in issue descriptions
    lines = issue_content.split('\n')
    current_section = None

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Identify sections
        if re.match(r'(?i)(problem|issue|bug|error)', line):
            current_section = 'problem'
        elif re.match(r'(?i)(expected|should|desired)', line):
            current_section = 'expected'
        elif re.match(r'(?i)(current|actual|happening)', line):
            current_section = 'current'
        elif current_section and line:
            details[current_section] += line + ' '

    # Extract file paths mentioned
    file_pattern = r'`?([a-zA-Z0-9_\-/\.]+\.(js|ts|jsx|tsx|py|java|cpp|c|h|go|rs|php|rb|swift|kt))`?'
    details['files_mentioned'] = list(set(re.findall(file_pattern, issue_content)))

    # Extract function/method names (more specific pattern)
    func_pattern = r'([a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*)'
    details['functions_mentioned'] = list(set(re.findall(func_pattern, issue_content)))

    return details


def generate_implementation_guidance(issue_data, output_path=None):
    """
    Generate implementation guidance document from Linear issue data.

    Args:
        issue_data: Dictionary containing Linear issue data with keys:
                   - id: Issue identifier (e.g., PROJ-123)
                   - title: Issue title
                   - description: Full issue description
                   - status: Current status
                   - priority: Priority level
                   - url: Linear issue URL
        output_path: Optional directory path for output file
    """
    issue_id = issue_data.get('id', 'UNKNOWN')
    title = issue_data.get('title', 'Untitled Issue')
    description = issue_data.get('description', '')
    status = issue_data.get('status', 'Unknown')
    priority = issue_data.get('priority', 'Unknown')
    url = issue_data.get('url', '')

    # Extract details from issue description
    details = extract_issue_details(description)

    # Generate filename with current date and issue ID
    date_str = datetime.now().strftime('%Y-%m-%d')
    # Clean title for filename
    clean_title = re.sub(r'[^\w\s-]', '', title).strip()[:40]
    filename = f"{date_str} {issue_id} {clean_title}.md"

    if output_path:
        output_file = Path(output_path) / filename
    else:
        output_file = Path(filename)

    # Generate the implementation guidance content
    content = f"""# {issue_id}: {title}

**Linear Issue:** [{issue_id}]({url})
**Status:** {status} | **Priority:** {priority}

## Issue Description

{description}

## Implementation guidance

"""

    # Add primary implementation approach
    if details['files_mentioned']:
        primary_file = details['files_mentioned'][0][0]
        content += f"* The primary issue is likely in `{primary_file}`. "
        content += "Review the code to identify the specific function or method causing the problem.\n\n"
    else:
        content += "* Analyze the codebase to locate the files responsible for the reported issue.\n\n"

    # Add file references
    if details['files_mentioned']:
        content += "## Files to investigate\n\n"
        for file_info, ext in details['files_mentioned']:
            content += f"* `{file_info}` - Check for the problematic implementation\n"
        content += "\n"

    # Add function references
    if details['functions_mentioned']:
        content += "## Functions/Methods to review\n\n"
        for func_name in details['functions_mentioned']:
            content += f"* `{func_name}` - Verify implementation and logic\n"
        content += "\n"

    # Add next steps
    content += """## Next Steps

1. Locate the problematic code in the identified files
2. Analyze the current implementation vs expected behavior
3. Implement the fix following the project's coding standards
4. Test the changes to ensure the issue is resolved
5. Update any related documentation or tests

"""

    # Write the file
    with open(output_file, 'w') as f:
        f.write(content)

    return output_file


def main():
    """Main function to run the script."""
    parser = argparse.ArgumentParser(
        description='Generate implementation guidance document from Linear issue data'
    )
    parser.add_argument(
        'issue_data_file',
        help='Path to JSON file containing Linear issue data'
    )
    parser.add_argument(
        '--output', '-o',
        help='Output directory for the generated document'
    )

    args = parser.parse_args()

    # Read issue data from JSON file
    try:
        with open(args.issue_data_file, 'r') as f:
            issue_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {args.issue_data_file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading issue data: {e}")
        sys.exit(1)

    # Validate required fields
    required_fields = ['id', 'title', 'description']
    missing_fields = [field for field in required_fields if field not in issue_data]
    if missing_fields:
        print(f"Error: Missing required fields in issue data: {', '.join(missing_fields)}")
        sys.exit(1)

    # Generate guidance
    try:
        output_file = generate_implementation_guidance(issue_data, args.output)
        print(f"Generated implementation guidance: {output_file}")
    except Exception as e:
        print(f"Error generating guidance: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()