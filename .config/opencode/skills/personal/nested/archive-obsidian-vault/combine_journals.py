#!/usr/bin/env python3
"""
Script to combine journal files into monthly aggregated files.
- Processes files with YYYY-MM-DD.md format
- Ignores other files like @YYYY-MM Links.md
- Combines all daily journal entries for a month into @YYYY-MM Journal.md
- Supports --dry-run mode to preview changes without modifying files
"""

import os
import re
import argparse
import signal
import sys
from pathlib import Path
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


def get_month_year_from_date(date_obj):
    """Get YYYY-MM format from date object"""
    return date_obj.strftime('%Y-%m')


def shift_headings_down(content):
    """Shift all markdown headings down by one level"""
    lines = content.split('\n')
    shifted_lines = []
    
    for line in lines:
        # Check if line starts with markdown heading
        if re.match(r'^#+\s', line):
            # Add one more # to shift heading down a level
            shifted_line = '#' + line
            shifted_lines.append(shifted_line)
        else:
            shifted_lines.append(line)
    
    return '\n'.join(shifted_lines)


def process_journal_files(journal_dir, month_prefix=None, dry_run=False, verbose=False):
    """Process all journal files and combine them by month"""
    journal_path = Path(journal_dir)
    monthly_entries = {}
    files_to_delete = []
    files_processed = 0
    
    # Collect all journal files and group by month
    for file_path in sorted(journal_path.glob('*.md')):
        filename = file_path.name
        
        if not is_journal_file(filename):
            if verbose:
                print(f"Skipping non-journal file: {filename}")
            continue
            
        date_obj = extract_date_from_filename(filename)
        if not date_obj:
            continue
            
        # Filter by month prefix if specified
        if month_prefix:
            file_month_prefix = date_obj.strftime('%Y-%m')
            if file_month_prefix != month_prefix:
                continue
        
        files_processed += 1
        month_key = get_month_year_from_date(date_obj)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read().strip()
        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue
        
        if month_key not in monthly_entries:
            monthly_entries[month_key] = []
        
        # Add entry with date header and content
        date_header = f"# {date_obj.strftime('%Y-%m-%d')}"
        if content:
            # Shift down any existing headings by one level
            content = shift_headings_down(content)
            entry = f"{date_header}\n\n{content}"
        else:
            entry = f"{date_header}\n\n*(No content)*"
        
        monthly_entries[month_key].append((date_obj, entry))
        files_to_delete.append(file_path)
        
        if verbose:
            print(f"Added {filename} to {month_key} journal")
    
    # Create combined files for each month
    files_created = 0
    for month_key, entries in monthly_entries.items():
        if not entries:
            continue
            
        # Sort entries by date
        entries.sort(key=lambda x: x[0])
        
        # Create combined content
        combined_content = "\n\n".join([entry[1] for entry in entries])
        combined_content += "\n"
        
        # Create output filename
        output_filename = f"{month_key} Journal.md"
        output_path = journal_path / output_filename
        
        if dry_run:
            print(f"[DRY RUN] Would create: {output_filename} ({len(entries)} entries)")
            print(f"\n{Colors.BOLD}=== Content of {output_filename} ==={Colors.RESET}")
            print(combined_content)
            print(f"{Colors.BOLD}=== End of {output_filename} ==={Colors.RESET}\n")
        else:
            try:
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(combined_content)
                print(f"Created: {output_filename} ({len(entries)} entries)")
                files_created += 1
            except Exception as e:
                print(f"Error creating {output_filename}: {e}")
    
    # Delete original files after successful combination
    files_deleted = 0
    if not dry_run and files_created > 0:
        for file_path in files_to_delete:
            try:
                file_path.unlink()
                files_deleted += 1
                if verbose:
                    print(f"Deleted original file: {file_path.name}")
            except Exception as e:
                print(f"Error deleting {file_path.name}: {e}")
        
        if files_deleted > 0:
            print(f"Deleted {files_deleted} original journal files")
    elif dry_run and len(files_to_delete) > 0:
        print(f"[DRY RUN] Would delete {len(files_to_delete)} original journal files")
    
    return files_created, files_processed


def main():
    """Main function"""
    # Set up signal handler for graceful exit
    signal.signal(signal.SIGINT, signal_handler)
    
    parser = argparse.ArgumentParser(
        description="Combine daily journal files into monthly aggregated files.",
        epilog="""
Examples:
  %(prog)s --dry-run . 2025-07          # Dry run for July 2025 in current directory
  %(prog)s Journal 2025-08              # Process August 2025 files in Journal directory
  %(prog)s --dry-run --verbose          # Interactive mode with dry run and detailed output
  %(prog)s -v . 2025-07                 # Verbose mode showing processing details
  
The script processes files named YYYY-MM-DD.md and creates YYYY-MM Journal.md files
containing all daily entries for each month, organized chronologically.
Original daily files are deleted after successful combination.
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
                       help="Show detailed output including processing details")
    
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
            prompt = "[DRY RUN] Enter month prefix (YYYY-MM, or leave empty for all months): " if args.dry_run else "Enter month prefix (YYYY-MM, or leave empty for all months): "
            month_input = input(prompt).strip()
            args.month_prefix = month_input if month_input else None
        except KeyboardInterrupt:
            print("\n\nOperation cancelled by user.")
            sys.exit(0)
    
    # Validate month prefix format if provided
    if args.month_prefix and not re.match(r'^\d{4}-\d{2}$', args.month_prefix):
        print("Error: Month prefix must be in YYYY-MM format (e.g., 2025-07)")
        return
    
    if not os.path.exists(args.journal_dir):
        print(f"Error: Directory '{args.journal_dir}' not found")
        return
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be created")
    
    if args.month_prefix:
        print(f"Processing journal files for {args.month_prefix}...")
    else:
        print("Processing all journal files...")
        
    files_created, files_processed = process_journal_files(args.journal_dir, args.month_prefix, args.dry_run, args.verbose)
    
    if args.dry_run:
        print(f"Would create {files_created} monthly journal files from {files_processed} daily journal files")
    else:
        print(f"Created {files_created} monthly journal files from {files_processed} daily journal files")


if __name__ == "__main__":
    main()