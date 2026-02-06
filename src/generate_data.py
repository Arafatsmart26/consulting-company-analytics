"""
Generate synthetic consulting company data.
Creates realistic datasets for consultants, clients, projects, timesheets, and invoices.
"""
import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
from pathlib import Path

from src.config import *
from src.utils import *

fake = Faker(['da_DK', 'en_US', 'no_NO', 'sv_SE'])
Faker.seed(RANDOM_SEED)


def generate_consultants() -> pd.DataFrame:
    """Generate consultant dimension table."""
    set_seed(RANDOM_SEED)
    
    consultants = []
    for i in range(1, NUM_CONSULTANTS + 1):
        level = random.choice(CONSULTANT_LEVELS)
        role = random.choice(CONSULTANT_ROLES)
        country = random.choice(COUNTRIES)
        
        # Hire dates spread over last 3 years
        hire_date = random_date_between(
            datetime(2021, 1, 1),
            datetime(2023, 12, 31)
        )
        
        consultants.append({
            'consultant_id': i,
            'full_name': fake.name(),
            'level': level,
            'role': role,
            'country': country,
            'hire_date': hire_date.strftime('%Y-%m-%d'),
            'cost_rate_dkk_per_hour': COST_RATES[level]
        })
    
    df = pd.DataFrame(consultants)
    return df


def generate_clients() -> pd.DataFrame:
    """Generate client dimension table."""
    set_seed(RANDOM_SEED + 1)
    
    clients = []
    for i in range(1, NUM_CLIENTS + 1):
        sector = random.choice(SECTORS)
        country = random.choice(COUNTRIES)
        
        # Generate realistic company names
        if sector == "Public":
            client_name = f"{fake.city()} {random.choice(['Kommunen', 'Region', 'Styrelse', 'Ministerium'])}"
        else:
            client_name = fake.company()
        
        clients.append({
            'client_id': i,
            'client_name': client_name,
            'sector': sector,
            'country': country
        })
    
    df = pd.DataFrame(clients)
    return df


def generate_projects(clients_df: pd.DataFrame, consultants_df: pd.DataFrame) -> pd.DataFrame:
    """Generate project dimension table."""
    set_seed(RANDOM_SEED + 2)
    
    projects = []
    start_dt = datetime.strptime(START_DATE, "%Y-%m-%d")
    end_dt = datetime.strptime(END_DATE, "%Y-%m-%d")
    
    # Distribute projects across the 18-month period
    project_dates = []
    for _ in range(NUM_PROJECTS):
        project_start = random_date_between(start_dt, end_dt - timedelta(days=30))
        duration = random.randint(MIN_PROJECT_DURATION_DAYS, MAX_PROJECT_DURATION_DAYS)
        project_end = min(project_start + timedelta(days=duration), end_dt)
        project_dates.append((project_start, project_end))
    
    # Sort by start date for realism
    project_dates.sort(key=lambda x: x[0])
    
    for i, (proj_start, proj_end) in enumerate(project_dates, 1):
        client_id = random.randint(1, NUM_CLIENTS)
        contract_type = random.choice(CONTRACT_TYPES)
        
        # Select PM from consultants
        pm_candidates = consultants_df[consultants_df['role'] == 'PM']
        if len(pm_candidates) > 0:
            pm_id = random.choice(pm_candidates['consultant_id'].tolist())
        else:
            pm_id = random.randint(1, NUM_CONSULTANTS)
        
        # Budget hours based on duration and contract type
        # Fixed price projects tend to have tighter budgets
        if contract_type == "Fixed":
            budget_hours = random.randint(200, 1500)
        else:
            budget_hours = random.randint(300, 2000)
        
        # Budget value based on blended rate estimate
        # Assume average blended rate around 750 DKK/hour
        blended_rate_estimate = random.uniform(700, 900)
        budget_value_dkk = int(budget_hours * blended_rate_estimate)
        
        # Planned margin: Fixed price typically higher margin target
        if contract_type == "Fixed":
            planned_margin_pct = random.uniform(0.20, 0.35)
        else:
            planned_margin_pct = random.uniform(0.15, 0.25)
        
        project_name = f"{fake.catch_phrase()} {random.choice(['Project', 'Program', 'Initiative', 'Transformation'])}"
        
        projects.append({
            'project_id': i,
            'client_id': client_id,
            'project_name': project_name,
            'contract_type': contract_type,
            'start_date': proj_start.strftime('%Y-%m-%d'),
            'end_date': proj_end.strftime('%Y-%m-%d'),
            'project_manager_id': pm_id,
            'budget_hours': budget_hours,
            'budget_value_dkk': budget_value_dkk,
            'planned_margin_pct': round(planned_margin_pct, 3)
        })
    
    df = pd.DataFrame(projects)
    return df


def generate_timesheets(consultants_df: pd.DataFrame, projects_df: pd.DataFrame) -> pd.DataFrame:
    """Generate timesheet fact table."""
    set_seed(RANDOM_SEED + 3)
    
    timesheets = []
    dates = date_range(START_DATE, END_DATE)
    
    # Create mapping of active projects by date
    active_projects_by_date = {}
    for date in dates:
        active_projects_by_date[date] = projects_df[
            (pd.to_datetime(projects_df['start_date']) <= date) &
            (pd.to_datetime(projects_df['end_date']) >= date)
        ]['project_id'].tolist()
    
    entry_id = 1
    
    for consultant_id in range(1, NUM_CONSULTANTS + 1):
        consultant = consultants_df[consultants_df['consultant_id'] == consultant_id].iloc[0]
        level = consultant['level']
        
        # Utilization varies by level
        utilization_by_level = {
            "Junior": 0.70,
            "Consultant": 0.80,
            "Senior": 0.85,
            "Lead": 0.75  # Leads have more management overhead
        }
        target_utilization = utilization_by_level.get(level, 0.75)
        
        for date in dates:
            is_weekend_day = is_weekend(date)
            
            # Weekend work is rare
            if is_weekend_day and random.random() > WEEKEND_HOURS_PROBABILITY:
                continue
            
            # Daily hours: 6-8 on weekdays, 0-4 on weekends
            if is_weekend_day:
                hours = random.uniform(0, 4) if random.random() < 0.3 else 0
            else:
                hours = random.uniform(MIN_DAILY_HOURS, MAX_DAILY_HOURS)
            
            if hours == 0:
                continue
            
            # Determine if billable
            active_projects = active_projects_by_date.get(date, [])
            
            if active_projects and random.random() < target_utilization:
                # Billable work
                project_id = random.choice(active_projects)
                billable_flag = True
            else:
                # Non-billable (bench, training, internal)
                project_id = None
                billable_flag = False
            
            timesheets.append({
                'entry_id': entry_id,
                'work_date': date.strftime('%Y-%m-%d'),
                'consultant_id': consultant_id,
                'project_id': project_id,
                'hours': round(hours, 2),
                'billable_flag': 1 if billable_flag else 0
            })
            entry_id += 1
    
    df = pd.DataFrame(timesheets)
    return df


def generate_invoices(projects_df: pd.DataFrame, clients_df: pd.DataFrame) -> pd.DataFrame:
    """Generate invoice fact table."""
    set_seed(RANDOM_SEED + 4)
    
    invoices = []
    invoice_id = 1
    
    for _, project in projects_df.iterrows():
        project_id = project['project_id']
        client_id = project['client_id']
        start_date = datetime.strptime(project['start_date'], '%Y-%m-%d')
        end_date = datetime.strptime(project['end_date'], '%Y-%m-%d')
        contract_type = project['contract_type']
        
        client = clients_df[clients_df['client_id'] == client_id].iloc[0]
        sector = client['sector']
        
        # Generate monthly invoices while project is active
        invoice_date = start_date
        
        while invoice_date <= end_date:
            # Invoice amount varies by contract type
            if contract_type == "Fixed":
                # Fixed price: distribute budget over invoices
                num_invoices_estimate = max(1, (end_date - start_date).days // INVOICE_FREQUENCY_DAYS)
                amount = project['budget_value_dkk'] / num_invoices_estimate
                amount = amount * random.uniform(0.9, 1.1)  # Some variation
            else:
                # T&M: variable based on hours worked (estimate)
                hours_estimate = random.uniform(40, 160)  # Monthly hours
                rate_estimate = random.uniform(700, 900)
                amount = hours_estimate * rate_estimate
            
            # Payment days based on sector
            if sector == "Public":
                payment_days = max(0, int(np.random.normal(PAYMENT_DAYS_PUBLIC_MEAN, PAYMENT_DAYS_PUBLIC_STD)))
            else:
                payment_days = max(0, int(np.random.normal(PAYMENT_DAYS_PRIVATE_MEAN, PAYMENT_DAYS_PRIVATE_STD)))
            
            # Payment status: older invoices more likely to be paid
            days_since_invoice = (datetime.strptime(END_DATE, '%Y-%m-%d') - invoice_date).days
            if days_since_invoice > payment_days:
                paid_flag = True if random.random() > 0.2 else False  # 80% paid if past due date
            else:
                paid_flag = True if random.random() > 0.6 else False  # 40% paid if not yet due
            
            invoices.append({
                'invoice_id': invoice_id,
                'project_id': project_id,
                'invoice_date': invoice_date.strftime('%Y-%m-%d'),
                'amount_dkk': int(amount),
                'paid_flag': 1 if paid_flag else 0,
                'payment_days': payment_days
            })
            
            invoice_id += 1
            invoice_date += timedelta(days=INVOICE_FREQUENCY_DAYS)
    
    df = pd.DataFrame(invoices)
    return df


def main():
    """Main function to generate all datasets."""
    print("Generating synthetic consulting data...")
    print(f"Random seed: {RANDOM_SEED}")
    
    # Generate dimension tables
    print("Generating consultants...")
    consultants_df = generate_consultants()
    consultants_df.to_csv(DATA_RAW / "dim_consultant.csv", index=False)
    print(f"  Created {len(consultants_df)} consultants")
    
    print("Generating clients...")
    clients_df = generate_clients()
    clients_df.to_csv(DATA_RAW / "dim_client.csv", index=False)
    print(f"  Created {len(clients_df)} clients")
    
    print("Generating projects...")
    projects_df = generate_projects(clients_df, consultants_df)
    projects_df.to_csv(DATA_RAW / "dim_project.csv", index=False)
    print(f"  Created {len(projects_df)} projects")
    
    # Generate fact tables
    print("Generating timesheets (this may take a moment)...")
    timesheets_df = generate_timesheets(consultants_df, projects_df)
    timesheets_df.to_csv(DATA_RAW / "fact_timesheet.csv", index=False)
    print(f"  Created {len(timesheets_df)} timesheet entries")
    
    print("Generating invoices...")
    invoices_df = generate_invoices(projects_df, clients_df)
    invoices_df.to_csv(DATA_RAW / "fact_invoice.csv", index=False)
    print(f"  Created {len(invoices_df)} invoices")
    
    print("\nData generation complete!")
    print(f"Files saved to: {DATA_RAW}")
    print("\nGenerated files:")
    for file in DATA_RAW.glob("*.csv"):
        size_mb = file.stat().st_size / (1024 * 1024)
        print(f"  - {file.name} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
