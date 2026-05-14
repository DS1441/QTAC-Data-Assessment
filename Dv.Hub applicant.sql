USE QTAC_DataVault;
GO

-- 1. Creating Hub for Applicants Business Keys 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'hub_applicant' AND schema_id = SCHEMA_ID('dv'))
BEGIN
    CREATE TABLE dv.hub_applicant (
        hub_applicant_key BINARY(20) PRIMARY KEY,
        applicant_id NVARCHAR(50) UNIQUE,
        load_date DATETIME DEFAULT GETDATE(),
        record_source NVARCHAR(100)
    );
END
GO

-- 2. Integration ,consolidating all unique IDs from mulyiple source extracts
INSERT INTO dv.hub_applicant (hub_applicant_key, applicant_id, record_source)
SELECT DISTINCT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50))))), 
    CAST(applicant_id AS NVARCHAR(50)), 
    'staging.applicants'
FROM staging.applicants
WHERE applicant_id IS NOT NULL;

-- 3. Adding new applicants from the uddated extraction process
INSERT INTO dv.hub_applicant (hub_applicant_key, applicant_id, record_source)
SELECT DISTINCT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50))))), 
    CAST(applicant_id AS NVARCHAR(50)), 
    'staging.applicants_update'
FROM staging.applicants_update
WHERE CAST(applicant_id AS NVARCHAR(50)) NOT IN (SELECT applicant_id FROM dv.hub_applicant);
