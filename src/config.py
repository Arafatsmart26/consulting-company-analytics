"""
Configuration settings for data generation.
"""
import os
from pathlib import Path

# Project root directory
PROJECT_ROOT = Path(__file__).parent.parent

# Data directories
DATA_RAW = PROJECT_ROOT / "data" / "raw"
DATA_PROCESSED = PROJECT_ROOT / "data" / "processed"

# Database
DB_PATH = PROJECT_ROOT / "analytics.db"

# Ensure directories exist
DATA_RAW.mkdir(parents=True, exist_ok=True)
DATA_PROCESSED.mkdir(parents=True, exist_ok=True)

# Data generation parameters
RANDOM_SEED = 42
START_DATE = "2023-01-01"
END_DATE = "2024-06-30"  # 18 months
MONTHS = 18

# Consultant parameters
NUM_CONSULTANTS = 45
CONSULTANT_LEVELS = ["Junior", "Consultant", "Senior", "Lead"]
CONSULTANT_ROLES = ["Engineer", "Analyst", "PM"]
COUNTRIES = ["Denmark", "Norway", "Sweden", "UK"]

# Cost rates by level (DKK per hour)
COST_RATES = {
    "Junior": 450,
    "Consultant": 650,
    "Senior": 900,
    "Lead": 1200
}

# Client parameters
NUM_CLIENTS = 25
SECTORS = ["Public", "Private"]

# Project parameters
NUM_PROJECTS = 45  # 30-60 range, using 45
CONTRACT_TYPES = ["T&M", "Fixed"]
MIN_PROJECT_DURATION_DAYS = 30
MAX_PROJECT_DURATION_DAYS = 270  # ~9 months

# Timesheet parameters
MIN_DAILY_HOURS = 6
MAX_DAILY_HOURS = 8
WEEKEND_HOURS_PROBABILITY = 0.1  # 10% chance of weekend work
BILLABLE_RATE = 0.75  # 75% of hours are billable on average

# Invoice parameters
INVOICE_FREQUENCY_DAYS = 30  # Monthly invoices
PAYMENT_DAYS_PUBLIC_MEAN = 45
PAYMENT_DAYS_PUBLIC_STD = 15
PAYMENT_DAYS_PRIVATE_MEAN = 25
PAYMENT_DAYS_PRIVATE_STD = 10
