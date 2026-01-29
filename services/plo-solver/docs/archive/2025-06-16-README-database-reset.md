# Database Reset Script

The database reset script provides a safe and reliable way to completely reset your PLO Solver database.

## Usage

```bash
# Show help
scripts/operations/reset-database.sh --help

# Check database connection
scripts/operations/reset-database.sh --check

# Show database information
scripts/operations/reset-database.sh --info

# Reset database (interactive - will ask for confirmation)
scripts/operations/reset-database.sh
```

## What it Does

### Interactive Reset (`scripts/operations/reset-database.sh`)
1. **Shows current database state** - Lists existing tables and row counts
2. **Asks for confirmation** - You must type 'y' to proceed
3. **Drops the entire database** - Completely removes the `plosolver` database
4. **Creates a fresh database** - Creates a new empty `plosolver` database
5. **Recreates all tables** - Uses Flask-SQLAlchemy models to create all tables
6. **Shows final state** - Displays the new database structure

### Information Commands
- `--info` - Shows current database tables and row counts
- `--check` - Tests database connection
- `--help` - Shows usage information

## Prerequisites

1. **PostgreSQL must be running**
   ```bash
   # Check if running
   pg_isready -h localhost -p 5432 -U postgres
   
   # Start if needed
   brew services start postgresql
   ```

2. **Python environment set up**
   - Flask application in `backend/` directory
   - Database models properly configured
   - Dependencies installed

## Database Configuration

The script uses these default settings:
- **Host:** localhost
- **Port:** 5432
- **User:** postgres
- **Password:** postgres
- **Database:** plosolver

You can modify these in the script header if your setup is different.

## Files Created

- `scripts/operations/reset-database.sh` - Main shell script
- `backend/reset_db.py` - Python helper script for database operations

## Example Output

```bash
➜ scripts/operations/reset-database.sh --info
🗄️ PLO Solver Database Reset Script
====================================

🔍 Checking database information...
✅ PostgreSQL is running
ℹ️ Current database information:
  📊 Database 'plosolver' exists
📊 Database Information:
  Database URL: postgresql://postgres:postgres@localhost:5432/plosolver
  Tables (3): users, user_sessions, spots
    users: 2 rows
    user_sessions: 3 rows
    spots: 0 rows
```

## Safety Features

- **Interactive confirmation** - Won't proceed without explicit 'y' confirmation
- **Connection verification** - Checks PostgreSQL is running first
- **Error handling** - Stops on any error and shows clear messages
- **Information display** - Shows before/after state for verification

## Python Helper Script

The `backend/reset_db.py` script can also be used directly:

```bash
cd backend
python reset_db.py reset   # Reset database
python reset_db.py info    # Show database info
python reset_db.py check   # Check connection
python reset_db.py seed    # Add seed data
```

## Common Issues

1. **PostgreSQL not running**
   ```
   ❌ PostgreSQL is not running!
   ```
   Solution: Start PostgreSQL with `brew services start postgresql`

2. **Backend directory not found**
   ```
   ❌ Backend directory not found
   ```
   Solution: Run from the project root directory

3. **Database connection failed**
   ```
   ❌ Database connection failed
   ```
   Solution: Check PostgreSQL settings and credentials 