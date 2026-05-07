#!/usr/bin/env python3
"""
Script to delete empty journal files.
- Processes files with YYYY-MM-DD.md format
- Identifies truly empty files (no content after stripping whitespace)
- Deletes empty files
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


def is_file_empty(content):
    """Check if file content is effectively empty (only whitespace)"""
    return not content.strip()


def show_file_content(filename, content, verbose=False):
    """Show file content that would be deleted"""
    if not verbose:
        return
        
    print(f"\n{Colors.BOLD}{filename} content:{Colors.RESET}")
    if content.strip():
        for i, line in enumerate(content.split('\n')):
            print(f"{Colors.RED}-{i+1:3}: {line}{Colors.RESET}")
    else:
        print(f"{Colors.YELLOW}(file is empty or contains only whitespace){Colors.RESET}")


def process_journal_files(journal_dir, month_prefix=None, dry_run=False, verbose=False):
    """Process all journal files and identify empty ones for deletion"""
    journal_path = Path(journal_dir)
    files_to_delete = []
    files_processed = 0
    
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
        
        files_processed += 1
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue
            
        if is_file_empty(content):
            files_to_delete.append(file_path)
            if verbose:
                show_file_content(filename, content, True)
    
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
    
    return files_to_delete, files_processed


def main():
    """Main function"""
    # Set up signal handler for graceful exit
    signal.signal(signal.SIGINT, signal_handler)
    
    parser = argparse.ArgumentParser(
        description="Delete empty markdown journal files.",
        epilog="""
Examples:
  %(prog)s --dry-run . 2025-07          # Dry run for July 2025 in current directory
  %(prog)s Journal 2025-08              # Process August 2025 files in Journal directory
  %(prog)s --dry-run --verbose          # Interactive mode with dry run and detailed output
  %(prog)s -v . 2025-07                 # Verbose mode showing file contents before deletion
  
The script processes files named YYYY-MM-DD.md and deletes files that contain
only whitespace or are completely empty.
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
                       help="Show detailed output including file contents before deletion")
    
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
        print("DRY RUN MODE - No files will be deleted")
    
    print(f"Processing journal files for {args.month_prefix}...")
    files_to_delete, files_processed = process_journal_files(args.journal_dir, args.month_prefix, args.dry_run, args.verbose)
    
    if files_to_delete:
        if args.dry_run:
            print(f"Found {len(files_to_delete)} empty files (out of {files_processed} processed) that would be deleted:")
            for file_path in files_to_delete:
                print(f"  - {file_path.name}")
        else:
            print(f"Deleted {len(files_to_delete)} empty files (out of {files_processed} processed)")
    else:
        print(f"No empty files found (processed {files_processed} files)")


if __name__ == "__main__":
    main()