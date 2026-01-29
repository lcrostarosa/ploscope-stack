#!/usr/bin/env python3
"""
Environment File Synchronization Script

This script synchronizes the order of environment variables across all env files
in the project, using env.example as the master template.

Features:
- Reorders variables to match env.example
- Identifies duplicates within files
- Reports missing variables from env.example
- Reports new variables not in env.example
- Preserves comments and section headers
- Generates a detailed report of changes

Usage:
    python scripts/utilities/sync_env_files.py [--dry-run] [--backup]
"""

import os
import re
import shutil
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional
from collections import defaultdict
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class EnvFileParser:
    """Parser for environment files that preserves structure and comments."""
    
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.variables: Dict[str, str] = {}
        self.comments: List[str] = []
        self.sections: List[Tuple[str, List[str]]] = []
        self.duplicates: List[str] = []
        
    def parse(self) -> None:
        """Parse the environment file and extract variables, comments, and sections."""
        if not self.file_path.exists():
            logger.warning(f"File {self.file_path} does not exist")
            return
            
        current_section = "General"
        current_section_lines = []
        
        with open(self.file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for line_num, line in enumerate(lines, 1):
            line = line.rstrip('\n')
            
            # Skip empty lines
            if not line.strip():
                if current_section_lines:
                    self.sections.append((current_section, current_section_lines))
                    current_section_lines = []
                continue
                
            # Check for section headers (lines starting with # and containing =)
            if line.strip().startswith('#') and '=' in line:
                if current_section_lines:
                    self.sections.append((current_section, current_section_lines))
                current_section = line.strip('# ').split('=')[0].strip()
                current_section_lines = [line]
                continue
                
            # Check for comments
            if line.strip().startswith('#'):
                current_section_lines.append(line)
                self.comments.append(line)
                continue
                
            # Check for variable assignments
            if '=' in line and not line.strip().startswith('#'):
                parts = line.split('=', 1)
                if len(parts) == 2:
                    var_name = parts[0].strip()
                    var_value = parts[1].strip()
                    
                    # Check for duplicates
                    if var_name in self.variables:
                        self.duplicates.append(var_name)
                        logger.warning(f"Duplicate variable '{var_name}' found in {self.file_path}")
                    
                    self.variables[var_name] = var_value
                    current_section_lines.append(line)
                else:
                    current_section_lines.append(line)
            else:
                current_section_lines.append(line)
                
        # Add the last section
        if current_section_lines:
            self.sections.append((current_section, current_section_lines))


class EnvFileSynchronizer:
    """Synchronizes environment files using a master template."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.master_file = project_root / "env.example"
        self.env_files = self._find_env_files()
        self.master_parser = EnvFileParser(self.master_file)
        self.file_parsers: Dict[Path, EnvFileParser] = {}
        self.report = {
            'duplicates': [],
            'missing_vars': [],
            'new_vars': [],
            'reordered_files': [],
            'errors': []
        }
        
    def _find_env_files(self) -> List[Path]:
        """Find all environment files in the project."""
        env_files = []
        for file_path in self.project_root.glob("env.*"):
            if file_path.name != "env.example":
                env_files.append(file_path)
        return sorted(env_files)
    
    def parse_all_files(self) -> None:
        """Parse all environment files."""
        logger.info("Parsing master file (env.example)...")
        self.master_parser.parse()
        
        logger.info(f"Parsing {len(self.env_files)} environment files...")
        for env_file in self.env_files:
            logger.info(f"Parsing {env_file.name}...")
            parser = EnvFileParser(env_file)
            parser.parse()
            self.file_parsers[env_file] = parser
    
    def analyze_files(self) -> None:
        """Analyze all files for issues."""
        logger.info("Analyzing files for duplicates, missing variables, and new variables...")
        
        # Get master variables
        master_vars = set(self.master_parser.variables.keys())
        
        for file_path, parser in self.file_parsers.items():
            file_vars = set(parser.variables.keys())
            
            # Check for duplicates
            if parser.duplicates:
                self.report['duplicates'].append({
                    'file': file_path.name,
                    'variables': parser.duplicates
                })
            
            # Check for missing variables (in master but not in file)
            missing = master_vars - file_vars
            if missing:
                self.report['missing_vars'].append({
                    'file': file_path.name,
                    'variables': sorted(missing)
                })
            
            # Check for new variables (in file but not in master)
            new_vars = file_vars - master_vars
            if new_vars:
                self.report['new_vars'].append({
                    'file': file_path.name,
                    'variables': sorted(new_vars)
                })
    
    def reorder_file(self, file_path: Path, parser: EnvFileParser, dry_run: bool = False) -> bool:
        """Reorder a file's variables to match the master template."""
        logger.info(f"Reordering {file_path.name}...")
        
        # Get the master variable order
        master_order = list(self.master_parser.variables.keys())
        
        # Create new content
        new_content = []
        
        # Add header comment if it exists
        if parser.comments and parser.comments[0].strip().startswith('# ==========================================='):
            new_content.append(parser.comments[0])
            new_content.append("")
        
        # Add variables in master order
        for var_name in master_order:
            if var_name in parser.variables:
                new_content.append(f"{var_name}={parser.variables[var_name]}")
        
        # Add any new variables not in master at the end
        master_vars_set = set(self.master_parser.variables.keys())
        file_vars = set(parser.variables.keys())
        new_vars = file_vars - master_vars_set
        
        if new_vars:
            new_content.append("")
            new_content.append("# Variables not in master template:")
            for var_name in sorted(new_vars):
                new_content.append(f"{var_name}={parser.variables[var_name]}")
        
        # Write the file
        if not dry_run:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(new_content) + '\n')
                self.report['reordered_files'].append(file_path.name)
                return True
            except Exception as e:
                logger.error(f"Error writing {file_path}: {e}")
                self.report['errors'].append(f"Error writing {file_path.name}: {e}")
                return False
        else:
            logger.info(f"[DRY RUN] Would reorder {file_path.name}")
            return True
    
    def sync_all_files(self, dry_run: bool = False, backup: bool = False) -> None:
        """Synchronize all environment files."""
        logger.info("Starting environment file synchronization...")
        
        # Parse all files
        self.parse_all_files()
        
        # Analyze for issues
        self.analyze_files()
        
        # Create backups if requested
        if backup and not dry_run:
            self._create_backups()
        
        # Reorder each file
        for file_path, parser in self.file_parsers.items():
            self.reorder_file(file_path, parser, dry_run)
        
        # Print report
        self._print_report()
    
    def _create_backups(self) -> None:
        """Create backup copies of all environment files."""
        backup_dir = self.project_root / "backups" / "env_files"
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        for file_path in self.env_files:
            backup_path = backup_dir / f"{file_path.name}.backup"
            shutil.copy2(file_path, backup_path)
            logger.info(f"Created backup: {backup_path}")
    
    def _print_report(self) -> None:
        """Print a detailed report of the synchronization."""
        print("\n" + "="*60)
        print("ENVIRONMENT FILE SYNCHRONIZATION REPORT")
        print("="*60)
        
        # Duplicates
        if self.report['duplicates']:
            print("\n❌ DUPLICATE VARIABLES FOUND:")
            for item in self.report['duplicates']:
                print(f"  {item['file']}: {', '.join(item['variables'])}")
        else:
            print("\n✅ No duplicate variables found")
        
        # Missing variables
        if self.report['missing_vars']:
            print("\n⚠️  MISSING VARIABLES (not in env.example):")
            for item in self.report['missing_vars']:
                print(f"  {item['file']}: {', '.join(item['variables'])}")
        else:
            print("\n✅ All files have all variables from env.example")
        
        # New variables
        if self.report['new_vars']:
            print("\n🆕 NEW VARIABLES (not in env.example):")
            for item in self.report['new_vars']:
                print(f"  {item['file']}: {', '.join(item['variables'])}")
        else:
            print("\n✅ No new variables found")
        
        # Reordered files
        if self.report['reordered_files']:
            print(f"\n🔄 REORDERED FILES ({len(self.report['reordered_files'])}):")
            for file_name in self.report['reordered_files']:
                print(f"  ✅ {file_name}")
        else:
            print("\n✅ No files were reordered")
        
        # Errors
        if self.report['errors']:
            print("\n❌ ERRORS:")
            for error in self.report['errors']:
                print(f"  {error}")
        
        print("\n" + "="*60)


def main():
    """Main function to run the environment file synchronization."""
    parser = argparse.ArgumentParser(
        description="Synchronize environment variable order across all env files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/utilities/sync_env_files.py --dry-run
  python scripts/utilities/sync_env_files.py --backup
  python scripts/utilities/sync_env_files.py --dry-run --backup
        """
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without making changes'
    )
    
    parser.add_argument(
        '--backup',
        action='store_true',
        help='Create backup copies of files before modifying them'
    )
    
    args = parser.parse_args()
    
    # Get project root (assuming script is in scripts/utilities/)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent
    
    if not (project_root / "env.example").exists():
        logger.error("env.example not found in project root")
        return 1
    
    # Create synchronizer and run
    synchronizer = EnvFileSynchronizer(project_root)
    
    try:
        synchronizer.sync_all_files(dry_run=args.dry_run, backup=args.backup)
        return 0
    except Exception as e:
        logger.error(f"Error during synchronization: {e}")
        return 1


if __name__ == "__main__":
    exit(main()) 