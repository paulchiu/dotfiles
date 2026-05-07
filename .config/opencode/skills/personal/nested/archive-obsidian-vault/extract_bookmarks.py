#!/usr/bin/env python3
"""
Script to extract bookmarks from markdown journal files and create a bookmarks file.
- Processes files with YYYY-MM-DD.md format
- Extracts bookmark links in markdown format
- Groups bookmarks by month
- Removes bookmarks from original files
- Deletes empty files after bookmark removal
- Supports --dry-run mode to preview changes without modifying files
"""

import os
import re
import argparse
import signal
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    print("\n\nOperation cancelled by user.")
    sys.exit(0)


def is_journal_file(filename):
    """Check if filename matches YYYY-MM-DD.md pattern"""
    pattern = r'^\d{4}-\d{2}-\d{2}\.md$'
    return bool(re.match(pattern, filename))


def extract_date_from_filename(filename):
    """Extract date from YYYY-MM-DD.md filename"""
    match = re.match(r'^(\d{4})-(\d{2})-(\d{2})\.md$', filename)
    if match:
        year, month, day = match.groups()
        return datetime(int(year), int(month), int(day))
    return None


def extract_bookmarks_from_content(content):
    """Extract bookmark links from markdown content"""
    bookmarks = []
    remaining_lines = []
    
    lines = content.split('\n')
    
    for line in lines:
        line_stripped = line.strip()
        
        # Check for markdown links: [text](url) or [**text**](url)
        markdown_link_pattern = r'\[([^\]]+)\]\(([^)]+)\)'
        
        # Check for plain URLs (http/https)
        url_pattern = r'https?://[^\s]+'
        
        if re.search(markdown_link_pattern, line_stripped):
            bookmarks.append(line_stripped)
        elif re.search(url_pattern, line_stripped):
            # Convert plain URL to markdown format
            url_match = re.search(url_pattern, line_stripped)
            if url_match:
                url = url_match.group()
                # Use the URL as both the text and link
                markdown_link = f"[{url}]({url})"
                bookmarks.append(markdown_link)
        else:
            remaining_lines.append(line)
    
    return bookmarks, '\n'.join(remaining_lines)


def get_month_name(date_obj):
    """Get month name from datetime object"""
    return date_obj.strftime('%B')


def show_diff(filename, original_content, new_content, verbose=False):
    """Show a colorized mock diff of changes"""
    if not verbose:
        return
        
    print(f"\n{Colors.BOLD}--- {filename} (original){Colors.RESET}")
    print(f"{Colors.BOLD}+++ {filename} (after changes){Colors.RESET}")
    
    original_lines = original_content.split('\n')
    new_lines = new_content.split('\n')
    
    # Simple diff - show removed lines with - and remaining lines with context
    for i, line in enumerate(original_lines):
        if line not in new_lines:
            print(f"{Colors.RED}-{i+1:3}: {line}{Colors.RESET}")
    
    if new_content.strip():
        print(f"{Colors.CYAN}Remaining content:{Colors.RESET}")
        for i, line in enumerate(new_lines):
            if line.strip():  # Only show non-empty lines
                print(f" {i+1:3}: {line}")
    else:
        print(f"{Colors.YELLOW}(file would be empty){Colors.RESET}")


def process_journal_files(journal_dir, month_prefix=None, dry_run=False, verbose=False):
    """Process all journal files and extract bookmarks"""
    journal_path = Path(journal_dir)
    bookmarks_by_month = defaultdict(list)
    files_to_delete = []
    
    for file_path in journal_path.glob('*.md'):
        filename = file_path.name
        
        if not is_journal_file(filename):
            continue
            
        date_obj = extract_date_from_filename(filename)
        if not date_obj:
            continue
            
        # Filter by month prefix if specified
        if month_prefix:
            file_month_prefix = date_obj.strftime('%Y-%m')
            if file_month_prefix != month_prefix:
                continue
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue
            
        bookmarks, remaining_content = extract_bookmarks_from_content(content)
        
        if bookmarks:
            month_key = date_obj.strftime('%Y-%m')
            for bookmark in bookmarks:
                date_str = date_obj.strftime('%Y-%m-%d')
                bookmarks_by_month[month_key].append(f"- {date_str}: {bookmark}")
        
        # Update file with remaining content or mark for deletion
        remaining_content = remaining_content.strip()
        if remaining_content:
            if dry_run:
                print(f"[DRY RUN] Would update {filename} (remove bookmarks)")
                show_diff(filename, content, remaining_content, verbose)
            else:
                if verbose:
                    show_diff(filename, content, remaining_content, True)
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(remaining_content)
                    print(f"Updated {filename} (removed bookmarks)")
                except Exception as e:
                    print(f"Error updating {filename}: {e}")
        else:
            files_to_delete.append(file_path)
            if verbose and (dry_run or not dry_run):
                print(f"\n{Colors.BOLD}{filename} would be deleted (contains only bookmarks):{Colors.RESET}")
                for i, line in enumerate(content.split('\n')):
                    if line.strip():
                        print(f"{Colors.RED}-{i+1:3}: {line}{Colors.RESET}")
    
    # Delete empty files
    for file_path in files_to_delete:
        if dry_run:
            print(f"[DRY RUN] Would delete empty file: {file_path.name}")
        else:
            try:
                file_path.unlink()
                print(f"Deleted empty file: {file_path.name}")
            except Exception as e:
                print(f"Error deleting {file_path.name}: {e}")
    
    return bookmarks_by_month


def create_bookmarks_files(bookmarks_by_month, dry_run=False, verbose=False):
    """Create separate bookmarks files for each month"""
    created_files = []
    
    for month_key in sorted(bookmarks_by_month.keys()):
        year, month = month_key.split('-')
        date_obj = datetime(int(year), int(month), 1)
        month_name = date_obj.strftime('%B')
        output_file = f"{month_key} Links.md"
        
        # Sort bookmarks by date within each month
        month_bookmarks = bookmarks_by_month[month_key]
        month_bookmarks.sort(key=lambda x: x.split(':')[0])
        
        file_content = f"# {month_name}\n" + "\n".join(month_bookmarks) + "\n"
        
        if dry_run:
            print(f"[DRY RUN] Would create {output_file}")
            if verbose:
                print(f"\n{Colors.BOLD}Content of {output_file}:{Colors.RESET}")
                for i, line in enumerate(file_content.split('\n')):
                    if line.strip():
                        print(f"{Colors.GREEN}+{i+1:3}: {line}{Colors.RESET}")
            created_files.append(output_file)
        else:
            if verbose:
                print(f"\n{Colors.BOLD}Creating {output_file}:{Colors.RESET}")
                for i, line in enumerate(file_content.split('\n')):
                    if line.strip():
                        print(f"{Colors.GREEN}+{i+1:3}: {line}{Colors.RESET}")
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(file_content)
            
            created_files.append(output_file)
            print(f"Created {output_file}")
    
    return created_files


def main():
    """Main function"""
    # Set up signal handler for graceful exit
    signal.signal(signal.SIGINT, signal_handler)
    
    parser = argparse.ArgumentParser(
        description="Extract bookmarks from markdown journal files and create monthly bookmark files.",
        epilog="""
Examples:
  %(prog)s --dry-run . 2025-07          # Dry run for July 2025 in current directory
  %(prog)s Journal 2025-08              # Process August 2025 files in Journal directory
  %(prog)s --dry-run --verbose          # Interactive mode with dry run and detailed diff output
  %(prog)s -v . 2025-07                 # Verbose mode showing diffs of changes
  
The script processes files named YYYY-MM-DD.md and extracts:
- Markdown links: [text](url)
- Plain URLs: https://example.com
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("journal_dir", nargs='?',
                       help="Directory containing journal files (e.g., '.', 'Journal', '/path/to/files')")
    parser.add_argument("month_prefix", nargs='?',
                       help="Month prefix in YYYY-MM format (e.g., 2025-07)")
    parser.add_argument("--dry-run", action="store_true", 
                       help="Preview changes without modifying files - shows what would be done")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Show detailed changes including mock diff of file modifications")
    
    args = parser.parse_args()
    
    # Get journal directory from user if not provided as argument
    if not args.journal_dir:
        try:
            prompt = "[DRY RUN] Enter journal directory path: " if args.dry_run else "Enter journal directory path: "
            args.journal_dir = input(prompt).strip()
        except KeyboardInterrupt:
            print("\n\nOperation cancelled by user.")
            sys.exit(0)
    
    # Get month prefix from user if not provided as argument
    if not args.month_prefix:
        try:
            prompt = "[DRY RUN] Enter month prefix (YYYY-MM): " if args.dry_run else "Enter month prefix (YYYY-MM): "
            args.month_prefix = input(prompt).strip()
        except KeyboardInterrupt:
            print("\n\nOperation cancelled by user.")
            sys.exit(0)
    
    # Validate month prefix format
    if not re.match(r'^\d{4}-\d{2}$', args.month_prefix):
        print("Error: Month prefix must be in YYYY-MM format (e.g., 2025-07)")
        return
    
    if not os.path.exists(args.journal_dir):
        print(f"Error: Directory '{args.journal_dir}' not found")
        return
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be modified")
    
    print(f"Processing journal files for {args.month_prefix}...")
    bookmarks_by_month = process_journal_files(args.journal_dir, args.month_prefix, args.dry_run, args.verbose)
    
    if bookmarks_by_month:
        created_files = create_bookmarks_files(bookmarks_by_month, args.dry_run, args.verbose)
        
        total_bookmarks = sum(len(bookmarks) for bookmarks in bookmarks_by_month.values())
        print(f"Total bookmarks extracted: {total_bookmarks}")
        
        if args.dry_run:
            print(f"Would create {len(created_files)} bookmark files:")
            for file in created_files:
                print(f"  - {file}")
        else:
            print(f"Created {len(created_files)} bookmark files")
    else:
        print("No bookmarks found in journal files")


if __name__ == "__main__":
    main()