# -*- coding: utf-8 -*-
"""
Created on Wed May 13 12:43:10 2026

@author: hp
"""

import pandas as pd
from sqlalchemy import create_engine
import os


connection_string = (
    "mssql+pyodbc://DESKTOP-HP15NIT/QTAC_DataVault?"
    "driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)
engine = create_engine(connection_string)


path = r'C:\QTAC' 

# The list of files to process
files = {
    'applicants.csv': 'applicants',
    'applicants_update.csv': 'applicants_update',
    'courses.csv': 'courses',
    'preferences.csv': 'preferences',
    'qualifications.csv': 'qualifications'
}

print("--- Starting Bronze/Staging Load ---")

for file_name, table_name in files.items():
    full_path = os.path.join(path, file_name)
    
    if os.path.exists(full_path):
        # Read the CSV
        df = pd.read_csv(full_path)
        
        # Load into the 'staging' schema
        df.to_sql(table_name, schema='staging', con=engine, if_exists='replace', index=False)
        print(f"✅ Success: {file_name} -> staging.{table_name}")
    else:
       
        print(f"❌ Error: Could not find '{file_name}' in {path}")

print("--- Data Ingestion Complete ---")
