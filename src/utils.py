"""
Utility functions for data generation.
"""
import random
from datetime import datetime, timedelta
from typing import List, Tuple


def set_seed(seed: int):
    """Set random seed for reproducibility."""
    random.seed(seed)
    import numpy as np
    np.random.seed(seed)


def date_range(start_date: str, end_date: str) -> List[datetime]:
    """Generate list of dates between start and end (inclusive)."""
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    dates = []
    current = start
    while current <= end:
        dates.append(current)
        current += timedelta(days=1)
    return dates


def is_weekend(date: datetime) -> bool:
    """Check if date is weekend (Saturday=5, Sunday=6)."""
    return date.weekday() >= 5


def get_work_days(start_date: str, end_date: str) -> List[datetime]:
    """Get only weekdays (Monday-Friday) in date range."""
    dates = date_range(start_date, end_date)
    return [d for d in dates if not is_weekend(d)]


def weighted_choice(choices: List, weights: List[float]) -> str:
    """Choose from list based on weights."""
    return random.choices(choices, weights=weights, k=1)[0]


def random_date_between(start: datetime, end: datetime) -> datetime:
    """Generate random date between start and end."""
    time_between = end - start
    days_between = time_between.days
    random_days = random.randrange(days_between)
    return start + timedelta(days=random_days)


def calculate_blended_rate(consultants: List[dict], project_hours: dict) -> float:
    """Calculate blended hourly rate for a project based on consultant assignments."""
    if not project_hours:
        return 800  # Default rate
    
    total_cost = sum(
        consultants[cid]['cost_rate'] * hours 
        for cid, hours in project_hours.items()
    )
    total_hours = sum(project_hours.values())
    return total_cost / total_hours if total_hours > 0 else 800
