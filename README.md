QTAC Data Warehouse Engineering Assessment

Design Pattern: Data Vault 2.0 (Medallion Architecture)
1. Model Design & Rationale 
I selected Data Vault 2.0 for the warehouse layer (Silver) rather than a traditional Kimball Star Schema.
•	Adaptability: Data Vault is designed to handle the "messy" nature of source systems by decoupling business keys (Hubs) from descriptive context (Satellites).
•	Auditability & Versioning: By utilizing a composite primary key (Hash Key + load_date) in my Satellites, I successfully implemented SCD Type 2 history. This ensures that historical changes (such as James O'Connor's interstate move) are preserved as new versions rather than being overwritten.
•	Parallel Loading: The use of SHA1 Hashing allows for parallel ingestion, as keys can be generated independently of the database.
2. Data Quality Awareness & Edge Cases 
The source extracts contained intentional "traps" which I resolved within the SQL transformation logic:
•	Primary Key Violations (Duplicates): Spotted duplicate preference and applicant transactions. I implemented CTEs with ROW_NUMBER() to de-duplicate these at the point of ingestion.
•	Referential Integrity (Orphans): Identified qualification records for an applicant (ID 9999, present in qualifications data but missing from master applicant files). I utilized Inner Joins to ensure only validated data entered the warehouse.
•	Inconsistent Data Types: Addressed non-numeric strings in ATAR and GPA fields using TRY_CAST logic to maintain pipeline stability while preserving data quality.
3. SQL Logic & Ingestion and extraction Path using Python 
The pipeline follows a clean, idempotent path:
1.	Bronze (Staging): Automated Python ingestion using SQLAlchemy and Pandas. Staging tables are replaced per run to ensure a clean, idempotent start.
2.	Silver (Vault): Sequential loading following Data Vault dependencies: Hubs (Anchors) -> Satellites (Context) -> Links (Relationships).
3.	Gold (Mart): A business-ready View (gold.vw_ApplicantAdmissionSummary) that resolves the latest historical record (SCD2) and ranks preferences for reporting.
4.	Automated Extraction: A final Python extraction script was used to programmatically pull data from the warehouse and gold layers into the Submission_Files/ directory, ensuring the deliverables are a direct, error-free snapshot of the system.
4. Key Assumptions
•	Latest Truth: The record with the most recent load_date in a Satellite is considered the current business state.
•	Preference Priority: Per requirements, the lowest preference_order (1) is prioritized as the primary "Highest Preference" for the gold summary.
5. Bonus Features
•	Git History: A full commit history is provided showing the step-by-step development of the pipeline.
•	Model Diagram: A generated ERD is included to visualize the Hub-and-Spoke architecture.
•	Integrity Tests: SQL logic includes existence checks (NOT EXISTS) to prevent duplicate historical snapshots on re-runs.

