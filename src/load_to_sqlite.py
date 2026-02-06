"""
Load CSV data into SQLite database and create schema/views.
"""
import sqlite3
import pandas as pd
from pathlib import Path
import sys

from src.config import *


def create_database():
    """Create SQLite database and load schema."""
    print(f"Creating database: {DB_PATH}")
    
    # Remove existing database if it exists
    if DB_PATH.exists():
        DB_PATH.unlink()
        print("  Removed existing database")
    
    conn = sqlite3.connect(DB_PATH)
    print("  Database created")
    
    return conn


def load_schema(conn: sqlite3.Connection):
    """Load SQL schema from file."""
    schema_file = PROJECT_ROOT / "sql" / "schema.sql"
    
    if not schema_file.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_file}")
    
    print(f"\nLoading schema from {schema_file.name}...")
    with open(schema_file, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
    
    conn.executescript(schema_sql)
    conn.commit()
    print("  Schema loaded successfully")


def load_csv_to_table(conn: sqlite3.Connection, csv_path: Path, table_name: str):
    """Load CSV file into database table."""
    if not csv_path.exists():
        print(f"  WARNING: CSV file not found: {csv_path}")
        return
    
    print(f"  Loading {csv_path.name} -> {table_name}...")
    df = pd.read_csv(csv_path)
    
    # Handle NULL values in project_id for timesheets
    if table_name == 'fact_timesheet':
        df['project_id'] = df['project_id'].replace('', None)
        df['project_id'] = pd.to_numeric(df['project_id'], errors='coerce')
        # Replace NaN with None for proper NULL handling in SQLite
        df['project_id'] = df['project_id'].where(pd.notnull(df['project_id']), None)
    
    df.to_sql(table_name, conn, if_exists='append', index=False)
    print(f"    Loaded {len(df)} rows")


def load_data(conn: sqlite3.Connection):
    """Load all CSV files into database."""
    print("\nLoading data files...")
    
    tables = [
        ('dim_consultant.csv', 'dim_consultant'),
        ('dim_client.csv', 'dim_client'),
        ('dim_project.csv', 'dim_project'),
        ('fact_timesheet.csv', 'fact_timesheet'),
        ('fact_invoice.csv', 'fact_invoice'),
    ]
    
    for csv_file, table_name in tables:
        csv_path = DATA_RAW / csv_file
        load_csv_to_table(conn, csv_path, table_name)


def load_views(conn: sqlite3.Connection):
    """Load SQL views from file."""
    views_file = PROJECT_ROOT / "sql" / "views.sql"
    
    if not views_file.exists():
        raise FileNotFoundError(f"Views file not found: {views_file}")
    
    print(f"\nLoading views from {views_file.name}...")
    with open(views_file, 'r', encoding='utf-8') as f:
        views_sql = f.read()
    
    conn.executescript(views_sql)
    conn.commit()
    print("  Views created successfully")


def verify_data(conn: sqlite3.Connection):
    """Verify data was loaded correctly."""
    print("\nVerifying data...")
    
    tables = ['dim_consultant', 'dim_client', 'dim_project', 'fact_timesheet', 'fact_invoice']
    
    for table in tables:
        cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"  {table}: {count:,} rows")
    
    # Check views
    views = ['v_utilization_daily', 'v_project_financials', 'v_client_revenue', 'v_ar_aging']
    for view in views:
        try:
            cursor = conn.execute(f"SELECT COUNT(*) FROM {view}")
            count = cursor.fetchone()[0]
            print(f"  {view}: {count:,} rows")
        except sqlite3.OperationalError as e:
            print(f"  {view}: Error - {e}")


def main():
    """Main function to load data into SQLite."""
    print("=" * 60)
    print("Loading data into SQLite database")
    print("=" * 60)
    
    try:
        # Create database
        conn = create_database()
        
        # Load schema
        load_schema(conn)
        
        # Load data
        load_data(conn)
        
        # Load views
        load_views(conn)
        
        # Verify
        verify_data(conn)
        
        conn.close()
        
        print("\n" + "=" * 60)
        print("Database setup complete!")
        print(f"Database location: {DB_PATH}")
        print("=" * 60)
        
    except Exception as e:
        print(f"\nERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
